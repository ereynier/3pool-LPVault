// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../../src/Vault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Handler is Test {
    Vault private vault;
    HelperConfig private config;

    address poolAddress;
    address gauge_address;
    address minter_address;
    address lp_token_address;
    address DAI;
    address CRV;
    address owner;

    constructor(Vault _vault, HelperConfig _config) {
        vault = _vault;
        config = _config;
        (poolAddress, gauge_address, minter_address, lp_token_address, DAI, CRV, owner,) = config.activeNetworkConfig();
    }


    function deposit(uint256 amount) external {
        if (amount == 0) return;
        amount = bound(amount, 1, 50000 ether);
        deal(DAI, address(this), amount);
        IERC20(DAI).approve(address(vault), amount);
        vault.deposit(amount);
    }

    function withdraw(uint256 lpAMount) external {
        if (lpAMount == 0) return;
        if (IERC20(vault).balanceOf(address(this)) == 0) return;
        lpAMount = bound(lpAMount, 1, IERC20(vault).balanceOf(address(this)));
        IERC20(vault).approve(address(vault), lpAMount);
        vault.withdraw(lpAMount);
    }

    function harvest() external {
        vault.harvest();
    }


    /* ===== Helper Functions ===== */

    function updateTimestamp() public {
        vm.warp(block.timestamp + 60);
    }

}
