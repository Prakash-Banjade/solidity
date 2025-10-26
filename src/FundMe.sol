// Users can fund (send ETH) to the owner
// Owner can withdraw the received ETH
// Restrict ETH amount to be sent to greater or equal to certain USD

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {EthToUsdConverter} from "./EthToUsdConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using EthToUsdConverter for uint256;
    uint256 public constant MIN_USD = 5e18; // 5 USD (5 * 1e18)
    address private immutable i_owner; // convertion for immutable variables is `i_` as prefix
    AggregatorV3Interface private s_priceFeed; // convertion for storage variables is `s_` as prefix

    // for looping throught the keys of `s_addressToFundAmount` mapping, we store the keys separately in `s_funders`
    mapping(address => uint256) private s_addressToFundAmount;
    address[] private s_funders;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.convertEthToUsd(s_priceFeed) >= MIN_USD,
            "Not enough ETH"
        );
        s_addressToFundAmount[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;

        // reset the `s_addressToFundAmount` mapping values to 0 and reset the `s_funders` array
        for (uint i = 0; i < fundersLength; i++) {
            address funder = s_funders[i];
            s_addressToFundAmount[funder] = 0;
        }

        // s_funders = new address[](0); // fill with 0
        delete s_funders; // more gas efficient

        // send ether - 3 ways
        // 1. transfer
        // 2. send
        // 3. call - recommended approach
        (bool ok, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );

        require(ok, "call failed");
    }

    // when attached to a function, first checks sender is owner then executes the function code. It can be reversed also
    modifier onlyOwner() {
        _onlyOwner();
        _; // rest of the function code
    }

    function _onlyOwner() internal view {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
    }

    // someone can trigger our contract to run without specifying any function or can accidently send ether without any existing function call
    // at this point we can use `receive` and `fallback` special functions to catch such activities
    receive() external payable {
        // triggered automatically when no calldata is sent
        fund();
    }

    fallback() external payable {
        // triggered automatically when calldata is present
        fund();
    }

    function getVersion() external view returns (uint256) {
        return s_priceFeed.version();
    }

    function getAddressToFundAmount(
        address addr
    ) external view returns (uint256) {
        return s_addressToFundAmount[addr];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
