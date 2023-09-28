// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address poolAddress;
        address gauge_address;
        address minter_address;
        address lp_token_address;
        address DAI;
        address CRV;
        address owner;
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getEthereumConfig();
        }
        // else if (block.chainid == 11155111) {
        //     activeNetworkConfig = getSepoliaEthConfig();
        // } else {
        //     activeNetworkConfig = getOrCreateAnvilEthConfig();
        // }
    }

    function getEthereumConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            poolAddress: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
            gauge_address: 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A,
            minter_address: 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0,
            lp_token_address: 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490,
            DAI: 0x6B175474E89094C44Da98b954EedeAC495271d0F,
            CRV: 0xD533a949740bb3306d119CC777fa900bA034cd52,
            owner: 0xb8327672284895742D91Be59d45B5984972f6E1f,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    // function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
    //     return NetworkConfig({
    //         wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
    //         wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
    //         daiUsdPriceFeed: 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19,
    //         ghoUsdPriceFeed: 0x635A86F9fdD16Ff09A0701C305D3a845F1758b8E,
    //         weth: 0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92,
    //         wbtc: 0xf864F011C5A97fD8Da79baEd78ba77b47112935a,
    //         dai: 0x53844F9577C2334e541Aec7Df7174ECe5dF1fCf0,
    //         gho: 0x5d00fab5f2F97C4D682C1053cDCAA59c2c37900D,
    //         tokenPriceInUsd: 1e17,
    //         totalSupply: 1e7,
    //         unlockTimestamp: block.timestamp + 100 days,
    //         deployerKey: vm.envUint("PRIVATE_KEY")
    //     });
    // }

    // function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    //     if (activeNetworkConfig.wethUsdPriceFeed != address(0)) {
    //         return activeNetworkConfig;
    //     }

    //     vm.startBroadcast();
    //     MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
    //     ERC20Mock wethMock = new ERC20Mock();
    //     wethMock.mint(msg.sender, 1000e8);
    //     MockV3Aggregator btcUsdPriceFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
    //     ERC20Mock wbtcMock = new ERC20Mock();
    //     wbtcMock.mint(msg.sender, 1000e8);
    //     MockV3Aggregator daiUsdPriceFeed = new MockV3Aggregator(DECIMALS, DAI_USD_PRICE);
    //     ERC20Mock daiMock = new ERC20Mock();
    //     daiMock.mint(msg.sender, 1000e8);
    //     MockV3Aggregator ghoUsdPriceFeed = new MockV3Aggregator(DECIMALS, GHO_USD_PRICE);
    //     ERC20Mock ghoMock = new ERC20Mock();
    //     ghoMock.mint(msg.sender, 1000e8);
    //     vm.stopBroadcast();

    //     return NetworkConfig({
    //         wethUsdPriceFeed: address(ethUsdPriceFeed),
    //         wbtcUsdPriceFeed: address(btcUsdPriceFeed),
    //         daiUsdPriceFeed: address(daiUsdPriceFeed),
    //         ghoUsdPriceFeed: address(ghoUsdPriceFeed),
    //         weth: address(wethMock),
    //         wbtc: address(wbtcMock),
    //         dai: address(daiMock),
    //         gho: address(ghoMock),
    //         tokenPriceInUsd: 1e17,
    //         totalSupply: 1e7,
    //         unlockTimestamp: block.timestamp + 100 days,
    //         deployerKey: DEFAULT_ANVIL_KEY
    //     });
    // }
}
