// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughETHSent();
error FundMe__WithdrawFailed();

contract FundMe {
    using PriceConverter for uint256;

    address private immutable i_owner;
    uint256 public MINIMUM_USD = 5e18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address _priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
        i_owner = msg.sender;
    }

    address[] private s_funders;
    mapping(address funders => uint256 amountFunded)
        private s_addressToAmountFunded;

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "GAREEB ORR ETH BHEJ"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] =
            s_addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function getversion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Withrawsl failed!!");
    }

     function cheapwithdraw() public onlyOwner {
        uint256 fundersCount = s_funders.length;
        for (uint256 i = 0; i < fundersCount; i++) {
            s_addressToAmountFunded[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Withrawsl failed!!");
    }

    function getAddressToAmountFunded(
        address fundingaddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingaddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "NOT THE OWNER");
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
