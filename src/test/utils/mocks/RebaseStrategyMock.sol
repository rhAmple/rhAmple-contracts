// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IRebaseStrategy} from "../../../interfaces/IRebaseStrategy.sol";

contract RebaseStrategyMock is IRebaseStrategy {
    bool public shouldHedge;
    bool public valid;

    function setShouldHedgeAndValid(bool shouldHedge_, bool valid_) external {
        shouldHedge = shouldHedge_;
        valid = valid_;
    }

    function setShouldHedge(bool shouldHedge_) external {
        shouldHedge = shouldHedge_;
    }

    function setValid(bool valid_) external {
        valid = valid_;
    }

    //--------------------------------------------------------------------------
    // IRebaseStrategy Functions

    function getSignal() external view returns (bool, bool) {
        return (shouldHedge, valid);
    }

}
