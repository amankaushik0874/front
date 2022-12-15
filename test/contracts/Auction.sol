// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ReopenNFT.sol";
import "./Router.sol";

contract Auction is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public Season = 0;
    mapping(uint256 => SeasonStruct) public SeasonDataMapping;
    mapping(uint256 => mapping(uint256 => Bid)) public bidsMapping;
    mapping(uint256 => mapping(uint256 => Bid)) public NFTWinnersData;
    mapping(uint256 => mapping(address => uint256)) private bidsAddressMapping;
    NFT public nft;
    Router routerContract;
    address public operator;
    address public projectWallet;
    struct Bid {
        address bidder;
        uint256 ethAmount;
    }
    struct SeasonStruct {
        uint256 minBidAmount;
        uint256 lastTokenId;
        uint256 bidCount;
        uint256 items;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint8 auctionState;
        uint raisedFunds;
        uint contributorsPercent;
        uint projectPercent;
    }

    event BidMade(address bidder, uint256 ethAmount);
    address public reopen = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    // Modifiers
    modifier contractActive() {
        require(SeasonDataMapping[Season].auctionState == 1, "Not Active");
        require(
            block.timestamp > SeasonDataMapping[Season].auctionStart,
            "Auction not started"
        );
        require(
            block.timestamp < SeasonDataMapping[Season].auctionEnd,
            "Auction Ended"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the Operator");
        _;
    }

    // Functions
    function initialize(
        NFT nft_,
        address operator_,
        address projectWallet_,
        uint256 minBidAmount_,
        uint256 items_,
        Router router_,
        uint256 auctionStart_,
        uint256 auctionEnd_,
        uint contributorsPercent_
    ) internal initializer {
        require(auctionStart_ > block.timestamp, "Time cannot be past");
        require(auctionEnd_ > auctionStart_, "Time cannot be past");
        require(items_ > 0, "Items should be more than 0");
        __Ownable_init();
        nft = nft_;
        operator = operator_;
        projectWallet = projectWallet_;
        SeasonDataMapping[Season].minBidAmount = minBidAmount_;
        routerContract = router_;
        SeasonDataMapping[Season].items = items_;
        SeasonDataMapping[Season].auctionStart = auctionStart_;
        SeasonDataMapping[Season].auctionEnd = auctionEnd_;
        SeasonDataMapping[Season].contributorsPercent = contributorsPercent_;
        SeasonDataMapping[Season].projectPercent = 100 - contributorsPercent_;
        nft.createToken(items_, operator);
    }

    function approveAuction() public {
        if(msg.sender == reopen || msg.sender == operator) {
            SeasonDataMapping[Season].auctionState++;
        }
    }

    function placeBid() public payable contractActive {
        require(
            msg.value > SeasonDataMapping[Season].minBidAmount,
            "Increase the Bid Amount"
        );
        if (bidsAddressMapping[Season][msg.sender] != 0) {
            revert("Bid Already Placed");
        }
        if (SeasonDataMapping[Season].bidCount > 10) {
            uint256 highestBid = sort()[10].ethAmount;
            if (msg.value > highestBid) {
                SeasonDataMapping[Season].auctionEnd =
                    SeasonDataMapping[Season].auctionEnd +
                    600;
            }
        }
        bidsMapping[Season][SeasonDataMapping[Season].bidCount] = Bid(
            msg.sender,
            msg.value
        );
        bidsAddressMapping[Season][msg.sender] = msg.value;
        SeasonDataMapping[Season].bidCount++;
        emit BidMade(msg.sender, msg.value);
    }

    function increaseBid() public payable contractActive {
        if (bidsAddressMapping[Season][msg.sender] == 0) {
            revert("You have not placed a bid");
        }
        for (uint256 i = 0; i < SeasonDataMapping[Season].bidCount; i++) {
            if (bidsMapping[Season][i].bidder == msg.sender) {
                bidsMapping[Season][i].ethAmount =
                    bidsMapping[Season][i].ethAmount +
                    msg.value; 
            }
        }
    }

    function sort() public returns (Bid[] memory) {
        for (uint256 i = 0; i < SeasonDataMapping[Season].bidCount; i++) {
            uint256 min = i;
            for (
                uint256 j = i + 1;
                j < SeasonDataMapping[Season].bidCount;
                j++
            ) {
                if (
                    bidsMapping[Season][j].ethAmount >
                    bidsMapping[Season][min].ethAmount
                ) {
                    min = j;
                }
            }
            if (min != i) {
                // Swapping the elements
                Bid memory tmp = bidsMapping[Season][min];
                bidsMapping[Season][min] = bidsMapping[Season][i];
                bidsMapping[Season][i] = tmp;
            }
        }
        Bid[] memory qwerty = new Bid[](SeasonDataMapping[Season].items);
        for (uint256 k = 0; k < SeasonDataMapping[Season].items; k++) {
            qwerty[k] = bidsMapping[Season][k];
        }
        return qwerty;
    }

    function selectWinners() public payable onlyOperator {
        require(block.timestamp > SeasonDataMapping[Season].auctionEnd, "Not Time");
        Bid[] memory allNFTWinners = selectWinnersSliced();
        for (
            uint256 i = SeasonDataMapping[Season].lastTokenId;
            i <
            (SeasonDataMapping[Season].lastTokenId +
                SeasonDataMapping[Season].items);
            i++
        ) {
            nft.approve(allNFTWinners[i - SeasonDataMapping[Season].lastTokenId].bidder, i);
            NFTWinnersData[Season][i - SeasonDataMapping[Season].lastTokenId] = Bid(
            allNFTWinners[i - SeasonDataMapping[Season].lastTokenId].bidder,
            allNFTWinners[i - SeasonDataMapping[Season].lastTokenId].ethAmount
        );
            SeasonDataMapping[Season].raisedFunds += allNFTWinners[i - SeasonDataMapping[Season].lastTokenId].ethAmount;
        }
        withdraw();
        routerContract.transferFunds(SeasonDataMapping[Season].contributorsPercent, SeasonDataMapping[Season].projectPercent, Season, projectWallet);
        Season++;
    }

    function createNewSeason(uint minBidAmount_, uint256 items_, uint256 auctionStart_, uint256 auctionEnd_)
        public
        returns (uint256)
    {   
        SeasonDataMapping[Season].contributorsPercent = SeasonDataMapping[Season -1 ].contributorsPercent;
        SeasonDataMapping[Season].projectPercent = SeasonDataMapping[Season -1 ].projectPercent;
        SeasonDataMapping[Season].minBidAmount = minBidAmount_;
        SeasonDataMapping[Season].items =
            SeasonDataMapping[Season].items +
            items_;
        SeasonDataMapping[Season].auctionStart = auctionStart_;
        SeasonDataMapping[Season].auctionEnd = auctionEnd_;
        SeasonDataMapping[Season].lastTokenId =
            SeasonDataMapping[Season - 1].lastTokenId +
            items_;
        return SeasonDataMapping[Season].items;
    }

    function snapshot(uint season_) public view returns(uint, address[] memory) {
        address[] memory snapshotData = new address[](SeasonDataMapping[season_ - 1].items);
        for(uint i=SeasonDataMapping[season_ -1 ].lastTokenId; i<(SeasonDataMapping[Season-1].lastTokenId + SeasonDataMapping[season_-1].items); i++) {
            snapshotData[i - SeasonDataMapping[season_ -1 ].lastTokenId] = nft.ownerOf(i);
        }
        return (SeasonDataMapping[season_ -1 ].lastTokenId, snapshotData);
    }

    function selectWinnersSliced() internal returns (Bid[] memory) {
        Bid[] memory allNFTWinners = sort();
        return this.sortWinners(allNFTWinners);
    }

    function throwSeasonData(uint season_) public view returns (Bid[] memory) {
        Bid[] memory throwData = new Bid[](SeasonDataMapping[season_].items);
        for (uint i = 0; i < SeasonDataMapping[season_].items; i++) {
        throwData[i] = NFTWinnersData[season_][i];
    }
        return throwData;
    }

    function sortWinners(Bid[] calldata newDatas)
        public
        view
        returns (Bid[] calldata)
    {
        return newDatas[0:SeasonDataMapping[Season].items];
    }

    function checkAuctionState() public view returns (string memory) {
        if(block.timestamp > SeasonDataMapping[Season].auctionStart && block.timestamp < SeasonDataMapping[Season].auctionEnd && SeasonDataMapping[Season].auctionState == 1) {
            return "Active";
        }
        else return "Not Active";
    }

    function withdraw() internal onlyOwner {
        payable(routerContract).transfer(SeasonDataMapping[Season].raisedFunds);
    }

    function claimNFT(uint _tokenId) public {
         require(nft.getApproved(_tokenId) == msg.sender, "Not Authorised");
         nft.safeTransferFrom(operator, msg.sender, _tokenId);
        }

    function claimMoney() public {
         require(block.timestamp > SeasonDataMapping[Season].auctionEnd, "Not Time");
        require(bidsAddressMapping[Season-1][msg.sender] != 0, "You cannot claim");
        payable(msg.sender).transfer(bidsAddressMapping[Season-1][msg.sender]);
        }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
