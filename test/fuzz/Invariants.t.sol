// Invariants:
// Getter view should never revert

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../../src/Vault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VaultDeployer} from "../../script/VaultDeployer.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    Vault public vault;
    HelperConfig public config;
    VaultDeployer deployer;

    Handler handler;

    address poolAddress;
    address gauge_address;
    address minter_address;
    address lp_token_address;
    address DAI;
    address CRV;
    address owner;

    address CHARITY = makeAddr("charity");

    function setUp() external {
        deployer = new VaultDeployer();
        (vault, config) = deployer.run();
        (poolAddress, gauge_address, minter_address, lp_token_address, DAI, CRV, owner,) = config.activeNetworkConfig();
        handler = new Handler(vault, config);

        vm.prank(owner);
        vault.setCharity(CHARITY);

        targetContract(address(handler));
    }

    function invariant_MintedLPsShouldAllwaysBeEqualToPoolLPsHoldByVault() public {
        uint256 mintedLPs;
        uint256 vaultLPs;

        mintedLPs = IERC20(vault).balanceOf(address(handler));
        vaultLPs = IERC20(gauge_address).balanceOf(address(vault));

        assertEq(vaultLPs, mintedLPs);
        console.log("LPs ", vaultLPs);
    }

    function invariant_gettersShouldNotRevert() public view {
        vault.exchangeRate();
    }
}
