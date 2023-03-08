// DAO/MyProposal.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExecutableProposal.sol";

contract MyProposal is IExecutableProposal {
    event ProposalExecution(uint id, uint votes, uint tokens);
    
    function executeProposal(uint proposalId, uint numVotes, uint numTokens) external override {
        emit ProposalExecution(proposalId, numVotes, numTokens);
    }
}