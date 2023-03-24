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
        mapping (address => uint) votesReceived;
        IExecutableProposal executable;
    }
    Proposal[] public proposals;

    address public administrator;
    uint public startDateVoting;
    uint public endDateVoting;
    bool public votingStarted;

    // list of participants registered in the DAO
    //
    mapping(address => bool) public participants;

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

        console.log ("proceso de votacion iniciado entre %s y %s", startDateVoting, endDateVoting);
    }

    function finalizarVotacion() onlyAdmin votingIsStarted votingIsExpired external override {
        emit FinVotacion();
        votingStarted = false;
        console.log ("Proceso de votacion finalizado");
    }

    function aniadirParticipante() isNotParticipant noAdmin external override {
        participants[msg.sender] = true;

        console.log ("Participante %s aniadido", msg.sender);
    }

    function aniadirPropuesta(string memory descr, uint budget, IExecutableProposal exec) isParticipant votingIsStarted external override returns (uint) {
        uint idx = proposals.length;
        proposals.push();

        Proposal storage newProposal = proposals[idx];
        proposalCounter++;
        newProposal.owner = msg.sender;
        newProposal.id = proposalCounter;
        newProposal.description = descr;
        newProposal.budget = budget;
        newProposal.votes = 0;
        newProposal.active = true;
        newProposal.approved = false;
        newProposal.executable = exec;
        emit NuevaPropuesta (proposalCounter, msg.sender, budget); 
        console.log ("Propuesta [%s] %s con presupuesto %s aniadido", proposalCounter, descr, budget);
        return proposalCounter;
    }
    
    function retirarPropuesta(uint propId) isParticipant external override {
        Proposal storage proposalToBeRetired = findActiveNotApprovedProposal(propId);
        
        if (proposalToBeRetired.owner == msg.sender) {
            proposalToBeRetired.active = false;

            emit PropuestaRetirada (propId);
            console.log ("Propuesta [%s-%s] retirada por %s", propId, proposalToBeRetired.description, msg.sender);
        }
        else {
            console.log ("Propuesta [%s-%s] no retirada.'%s' no es el creador. ", propId, proposalToBeRetired.description, msg.sender);
            revert();
        }
    }
    
    function votar(uint propId, uint numVotes) isParticipant votingIsStarted external override {
        Proposal storage proposalToBeVoted = findActiveNotApprovedProposal(propId);
        uint oldVotes = proposalToBeVoted.votesReceived[msg.sender];
        uint newVotes = oldVotes + numVotes;
        proposalToBeVoted.votesReceived[msg.sender] = newVotes;

        proposalToBeVoted.votes = proposalToBeVoted.votes + numVotes;
        console.log ("Propuesta [%s] ha recibido [%s] votos. Total de votos: [%s]", propId, numVotes, proposalToBeVoted.votes);

        if (proposalToBeVoted.votes >= proposalToBeVoted.budget){
            proposalToBeVoted.executable.executeProposal{gas:100000}(propId, proposalToBeVoted.votes, proposalToBeVoted.budget);
            proposalToBeVoted.approved = true;
            console.log ("Propuesta [%s] aprobada", propId);
            emit PropuestaAprobada (propId, proposalToBeVoted.votes, proposalToBeVoted.budget);
        }
    }

    // Auxiliary function 
    // 

    function findActiveNotApprovedProposal(uint propId) private view returns (Proposal storage) {
        uint pos = 0;
        uint arrayLength = proposals.length;
        while (proposals[pos].id != propId && pos <= arrayLength){
            pos++;
        }

        if (proposals[pos].id == propId && proposals[pos].active && !proposals[pos].approved) {
            return proposals[pos];
        }
        else {
            console.log ("Propuesta [%s] no existe, ha sido retirada previamente o ya ha sido aprobada.", propId);
            revert();
        }
    }
}