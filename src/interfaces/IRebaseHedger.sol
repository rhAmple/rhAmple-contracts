// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title The RebaseHedger Interface
 *
 * @dev A RebaseHedger implementation can be used to deposit Ample
 *      tokens into a protocol which hedges, to some degree, the rebase.
 *
 *      While a RebaseHedger uses an own receipt token, e.g. Aave the
 *      aAmple token, this interface *only* uses Ample denominated amounts.
 *
 *      Note that in case a withdrawal of Ample tokens in the underlying
 *      protocol is not possible, the RebaseHedger's implementation
 *      *market sells* the protocol's receipt token for Ample tokens!
 *
 *      Therefore, the following invariant can NOT be guaranteed:
 *          balance = balanceOf(address(this));
 *          withdrawed = withdraw(balance);
 *          assert(balance == withdrawed);
 *
 * @author merkleplant
 */
interface IRebaseHedger {

    /// @notice Deposits Amples from msg.sender and mints *same amount* of
    ///         receipt tokens as Amples deposited.
    /// @param amples The amount of Amples to deposit.
    function deposit(uint amples) external;

    /// @notice Burns receipt tokens from msg.sender and withdraws Amples.
    /// @dev Note that in case a withdrawal in the underlying protocol is not
    ///      possible, the underlying receipt tokens will be sold in the open
    ///      market for Amples.
    /// @param amples The amount of Amples to withdraw.
    function withdraw(uint amples) external;

    /// @notice Returns the underlying Ample balance of an address.
    /// @param who The address to fetch the Ample balance from.
    /// @return The amount of Amples the address holds in the underlying protocol.
    function balanceOf(address who) external view returns (uint);

    /// @notice Returns the rebase hedger's receipt token address.
    /// @dev Note to be careful using this token directly as there can
    ///      be different conversion rates for different implementations.
    /// @return The address of the rebase hedger's receipt token.
    function token() external view returns (address);

    /// @notice Claims rewards from the underlying protocol and sends them to
    ///         some address.
    /// @dev Must be called via delegate call so that caller's address is
    ///      forwarded as msg.sender.
    /// @param receiver The address to send the rewards to.
    function claimRewards(address receiver) external;

}
