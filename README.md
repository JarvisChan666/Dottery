

## 
The `Raffle.sol` contract is a smart contract for a decentralized lottery system that uses Chainlink VRF to generate random numbers in a secure and verifiable manner. It's designed to ensure fairness and transparency in the selection of a winner, with various mechanisms in place to prevent manipulation and ensure the integrity of the raffle process.


CEI Design
- Checks(safety, gas efficiency)
- Effects
- Interactions


## Style Guide
## Layout Order
Pragma statements

Import statements

Events

Errors

Interfaces

Libraries

Contracts

Inside each contract, library or interface, use the following order:

Type declarations

State variables

Events

Errors

Modifiers

Functions

### Function Order
constructor

receive function (if exists)

fallback function (if exists)

external

public

internal

private