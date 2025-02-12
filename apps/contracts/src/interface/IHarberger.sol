// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IHarberger {
    function registerSbt(address _asset, address _idc) external  returns (bool _success);
    
    function registerAsset(address _asset, uint _tokenId) external  returns (bool _success);

    function bid(address _asset, uint _tokenId, uint _bidAmount, uint _perceivedAssetValue)  external;

    function claim(address _asset, uint256 _assetId) external;

    function setTaxRate(address _asset, uint256 _assetId)  external;
}