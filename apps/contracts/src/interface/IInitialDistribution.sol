// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


interface IInitialDistribution {
    
    function registerAsset(address _asset) external returns (bool success);
}