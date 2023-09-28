// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/* ========== Imports ========== */

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/* ========== Interfaces, libraries, contracts ========== */
interface CurvePool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);
}

interface IGauge {
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;
}

interface Minter {
    function mint(address gauge_addr) external;
}

contract Vault is ERC20, Ownable, ReentrancyGuard {
    /* ========== Errors ========== */

    error Vault__InvalidAmount(uint256 amount);
    error Vault__InvalidToken(address token);
    error Vault__AllowanceToLow(uint256 amount, uint256 allowed);
    error Vault__ApproveFailed(uint256 amount);
    error Vault__TransferFailed(address token, uint256 amount, address from, address to);
    error Vault__InvalidAddress(address addr);

    /* ========== Types ========== */
    /* ========== State variables ========== */

    address public immutable poolAddress;
    CurvePool public immutable pool;
    address public immutable gauge_address;
    IGauge public immutable gauge;
    address public immutable minter_address;
    Minter public immutable minter;
    address public immutable lp_token_address;

    address public immutable DAI; // 0x6B175474E89094C44Da98b954EedeAC495271d0F
    address public immutable CRV; // 0xD533a949740bb3306d119CC777fa900bA034cd52

    uint256 public slippage = 0.001 ether;
    address public charity;

    /* ========== Events ========== */

    event slippageChanged(uint256 newSlippage);
    event lpMinted(uint256 amount);

    /* ========== Modifiers ========== */

    modifier greaterThanZero(uint256 amount) {
        if (amount <= 0) {
            revert Vault__InvalidAmount(amount);
        }
        _;
    }

    /* ========== FUNCTIONS ========== */
    /* ========== constructor ========== */

    constructor(
        address _poolAddress,
        address _gauge_address,
        address _minter_address,
        address _lp_token_address,
        address _DAI,
        address _CRV,
        address _owner
    ) ERC20("Vault", "VAULT") {
        poolAddress = _poolAddress;
        pool = CurvePool(_poolAddress);
        gauge_address = _gauge_address;
        gauge = IGauge(_gauge_address);
        minter_address = _minter_address;
        minter = Minter(_minter_address);
        lp_token_address = _lp_token_address;
        DAI = _DAI;
        CRV = _CRV;
        transferOwnership(_owner);
    }

    /* ========== Receive ========== */
    /* ========== Fallback ========== */
    /* ========== External functions ========== */

    /**
     * @param _amountInWei The amount of DAI to deposit.
     * @notice This function will deposit the specified amount of DAI and send the LP tokens to the caller.
     * @dev This function will revert if the caller does not have enough DAI.
     * @dev This function will revert if the caller does not have enough allowance.
     * @dev This function will revert if the transferFrom fails.
     * @dev This function will revert if the approve fails.
     * @dev This function will revert if the add_liquidity fails.
     */
    function deposit(uint256 _amountInWei) external greaterThanZero(_amountInWei) nonReentrant {
        if (IERC20(DAI).allowance(msg.sender, address(this)) < _amountInWei) {
            revert Vault__AllowanceToLow(_amountInWei, IERC20(DAI).allowance(msg.sender, address(this)));
        }

        bool success = IERC20(DAI).transferFrom(msg.sender, address(this), _amountInWei);
        if (!success) {
            revert Vault__TransferFailed(DAI, _amountInWei, msg.sender, address(this));
        }

        success = IERC20(DAI).approve(poolAddress, _amountInWei);
        if (!success) {
            revert Vault__ApproveFailed(_amountInWei);
        }

        uint256[3] memory amounts = [_amountInWei, 0, 0];
        uint256 min_mint_amount = pool.calc_token_amount(amounts, true) * (1 ether - slippage) / 1 ether;
        uint256 balance_before = IERC20(lp_token_address).balanceOf(address(this));
        pool.add_liquidity(amounts, min_mint_amount);
        uint256 lp_received = IERC20(lp_token_address).balanceOf(address(this)) - balance_before;
        // Stake LP tokens
        success = IERC20(lp_token_address).approve(gauge_address, lp_received);
        if (!success) {
            revert Vault__ApproveFailed(lp_received);
        }
        gauge.deposit(lp_received);

        _mint(msg.sender, lp_received);
        emit lpMinted(lp_received);
    }

    /**
     * @param _lpAmount The amount of LP tokens to withdraw.
     * @notice This function will withdraw the specified amount of LP tokens and send the DAI to the caller. Whatever the slippage is.
     * @dev This function will revert if the caller does not have enough LP tokens.
     * @dev This function will revert if the caller does not have enough allowance.
     * @dev This function will revert if the transferFrom fails.
     */
    function withdraw(uint256 _lpAmount) external greaterThanZero(_lpAmount) nonReentrant {
        if (allowance(msg.sender, address(this)) < _lpAmount) {
            revert Vault__AllowanceToLow(_lpAmount, allowance(msg.sender, address(this)));
        }
        if (balanceOf(msg.sender) < _lpAmount) {
            revert Vault__InvalidAmount(_lpAmount);
        }
        _burn(msg.sender, _lpAmount);

        // Unstake LP tokens
        gauge.withdraw(_lpAmount);

        uint256 balanceBefore = IERC20(DAI).balanceOf(address(this));
        uint256 min_amount = 0;
        pool.remove_liquidity_one_coin(_lpAmount, 0, min_amount);
        uint256 amount_received = IERC20(DAI).balanceOf(address(this)) - balanceBefore;

        // Send back DAI to user
        bool success = IERC20(DAI).transfer(msg.sender, amount_received);
        if (!success) {
            revert Vault__TransferFailed(DAI, amount_received, address(this), msg.sender);
        }
    }

    /**
     * @notice This function will harvest the CRV tokens and send them to the charity, the caller and the owner. (1%, 1%, 98%)
     * @dev This function will revert if the charity address is invalid.
     * @dev This function will revert if the transfer fails.
     * @dev This function will revert if the mint fails.
     */
    function harvest() external {
        // Harvest CRV, swap to accepted token, split it between the charity, the caller (and the Owner?)
        if (charity == address(0)) {
            revert Vault__InvalidAddress(charity);
        }

        minter.mint(gauge_address);

        // TODO: Swap to accepted token (DAI ?)

        uint256 balance = IERC20(CRV).balanceOf(address(this));
        bool success = IERC20(CRV).transfer(msg.sender, balance / 100);
        if (!success) {
            revert Vault__TransferFailed(CRV, balance / 100, address(this), msg.sender);
        }

        success = IERC20(CRV).transfer(owner(), balance / 100);
        if (!success) {
            revert Vault__TransferFailed(CRV, balance / 100, address(this), owner());
        }

        success = IERC20(CRV).transfer(charity, IERC20(CRV).balanceOf(address(this)));
        if (!success) {
            revert Vault__TransferFailed(CRV, IERC20(CRV).balanceOf(address(this)), address(this), charity);
        }
    }

    /**
     * @param _slippage The new slippage.
     * @notice This function is used to set the slippage tolerence.
     */
    function setSlippage(uint256 _slippage) external onlyOwner {
        if (_slippage > 0.01 ether) {
            revert Vault__InvalidAmount(_slippage);
        }
        slippage = _slippage;
        emit slippageChanged(_slippage);
    }

    /**
     * @param _charity The new charity address.
     * @notice This function is used to set the charity address.
     * @notice Careful, centralization risk.
     */
    function setCharity(address _charity) external onlyOwner {
        charity = _charity;
    }

    /* ========== Public functions ========== */
    /* ========== Internal functions ========== */
    /* ========== Private functions ========== */
    /* ========== Internal & private view / pure functions ========== */
    /* ========== External & public view / pure functions ========== */

    /**
     * @return The current exchange rate.
     * @notice This function is used to calculate the amount of LP tokens to expect for 1 DAI.
     */
    function exchangeRate() external view returns (uint256) {
        uint256[3] memory amounts = [uint256(1 ether), 0, 0];
        uint256 lp_received = pool.calc_token_amount(amounts, true);
        return lp_received;
    }
}
