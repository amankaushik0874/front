// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HoldersYieldTreasure {
    uint256 public totalMoney;
    uint256 public Season = 0;

    function calculateAmount(uint256 numberOfAddress, uint256 splitAmount)
        public
        payable
        returns (uint256[] memory)
    {
        uint256[] memory indexArray = new uint256[](numberOfAddress);
        uint256[] memory amountArray = new uint256[](numberOfAddress);
        uint256 temp = numberOfAddress;
        uint256 totals;
        for (uint256 x = 1; x <= numberOfAddress; x++) {
            totals += x;
            indexArray[x - 1] = temp;
            temp--;
        }
        for (uint256 y = 0; y < numberOfAddress; y++) {
            amountArray[y] = (splitAmount / totals) * indexArray[y];
        }
        return (amountArray);
    }

    function payHolders(
        address[] memory season1,
        address[] memory season2,
        address[] memory season3
    ) public payable {
        totalMoney = address(this).balance;
        uint256[] memory splitSeason1Amount = calculateAmount(
            season1.length,
            (totalMoney / 100) * 10
        );
        uint256[] memory splitSeason2Amount = calculateAmount(
            season2.length,
            (totalMoney / 100) * 20
        );
        uint256[] memory splitSeason3Amount = calculateAmount(
            season3.length,
            (totalMoney / 100) * 70
        );
        paynftOwners(season1, splitSeason1Amount);
        paynftOwners(season2, splitSeason2Amount);
        paynftOwners(season3, splitSeason3Amount);
        Season++;
    }

    function payHolders(address[] memory season1, address[] memory season2)
        public
        payable
    {
        totalMoney = address(this).balance;
        uint256[] memory splitSeason1Amount = calculateAmount(
            season1.length,
            (totalMoney / 100) * 20
        );
        uint256[] memory splitSeason2Amount = calculateAmount(
            season2.length,
            (totalMoney / 100) * 80
        );
        paynftOwners(season1, splitSeason1Amount);
        paynftOwners(season2, splitSeason2Amount);
        Season++;
    }

    function payHolders(address[] memory season1) public payable {
        totalMoney = address(this).balance;
        uint256[] memory splitSeason1Amount = calculateAmount(
            season1.length,
            totalMoney
        );
        paynftOwners(season1, splitSeason1Amount);
        Season++;
    }

    function paynftOwners(
        address[] memory nftOwners,
        uint256[] memory nftOwnersAmount
    ) public payable {
        for (uint256 a = 0; a < nftOwners.length; a++) {
            payable(nftOwners[a]).transfer(nftOwnersAmount[a]);
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
