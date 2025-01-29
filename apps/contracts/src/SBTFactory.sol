// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { SBT } from "src/SBT.sol";
import "src/utils/Events.sol";

contract SBTFactory {
    address immutable harberger;

    constructor(address _harberger) {
        harberger = _harberger;
    }

    /**
     * @dev Used to create a Harberger SBT Asset
     * @param _name Name of the asset
     * @param _symbol Symbol of the asset
     * @param _initialOwner Initial Owner of the asset
     */
    function createSbtAsset(
        string memory _name,
        string memory _symbol,
        address _initialOwner
    )
        external
        returns (address assetAddress)
    {
        SBT sbtAsset = new SBT(_name, _symbol, harberger, _initialOwner);

        assetAddress = address(sbtAsset);

        emit SBTFactory_New_Asset(assetAddress, _initialOwner, _name, _symbol);
    }
}
