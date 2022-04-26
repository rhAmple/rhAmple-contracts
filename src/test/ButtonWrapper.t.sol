// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./BaseTest.t.sol";

import {ERC20Mock} from "./utils/mocks/ERC20Mock.sol";
import {RebaseHedgerMock} from "./utils/mocks/RebaseHedgerMock.sol";

/**
 * @dev ButtonWrapper Function Tests.
 */
contract ButtonWrapper is BaseTest {

    function testDepositAndMint(
        bool isDeposit,
        address user,
        uint amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));

        ample.mint(user, amount);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amount);

        // Mint of zero rhAmples forbidden.
        if (amount == 0) {
            if (isDeposit) {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.deposit(amount);
            } else {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.mint(amount);
            }
            return;
        }

        // Mint of more than MAX_SUPPLY rhAmples forbidden.
        if (amount > MAX_SUPPLY) {
            if (isDeposit) {
                vm.expectRevert(Errors.MaxSupplyReached);
                rhAmple.deposit(amount);
            } else {
                vm.expectRevert(Errors.MaxSupplyReached);
                rhAmple.mint(amount);
            }
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit RhAmplesMinted(user, amount);

        if (isDeposit) {
            assertEq(rhAmple.deposit(amount), amount);
        } else {
            assertEq(rhAmple.mint(amount), amount);
        }

        // Check that Amples transferred.
        assertEq(ample.balanceOf(user), 0);
        assertEq(ample.balanceOf(address(rhAmple)), amount);

        // Check that rhAmples minted.
        assertEq(rhAmple.balanceOf(user), amount);

        // Check that total supply, total underlying and user's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), amount);
        assertEq(rhAmple.totalUnderlying(), amount);
        assertEq(rhAmple.balanceOfUnderlying(user), amount);
    }

    function testDepositAndMintFor(
        bool isDeposit,
        address user,
        address to,
        uint amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));

        ample.mint(user, amount);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amount);

        // Mint to zero address forbidden.
        if (to == address(0)) {
            if (isDeposit) {
                vm.expectRevert(Errors.InvalidRecipient);
                rhAmple.depositFor(to, amount);
            } else {
                vm.expectRevert(Errors.InvalidRecipient);
                rhAmple.mintFor(to, amount);
            }
            return;
        }

        // Mint of zero rhAmples forbidden.
        if (amount == 0) {
            if (isDeposit) {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.depositFor(to, amount);
            } else {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.mintFor(to, amount);
            }
            return;
        }

        // Mint of more than MAX_SUPPLY rhAmples forbidden.
        if (amount > MAX_SUPPLY) {
            if (isDeposit) {
                vm.expectRevert(Errors.MaxSupplyReached);
                rhAmple.depositFor(to, amount);
            } else {
                vm.expectRevert(Errors.MaxSupplyReached);
                rhAmple.mintFor(to, amount);
            }
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit RhAmplesMinted(to, amount);

        if (isDeposit) {
            assertEq(rhAmple.depositFor(to, amount), amount);
        } else {
            assertEq(rhAmple.mintFor(to, amount), amount);
        }

        // Check that Amples transferred.
        assertEq(ample.balanceOf(user), 0);
        assertEq(ample.balanceOf(address(rhAmple)), amount);

        // Check that rhAmples minted.
        assertEq(rhAmple.balanceOf(to), amount);

        // Check that total supply, total underlying and to's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), amount);
        assertEq(rhAmple.totalUnderlying(), amount);
        assertEq(rhAmple.balanceOfUnderlying(to), amount);
    }

    function testBurnAndWithdraw(
        bool isBurn,
        address user,
        uint amountMinted,
        uint amountBurned
    ) public {
        vm.assume(amountMinted != 0);
        vm.assume(amountMinted < MAX_SUPPLY);
        vm.assume(amountBurned < amountMinted);
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));

        ample.mint(user, amountMinted);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amountMinted);
        rhAmple.mint(amountMinted);

        // Burn of zero rhAmples is forbidden.
        if (amountBurned == 0) {
            if (isBurn) {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.burn(amountBurned);
            } else {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.withdraw(amountBurned);
            }
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit RhAmplesBurned(user, amountBurned);

        if (isBurn) {
            assertEq(rhAmple.burn(amountBurned), amountBurned);
        } else {
            assertEq(rhAmple.withdraw(amountBurned), amountBurned);
        }

        uint amountLeft = amountMinted - amountBurned;

        // Check that Amples transferred.
        assertEq(ample.balanceOf(user), amountBurned);
        assertEq(ample.balanceOf(address(rhAmple)), amountLeft);

        // Check that rhAmples burned.
        assertEq(rhAmple.balanceOf(user), amountLeft);

        // Check that total supply, total underlying and user's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), amountLeft);
        assertEq(rhAmple.totalUnderlying(), amountLeft);
        assertEq(rhAmple.balanceOfUnderlying(user), amountLeft);
    }

    function testBurnAndWithdrawTo(
        bool isBurn,
        address user,
        address to,
        uint amountMinted,
        uint amountBurned
    ) public {
        vm.assume(amountMinted != 0);
        vm.assume(amountMinted < MAX_SUPPLY);
        vm.assume(amountBurned < amountMinted);
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));
        vm.assume(to != address(0));
        vm.assume(to != address(rhAmple));

        ample.mint(user, amountMinted);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amountMinted);
        rhAmple.mint(amountMinted);

        // Burn of zero rhAmples is forbidden.
        if (amountBurned == 0) {
            if (isBurn) {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.burnTo(to, amountBurned);
            } else {
                vm.expectRevert(Errors.InvalidAmount);
                rhAmple.withdrawTo(to, amountBurned);
            }
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit RhAmplesBurned(user, amountBurned);

        if (isBurn) {
            assertEq(rhAmple.burnTo(to, amountBurned), amountBurned);
        } else {
            assertEq(rhAmple.withdrawTo(to, amountBurned), amountBurned);
        }

        uint amountLeft = amountMinted - amountBurned;

        // Check that Amples transferred.
        assertEq(ample.balanceOf(to), amountBurned);
        assertEq(ample.balanceOf(address(rhAmple)), amountLeft);

        // Check that rhAmples burned.
        assertEq(rhAmple.balanceOf(user), amountLeft);

        // Check that total supply, total underlying and user's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), amountLeft);
        assertEq(rhAmple.totalUnderlying(), amountLeft);
        assertEq(rhAmple.balanceOfUnderlying(user), amountLeft);
    }

    function testBurnAndWithdrawAll(
        bool isBurn,
        address user,
        uint amount
    ) public {
        vm.assume(amount != 0);
        vm.assume(amount < MAX_SUPPLY);
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));

        // Mint some rhAmples to address(this) so that we do not burn the whole
        // rhAmple supply.
        ample.mint(address(this), 1);
        ample.approve(address(rhAmple), 1);
        rhAmple.mint(1);

        ample.mint(user, amount);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amount);
        rhAmple.mint(amount);

        vm.expectEmit(true, true, true, true);
        emit RhAmplesBurned(user, amount);

        if (isBurn) {
            assertEq(rhAmple.burnAll(), amount);
        } else {
            assertEq(rhAmple.withdrawAll(), amount);
        }

        // Check that Amples transferred.
        assertEq(ample.balanceOf(user), amount);
        assertEq(ample.balanceOf(address(rhAmple)), 1);

        // Check that rhAmples burned.
        assertEq(rhAmple.balanceOf(user), 0);

        // Check that total supply, total underlying and user's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), 1);
        assertEq(rhAmple.totalUnderlying(), 1);
        assertEq(rhAmple.balanceOfUnderlying(address(user)), 0);
    }

    function testBurnAndWithdrawAllTo(
        bool isBurn,
        address user,
        address to,
        uint amount
    ) public {
        vm.assume(amount != 0);
        vm.assume(amount < MAX_SUPPLY);
        vm.assume(user != address(0));
        vm.assume(user != address(rhAmple));
        vm.assume(to != address(0));
        vm.assume(to != address(rhAmple));

        // Mint some rhAmples to address(this) so that we do not burn the whole
        // rhAmple supply.
        ample.mint(address(this), 1);
        ample.approve(address(rhAmple), 1);
        rhAmple.mint(1);

        ample.mint(user, amount);

        vm.startPrank(user);
        ample.approve(address(rhAmple), amount);
        rhAmple.mint(amount);

        vm.expectEmit(true, true, true, true);
        emit RhAmplesBurned(user, amount);

        if (isBurn) {
            assertEq(rhAmple.burnAllTo(to), amount);
        } else {
            assertEq(rhAmple.withdrawAllTo(to), amount);
        }

        // Check that Amples transferred.
        assertEq(ample.balanceOf(to), amount);
        assertEq(ample.balanceOf(address(rhAmple)), 1);

        // Check that rhAmples burned.
        assertEq(rhAmple.balanceOf(user), 0);

        // Check that total supply, total underlying and to's underlying
        // balance got updated.
        assertEq(rhAmple.totalSupply(), 1);
        assertEq(rhAmple.totalUnderlying(), 1);
        assertEq(rhAmple.balanceOfUnderlying(to), 0);
    }

}
