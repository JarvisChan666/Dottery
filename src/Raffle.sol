// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @author  JarvisChan666.
 * @title   A Raffle Contract.
 * @dev     Implements Chainlink VRFv2.
 * @notice  A sample raffle.
 */

contract Raffle {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTime();

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    event EnteredRaffle(address indexed player);

    constructor(uint256 _entranceFee, uint256 _interval) {
        i_entranceFee = _entranceFee;
        // @Dev Duration of lottery in seconds
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
    }

    // We won't use it in this contract, so external is gas efficient
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert Raffle__NotEnoughTime();
        }

        
    }
}
