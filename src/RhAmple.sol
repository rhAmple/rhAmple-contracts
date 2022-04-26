// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Ownable} from "solrocket/Ownable.sol";

import {ElasticReceiptToken} from "elastic-receipt-token/ElasticReceiptToken.sol";
import {IButtonWrapper} from "./interfaces/_external/IButtonWrapper.sol";

import {IRebaseHedger} from "./interfaces/IRebaseHedger.sol";
import {IRebaseStrategy} from "./interfaces/IRebaseStrategy.sol";

/*
 * @title The rebase-hedged Ample (rhAmple) Token
 *
 * @dev The rhAmple token is a %-ownership of Ample supply interest-bearing
 *      token, i.e. wAmple interest bearing.
 *
 *      However, the rhAmple token denominates user deposits in Ample.
 *      This is possible by using the ElasticReceiptToken which ensures the
 *      rhAmple supply always equals the amount of Amples deposited.
 *
 *      The conversion rate of rhAmple:Ample is therefore 1:1. This conversion
 *      rate can only break _during_ a user's withdrawal in which rebase-hedged
 *      receipt tokens may be selled in the open market.
 *
 * @author merkleplant
 */
contract RhAmple is ElasticReceiptToken, Ownable, IButtonWrapper {
    using SafeTransferLib for ERC20;

    //--------------------------------------------------------------------------
    // Events

    //----------------------------------
    // onlyOwner Events

    /// @notice Emitted when the max amount of Amples allowed to hedge changed.
    event MaxAmplesToHedgeChanged(uint from, uint to);

    /// @notice Emitted when Ample's market oracle changed.
    event RebaseStrategyChanged(address from, address to);

    /// @notice Emitted when the IRebaseHedger address changed.
    event RebaseHedgerChanged(address from, address to);

    /// @notice Emitted when IRebaseHedger's underlying protocol rewards
    ///         claimed.
    event RebaseHedgerRewardsClaimed();

    //----------------------------------
    // User Events

    /// @notice Emitted when a user mints rhAmples.
    event RhAmplesMinted(address to, uint rhAmples);

    /// @notice Emitted when a user burns rhAmples.
    event RhAmplesBurned(address from, uint rhAmples);

    //----------------------------------
    // Restructuring Events

    /// @notice Emitted when Amples deposited into the IRebaseHedger.
    event AmplesHedged(uint epoch, uint amples);

    /// @notice Emitted when Amples withdrawn from the IRebaseHedger.
    event AmplesDehedged(uint epoch, uint amples);

    //----------------------------------
    // Failure Events

    /// @notice Emitted when the IRebaseStrategy implementation sends an
    ///         invalid signal.
    event RebaseStrategyFailure();

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The ERC20 decimals of rhAmple.
    /// @dev Is the same as Ample's.
    uint private constant DECIMALS = 9;

    //--------------------------------------------------------------------------
    // Storage

    /// @notice The Ample token address.
    address public immutable ample;

    /// @notice The IRebaseStrategy implementation address.
    /// @dev Changeable by owner.
    address public rebaseStrategy;

    /// @notice The IRebaseHedger implementation address.
    /// @dev Changeable by owner.
    address public rebaseHedger;

    /// @notice The max amount of Amples allowed to deposit into
    ///         the IRebaseHedger.
    /// @dev Changeable by owner.
    /// @dev Setting to zero disables hedging.
    uint public maxAmplesToHedge;

    /// @dev The restructure counter, i.e. the number of rhAmple restructurings
    ///      executed since inception.
    uint public epoch;

    /// @notice True if Ample deposits are hedged against rebase, false
    ///         otherwise.
    /// @dev Updated every time rhAmple restructures.
    /// @dev Useful for off-chain services to fetch rhAmple's hedging state.
    bool public isHedged;

    //--------------------------------------------------------------------------
    // Constructor

    constructor(
        address ample_,
        address rebaseStrategy_,
        address rebaseHedger_,
        uint maxAmplesToHedge_
    ) ElasticReceiptToken("rebase-hedged Ample", "rhAMPL", uint8(DECIMALS)) {
        // Make sure that strategy is working.
        bool isValid;
        ( , isValid) = IRebaseStrategy(rebaseStrategy_).getSignal();
        require(isValid);

        // Set storage variables.
        ample = ample_;
        rebaseStrategy = rebaseStrategy_;
        rebaseHedger = rebaseHedger_;
        maxAmplesToHedge = maxAmplesToHedge_;

        // Approve Amples for IRebaseHedger.
        // Note that Ample does NOT interpret max(uint) as infinite.
        ERC20(ample_).approve(rebaseHedger_, type(uint).max);
    }

    //--------------------------------------------------------------------------
    // Restructure Function

    /// @notice Restructure Ample deposits, i.e. re-evaluate if Amples should
    ///         hedged against upcoming rebase.
    function restructure() external {
        _restructure();
    }

    //--------------------------------------------------------------------------
    // IButtonWrapper Mutating Functions

    /// @inheritdoc IButtonWrapper
    function mint(uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        _deposit(msg.sender, msg.sender, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function mintFor(address to, uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        _deposit(msg.sender, to, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function burn(uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _withdraw(msg.sender, msg.sender, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnTo(address to, uint rhAmples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _withdraw(msg.sender, to, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnAll()
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        return _withdraw(msg.sender, msg.sender, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function burnAllTo(address to)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));
        return _withdraw(msg.sender, to, rhAmples);
    }

    /// @inheritdoc IButtonWrapper
    function deposit(uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _deposit(msg.sender, msg.sender, amples);
    }

    /// @inheritdoc IButtonWrapper
    function depositFor(address to, uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        return _deposit(msg.sender, to, amples);
    }

    /// @inheritdoc IButtonWrapper
    function withdraw(uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        _withdraw(msg.sender, msg.sender, amples);
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawTo(address to, uint amples)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        _withdraw(msg.sender, to, amples);
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAll()
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));

        _withdraw(msg.sender, msg.sender, rhAmples);
        return rhAmples;
    }

    /// @inheritdoc IButtonWrapper
    function withdrawAllTo(address to)
        external
        override(IButtonWrapper)
        returns (uint)
    {
        uint rhAmples = super.balanceOf(address(msg.sender));

        _withdraw(msg.sender, to, rhAmples);
        return rhAmples;
    }

    //--------------------------------------------------------------------------
    // IButtonWrapper View Functions

    /// @inheritdoc IButtonWrapper
    function underlying()
        external
        view
        override(IButtonWrapper)
        returns (address)
    {
        return ample;
    }

    /// @inheritdoc IButtonWrapper
    function totalUnderlying()
        external
        view
        override(IButtonWrapper)
        returns (uint256)
    {
        return _totalAmpleBalance();
    }

    /// @inheritdoc IButtonWrapper
    function balanceOfUnderlying(address who)
        external
        view
        override(IButtonWrapper)
        returns (uint256)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return super.balanceOf(who);
    }

    /// @inheritdoc IButtonWrapper
    function underlyingToWrapper(uint amples)
        external
        pure
        override(IButtonWrapper)
        returns (uint)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return amples;
    }

    /// @inheritdoc IButtonWrapper
    function wrapperToUnderlying(uint256 rhAmples)
        external
        pure
        override(IButtonWrapper)
        returns (uint256)
    {
        // Note that the conversion rate of Ample:rhAmple is 1:1.
        return rhAmples;
    }

    //--------------------------------------------------------------------------
    // onlyOwner Mutating Functions

    /// @notice Sets the max amount of Amples allowed to hedge.
    /// @dev Only callable by owner.
    function setMaxAmplesToHedge(uint maxAmplesToHedge_) external onlyOwner {
        // Note that MAX_SUPPLY is defined in the upstream ElasticReceiptToken
        // contract.
        if (maxAmplesToHedge_ > MAX_SUPPLY) {
            // Do nothing if maxAmplesToHedge does not change.
            if (maxAmplesToHedge == MAX_SUPPLY) {
                return;
            }

            emit MaxAmplesToHedgeChanged(maxAmplesToHedge, MAX_SUPPLY);
            maxAmplesToHedge = MAX_SUPPLY;
        } else {
            // Do nothing if maxAmplesToHedge does not change.
            if (maxAmplesToHedge == maxAmplesToHedge_) {
                return;
            }

            emit MaxAmplesToHedgeChanged(maxAmplesToHedge, maxAmplesToHedge_);
            maxAmplesToHedge = maxAmplesToHedge_;
        }
    }

    /// @notice Sets the rebase strategy implementation.
    /// @dev Only callable by owner.
    function setRebaseStrategy(address rebaseStrategy_) external onlyOwner {
        // Do nothing if rebaseStrategy does not change.
        if (rebaseStrategy == rebaseStrategy_) {
            return;
        }

        // Make sure that strategy is working.
        bool isValid;
        ( , isValid) = IRebaseStrategy(rebaseStrategy_).getSignal();
        require(isValid);

        emit RebaseStrategyChanged(rebaseStrategy, rebaseStrategy_);
        rebaseStrategy = rebaseStrategy_;
    }

    /// @notice Set a new IRebaseHedger implementation.
    /// @dev Only callable by owner.
    function setRebaseHedger(address rebaseHedger_) external onlyOwner {
        // Do nothing if rebaseHedger does not change.
        if (rebaseHedger == rebaseHedger_) {
            return;
        }

        // Note that rewards are not claimed. This is to make sure that the
        // IRebaseHedger implementation can be changed in case the claiming
        // process is broken.

        // Withdraw Amples from current IRebaseHedger and remove approvals.
        _dehedgeAmples();
        ERC20(ample).approve(rebaseHedger, 0);

        // Set new IRebaseHedger.
        emit RebaseHedgerChanged(rebaseHedger, rebaseHedger_);
        rebaseHedger = rebaseHedger_;

        // Approve Amples for IRebaseHedger.
        // Note that Ample does NOT interpret max(uint) as infinite.
        ERC20(ample).approve(rebaseHedger_, type(uint).max);
    }

    /// @notice Claims IRebaseHedger's underlying protocol rewards.
    /// @dev Only callable by owner.
    function claimRebaseHedgerRewards(address receiver) external onlyOwner {
        IRebaseHedger(rebaseHedger).claimRewards(receiver);
        emit RebaseHedgerRewardsClaimed();
    }

    //--------------------------------------------------------------------------
    // Overriden ElasticReceiptToken Functions

    /// @dev Internal function restructuring the Ample deposits and returning
    ///      the total amount of Amples under management, i.e. the supply target
    ///      for rhAmple.
    function _supplyTarget()
        internal
        override(ElasticReceiptToken)
        returns (uint)
    {
        _restructure();

        return _totalAmpleBalance();
    }

    //--------------------------------------------------------------------------
    // Private Functions

    /// @dev Private function restructuring the Ample deposits, i.e.
    ///      hedging or dehedging Amples depending on the {IRebaseStrategy}
    ///      implementation's signal.
    function _restructure() private {
        bool shouldHedge;
        bool isValid;
        (shouldHedge, isValid) = IRebaseStrategy(rebaseStrategy).getSignal();

        if (!isValid) {
            isHedged = false;

            // Handle strategy failure by dehedging all Amples and setting max
            // Amples allowed to hedge to zero.
            _handleStrategyFailure();
            return;
        }

        if (shouldHedge) {
            _hedgeAmples();
            isHedged = true;
        } else {
            _dehedgeAmples();
            isHedged = false;
        }
    }

    /// @dev Private function to handle a user deposit. Returns the amount
    ///      of rhAmples minted.
    function _deposit(address from, address to, uint amples)
        private
        returns (uint)
    {
        super._mint(to, amples);
        ERC20(ample).safeTransferFrom(from, address(this), amples);

        emit RhAmplesMinted(to, amples);

        return amples;
    }

    /// @dev Private function to handle a user withdrawal. Returns the amount
    ///      of Amples withdrawn.
    function _withdraw(address from, address to, uint rhAmples)
        private
        returns (uint)
    {
        // Note that the rhAmple amount could change due to rebasing and needs
        // to be updated.
        rhAmples = super._burn(from, rhAmples);

        uint amples = _ableToWithdraw(rhAmples);

        // Note that Ample disallows transfers to zero address.
        ERC20(ample).safeTransfer(to, amples);

        emit RhAmplesBurned(from, rhAmples);

        return amples;
    }

    /// @dev Private function to prepare Ample withdrawal. Returns the amount
    ///      of Amples eligible to withdraw for given amount of rhAmples.
    function _ableToWithdraw(uint rhAmples) private returns (uint) {
        uint rawAmpleBalance = _rawAmpleBalance();

        if (rawAmpleBalance >= rhAmples) {
            return rhAmples;
        }

        uint amplesMissing = rhAmples - rawAmpleBalance;

        // Note that the withdrawed amount does not have to equal amplesMissing.
        // For more info see IRebaseHedger.
        IRebaseHedger(rebaseHedger).withdraw(amplesMissing);

        // Note that positive slippage is attributed to user.
        return ERC20(ample).balanceOf(address(this));
    }

    /// @dev Private function to hedge Ample deposits against negative rebase.
    function _hedgeAmples() private {
        uint amplesToHedge = _rawAmpleBalance();
        uint hedgedAmpleBalance = _hedgedAmpleBalance();

        // Return if nothing to hedge or hedged Amples is already at max.
        if (amplesToHedge == 0 || hedgedAmpleBalance >= maxAmplesToHedge) {
            return;
        }

        // Don't hedge more than allowed.
        if (amplesToHedge + hedgedAmpleBalance > maxAmplesToHedge) {
            amplesToHedge = maxAmplesToHedge - hedgedAmpleBalance;
        }

        // @todo Add test for this case.
        // Approve Amples for IRebaseHedger if allowance is not sufficint.
        // Note that Ample does NOT interpret max(uint) as infinite.
        uint allowance = ERC20(ample).allowance(address(this), rebaseHedger);
        if (allowance < amplesToHedge) {
            ERC20(ample).approve(rebaseHedger, type(uint).max);
        }

        IRebaseHedger(rebaseHedger).deposit(amplesToHedge);

        emit AmplesHedged(++epoch, amplesToHedge);
    }

    /// @dev Private function to de-hedge Ample deposits against negative
    ///      rebase.
    function _dehedgeAmples() private {
        uint amplesToDehedge = _hedgedAmpleBalance();

        // Return if nothing to dehedge.
        if (amplesToDehedge == 0) {
            return;
        }

        IRebaseHedger(rebaseHedger).withdraw(amplesToDehedge);

        emit AmplesDehedged(++epoch, amplesToDehedge);
    }

    /// @dev Private function to handle strategy failure. De-hedges all Amples
    ///      and sets maxAmplesToHedge to 0.
    function _handleStrategyFailure() private {
        // Dehedge all Amples while price is unknown.
        _dehedgeAmples();

        // Set max Ample allowed to hedge to zero.
        // Note that this effectively pauses the hedging functionality.
        emit MaxAmplesToHedgeChanged(maxAmplesToHedge, 0);
        maxAmplesToHedge = 0;

        emit RebaseStrategyFailure();
    }

    /// @dev Private function returning the total amount of Amples
    ///      under management. The amount of Amples under management is the
    ///      sum of raw Amples held in the contract and Amples hedged in the
    ///      IRebaseHedger.
    function _totalAmpleBalance() private view returns (uint) {
        return _rawAmpleBalance() + _hedgedAmpleBalance();
    }

    /// @dev Private function returning the total amount of raw Amples held
    ///      in this contract.
    function _rawAmpleBalance() private view returns (uint) {
        return ERC20(ample).balanceOf(address(this));
    }

    /// @dev Private function returning the total amount of Amples hedged in
    ///      the IRebaseHedger.
    function _hedgedAmpleBalance() private view returns (uint) {
        // Note that IRebaseHedger's balance denomination is in Ample.
        return IRebaseHedger(rebaseHedger).balance();
    }

}
