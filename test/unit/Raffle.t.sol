// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

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
}
