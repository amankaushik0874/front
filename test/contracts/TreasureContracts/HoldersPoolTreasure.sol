// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../ReopenNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HoldersPoolTreasure is Ownable, IERC721Receiver {
    uint256 public totalItemsStaked;
    NFT nft;

    struct Stake {
        address owner;
        uint256 stakedAt;
    }

    mapping(address => mapping(uint256 => Stake)) vault;

    event ItemStaked(uint256 tokenId, address owner, uint256 timestamp);
    event ItemUnstaked(uint256 tokenId, address owner, uint256 timestamp);
    event Claimed(address owner, uint256 reward);

    constructor() {}

    //--------------------------------------------------------------------
    // FUNCTIONS

    function stake(address _nftAddress, uint256 tokenIds) external {
        nft = NFT(_nftAddress);
        uint256 tokenId;
        uint256 stakedCount;

        tokenId = tokenIds;
        if (vault[_nftAddress][tokenId].owner != address(0)) {
            revert("NFTStakingVault__ItemAlreadyStaked");
        }
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert("NFTStakingVault__NotItemOwner");
        }

        nft.lock(address(this), tokenId);

        vault[_nftAddress][tokenId] = Stake(msg.sender, block.timestamp);

        emit ItemStaked(tokenId, msg.sender, block.timestamp);

        unchecked {
            stakedCount++;
        }
        totalItemsStaked = totalItemsStaked + stakedCount;
    }

    function unstake(
        address _nftAddress,
        uint256 tokenIds,
        uint256 ethAmount_
    ) external {
        _claim(_nftAddress, msg.sender, tokenIds, true, ethAmount_);
    }

    function claim(
        address _nftAddress,
        uint256 tokenIds,
        uint256 ethAmount_
    ) external {
        _claim(_nftAddress, msg.sender, tokenIds, false, ethAmount_);
    }

    function _claim(
        address _nftAddress,
        address user,
        uint256 tokenIds,
        bool unstakeAll,
        uint256 ethAmount_
    ) internal {
        uint256 tokenId;
        uint256 calculatedReward;
        uint256 rewardEarned;

        tokenId = tokenIds;
        if (vault[_nftAddress][tokenId].owner != user) {
            revert("NFTStakingVault__NotItemOwner");
        }
        uint256 _stakedAt = vault[_nftAddress][tokenId].stakedAt;

        uint256 stakingPeriod = block.timestamp - _stakedAt;
        calculatedReward += (stakingPeriod * ethAmount_) / 365 days;

        vault[_nftAddress][tokenId].stakedAt = block.timestamp;

        rewardEarned = calculatedReward;

        emit Claimed(user, rewardEarned);

        if (rewardEarned != 0) {
            payable(user).transfer(rewardEarned);
        }

        if (unstakeAll) {
            _unstake(_nftAddress, user, tokenIds);
        }
    }

    function _unstake(
        address _nftAddress,
        address user,
        uint256 tokenIds
    ) internal {
        uint256 tokenId;
        uint256 unstakedCount;

        tokenId = tokenIds;
        require(vault[_nftAddress][tokenId].owner == user, "Not Owner");

        nft.unlock(tokenId);

        delete vault[_nftAddress][tokenId];

        emit ItemUnstaked(tokenId, user, block.timestamp);

        unchecked {
            unstakedCount++;
        }
        totalItemsStaked = totalItemsStaked - unstakedCount;
    }

    function getTotalRewardEarned(
        address _nftAddress,
        address user,
        uint256 ethAmount_
    ) external view returns (uint256 rewardEarned) {
        uint256 calculatedReward;
        uint256[] memory tokens = tokensOfOwner(_nftAddress, user);

        uint256 len = tokens.length;
        for (uint256 i; i < len; ) {
            uint256 _stakedAt = vault[_nftAddress][tokens[i]].stakedAt;
            uint256 stakingPeriod = block.timestamp - _stakedAt;
            calculatedReward += (stakingPeriod * ethAmount_) / 365 days;
            unchecked {
                ++i;
            }
        }
        rewardEarned = calculatedReward;
    }

    function getRewardEarnedPerNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 ethAmount_
    ) external view returns (uint256 rewardEarned) {
        uint256 _stakedAt = vault[_nftAddress][_tokenId].stakedAt;
        uint256 stakingPeriod = block.timestamp - _stakedAt;
        uint256 calculatedReward = (stakingPeriod * ethAmount_) / 365 days;
        rewardEarned = calculatedReward;
    }

    function balanceOf(address _nftAddress, address user)
        public
        view
        returns (uint256 nftStakedbalance)
    {
        uint256 supply = nft.totalSupply();
        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[_nftAddress][i].owner == user) {
                    nftStakedbalance += 1;
                }
            }
        }
    }

    function tokensOfOwner(address _nftAddress, address user)
        public
        view
        returns (uint256[] memory tokens)
    {
        uint256 balance = balanceOf(_nftAddress, user);
        uint256 supply = nft.totalSupply();
        tokens = new uint256[](balance);

        uint256 counter;

        if (balance == 0) {
            return tokens;
        }

        unchecked {
            for (uint256 i; i <= supply; ++i) {
                if (vault[_nftAddress][i].owner == user) {
                    tokens[counter] = i;
                    counter++;
                }
                if (counter == balance) {
                    return tokens;
                }
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    fallback() external payable {}
}
