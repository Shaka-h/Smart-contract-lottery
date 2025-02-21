// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title A sample Raffle Contract
 * @author Miriam Shaka
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2
 */

contract Raffle is VRFV2PlusWrapperConsumerBase, ConfirmedOwner(msg.sender) {
    error SendMoreToEnterRaffle();
    error TransaferFailed();
    error RaffleNotOpen();
    error UpKeepNotNeeded(uint256 balance, uint256 s_players_length, RaffleStatus s_raffleState);

    uint256 private immutable i_entryFees;
    uint256 private immutable i_timeInterval;
    address payable[] private s_players;
    address payable s_winner;
    uint256 private s_lastTimeStamp;

    uint32 private _callbackGasLimit;
    uint32 private constant NUM_WORDS = 2;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;
    RaffleStatus private s_raffleState;

    enum RaffleStatus {
        OPEN,
        CALCULATING,
        CLOSED
    }

    event EnteredRaffle(address indexed player);
    event RequestSent(uint256 requestId, uint32 numWords);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entryFees,
        uint256 timeInterval,
        address _vrfV2PlusWrapper,
        uint32 callbackGasLimit
    ) VRFV2PlusWrapperConsumerBase(_vrfV2PlusWrapper) {
        i_entryFees = entryFees;
        i_timeInterval = timeInterval;
        s_lastTimeStamp = block.timestamp;
        _callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleStatus.OPEN;
    }

    function enterRaffle() public payable {
        if (s_raffleState != RaffleStatus.OPEN) {
            revert RaffleNotOpen();
        }
        if (msg.value < i_entryFees) {
            revert SendMoreToEnterRaffle();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }
        //has time passed
        //done randomely
        //done automatically
    function performUpkeep(bytes memory, bool enableNativePayment) external {
        (bool upKeepNeeded, )= checkUpkeep("");

        if (!upKeepNeeded) {
            revert UpKeepNotNeeded(address(this).balance, s_players.length, s_raffleState);
        }

        s_raffleState = RaffleStatus.CALCULATING;
        // Check
        if (block.timestamp - s_lastTimeStamp > i_timeInterval) {
            s_raffleState = RaffleStatus.CALCULATING;

            bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
                VRFV2PlusClient.ExtraArgsV1({
                    nativePayment: enableNativePayment
                })
            );
            uint256 requestId;
            uint256 reqPrice;
            if (enableNativePayment) {
                (requestId, reqPrice) = requestRandomnessPayInNative(
                    _callbackGasLimit,
                    REQUEST_CONFIRMATIONS,
                    NUM_WORDS,
                    extraArgs
                );
            } else {
                (requestId, reqPrice) = requestRandomness(
                    _callbackGasLimit,
                    REQUEST_CONFIRMATIONS,
                    NUM_WORDS,
                    extraArgs
                );
            }

            // Effect
            // DirectFundingConsumer consumer = new DirectFundingConsumer;

            s_requests[requestId] = RequestStatus({
                paid: reqPrice,
                randomWords: new uint256[](0),
                fulfilled: false
            });
            requestIds.push(requestId);
            lastRequestId = requestId;
            emit RequestSent(requestId, NUM_WORDS);
            // return requestId;
        }
    }

    // When an abstract contract is inherited then define undefined functions
    //   function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;
    //virtual..has to be overriden
    //VRFV2PlusWrapperConsumerBase calls rawFulfillRandomWords which then calls fulfillRandomWords which is a virtual..
    // ..so its either we declare our contract as an abstract or override the functionit

    // Check Effect Interactioin(CEI)
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        // Check
        //using random number to pick winner

        // Effects
        uint256 index_of_winner = _randomWords[0] % s_players.length;
        address payable winner = s_players[index_of_winner];
        s_winner = winner;

        s_raffleState = RaffleStatus.CLOSED;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);

        // Interactions
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (success) {
            revert TransaferFailed();
        }
    }

    function getEntryFees() external view returns (uint256) {
        return i_entryFees;
    }

    function checkUpkeep(
        //is it time to perform upkeep
        //chainlink nodes continuosuly call this fumction till when condiotons are met
        bytes memory /* checkData */
    )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp > i_timeInterval;
        bool lotteryIsOpen = s_raffleState == RaffleStatus.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded =
            timeHasPassed &&
            lotteryIsOpen &&
            hasBalance &&
            hasPlayers;

        return (upkeepNeeded, hex"");
    }

}

