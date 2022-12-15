// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Interfaces/ERC721ALockable.sol";

contract NFT is Ownable, ERC721ALockable, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 nftprice = 10000000000000;
    uint256 _feeAmount = nftprice / 10;
    uint256 Season = 0;
    string internal baseTokenUri;
    string internal baseTokenUriExt;
    address payable artist;

    constructor(address payable artist_) ERC721A("Reopen", "RPN") {
        artist = artist_;
        setRoyaltyInfo(artist, uint96(_feeAmount));
    }

    function createToken(uint256 _amount, address auction_) public {
        uint256 tokenId = _tokenIds.current();
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            tokenId++;
            _setTokenRoyalty(tokenId, artist, uint96(_feeAmount));
        }
        _mint(auction_, _amount);
        Season++;
    }

    function createNewSeason(uint256 _newAmount, address auction_) public {
        createToken(_newAmount, auction_);
    }

    function _feeDenominator() internal pure virtual override returns (uint96) {
        return 10000000000000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721ALockable)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "Token does not exist!");
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    Strings.toString(tokenId_),
                    baseTokenUriExt
                )
            );
    }

    function setBaseTokenUri(string calldata newBaseTokenUri_) public {
        baseTokenUri = newBaseTokenUri_;
    }

    function setBaseTokenUriExt(string calldata newBaseTokenUriExt_) external {
        baseTokenUriExt = newBaseTokenUriExt_;
    }

    function _payTxFee() public {
        payable(artist).transfer(_feeAmount);
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance - _feeAmount);
        payable(artist).transfer(_feeAmount);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) internal {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        //suppress error
        _tokenId;
        return (artist, _feeAmount);
    }
}
