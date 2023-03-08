// DAO/IVoting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExecutableProposal.sol";

interface IVoting {
    event InicioVotacion(uint startDate, uint endDate);
    event NuevaPropuesta(uint propId, address propOwner, uint budget);
    event PropuestaRetirada(uint propId);
    event PropuestaAprobada(uint propId, uint numVotes, uint numTokens);
    event FinVotacion();
    function iniciarVotacion(uint startDate, uint endDate) external;
    function finalizarVotacion() external;
    function aniadirParticipante() external;
    function aniadirPropuesta(string memory descr, uint budget, IExecutableProposal exec) external returns (uint);
    function retirarPropuesta(uint propId) external;
    function votar(uint propId, uint numVotes) external;
}