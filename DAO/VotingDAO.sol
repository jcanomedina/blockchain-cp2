// DAO/VotingDAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVoting.sol";
import "./IExecutableProposal.sol";
import "hardhat/console.sol";

contract VotingDAO is IVoting {

    // proposals received by the DAO
    //
    uint proposalCounter = 0;
    struct Proposal {
        address owner;
        uint id;
        string description;
        uint budget;
        uint votes;
        bool approved;
        bool active;
        IExecutableProposal executable;
    }
    Proposal[] public proposals;

    address administrator;
    uint startDateVoting;
    uint endDateVoting;
    bool votingStarted;

    // list of participants registered in the DAO
    //
    mapping(address => bool) participants;

    // votes sent by a participant to a proposal
    //
    struct VoteProposal {
        uint propId;
        uint numVotes;
        uint numTokens;
    }
    mapping(address => VoteProposal[]) votesParticipants;

    // modifiers
    //
    modifier onlyAdmin {
        require(msg.sender == administrator);
        _;
    }

    modifier noAdmin {
        require(msg.sender != administrator);
        _;
    }

    modifier votingIsNotStarted {
        require (votingStarted == false);
        _;
    }

    modifier votingIsStarted {
        require (votingStarted == true);
        _;
    }

    modifier votingIsExpired {
        require (block.timestamp > endDateVoting);
        _;
    }

    modifier isParticipant {
        require (participants[msg.sender] == true);
        _;
    }

    modifier isNotParticipant {
        require (participants[msg.sender] == false);
        _;
    }

    event InicioVotacion(uint startDate, uint endDate);                     // iniciarVotacion
    event NuevaPropuesta(uint propId, address propOwner, uint budget);      // aniadirPropuesta 
    event PropuestaRetirada(uint propId);                                   // retirarPropuesta
    event PropuestaAprobada(uint propId, uint numVotes, uint numTokens);    // votar       
    event FinVotacion();                                                    // finalizarVotacion 

    constructor() {
        administrator = msg.sender;
    }

    function iniciarVotacion(uint startDate, uint endDate) onlyAdmin votingIsNotStarted external override {
        emit InicioVotacion (startDate, endDate);

        startDateVoting = startDate;
        endDateVoting = endDate;
        votingStarted = true;
    }

    function finalizarVotacion() onlyAdmin votingIsStarted votingIsExpired external override {
        emit FinVotacion();
        votingStarted = false;
    }

    function aniadirParticipante() isNotParticipant noAdmin external override {
        participants[msg.sender] = true;
    }

    function aniadirPropuesta(string memory descr, uint budget, IExecutableProposal exec) isParticipant votingIsStarted external override returns (uint) {
        proposalCounter++;
        Proposal memory newProposal;
        newProposal.owner = msg.sender;
        newProposal.id = proposalCounter;
        newProposal.description = descr;
        newProposal.budget = budget;
        newProposal.votes = 0;
        newProposal.active = true;
        newProposal.approved = false;
        newProposal.executable = exec;

        proposals.push(newProposal);

        emit NuevaPropuesta (proposalCounter, msg.sender, budget); 
        return proposalCounter;
    }
    
    function retirarPropuesta(uint propId) isParticipant external override {
        Proposal memory proposalToBeRetired = findActiveNotApprovedProposal(propId);
        
        if (proposalToBeRetired.owner == msg.sender) {
            proposalToBeRetired.active = false;

            emit PropuestaRetirada (propId);
        }
        else {
            revert();
        }
    }
    
    function votar(uint propId, uint numVotes) isParticipant votingIsStarted external override {
        Proposal memory proposalToBeVoted = findActiveNotApprovedProposal(propId);
        VoteProposal memory voteProposal;

        uint pos = 0 ;
        uint arrayLength = votesParticipants[msg.sender].length;
        while (votesParticipants[msg.sender][pos].propId != propId && pos <= arrayLength) pos++;

        if (votesParticipants[msg.sender][pos].propId == propId) {
            voteProposal = votesParticipants[msg.sender][pos];
        }
        else {
            voteProposal.propId = propId;
            voteProposal.numVotes = 0;
            voteProposal.numTokens = 0;
            votesParticipants[msg.sender].push(voteProposal);
        }

        // uint previousVotes = voteProposal.numVotes;
        


        proposalToBeVoted.votes = proposalToBeVoted.votes + numVotes;

        if (proposalToBeVoted.votes >= proposalToBeVoted.budget){
            proposalToBeVoted.executable.executeProposal{gas:100000}(propId, proposalToBeVoted.votes, proposalToBeVoted.budget);
            
            emit PropuestaAprobada (propId, proposalToBeVoted.votes, proposalToBeVoted.budget);
        }
    }

    // Auxiliary function 
    // 

    function findActiveNotApprovedProposal(uint propId) private view returns (Proposal memory) {
        uint pos = 0;
        uint arrayLength = proposals.length;
        while (proposals[pos].id != propId && pos <= arrayLength){
            pos++;
        }

        if (proposals[pos].id == propId && proposals[pos].active && !proposals[pos].approved) {
            return proposals[pos];
        }
        else {
            revert();
        }
    }

    function findOrCreateEmptyVote (uint propId) private returns (VoteProposal memory) {
        VoteProposal[] memory voteProposals = votesParticipants[msg.sender];
        VoteProposal memory voteProposal;

        uint pos = 0 ;
        uint arrayLength = voteProposals.length;
        while (voteProposals[pos].propId != propId && pos <= arrayLength) pos++;

        if (voteProposals[pos].propId == propId) {
            voteProposal = voteProposals[pos];
        }
        else {
            voteProposal.propId = propId;
            voteProposal.numVotes = 0;
            voteProposal.numTokens = 0;
            votesParticipants[msg.sender].push(voteProposal);
        }
        return voteProposal;
    }
}