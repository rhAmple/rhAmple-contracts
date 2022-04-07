// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IRebaseHedger} from "../../../interfaces/IRebaseHedger.sol";

import {ERC20Mock} from "./ERC20Mock.sol";

contract RebaseHedgerMock is IRebaseHedger {

    ERC20Mock ample;
    ERC20Mock receiptToken;

    ERC20Mock public rewardToken;

    uint public rewardsClaimable;

    constructor(ERC20Mock ample_, ERC20Mock receiptToken_) {
        ample = ample_;

        receiptToken = receiptToken_;

        rewardToken = new ERC20Mock("RWD", "REWARDS", uint8(18));
    }

    function setRewardsClaimable(uint rewardsClaimable_) external {
        rewardsClaimable = rewardsClaimable_;
    }

    //--------------------------------------------------------------------------
    // IRebaseHedger Functions

    function deposit(uint amples) external {
        ample.transferFrom(msg.sender, address(this), amples);
        receiptToken.mint(msg.sender, amples);
    }

    function withdraw(uint amples) external {
        ample.transfer(msg.sender, amples);
        receiptToken.burn(msg.sender, amples);
    }

    function claimRewards(address receiver) external {
        rewardToken.mint(receiver, rewardsClaimable);
        rewardsClaimable = 0;
    }

    function balanceOf(address who) external view returns (uint) {
        return receiptToken.balanceOf(who);
    }

    function token() external view returns (address) {
        return address(receiptToken);
    }

}
