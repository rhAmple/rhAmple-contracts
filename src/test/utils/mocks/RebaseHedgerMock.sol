// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IRebaseHedger} from "../../../interfaces/IRebaseHedger.sol";

import {ERC20Mock} from "./ERC20Mock.sol";

contract RebaseHedgerMock is IRebaseHedger {

    ERC20Mock public ample;
    ERC20Mock public rewardToken;

    uint public rewardsClaimable;

    uint private _balance;

    constructor(ERC20Mock ample_) {
        ample = ample_;
        rewardToken = new ERC20Mock("RWD", "REWARDS", uint8(18));
    }

    function setRewardsClaimable(uint rewardsClaimable_) external {
        rewardsClaimable = rewardsClaimable_;
    }

    function increaseBalance(uint amount) public {
        _balance += amount;
    }

    function decreaseBalance(uint amount) public {
        _balance -= amount;
    }

    //--------------------------------------------------------------------------
    // IRebaseHedger Functions

    function deposit(uint amples) external {
        ample.transferFrom(msg.sender, address(this), amples);
        _balance += amples;
    }

    function withdraw(uint amples) external {
        ample.transfer(msg.sender, amples);
        _balance -= amples;
    }

    function claimRewards(address receiver) external {
        rewardToken.mint(receiver, rewardsClaimable);
        rewardsClaimable = 0;
    }

    function balance() external view returns (uint) {
        return _balance;
    }

}
