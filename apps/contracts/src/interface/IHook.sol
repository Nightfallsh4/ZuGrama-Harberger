// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


interface IHook {
    

    function checkMint() external  returns (bool success);

    function checkBeforeBid(address _bidder, address _asset, address _assetId, uint _bidAmount, bytes memory _data)  external returns (bool success);

    function checkAfterBid(address _bidder, address _asset, address _assetId, uint _bidAmount, bytes memory _data) external returns (bool success); 

}