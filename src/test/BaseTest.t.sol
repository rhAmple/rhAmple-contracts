// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../RhAmple.sol";

import {ERC20Mock} from "./utils/mocks/ERC20Mock.sol";
import {RebaseHedgerMock} from "./utils/mocks/RebaseHedgerMock.sol";
import {RebaseStrategyMock} from "./utils/mocks/RebaseStrategyMock.sol";

/**
 * Errors library for rhAmple's custom errors.
 * Enables checking for errors with vm.expectRevert(Errors.<Error>).
 */
library Errors {
    // Inherited from solrocket/Ownable.sol.
    bytes internal constant OnlyCallableByOwner
        = abi.encodeWithSignature("OnlyCallableByOwner()");

    // Inheritc from elastic-receipt-token/ElasticReceiptToken.sol.
    bytes internal constant InvalidRecipient
        = abi.encodeWithSignature("InvalidRecipient()");
    bytes internal constant InvalidAmount
        = abi.encodeWithSignature("InvalidAmount()");
    bytes internal constant MaxSupplyReached
        = abi.encodeWithSignature("MaxSupplyReached()");
}

/**
 * @dev Root contract for rhAmple Test Contracts.
 *
 *      Provides the setUp function, access to common test utils, constants
 *      etc.
 */
abstract contract BaseTest is Test {
    // SuT
    RhAmple rhAmple;

    // Settings
    uint maxAmplesToHedge = MAX_SUPPLY;

    // Mocks
    ERC20Mock ample;
    RebaseStrategyMock rebaseStrategy;
    RebaseHedgerMock rebaseHedger;

    // Events copied from SuT.
    // Note that the Event declarations are needed to test for emission.
    event MaxAmplesToHedgeChanged(uint from, uint to);
    event RebaseStrategyChanged(address from, address to);
    event RebaseHedgerChanged(address from, address to);
    event RebaseHedgerRewardsClaimed();
    event RhAmplesMinted(address to, uint rhAmples);
    event RhAmplesBurned(address from, uint rhAmples);
    event AmplesHedged(uint epoch, uint amples);
    event AmplesDehedged(uint epoch, uint amples);
    event RebaseStrategyFailure();

    // Constants from SuT.
    uint internal constant DECIMALS = 9;

    // Constant copied from elastic-receipt-token.
    // For more info see github.com/pmerkleplant/elastic-receipt-token.
    uint internal constant MAX_SUPPLY = 1_000_000_000e18;

    function setUp() public {
        // Tokens
        ample = new ERC20Mock("AMPL", "Ample", uint8(9));

        // Rebase Strategy
        rebaseStrategy = new RebaseStrategyMock();
        rebaseStrategy.setShouldHedgeAndValid(false, true);

        // Rebase Hedger
        rebaseHedger = new RebaseHedgerMock(ample);

        // rhAmple
        rhAmple = new RhAmple(
            address(ample),
            address(rebaseStrategy),
            address(rebaseHedger),
            maxAmplesToHedge
        );
    }

}
