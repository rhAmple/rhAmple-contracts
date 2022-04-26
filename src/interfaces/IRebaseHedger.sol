// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title The RebaseHedger Interface
 *
 * @dev A IRebaseHedger implementation is used by the rhAmple contract to
 *      hedge, to some degree, an upcoming rebase.
 *
 *      The implementation *must* make sure that only the rhAmple contract is
 *      able to deposit and withdraw Amples as well as claiming any underlying
 *      protocol rewards.
 *
 *      The IRebaseHedger uses Ample denomination for all functions.
 *
 *      After depositing, the rhAmple contract *does not* receive receipt
 *      tokens. The hedged Amples are held inside the IRebaseHedger
 *      implementation. This is due to simplify claiming rewards from
 *      underlying protocols used by the IRebaseHedger implementation.
 *
 *      Note that in case a withdrawal of Ample tokens in the underlying
 *      protocol is not possible, the IRebaseHedger implementation
 *      *market sells* the underlying protocol's receipt token for Amples!
 *
 *      Therefore, the following invariant can NOT be guaranteed:
 *          balance = IRebaseHedger.balance();
 *          withdrawed = IRebaseHedger.withdraw(balance);
 *          assert(balance == withdrawed);
 *
 * @author merkleplant
 */
interface IRebaseHedger {

    /// @notice Deposits Amples from the rhAmple contract in order to hedge
    ///         against a negative rebase.
    /// @dev Only callable by the rhAmple contract.
    /// @param amples The amount of Amples to deposit.
    function deposit(uint amples) external;

    /// @notice Withdraws Amples from the IRebaseHedger implementation and
    ///         transfers them to the rhAmple contract.
    /// @dev Only callable by the rhAmple contract.
    /// @param amples The amount of Amples to withdraw.
    function withdraw(uint amples) external;

    /// @notice Claims rewards from the IRebaseHedger implementation's
    ///         underlying protocol and transfers them to the specified address.
    /// @dev Only callable by the rhAmple contract.
    /// @param receiver The address to receive the rewards.
    function claimRewards(address receiver) external;

    /// @notice Returns the balance, denominated in Ample, the rhAmple contract
    ///         has deposited in the IRebaseHedger implementation.
    /// @return rhAmple's balance in the IRebaseHedger implementation.
    function balance() external view returns (uint);

}
