// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {VaultDeployer} from "../../script/VaultDeployer.s.sol";
import {Vault} from "../../src/Vault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Gauge {
    function claimable_tokens(address addr) external returns (uint256);
}

contract PresaleTest is Test {
    VaultDeployer deployer;
    Vault vault;
    HelperConfig config;

    address poolAddress;
    address gauge_address;
    address minter_address;
    address lp_token_address;
    address DAI;
    address CRV;
    address owner;
    uint256 deployerKey;

    address public OWNER;
    address public USER_1 = makeAddr("user1");
    address public USER_2 = makeAddr("user2");
    address public CHARITY = makeAddr("charity");
    uint256 public constant STARTING_ERC20_BALANCE = 1000e18; // 1000 tokens

    function setUp() public {
        deployer = new VaultDeployer();
        (vault, config) = deployer.run();
        (poolAddress, gauge_address, minter_address, lp_token_address, DAI, CRV, owner, deployerKey) = config.activeNetworkConfig();
        OWNER = owner;
        deal(DAI, USER_1, STARTING_ERC20_BALANCE);
        deal(DAI, USER_2, STARTING_ERC20_BALANCE);
        vm.prank(OWNER);
        vault.setCharity(CHARITY);
    }

    /* ===== Constructor Tests ===== */


   
    /* ======= deposit Tests ======= */

    function testDepositGood() public {
        uint256 exchangeRate = vault.exchangeRate();
        vm.startPrank(USER_1);
        IERC20(DAI).approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();
        // user balance should be greater than exchange rate - slippage
        assertEq(IERC20(DAI).balanceOf(USER_1), STARTING_ERC20_BALANCE - 100 ether);
        assertGe(vault.balanceOf(USER_1), exchangeRate * 100 * (1 ether - vault.slippage()) / 1 ether); // rate * tokenExchanged * (1 - slippage) / 1e18
    }

    function testDepositRevertIfAmountIsZero() public {
        vm.startPrank(USER_1);
        IERC20(DAI).approve(address(vault), 0);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__InvalidAmount.selector, 0));
        vault.deposit(0);
        vm.stopPrank();
    }

    function testDepositRevertIfNotEnoughAllowed() public {
        vm.startPrank(USER_1);
        IERC20(DAI).approve(address(vault), 10 ether);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__AllowanceToLow.selector, 100 ether, 10 ether));
        vault.deposit(100 ether);
        vm.stopPrank();
    }

    /* ===== withdraw Tests ===== */

    function testWithdrawGood() public {
        vm.startPrank(USER_1);
        IERC20(DAI).approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();
        uint256 balanceBefore = IERC20(DAI).balanceOf(USER_1);
        vm.startPrank(USER_1);
        vault.approve(address(vault), vault.balanceOf(USER_1));
        vault.withdraw(vault.balanceOf(USER_1));
        vm.stopPrank();
        assertEq(vault.balanceOf(USER_1), 0);
        assertGt(IERC20(DAI).balanceOf(USER_1), balanceBefore);
        console.log(balanceBefore);
        console.log(IERC20(DAI).balanceOf(USER_1));
    }

    function testWithdrawRevertIfAmountIsZero() public {
        vm.startPrank(USER_1);
        vault.approve(address(vault), 0);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__InvalidAmount.selector, 0));
        vault.withdraw(0);
        vm.stopPrank();
    }

    function testWithdrawRevertIfAmountIsGreaterThanBalance() public {
        deal(address(vault), USER_1, 100 ether);
        vm.startPrank(USER_1);
        vault.approve(address(vault), 1000 ether);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__InvalidAmount.selector, 1000 ether));
        vault.withdraw(1000 ether);
        vm.stopPrank();
    }

    function testWithdrawRevertIfAllowanceToLow() public {
        vm.startPrank(USER_1);
        vault.approve(address(vault), 10 ether);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__AllowanceToLow.selector, 100 ether, 10 ether));
        vault.withdraw(100 ether);
        vm.stopPrank();
    }


    /* ===== harvest Tests ===== */

    function testHarvestGood() public {
        vm.startPrank(USER_1);
        IERC20(DAI).approve(address(vault), 100 ether);
        vault.deposit(100 ether);
        vm.stopPrank();
        vm.warp(block.timestamp + 365 days);
        Gauge gauge = Gauge(gauge_address);
        uint256 claimable = gauge.claimable_tokens(address(vault));
        console.log(claimable);
        vm.startPrank(USER_2);
        vault.harvest();
        vm.stopPrank();
        assertGt(IERC20(CRV).balanceOf(USER_2), 0);
        assertGt(IERC20(CRV).balanceOf(CHARITY), 0);
        assertGt(IERC20(CRV).balanceOf(OWNER), 0);
    }

    function testHarvestRevertIfCharityAddressIsZero() public {
        vm.startPrank(OWNER);
        vault.setCharity(address(0));
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__InvalidAddress.selector, address(0)));
        vault.harvest();
        vm.stopPrank();
    }

    /* ===== setSlippage Tests ===== */

    function testSetSlippageGood() public {
        vm.startPrank(OWNER);
        vault.setSlippage(0.00001 ether);
        vm.stopPrank();
        assertEq(vault.slippage(), 0.00001 ether);
    }

    function testSetSlippageRevertIfNotOwner() public {
        vm.startPrank(USER_1);
        vm.expectRevert();
        vault.setSlippage(0.00001 ether);
        vm.stopPrank();
    }

    function testSetSlippageRevertIfAboveMax() public {
        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(Vault.Vault__InvalidAmount.selector, 0.011 ether));
        vault.setSlippage(0.011 ether);
        vm.stopPrank();
    }

    /* ===== public & external view Tests ===== */

    
    /* ===== const getters Tests ===== */

   
    /* ===== immutable getters Tests ===== */

    
}
