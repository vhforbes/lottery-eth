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
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Lottery__NotEnoughValue();
error Lottery__TransferFailed();
error Lottery__IsClosed();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numParticipants, uint256 lotteryState);

/**
    @title A auto manageable lottery contract
    @author Victor Forbes
    @dev implements ChainlinkVRFV2 and Chainlink Keepers
 */
contract Lottery is VRFConsumerBaseV2, KeeperCompatibleInterface {
    /* Type declarations */
    enum LoterryState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    uint256 private i_entranceFee;
    address payable[] private s_participants;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    address private s_recentWinner;
    LoterryState private s_loterryState;
    uint256 private s_lastTimeStamp;

    /* Events */
    event LoterryEnter(address indexed participant);
    event RequestedLoterryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed pickedWinner);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_loterryState = LoterryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    /** Enables a participante to enter the loterry */
    function enterLoterry() public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery__NotEnoughValue();
        }

        if (s_loterryState != LoterryState.OPEN) {
            revert Lottery__IsClosed();
        }
        s_participants.push(payable(msg.sender));
        // Event good practice: name it in reverse
        emit LoterryEnter(msg.sender);
    }

    /** R */
    function requestRandomWinner() external {
        // Req ramdom number
        // Do something with it
        s_loterryState = LoterryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLoterryWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /*requestId*/
        uint256[] memory randomWords
    ) internal override {
        // Req ramdom number
        // Do something with it
        uint256 indexOfWinner = randomWords[0] % s_participants.length; // Pega o resto da divisão
        address payable recentWinner = s_participants[indexOfWinner];
        s_recentWinner = recentWinner;
        s_loterryState = LoterryState.OPEN;
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    // Function that chainlink nodes call for the upkeepNeeded to return true
    // For it to be true this conditions should happen:
    // 1. TIme intervall passed
    // 2. Lottery shoul have at least one player and eth
    // 3. Our subscription has link
    // 4. Lottery should be in open state
    function checkUpkeep(
        bytes calldata /* checkdata */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData*/
        )
    {
        bool isOpen = LoterryState.OPEN == s_loterryState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = (s_participants.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = this.checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(address(this).balance, s_participants.length, uint256(s_loterryState));
        }
        this.requestRandomWinner();
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

    function getLoterryState() public view returns (LoterryState) {
        return s_loterryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfParticipante() public view returns (uint256) {
        return s_participants.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmantions() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }
}
