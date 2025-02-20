// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


interface IPriceCalculator {
    
    function getPrice() external returns (uint256 price);

    function getCurrentPrice() external returns (uint256 currentPrice);

}