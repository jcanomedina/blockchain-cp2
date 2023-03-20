// DAO/VotingDAO.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVoting.sol";
import "./IExecutableProposal.sol";

contract VotingDAO is IVoting {

    uint proposalCounter = 0;
    struct Proposal {
        uint id;
        string description;
        uint budget;
        IExecutableProposal executable;
    }
    mapping(address => Proposal) proposals;

    address administrator;
    uint startDateVoting;
    uint endDateVoting;
    bool votingStarted;
    mapping(address => bool) participants;

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
        // require (startDate >= block.timestamp);

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
        newProposal.id = proposalCounter;
        newProposal.description = descr;
        newProposal.budget = budget;
        newProposal.executable = exec;

        proposals[msg.sender] = newProposal;

        emit NuevaPropuesta (proposalCounter, msg.sender, budget); 
        return proposalCounter;
    }
    
    function retirarPropuesta(uint propId) external override {
        emit PropuestaRetirada (propId);
    }
    
    function votar(uint propId, uint numVotes) votingIsStarted external override {
        // emit PropuestaAprobada 
    }
}