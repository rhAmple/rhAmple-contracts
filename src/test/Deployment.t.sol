// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Test.t.sol";

/**
 * @dev Deployment Tests.
 */
contract Deployment is Test {

    function testInvariants() public {
        // Ownable Dependency Invariants.
        assertEq(rhAmple.owner(), address(this));
        assertEq(rhAmple.pendingOwner(), address(0));

        // ElasticReceiptToken Dependency Invariants.
        assertEq(rhAmple.totalSupply(), 0);
        assertEq(rhAmple.scaledTotalSupply(), 0);

        // IButtonWrapper storage correctly initialized.
        assertEq(rhAmple.underlying(), address(ample));
        assertEq(rhAmple.totalUnderlying(), 0);
        assertEq(rhAmple.underlyingToWrapper(10e18), 10e18);
        assertEq(rhAmple.wrapperToUnderlying(10e18), 10e18);

        // rhAmple Invariants.
        assertTrue(!rhAmple.isHedged());
    }

    function testConstructor() public {
        // ElasticReceiptToken Constructor.
        assertEq(rhAmple.symbol(), "rhAMPL");
        assertEq(rhAmple.name(), "rebase-hedged Ample");
        assertEq(rhAmple.decimals(), uint8(DECIMALS));

        // Constructor arguments.
        assertEq(rhAmple.ample(), address(ample));
        assertEq(rhAmple.rebaseStrategy(), address(rebaseStrategy));
        assertEq(rhAmple.rebaseHedger(), address(rebaseHedger));
        assertEq(rhAmple.receiptToken(), address(receiptToken));
        assertEq(
            rhAmple.rebaseHedgerRewardsReceiver(),
            address(rebaseHedgerRewardsReceiver)
        );
        assertEq(rhAmple.maxAmplesToHedge(), maxAmplesToHedge);

        // Infinite allowance given to rebase hedger.
        assertEq(
            ample.allowance(address(rhAmple), address(rebaseHedger)),
            type(uint).max
        );
        assertEq(
            receiptToken.allowance(
                address(rhAmple), address(rebaseHedger)
            ),
            type(uint).max
        );
    }

}
