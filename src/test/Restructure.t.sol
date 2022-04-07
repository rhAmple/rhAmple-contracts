// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Test.t.sol";

import {ERC20Mock} from "./utils/mocks/ERC20Mock.sol";
import {RebaseHedgerMock} from "./utils/mocks/RebaseHedgerMock.sol";

/**
 * @dev Restructure Function Tests.
 */
contract Restructure is Test {

    function setUpMintRhAmples(uint amount) public {
        // Mint some rhAmples not run into div by zero.
        ample.mint(address(this), amount);
        ample.approve(address(rhAmple), amount);
        rhAmple.mint(amount);
    }

    function testHedging() public {
        setUpMintRhAmples(10e18);

        rebaseStrategy.setShouldHedge(true);

        vm.expectEmit(true, true, true, true);
        emit AmplesHedged(1, 10e18);

        rhAmple.restructure();

        assertEq(ample.balanceOf(address(rhAmple)), 0);
        assertEq(receiptToken.balanceOf(address(rhAmple)), 10e18);
        assertEq(rhAmple.balanceOf(address(this)), 10e18);
        assertTrue(rhAmple.isHedged());
    }

    function testHedgingMoreThanAllowed() public {
        setUpMintRhAmples(10e18);

        rhAmple.setMaxAmplesToHedge(5e18);
        rebaseStrategy.setShouldHedge(true);

        vm.expectEmit(true, true, true, true);
        emit AmplesHedged(1, 5e18);

        rhAmple.restructure();

        // Check that no more than 5e18 Amples got hedged.
        assertEq(ample.balanceOf(address(rhAmple)), 5e18);
        assertEq(receiptToken.balanceOf(address(rhAmple)), 5e18);
        assertEq(rhAmple.balanceOf(address(this)), 10e18);
        assertTrue(rhAmple.isHedged());
    }

    function testDehedging() public {
        setUpMintRhAmples(10e18);

        // Hedge Amples.
        rebaseStrategy.setShouldHedge(true);
        rhAmple.restructure();

        // Dehedge Amples.
        rebaseStrategy.setShouldHedge(false);

        vm.expectEmit(true, true, true, true);
        emit AmplesDehedged(2, 10e18);

        rhAmple.restructure();

        assertEq(ample.balanceOf(address(rhAmple)), 10e18);
        assertEq(receiptToken.balanceOf(address(rhAmple)), 0);
        assertEq(rhAmple.balanceOf(address(this)), 10e18);
        assertTrue(!rhAmple.isHedged());
    }

    function testRebaseStrategysSignalInvalid(bool isHedged) public {
        setUpMintRhAmples(10e18);

        if (isHedged) {
            // Hedge Amples.
            rebaseStrategy.setShouldHedge(true);
            rhAmple.restructure();
        }

        rebaseStrategy.setValid(false);

        vm.expectEmit(true, true, true, true);
        emit RebaseStrategyFailure();

        rhAmple.restructure();

        // Check that rhAmple is in dehedged state.
        assertEq(ample.balanceOf(address(rhAmple)), 10e18);
        assertEq(receiptToken.balanceOf(address(rhAmple)), 0);
        assertEq(rhAmple.balanceOf(address(this)), 10e18);
        assertTrue(!rhAmple.isHedged());

        // Check that max Amples allowed to hedge was set to zero.
        assertEq(rhAmple.maxAmplesToHedge(), 0);

        // Test that hedging functionality is paused.
        rebaseStrategy.setShouldHedgeAndValid(true, true);
        rhAmple.restructure();

        assertEq(ample.balanceOf(address(rhAmple)), 10e18);
        assertEq(receiptToken.balanceOf(address(rhAmple)), 0);
        assertEq(rhAmple.balanceOf(address(this)), 10e18);
        // Note that eventhough the amount of Amples hedged was 0, the protocol
        // still changed it's state to being hedged.
        assertTrue(rhAmple.isHedged());
    }

}
