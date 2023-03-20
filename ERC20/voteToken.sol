// ERC20/voteToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract voteToken is ERC20 {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor(uint256 initialSupply) ERC20("payVoteToken", "PVT") {
        owner = msg.sender ; 
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) onlyOwner public payable {
        _mint(to, amount);
    }
}