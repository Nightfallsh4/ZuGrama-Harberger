// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "src/utils/Errors.sol";
import "src/utils/Events.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Harberger } from "src/Harberger.sol";
import { SBT } from "src/SBT.sol";

contract Auction {
    using SafeERC20 for IERC20;

    struct AssetDetails {
        bool isAsset;
        uint64 auctionStartTime;
        uint64 auctionEndTime;
        uint64 validTill;
        address currentBidder;
        uint256 currentBid;
        uint256 currentTotalTax;
        uint256 currentInitialValue;
        uint256 minBid;
    }

    address immutable auctioner;
    IERC20 immutable USDC;

    mapping(address asset => mapping(uint256 assetId => AssetDetails details)) private assets;

    Harberger harberger;

    constructor(address _auctioner, address _usdc) {
        auctioner = _auctioner;
        USDC = IERC20(_usdc);
    }

    modifier onlyAuctioner() {
        if (msg.sender != auctioner) {
            revert Auction_NotAuctioner();
        }
        _;
    }

    modifier onlyAssetOwner(address _asset) {
        address owner = SBT(_asset).owner();
        if (owner != msg.sender) {
            revert Auction_SenderNotOwner();
        }
        _;
    }

    //////////////////////////////
    //////// External ////////////
    //////////////////////////////

    function bid(address _asset, uint256 _assetId, uint256 _bidAmount, uint256 _initialValue) external {
        AssetDetails memory assetDetails = assets[_asset][_assetId];
        checkAssetBidStatus(assetDetails);

        if (_bidAmount < assetDetails.minBid) {
            revert Auction_LessThanMinBid();
        }

        if (assetDetails.currentBid >= _bidAmount) {
            revert Auction_BidTooLess();
        }

        address previousBidder = assetDetails.currentBidder;
        uint256 previousAmount = assetDetails.currentBid;
        uint256 previousTax = assetDetails.currentTotalTax;

        uint256 tax = Harberger(harberger).getTotalTaxForValue(_initialValue);

        assetDetails.currentBid = _bidAmount;
        assetDetails.currentBidder = msg.sender;
        assetDetails.currentTotalTax = tax;
        assetDetails.currentInitialValue = _initialValue;
        assets[_asset][_assetId] = assetDetails;

        // @follow-up have to make it calculate the tax and get the entire amount
        // Total Tax for time period for bidding amount

        if (previousBidder != address(0)) {
            USDC.safeTransfer(previousBidder, previousAmount + previousTax);
        }

        USDC.safeTransferFrom(msg.sender, address(this), _bidAmount + tax); // @follow-up get total amount including tax
            // not just bid amount

        emit Auction_NewBid(msg.sender, _bidAmount);
    }

    function claim(address _asset, uint256 _assetId, address _bidder) external {
        // @follow-up can we just have the initial bid as initialValue
        AssetDetails memory assetDetails = assets[_asset][_assetId];
        checkAssetClaimStatus(assetDetails, _bidder);

        // @follow-up Approve first
        USDC.approve(address(harberger), assetDetails.currentBid + assetDetails.currentTotalTax);

        harberger.initialMint(
            _asset,
            _assetId,
            assetDetails.auctionEndTime,
            assetDetails.validTill,
            _bidder,
            assetDetails.currentBid,
            assetDetails.currentInitialValue
        );
    }

    function setHarberger(address _harberger) external onlyAuctioner {
        harberger = Harberger(_harberger);
    }

    function setAssetDetails(address _assetAddress, uint256 _assetId, uint256 _minBid) external onlyAssetOwner(_assetAddress) {
        AssetDetails memory assetDetails = assets[_assetAddress][_assetId];
        if (assetDetails.isAsset && assetDetails.validTill>= block.timestamp) {
            revert Auction_AssetDetailsCantBeChangedTillValidEnd();
        }
        // @follow-up check if assetId/tokenId Already exists, @follow-up add reclaim function after auction validity
        assets[_assetAddress][_assetId] = AssetDetails({
            isAsset: true,
            auctionStartTime: 0,
            auctionEndTime: 0,
            validTill: 0,
            currentBidder: address(0),
            currentBid: 0,
            currentTotalTax: 0,
            currentInitialValue: 0,
            minBid: _minBid
        });
        emit Auction_AssetSet(_assetAddress, _assetId, _minBid);
    }

    function startAuctionAndValidity(
        address _assetAddress,
        uint256 _assetId,
        uint256 _auctionDuration,
        uint256 _assetDuration
    )
        external
        onlyAssetOwner(_assetAddress)
    {
        AssetDetails memory assetDetails = assets[_assetAddress][_assetId];
        if (!assetDetails.isAsset) {
            revert Auction_NotAsset();
        }
        assets[_assetAddress][_assetId].auctionStartTime = uint64(block.timestamp); // timestamp wont exceed uint64
        assets[_assetAddress][_assetId].auctionEndTime = uint64(block.timestamp + _auctionDuration);
        assets[_assetAddress][_assetId].validTill = uint64(block.timestamp + _auctionDuration + _assetDuration);

        emit Auction_Started(_assetAddress, _assetId, block.timestamp + _auctionDuration);
    }

    //////////////////////////////
    //////// Internal ////////////
    //////////////////////////////
    function checkAssetBidStatus(AssetDetails memory assetDetails) internal view {
        // Checks if Asset is Authorised
        if (!assetDetails.isAsset) {
            revert Auction_NotAsset();
        }

        // Check if autionEndTime and auctionStartTime aren't zero, which mean the aution time isn't set yet
        if (assetDetails.auctionEndTime == 0 || assetDetails.auctionStartTime == 0) {
            revert Auction_TimeNotValid();
        }

        // Check if autionStartTime is not greater than current timestamp, ie Auction not started yet
        if (assetDetails.auctionStartTime > block.timestamp) {
            revert Auction_NotStarted();
        }

        // Check if auctionEnd Time is not less than current timestamp, ie Auction hasn't ended yet
        if (assetDetails.auctionEndTime < block.timestamp) {
            revert Auction_Ended();
        }
    }

    function checkAssetClaimStatus(AssetDetails memory assetDetails, address _bidder) internal view {
        // Checks if Asset is Authorised
        if (!assetDetails.isAsset) {
            revert Auction_NotAsset();
        }

        // Check if autionEndTime and auctionStartTime aren't zero, which mean the aution time isn't set yet
        if (assetDetails.auctionEndTime == 0 || assetDetails.auctionStartTime == 0) {
            revert Auction_TimeNotValid();
        }

        // Check if autionStartTime is not greater than current timestamp, ie Auction not started yet
        if (assetDetails.auctionStartTime > block.timestamp) {
            revert Auction_NotStarted();
        }

        // Check if auctionEnd Time is less than current timestamp, ie Auction has ended yet
        if (assetDetails.auctionEndTime > block.timestamp) {
            revert Auction_HasntEnded();
        }

        if (_bidder != assetDetails.currentBidder) {
            revert Auction_NotWinningBidder();
        }
    }

    ////////////////////////////////////////
    ////////// Getter Functions ////////////
    ////////////////////////////////////////
    function getAssetDetails(address _assetAddress, uint256 _assetId) external view returns (AssetDetails memory) {
        return assets[_assetAddress][_assetId];
    }

    // @follow-up make withdraw function
}
