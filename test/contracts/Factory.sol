//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReopenNFT.sol";
import "./Auction.sol";
import "./Router.sol";

contract Factory {
    address payable routerAddr =
        payable(0x7f8A1Ae9BE7F1B133C40342A7B7Dd49f981A340F);
    Router public routerContract = Router(routerAddr);
    address payable reopen =
        payable(0xe583327E8D32184aA21475f98c76c6900aB40a17);
    event NFTCreated(address tokenAddress);
    event AuctionCreated(address auctionAddress);

    function createNewCampaign(
        address operator_,
        address projectWallet_,
        uint256 minBidAmount_,
        uint256 totalNFTs,
        uint256 auctionStartTime_,
        uint256 auctionEndTime_,
        uint256 contributorsPercent_
    ) public returns (address, address) {
        NFT NFTContract = new NFT(reopen);
        emit NFTCreated(address(NFTContract));
        Auction auctionContract = new Auction();
        emit AuctionCreated(address(auctionContract));

        auctionContract.initialize(
            NFTContract,
            operator_,
            projectWallet_,
            minBidAmount_,
            totalNFTs,
            routerContract,
            auctionStartTime_,
            auctionEndTime_,
            contributorsPercent_
        );

        NFTContract.setApprovalForAll(address(auctionContract), true);
        auctionContract.transferOwnership(operator_);
        NFTContract.transferOwnership(operator_);
        return (address(NFTContract), address(auctionContract));
    }
}
