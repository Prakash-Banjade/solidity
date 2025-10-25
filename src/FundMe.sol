// Users can fund (send ETH) to the owner
// Owner can withdraw the received ETH
// Restrict ETH amount to be sent to greater or equal to certain USD

// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {EthToUsdConverter} from "./EthToUsdConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using EthToUsdConverter for uint256;
    uint256 public constant MIN_USD = 5e18; // 5 USD (5 * 1e18)
    address public immutable i_owner; // convertion for immutable variables is `i_` as prefix

    // for looping throught the keys of `addressToFundAmount` mapping, we store the keys separately in `funders`
    mapping(address => uint256) public addressToFundAmount;
    address[] funders;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.convertEthToUsd() >= MIN_USD, "Not enough ETH");
        addressToFundAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        // reset the `addressToFundAmount` mapping values to 0 and reset the `funders` array
        for (uint i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToFundAmount[funder] = 0;
        }

        // funders = new address[](0); // fill with 0
        delete funders; // more gas efficient

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
}
