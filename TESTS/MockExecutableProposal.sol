// MockExecutableProposal.sol
pragma solidity ^0.8.0;

import "../DAO/IExecutableProposal.sol";

contract MockExecutableProposal is IExecutableProposal {
    function executeProposal(uint propId, uint numVotes, uint budget) external override {}
}
