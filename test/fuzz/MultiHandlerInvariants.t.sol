// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../../src/Vault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VaultDeployer} from "../../script/VaultDeployer.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";
import {ActorManager} from "./ActorManager.t.sol";

contract MultiHandlerInvariantsTest is StdInvariant, Test {
    Vault public vault;
    HelperConfig public config;
    VaultDeployer deployer;

    ActorManager manager;
    Handler[] public handlers;

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

        for (uint256 i = 0; i < 3; i++) {
            handlers.push(new Handler(vault, config));
        }

        (poolAddress, gauge_address, minter_address, lp_token_address, DAI, CRV, owner,) = config.activeNetworkConfig();

        vm.prank(owner);
        vault.setCharity(CHARITY);

        manager = new ActorManager(handlers);
        targetContract(address(manager));
    }

    function invariant_UsersBalancesShouldAlwaysBeLessOrEqualToMaxSupply() public {
        uint256 mintedLPs;
        uint256 vaultLPs;

        
        // for each handler count supply
        for (uint256 i = 0; i < handlers.length; i++) {
            mintedLPs += IERC20(vault).balanceOf(address(handlers[i]));
        }
        vaultLPs = IERC20(gauge_address).balanceOf(address(vault));

        assertEq(vaultLPs, mintedLPs);

        console.log("LPs ", vaultLPs);
    }
}
