// ----- Loterry Contract -----
//
// Enter the loterry, paying a eth ammount
// Pick a random winner
// Winner selected every X time => automated
// Chainlink Oracle => ramdomness, automation (chainlink keeper)

// SPDX-License-Identifier: MIt
pragma solidity ^0.8.8;

error Lottery__NotEnoughValue();

contract Lottery {
    /* State Variables */
    uint256 private i_entranceFee;
    address payable[] private s_participants;

    /* Events */
    event LoterryEnter(address indexed participant);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterLoterry() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughValue();
        }
        s_participants.push(payable(msg.sender));
        // Event good practice: name it in reverse
        emit LoterryEnter(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getParticipants(uint256 index) public view returns (address) {
        return s_participants[index];
    }
}
