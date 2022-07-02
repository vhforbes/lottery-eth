// ----- Loterry Contract -----
//
// Enter the loterry, paying a eth ammount
// Pick a random winner
// Winner selected every X time => automated
// Chainlink Oracle => ramdomness, automation (chainlink keeper)

// SPDX-License-Identifier: MIt
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

error Lottery__NotEnoughValue();
error Lottery__TransferFailed();

contract Lottery is VRFConsumerBaseV2 {
    /* State Variables */
    uint256 private i_entranceFee;
    address payable[] private s_participants;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    address private s_recentWinner;

    /* Events */
    event LoterryEnter(address indexed participant);
    event RequestedLoterryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed pickedWinner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterLoterry() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughValue();
        }
        s_participants.push(payable(msg.sender));
        // Event good practice: name it in reverse
        emit LoterryEnter(msg.sender);
    }

    function requestRandomWinner() external {
        // Req ramdom number
        // Do something with it
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLoterryWinner(requestId);
    }

    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        // Req ramdom number
        // Do something with it
        uint256 indexOfWinner = randomWords[0] % s_participants.length; // Pega o resto da divisão
        address payable recentWinner = s_participants[indexOfWinner];
        s_recentWinner = recentWinner;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* View Pure Functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getParticipants(uint256 index) public view returns (address) {
        return s_participants[index];
    }

    function getParticipants() public view returns (address) {
        return s_recentWinner;
    }
}
