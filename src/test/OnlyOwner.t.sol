// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./BaseTest.t.sol";

import {ERC20Mock} from "./utils/mocks/ERC20Mock.sol";
import {RebaseHedgerMock} from "./utils/mocks/RebaseHedgerMock.sol";
import {RebaseStrategyMock} from "./utils/mocks/RebaseStrategyMock.sol";

/**
 * @dev onlyOwner Function Tests.
 */
contract OnlyOwner is BaseTest {

    function testOnlyOwnerFunctionsNotPubliclyCallable(address caller) public {
        if (caller == rhAmple.owner()) {
            return;
        }
        vm.startPrank(caller);

        vm.expectRevert(Errors.OnlyCallableByOwner);
        rhAmple.setMaxAmplesToHedge(10);

        vm.expectRevert(Errors.OnlyCallableByOwner);
        rhAmple.setRebaseStrategy(address(1));

        vm.expectRevert(Errors.OnlyCallableByOwner);
        rhAmple.setRebaseHedger(address(1));

        vm.expectRevert(Errors.OnlyCallableByOwner);
        rhAmple.claimRebaseHedgerRewards(address(1));
    }

    function testSetMaxAmplesToHedge(uint amount) public {
        bool amountDoesNotChange =
            amount == rhAmple.maxAmplesToHedge() ||
            amount > MAX_SUPPLY && rhAmple.maxAmplesToHedge() == MAX_SUPPLY;

        uint expected = amount > MAX_SUPPLY ? MAX_SUPPLY : amount;

        if (amountDoesNotChange) {
            // Note that no event should be emitted.
            rhAmple.setMaxAmplesToHedge(amount);

            assertEq(rhAmple.maxAmplesToHedge(), expected);
        } else {
            vm.expectEmit(true, true, true, true);
            emit MaxAmplesToHedgeChanged(maxAmplesToHedge, expected);

            rhAmple.setMaxAmplesToHedge(amount);

            assertEq(rhAmple.maxAmplesToHedge(), expected);
        }
    }

    function testSetRebaseStrategy(bool strategyIsValid) public {
        RebaseStrategyMock newStrategy = new RebaseStrategyMock();
        newStrategy.setValid(strategyIsValid);

        if (strategyIsValid) {
            vm.expectEmit(true, true, true, true);
            emit RebaseStrategyChanged(
                address(rebaseStrategy),
                address(newStrategy)
            );

            rhAmple.setRebaseStrategy(address(newStrategy));
            assertEq(rhAmple.rebaseStrategy(), address(newStrategy));
        } else {
            try rhAmple.setRebaseStrategy(address(newStrategy)) {
                revert();
            } catch {
                // Fails due to strategy delivering invalid signal.
            }
        }
    }

    function testSetRebaseHedger() public {
        RebaseHedgerMock oldHedger = rebaseHedger;
        RebaseHedgerMock newHedger = new RebaseHedgerMock(ample);

        vm.expectEmit(true, true, true, true);
        emit RebaseHedgerChanged(address(oldHedger), address(newHedger));

        rhAmple.setRebaseHedger(address(newHedger));

        // Check approvals.
        assertEq(
            ample.allowance(address(rhAmple), address(oldHedger)),
            0
        );
        assertEq(
            ample.allowance(address(rhAmple), address(newHedger)),
            type(uint).max
        );

        // Check rhAmple storage.
        assertEq(
            rhAmple.rebaseHedger(),
            address(newHedger)
        );
    }

    function testClaimRebaseHedgerRewards(uint amount, address receiver)
        public
    {
        // Set claimable reward amount.
        rebaseHedger.setRewardsClaimable(amount);

        vm.expectEmit(true, true, true, true);
        emit RebaseHedgerRewardsClaimed();

        rhAmple.claimRebaseHedgerRewards(receiver);
        assertEq(
            rebaseHedger.rewardToken().balanceOf(receiver),
            amount
        );
    }

}
