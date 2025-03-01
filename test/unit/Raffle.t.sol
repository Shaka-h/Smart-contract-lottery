// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, Script {
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entryFees;
    uint256 timeInterval;
    address vrfCoordinatorV2_5;
    uint32 callbackGasLimit;
    address public PLAYER = makeAddr("player1");
    uint256 public STARTING_BALANCE = 10 ether;

    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    error ContractHasNoBalance();

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();

        (helperConfig, raffle) = deployRaffle.run();

        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();

        entryFees = networkConfig.entryFees;
        timeInterval = networkConfig.timeInterval;
        vrfCoordinatorV2_5 = networkConfig.vrfCoordinatorV2_5;
        callbackGasLimit = networkConfig.callbackGasLimit;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitialState() external view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffle__SendMoreToEnterRaffle() external {
        // Arrange
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testArrayOfPlayers() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEmitRaffleEntered() external {
        vm.prank(PLAYER);
        vm.expectEmit(address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entryFees}();
    }

    function testCantEnterRaffleWhenNotOpen() external {
        //perform upkeep to keep state into calculating
        //upkeepNeededshould be true
        //time passed, isOpen, has balance and has players
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();
        // vm.warp timestamp
        // vm.roll blocknumber

        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();
    }

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() external {
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        vm.prank(PLAYER);
        (bool needed,) = raffle.checkUpkeep("");
        assert(!needed);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();

        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool needed,) = raffle.checkUpkeep("");
        assert(!needed);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();

        (bool needed,) = raffle.checkUpkeep("");
        assert(!needed);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        (bool needed,) = raffle.checkUpkeep("");
        assert(needed);
    }

    modifier upKeepNeeded() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entryFees}();
        vm.warp(block.timestamp + timeInterval + 1);
        vm.roll(block.number + 1);
        raffle.checkUpkeep("");
        _;
    }

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() external upKeepNeeded {
        // vm.expectRevert(Raffle.Raffle__UpkeepNotNeeded.selector);  does not revert cause it only reverts if upkeep is not satisfied
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() external {
        uint256 balance = 0;
        uint256 players = 0;
        Raffle.RaffleState state = raffle.getRaffleState();

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, balance, players, state));
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleState() external upKeepNeeded {
        raffle.performUpkeep("");
        Raffle.RaffleState state = raffle.getRaffleState();
        assert(state == Raffle.RaffleState.CALCULATING);
    }

    function testPerformUpkeepUpdatesRaffleEmitsRequestId() external upKeepNeeded {
        vm.recordLogs(); //record all the next emited events
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); //store the logs in this array
        console.log("Number of logs: ", entries.length);
        bytes32 requestId = entries[1].topics[1];
        assert(requestId != 0);
        Raffle.RaffleState state = raffle.getRaffleState();
        assert(uint256(state) > 0);
    }

    function testfulfillRandomWordsCanOnlyBecalledAfterPerformUpkeep(uint256 requestId) external upKeepNeeded {
        //its the vrfcoordinator calling the fullfillRandomWords
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(requestId, address(raffle));
    }

    // function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() external {
    //     //create player array

    //     uint256 startingIndex = 1;
    //     uint256 entrantlength = 3;

    //     for (uint256 i = startingIndex; i < startingIndex + entrantlength; i++) {
    //         address player = address(uint160(i));
    //         // hoax(player, 1 ether);
    //         vm.prank(PLAYER);
    //         raffle.enterRaffle{value: entryFees}();
    //     }

    //     vm.warp(block.timestamp + timeInterval + 1);
    //     vm.roll(block.number + 1);

    //     vm.recordLogs(); //record all the next emited events
    //     raffle.performUpkeep("");
    //     Vm.Log[] memory entries = vm.getRecordedLogs(); //store the logs in this array
    //     console.log("Number of logs: ", entries.length);
    //     bytes32 requestId = entries[1].topics[1];

    //     VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fulfillRandomWords(uint256(requestId), address(raffle));

    //     Raffle.RaffleState raffleState = raffle.getRaffleState();

    //     assert(uint256(raffleState) == 0);
    //     // assert(winnerBalance == startingBalance + prize);
    //     // assert(endingTimeStamp > startingTimeStamp);
    // }
}
