// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title The RebaseStrategy Interface
 *
 * @dev A RebaseStrategy implementation can be used to decide whether one
 *      should hedge against an upcoming rebase or not.
 *
 * @author merkleplant
 */
interface IRebaseStrategy {

    /// @notice Returns whether Ample's upcoming rebase should be hedged or not.
    /// @return bool: True if Ample's upcoming rebase should be hedged, false
    ///               otherwise.
    ///         bool: Whether the signal is valid.
    function getSignal() external returns (bool, bool);

}
