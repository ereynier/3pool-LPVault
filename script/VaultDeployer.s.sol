// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Vault} from "../src/Vault.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract VaultDeployer is Script {
    function run() external returns (Vault, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (
            address poolAddress,
            address gauge_address,
            address minter_address,
            address lp_token_address,
            address DAI,
            address CRV,
            address owner,
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        Vault vault = new Vault(
            poolAddress,
            gauge_address,
            minter_address,
            lp_token_address,
            DAI,
            CRV,
            owner
        );
        vm.stopBroadcast();

        return (vault, config);
    }
}
