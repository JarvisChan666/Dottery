// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @author  JarvisChan666.
 * @title   A Raffle Contract.
 * @dev     Implements Chainlink VRFv2.
 * @notice  A sample raffle.
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// TODO:  Ensure that any other significant state changes or actions are also accompanied by event emissions for transparency.
contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthSent(uint256 ethSent, uint256 neededEth);
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen(RaffleState state);
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /** State Variables */

    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane; // depend on the chain
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint256 _entranceFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _gasLane,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        // @Dev Duration of lottery in seconds
        i_interval = _interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_gasLane = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    /**
     * @dev Players enter the raffle game.
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent(msg.value, i_entranceFee);
        }

        // Raffle not open yet
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen(s_raffleState);
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev Offline, To see if it's time to perform an upkeep, aka automation(Execute our code automated)
     * The following should be true to trigger this func to return true
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contract has ETH, players
     * 4. The subscription is funded with LINK
     * 5. upKeepNeeded will be true when 4 variables are true
     * @return upKeepNeeded
     * @return memory
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upKeepNeeded, bytes memory /* performData */) {
        // Cache state variables in memory
        // Only read from storage once and then accessed from the cheaper memory
        uint256 lastTimeStamp = s_lastTimeStamp;
        RaffleState raffleState = s_raffleState;

        bool timeHasPassed = (block.timestamp - lastTimeStamp) >= i_interval;
        bool isOpen = raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upKeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upKeepNeeded, "0x0");
    }

    /**
     * @dev Called by Chainlink Keepers to execute our task automated
     * Initiates the process of selecting a raffle winner.
     * Requires that certain conditions are met, such as time interval and raffle state.
     */
    // TODO: Ensure that the performUpKeep function can only be called by authorized addresses, such as the Chainlink Keeper network, to prevent unauthorized triggering of the raffle draw.
    function performUpKeep(bytes calldata /* performData */) external {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        //uint256 requestId = i_vrfCoordinator.requestRandomWords
        i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gas lane
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    // Override from VRFConsumerBaseV2

    /**
     * @dev Get the random words and pick winner
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        // Checks

        // Effects
        uint256 indexWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);

        // Interactions
        // TODO: OpenZeppelin's SafeTransfer library
        // function sendValue(address payable recipient, uint256 amount) internal {
        // if (address(this).balance < amount) {
        //     revert AddressInsufficientBalance(address(this));
        // }

        // (bool success, ) = recipient.call{value: amount}("");
        // if (!success) {
        //     revert FailedInnerCall();
        // }
        // }
        Address.sendValue(winner, address(this).balance);
        // No need to check for success as sendValue reverts on failure
    }

    /** Getter Function */
    // We won't use it in this contract, so external is gas efficient
    /**
     * @dev Getter Function to get entrance fee
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
