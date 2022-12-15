// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Router is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public totalMoney;
    address contributors = 0x264eE1AA509A3D92fF7C11f510290689a3747620;
    address holderYield = 0x721CE71Fd08CAB3791128A310Af29F2bb9B3Bf93;
    address holderPool = 0x955aAb9B4941a1a4dAaFdbf7d6ee5BeB96E0d33b;
    address reopen = 0xe583327E8D32184aA21475f98c76c6900aB40a17;
    address ecosystem = 0x82d60CE61e450BD3079950585059c537632dAF40;

    function initialize() public initializer {
        __Ownable_init();
    }

    function transferFunds(
        uint256 contributorsPercent_,
        uint256 projectPercent_,
        uint256 Season_,
        address project
    ) public payable {
        totalMoney = address(this).balance / 100;
        if (Season_ == 1) {
            uint256 projectContributors = (totalMoney * 56) / 100;
            payable(reopen).transfer(totalMoney * 10);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
        } else if (Season_ == 2) {
            uint256 projectContributors = (totalMoney * 36) / 100;
            payable(reopen).transfer(totalMoney * 5);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
            payable(holderYield).transfer(totalMoney * 25);
        } else {
            uint256 projectContributors = (totalMoney * 30) / 100;
            payable(reopen).transfer(totalMoney * 5);
            payable(project).transfer(projectContributors * projectPercent_);
            payable(contributors).transfer(
                projectContributors * contributorsPercent_
            );
            payable(holderYield).transfer(totalMoney * 31);
        }
        payable(holderPool).transfer(totalMoney * 14);
        payable(ecosystem).transfer(totalMoney * 20);
    }

    function addFunds() public payable returns (string memory) {
        return "Hello";
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    receive() external payable {}

    fallback() external payable {}
}
