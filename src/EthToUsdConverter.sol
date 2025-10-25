// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// AggregatorV3Interface ABI: https://docs.chain.link/chainlink-local/api-reference/v022/aggregator-v3-interface
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library EthToUsdConverter {
    // Returns ETH price scaled to 18 decimals
    function getLatestEthPrice() public view returns (uint256) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD price feed contract address
        );

        (, int256 price, , uint256 updatedAt, ) = dataFeed.latestRoundData(); // price is something like 4000_00000000
        require(price > 0, "bad price");
        require(updatedAt != 0, "stale price");

        uint8 decimals = dataFeed.decimals(); // usually 8 for USD feeds
        // scale to 18 decimals without assuming 8
        uint256 scale = 10 ** (18 - decimals); // e.g. 10000000000

        // casting to 'uint256' is safe because Chainlink price feeds always return positive values
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(price) * scale; // e.g. 4000_00000000 * 10000000000
    }

    // Converts ETH amount (wei) to USD (18 decimals)
    function convertEthToUsd(
        uint256 ethAmountWei
    ) internal view returns (uint256) {
        uint256 ethPrice18 = getLatestEthPrice(); // 18 decimals
        // (ethPrice18 * ethAmountWei) / 1e18 keeps 18-decimal USD
        return (ethPrice18 * ethAmountWei) / 1e18;
    }
}
