// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Test.t.sol";

import {ERC20Mock} from "./utils/mocks/ERC20Mock.sol";
import {RebaseHedgerMock} from "./utils/mocks/RebaseHedgerMock.sol";
import {RebaseStrategyMock} from "./utils/mocks/RebaseStrategyMock.sol";

/**
 * @dev onlyOwner Function Tests.
 */
contract OnlyOwner is Test {

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
        rhAmple.setRebaseHedgerRewardsReceiver(address(1));

        vm.expectRevert(Errors.OnlyCallableByOwner);
        rhAmple.setRebaseHedger(address(1), false, false);
    }

    function testSetMaxAmplesToHedge(uint amount) public {
        uint newMaxAmplesToHedge = amount > MAX_SUPPLY ? MAX_SUPPLY : amount;

        vm.expectEmit(true, true, true, true);
        emit MaxAmplesToHedgeChanged(maxAmplesToHedge, newMaxAmplesToHedge);

        rhAmple.setMaxAmplesToHedge(amount);

        assertEq(rhAmple.maxAmplesToHedge(), newMaxAmplesToHedge);
    }

    function testSetRebaseStrategy(bool strategyIsValid) public {
        RebaseStrategyMock newStrategy = new RebaseStrategyMock();
        newStrategy.setValid(strategyIsValid);

        if (strategyIsValid) {
            vm.expectEmit(true, true, true, true);
            emit RebaseStrategyChanged(address(rebaseStrategy),
                                       address(newStrategy));

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

    function testSetRebaseHedgerRewardsReceiver(address to) public {
        vm.expectEmit(true, true, true, true);
        emit RebaseHedgerRewardsReceiverChanged(rebaseHedgerRewardsReceiver,
                                                to);

        rhAmple.setRebaseHedgerRewardsReceiver(to);
        assertEq(rhAmple.rebaseHedgerRewardsReceiver(), to);
    }

    //--------------------------------------------------------------------------
    // Rebase Hedger Switch Tests
    //
    //  States to test:
    //    - Don't withdraw tokens and don't claim rewards
    //    - Don't withdraw tokens but claim rewards which fails
    //    - Don't withdraw tokens but claim rewards which succeeds
    //    - Withdraw tokens but don't claim rewards
    //    - Withdraw tokens and claim rewards which fails
    //    - Withdraw tokens and claim rewards which succeeds

    function testSetRebaseHedgerNoWithdrawAndNoClaim() public {
        ERC20Mock oldToken = receiptToken;
        RebaseHedgerMock oldHedger = rebaseHedger;

        ERC20Mock newToken = new ERC20Mock("RT", "receipt token", uint8(9));
        RebaseHedgerMock newHedger = new RebaseHedgerMock(ample, newToken);

        // Mint receipt tokens to rhAmple and Amples to rebase hedger.
        uint oldTokenBalance = 10e18;
        oldToken.mint(address(rhAmple), oldTokenBalance);
        ample.mint(address(oldToken), oldTokenBalance);

        // Mint rewards tokens to rhAmple.
        uint rewardsClaimable = 20e18;
        oldHedger.setRewardsClaimable(rewardsClaimable);

        // Expect event.
        vm.expectEmit(true, true, true, true);
        emit RebaseHedgerChanged(address(oldHedger), address(newHedger));

        rhAmple.setRebaseHedger(address(newHedger), false, false);
        basicRebaseHedgerSwitchChecks(oldHedger, oldToken, newHedger, newToken);

        // Did not withdraw from rebase hedger.
        assertEq(oldHedger.balanceOf(address(rhAmple)), oldTokenBalance);

        // Did not claim rewards.
        assertEq(oldHedger.rewardsClaimable(), rewardsClaimable);
        assertEq(oldHedger.rewardToken().balanceOf(address(rhAmple)), 0);
    }

    function testSetRebaseHedgerNoWithdrawAndClaimFails() public {
        vm.expectRevert("Claim failed");
        rhAmple.setRebaseHedger(address(rebaseHedger), false, true);
    }

    function testSetRebaseHedgerNoWithdrawAndClaimSucceeds() public {
        // @todo Delegate call fails
    }

    function testSetRebaseHedgerWithdrawAndNoClaim() public {
        ERC20Mock oldToken = receiptToken;
        RebaseHedgerMock oldHedger = rebaseHedger;

        ERC20Mock newToken = new ERC20Mock("RT", "receipt token", uint8(9));
        RebaseHedgerMock newHedger = new RebaseHedgerMock(ample, newToken);

        // Mint receipt tokens to rhAmple and Amples to rebase hedger.
        uint oldTokenBalance = 10e18;
        oldToken.mint(address(rhAmple), oldTokenBalance);
        ample.mint(address(oldHedger), oldTokenBalance);

        // Mint rewards tokens to rhAmple.
        uint rewardsClaimable = 20e18;
        oldHedger.setRewardsClaimable(rewardsClaimable);

        // Expect events.
        vm.expectEmit(true, true, true, true);
        emit RebaseHedgerChanged(address(oldHedger), address(newHedger));

        rhAmple.setRebaseHedger(address(newHedger), true, false);
        basicRebaseHedgerSwitchChecks(oldHedger, oldToken, newHedger, newToken);
    }

    function testSetRebaseHedgerWithdrawAndClaimFails() public {
        vm.expectRevert("Claim failed");
        rhAmple.setRebaseHedger(address(rebaseHedger), false, true);
    }

    function testSetRebaseHedgerWithdrawAndClaimSucceeds() public {
        // @todo Delegate call fails
    }

    //--------------------------------------------------------------------------
    // Helper Functions

    function basicRebaseHedgerSwitchChecks(
        RebaseHedgerMock oldHedger,
        ERC20Mock oldToken,
        RebaseHedgerMock newHedger,
        ERC20Mock newToken
    ) public {
        // Check that old rebase hedger's allowance is cleared.
        assertEq(
            ample.allowance(address(rhAmple), address(oldHedger)),
            0
        );
        assertEq(
            oldToken.allowance(
                address(rhAmple), address(oldHedger)
            ),
            0
        );

        // Check that infinite allowance is given for new rebase hedger.
        assertEq(
            ample.allowance(address(rhAmple), address(newHedger)),
            type(uint).max
        );
        assertEq(
            newToken.allowance(
                address(rhAmple), address(newHedger)
            ),
            type(uint).max
        );

        // Check that rebase hedger and receipt token updated.
        assertEq(rhAmple.rebaseHedger(), address(newHedger));
        assertEq(rhAmple.receiptToken(), address(newToken));
    }

}
