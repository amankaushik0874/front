/*
 SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Royalties is Ownable {
    function payRoyalties(uint256 _amount, address _receiver) external {
        // calculo de royalties e pagamento
    }
}
