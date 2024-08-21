// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISablierV2Lockup } from "lib/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupRecipient } from
    "lib/v2-core/src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { IFjordPoints } from "./interfaces/IFjordPoints.sol";

struct DepositReceipt {
    uint16 epoch;
    uint256 staked;
    uint256 vestedStaked;
}

struct ClaimReceipt {
    uint16 requestEpoch;
    uint256 amount;
}

struct NFTData {
    uint16 epoch;
    uint256 amount;
}

struct UserData {
    uint256 totalStaked;
    uint256 unclaimedRewards;
    uint16 unredeemedEpoch;
    uint16 lastClaimedEpoch;
}

contract FjordStaking is ISablierV2LockupRecipient {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using EnumerableSet for EnumerableSet.UintSet;
    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when tokens are staked in the contract.
    /// @param user The address of the caller initiating the stake.
    /// @param epoch The current epoch cycle.
    /// @param amount The amount of tokens received in the stake.
    event Staked(address indexed user, uint16 indexed epoch, uint256 amount);

    /// @dev Emitted when vested FJORD tokens are staked in the contract.
    /// @param user The address of the caller initiating the stake.
    /// @param epoch The current epoch cycle.
    /// @param amount The amount of tokens received in the stake.
    /// @param streamID The stream id of the NFT.
    event VestedStaked(
        address indexed user, uint16 indexed epoch, uint256 indexed streamID, uint256 amount
    );

    /// @dev Emitted when rewards are added in the contract.
    /// @param epoch The current epoch cycle.
    /// @param amount The amount of tokens added as rewards.
    event RewardAdded(uint16 indexed epoch, address rewardAdmin, uint256 amount);

    /// @dev Emitted when rewards are claimed by the user.
    /// @param user The address of the caller initiating the claim.
    /// @param amount The amount of rewards given.
    event RewardClaimed(address indexed user, uint256 amount);

    /// @dev Emitted when rewards are claimed by the user before cooldown.
    /// @param user The address of the caller initiating the claim.
    /// @param rewardAmount The amount of rewards given.
    /// @param penaltyAmount The amount of tokens deducted as penalty.
    event EarlyRewardClaimed(address indexed user, uint256 rewardAmount, uint256 penaltyAmount);

    /// @dev Emitted when user claims rewards from all epoch cycles.
    /// @param user The address of the caller initiating the claim.
    /// @param totalRewardAmount The total reward amount given.
    /// @param totalPenaltyAmount The total amount penalised for early claim.
    event ClaimedAll(address indexed user, uint256 totalRewardAmount, uint256 totalPenaltyAmount);

    /// @dev Emitted when user unstakes the deposit.
    /// @param user The address of the caller initiating the unstake.
    /// @param epoch The epoch cycle for which unstake is initiated.
    /// @param stakedAmount The staked amount for the user.
    event Unstaked(address indexed user, uint16 indexed epoch, uint256 stakedAmount);

    /// @dev Emitted when user unstakes the vested FJO.
    /// @param user The address of the caller initiating the unstake.
    /// @param epoch The epoch cycle for which unstake is initiated.
    /// @param stakedAmount The staked amount for the user.
    /// @param streamID The stream id of the NFT.
    event VestedUnstaked(
        address indexed user, uint16 indexed epoch, uint256 stakedAmount, uint256 streamID
    );

    /// @dev Emitted when user unstakes the deposit from all epoch cycles.
    /// @param user The address of the caller initiating the unstake.
    /// @param totalStakedAmount The total staked amount for the user.
    /// @param activeDepositsBefore The epochs with active deposit in which user staked before unstake.
    /// @param activeDepositsAfter The epochs with active deposit in which user staked after unstake.
    event UnstakedAll(
        address indexed user,
        uint256 totalStakedAmount,
        uint256[] activeDepositsBefore,
        uint256[] activeDepositsAfter
    );

    /// @dev Emitted when user create a claim receipt.
    /// @param user The address of the caller initiating the claim receipt.
    /// @param requestEpoch The epoch of claim receipt.
    event ClaimReceiptCreated(address indexed user, uint16 requestEpoch);

    /// @dev Emitted when user claims reward from the claim receipt.
    /// @param epoch The epoch cycle for which reward is changed.
    /// @param rewardPerToken The amount of reward for given epoch.
    event RewardPerTokenChanged(uint16 epoch, uint256 rewardPerToken);

    /// @dev Emitted when sablier withdrawn hook is invoked.
    /// @param user The owner that stake stream id.
    /// @param streamID The stream id of the NFT.
    /// @param caller The stream sender that withdrawn the stream.
    /// @param amount The amount of tokens withdrawn.
    event SablierWithdrawn(address indexed user, uint256 streamID, address caller, uint256 amount);

    /// @dev Emitted when sablier withdrawn hook is invoked.
    /// @param user The owner that stake stream id.
    /// @param streamID The stream id of the NFT.
    /// @param caller The stream sender that withdrawn the stream.
    /// @param amount The amount of tokens unstake.
    event SablierCanceled(address indexed user, uint256 streamID, address caller, uint256 amount);
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @dev Error thrown when an address is not allowed to call a function.
    error CallerDisallowed();

    /// @dev Error thrown when a given amount is not in valid range.
    error InvalidAmount();

    /// @dev Error thrown when unstake a deposit too early.
    error UnstakeEarly();

    /// @dev Error thrown when claim reward too early.
    error ClaimTooEarly();

    /// @dev Error thrown when a deposit is not found.
    error DepositNotFound();

    /// @dev Error thrown when a claim receipt is not found.
    error ClaimReceiptNotFound();

    /// @dev Error thrown when a user have no active deposit.
    error NoActiveDeposit();

    /// @dev Error thrown when try to unstake more amount than the given deposit available.
    error UnstakeMoreThanDeposit();

    /// @dev Error thrown when user tries to stake an NFT that doesn't exists.
    error NotAStream();

    /// @dev Error thrown when user tries to stake an NFT that is not supported.
    error StreamNotSupported();

    /// @dev Error thrown when user tries to stake an NFT a cold stream.
    error NotAWarmStream();

    /// @dev Error thrown sablier vesting NFT is not of FJO token.
    error InvalidAsset();

    /// @dev Error thrown when there is nothing to claim.
    error NothingToClaim();

    /// @dev Error thrown when stream owner not found.
    error StreamOwnerNotFound();

    /// @dev Error thrown when address is zero.
    error InvalidZeroAddress();

    /// @dev Error thrown when complete claim request too early.
    error CompleteRequestTooEarly();

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice The owner of the staking contract.
    address public owner;

    /// @notice The address of the sablier vesting contrat.
    ISablierV2Lockup public sablier;

    /// @notice The address of the fjord points contract.
    IFjordPoints public points;

    /// @notice Deposit receipts for staking, user => epoch => deposit receipt
    mapping(address user => mapping(uint16 epoch => DepositReceipt)) public deposits;

    /// @notice Claim receipt receipts for reawrds, user => epoch => claim receipt
    mapping(address user => ClaimReceipt) public claimReceipts;

    /// @notice Active deposits by the user, user => set of epoch
    mapping(address user => EnumerableSet.UintSet epochIds) private _activeDeposits;

    /// @notice StreamIDs of the vested FJO staked, user => streamID => NFTData
    mapping(address user => mapping(uint256 streamID => NFTData)) private _streamIDs;

    /// @notice Owners of staked streams
    mapping(uint256 streamID => address user) private _streamIDOwners;

    /// @notice User stakes and rewards data
    mapping(address user => UserData) public userData;

    /// @notice Rewards distributed accumulated up to the epoch
    ///  rewardPerToken in each epoch will be updated one and only one, epoch => rewardPerToken
    mapping(uint16 epoch => uint256) public rewardPerToken;

    /// @notice Total staked
    uint256 public totalStaked;

    /// @notice Total vested staked
    uint256 public totalVestedStaked;

    /// @notice New staked
    uint256 public newStaked;

    /// @notice New vested staked
    uint256 public newVestedStaked;

    /// @notice Total rerwards
    uint256 public totalRewards;

    /// @notice Current epoch cycle number.
    uint16 public currentEpoch;

    /// @notice Last epoch when rewards were distributed.
    uint16 public lastEpochRewarded;

    /// @notice Mapping of authorized Sablier stream senders.
    mapping(address authorizedSablierSender => bool) public authorizedSablierSenders;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    /// @notice One epoch time in seconds.
    uint256 public constant epochDuration = 86_400 * 7; // 7 days;

    /// @notice Lock duration in epoch cycles.
    uint8 public constant lockCycle = 6;

    /// @notice Constant
    uint256 public constant PRECISION_18 = 1e18;

    /// @notice Claim cooldown duration in epoch cycles.
    uint8 public constant claimCycle = 3;

    /// @notice Address of FJORD token.
    ERC20 public immutable fjordToken;

    /// @notice Start time of the staking contract.
    uint256 public immutable startTime;

    /// @notice Reward admin.
    address public rewardAdmin;

    /**
     *
     *  CONSTRUCTOR & INITIALIZATION
     *
     */

    /**
     * @notice Initializes the contract with starting variables
     * @param _fjordToken is the FJORD token contract
     * @param _rewardAdmin is the Fee distributor contract
     */
    constructor(
        address _fjordToken,
        address _rewardAdmin,
        address _sablier,
        address _authorizedSablierSender,
        address _fjordPoints
    ) {
        if (
            _rewardAdmin == address(0) || _sablier == address(0) || _fjordToken == address(0)
                || _fjordPoints == address(0)
        ) revert InvalidZeroAddress();

        startTime = block.timestamp;
        owner = msg.sender;
        fjordToken = ERC20(_fjordToken);
        currentEpoch = 1;
        rewardAdmin = _rewardAdmin;
        sablier = ISablierV2Lockup(_sablier);
        points = IFjordPoints(_fjordPoints);
        if (_authorizedSablierSender != address(0)) {
            authorizedSablierSenders[_authorizedSablierSender] = true;
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerDisallowed();
        _;
    }

    modifier onlyRewardAdmin() {
        if (msg.sender != rewardAdmin) revert CallerDisallowed();
        _;
    }

    modifier checkEpochRollover() {
        _checkEpochRollover();
        _;
    }

    modifier redeemPendingRewards() {
        _redeem(msg.sender);
        _;
    }

    modifier onlySablier() {
        if (msg.sender != address(sablier)) revert CallerDisallowed();
        _;
    }

    function getEpoch(uint256 _timestamp) public view returns (uint16) {
        if (_timestamp < startTime) return 0;
        return uint16((_timestamp - startTime) / epochDuration) + 1;
    }

    function getActiveDeposits(address _user) public view returns (uint256[] memory) {
        return _activeDeposits[_user].values();
    }

    function getStreamData(address _user, uint256 _streamID) public view returns (NFTData memory) {
        return _streamIDs[_user][_streamID];
    }

    function getStreamOwner(uint256 _streamID) public view returns (address) {
        return _streamIDOwners[_streamID];
    }

    function setOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidZeroAddress();
        owner = _newOwner;
    }

    function setRewardAdmin(address _rewardAdmin) external onlyOwner {
        if (_rewardAdmin == address(0)) revert InvalidZeroAddress();
        rewardAdmin = _rewardAdmin;
    }

    function addAuthorizedSablierSender(address _address) external onlyOwner {
        authorizedSablierSenders[_address] = true;
    }

    function removeAuthorizedSablierSender(address _address) external onlyOwner {
        if (authorizedSablierSenders[_address]) authorizedSablierSenders[_address] = false;
    }

    /// @notice Stake FJORD tokens into the contract.
    /// @dev This function allows users to stake a certain number of FJORD tokens.
    /// @param _amount The amount of tokens user wants to stake.
    function stake(uint256 _amount) external checkEpochRollover redeemPendingRewards {
        //CHECK
        if (_amount == 0) revert InvalidAmount();

        //EFFECT
        userData[msg.sender].unredeemedEpoch = currentEpoch;

        DepositReceipt storage dr = deposits[msg.sender][currentEpoch];
        if (dr.epoch == 0) {
            dr.staked = _amount;
            dr.epoch = currentEpoch;
            _activeDeposits[msg.sender].add(currentEpoch);
        } else {
            dr.staked += _amount;
        }

        newStaked += _amount;

        //INTERACT
        fjordToken.safeTransferFrom(msg.sender, address(this), _amount);
        points.onStaked(msg.sender, _amount);

        emit Staked(msg.sender, currentEpoch, _amount);
    }

    /// @notice Stake vested FJORD tokens into the contract.
    /// @dev This function allows users to stake a certain their NFT from
    /// sablier that contains FJORD tokens.
    /// @param _streamID The streamID of the vested NFT.
    function stakeVested(uint256 _streamID) external checkEpochRollover redeemPendingRewards {
        //CHECK
        if (!sablier.isStream(_streamID)) revert NotAStream();
        if (sablier.isCold(_streamID)) revert NotAWarmStream();

        // only allow authorized stream sender to stake cancelable stream
        if (!authorizedSablierSenders[sablier.getSender(_streamID)]) {
            revert StreamNotSupported();
        }
        if (address(sablier.getAsset(_streamID)) != address(fjordToken)) revert InvalidAsset();

        uint128 depositedAmount = sablier.getDepositedAmount(_streamID);
        uint128 withdrawnAmount = sablier.getWithdrawnAmount(_streamID);
        uint128 refundedAmount = sablier.getRefundedAmount(_streamID);

        if (depositedAmount - (withdrawnAmount + refundedAmount) <= 0) revert InvalidAmount();

        uint256 _amount = depositedAmount - (withdrawnAmount + refundedAmount);

        //EFFECT
        userData[msg.sender].unredeemedEpoch = currentEpoch;

        DepositReceipt storage dr = deposits[msg.sender][currentEpoch];
        if (dr.epoch == 0) {
            dr.vestedStaked = _amount;
            dr.epoch = currentEpoch;

            _activeDeposits[msg.sender].add(currentEpoch);
        } else {
            dr.vestedStaked += _amount;
        }

        _streamIDs[msg.sender][_streamID] = NFTData({ epoch: currentEpoch, amount: _amount });
        _streamIDOwners[_streamID] = msg.sender;
        newStaked += _amount;
        newVestedStaked += _amount;

        //INTERACT
        sablier.transferFrom({ from: msg.sender, to: address(this), tokenId: _streamID });
        points.onStaked(msg.sender, _amount);

        emit VestedStaked(msg.sender, currentEpoch, _streamID, _amount);
    }

    /// @notice Unstake FJORD tokens from the contract.
    /// @dev This function allows users to unstake a certain number of FJORD tokens,
    /// while also claiming all the pending rewards. If _isEarly is true then the
    /// user will be able to bypass rewards cooldown of 3 epochs and claim early,
    /// but will incur early claim penalty.
    /// @param _epoch The epoch cycle from which user wants to unstake.
    /// @param _amount The amount of tokens user wants to unstake.
    /// @return total The total amount sent to the user.
    function unstake(uint16 _epoch, uint256 _amount)
        external
        checkEpochRollover
        redeemPendingRewards
        returns (uint256 total)
    {
        if (_amount == 0) revert InvalidAmount();

        DepositReceipt storage dr = deposits[msg.sender][_epoch];

        if (dr.epoch == 0) revert DepositNotFound();
        if (dr.staked < _amount) revert UnstakeMoreThanDeposit();

        // _epoch is same as current epoch then user can unstake immediately
        if (currentEpoch != _epoch) {
            // _epoch less than current epoch then user can unstake after at complete lockCycle
            if (currentEpoch - _epoch <= lockCycle) revert UnstakeEarly();
        }

        //EFFECT
        dr.staked -= _amount;
        if (currentEpoch != _epoch) {
            totalStaked -= _amount;
            userData[msg.sender].totalStaked -= _amount;
        } else {
            // unstake immediately
            newStaked -= _amount;
        }

        if (dr.staked == 0 && dr.vestedStaked == 0) {
            // no longer a valid unredeemed epoch
            if (userData[msg.sender].unredeemedEpoch == currentEpoch) {
                userData[msg.sender].unredeemedEpoch = 0;
            }
            delete deposits[msg.sender][_epoch];
            _activeDeposits[msg.sender].remove(_epoch);
        }

        total = _amount;

        //INTERACT
        fjordToken.safeTransfer(msg.sender, total);
        points.onUnstaked(msg.sender, _amount);

        emit Unstaked(msg.sender, _epoch, _amount);
    }

    /// @notice Unstake vested FJORD tokens from the contract.
    /// @dev This function allows users to unstake vested FJORD tokens,
    /// while also claiming all the pending rewards. If _isClaimEarly is true then the
    /// user will be able to bypass rewards cooldown of 3 epochs and claim early,
    /// but will incur early claim penalty.
    /// @param _streamID The sablier streamID that the user staked.
    function unstakeVested(uint256 _streamID) external checkEpochRollover redeemPendingRewards {
        //CHECK
        NFTData memory data = _streamIDs[msg.sender][_streamID];
        DepositReceipt memory dr = deposits[msg.sender][data.epoch];

        if (data.epoch == 0 || data.amount == 0 || dr.vestedStaked == 0 || dr.epoch == 0) {
            revert DepositNotFound();
        }

        // If epoch is same as current epoch then user can unstake immediately
        if (currentEpoch != data.epoch) {
            // If epoch less than current epoch then user can unstake after at complete lockCycle
            if (currentEpoch - data.epoch <= lockCycle) revert UnstakeEarly();
        }

        _unstakeVested(msg.sender, _streamID, data.amount);
    }

    /// @notice Partial or fully unstake vested .
    function _unstakeVested(address streamOwner, uint256 _streamID, uint256 amount) internal {
        NFTData storage data = _streamIDs[streamOwner][_streamID];
        DepositReceipt storage dr = deposits[streamOwner][data.epoch];
        if (amount > data.amount) revert InvalidAmount();

        bool isFullUnstaked = data.amount == amount;
        uint16 epoch = data.epoch;

        dr.vestedStaked -= amount;
        if (currentEpoch != data.epoch) {
            totalStaked -= amount;
            totalVestedStaked -= amount;
            userData[streamOwner].totalStaked -= amount;
        } else {
            // unstake immediately
            newStaked -= amount;
            newVestedStaked -= amount;
        }

        if (dr.vestedStaked == 0 && dr.staked == 0) {
            // instant unstake
            if (userData[streamOwner].unredeemedEpoch == currentEpoch) {
                userData[streamOwner].unredeemedEpoch = 0;
            }
            delete deposits[streamOwner][data.epoch];
            _activeDeposits[streamOwner].remove(data.epoch);
        }
        // fully unstake
        if (isFullUnstaked) {
            delete _streamIDs[streamOwner][_streamID];
            delete _streamIDOwners[_streamID];
        } else {
            data.amount -= amount;
        }

        //INTERACT
        if (isFullUnstaked) {
            sablier.transferFrom({ from: address(this), to: streamOwner, tokenId: _streamID });
        }

        points.onUnstaked(msg.sender, amount);

        emit VestedUnstaked(streamOwner, epoch, amount, _streamID);
    }

    /// @notice Unstake from all epochs.
    /// @dev This function allows users to unstake from all the epochs at once,
    /// while also claiming all the pending rewards.
    /// @return totalStakedAmount The total amount that has been unstaked.
    function unstakeAll()
        external
        checkEpochRollover
        redeemPendingRewards
        returns (uint256 totalStakedAmount)
    {
        uint256[] memory activeDeposits = getActiveDeposits(msg.sender);
        if (activeDeposits.length == 0) revert NoActiveDeposit();

        for (uint16 i = 0; i < activeDeposits.length; i++) {
            uint16 epoch = uint16(activeDeposits[i]);
            DepositReceipt storage dr = deposits[msg.sender][epoch];

            if (dr.epoch == 0 || currentEpoch - epoch <= lockCycle) continue;

            totalStakedAmount += dr.staked;

            // no vested staked and stake is 0 then delete the deposit
            if (dr.vestedStaked == 0) {
                delete deposits[msg.sender][epoch];
                _activeDeposits[msg.sender].remove(epoch);
            } else {
                // still have vested staked, then only delete the staked
                dr.staked = 0;
            }
        }

        totalStaked -= totalStakedAmount;
        userData[msg.sender].totalStaked -= totalStakedAmount;

        fjordToken.transfer(msg.sender, totalStakedAmount);
        points.onUnstaked(msg.sender, totalStakedAmount);

        // emit event
        emit UnstakedAll(
            msg.sender, totalStakedAmount, activeDeposits, getActiveDeposits(msg.sender)
        );
    }

    /// @notice Claim reward from specific epoch.
    /// @dev This function allows users to claim rewards from an epochs,
    /// if the user chooses to bypass the reward cooldown of 3 epochs,
    /// then reward penalty will be levied.
    /// @param _isClaimEarly Whether user wants to claim early and incur penalty.
    /// @return rewardAmount The reward amount that has been distributed.
    /// @return penaltyAmount The penalty incurred by the user for early claim.
    function claimReward(bool _isClaimEarly)
        external
        checkEpochRollover
        redeemPendingRewards
        returns (uint256 rewardAmount, uint256 penaltyAmount)
    {
        //CHECK
        UserData storage ud = userData[msg.sender];

        // do not allow to claimReward while user have pending claimReceipt
        // or user have claimed from the last epoch
        if (
            claimReceipts[msg.sender].requestEpoch > 0
                || claimReceipts[msg.sender].requestEpoch >= currentEpoch - 1
        ) revert ClaimTooEarly();

        if (ud.unclaimedRewards == 0) revert NothingToClaim();

        //EFFECT
        if (!_isClaimEarly) {
            claimReceipts[msg.sender] =
                ClaimReceipt({ requestEpoch: currentEpoch, amount: ud.unclaimedRewards });

            emit ClaimReceiptCreated(msg.sender, currentEpoch);

            return (0, 0);
        }

        rewardAmount = ud.unclaimedRewards;
        penaltyAmount = rewardAmount / 2;
        rewardAmount -= penaltyAmount;

        if (rewardAmount == 0) return (0, 0);

        totalRewards -= (rewardAmount + penaltyAmount);
        userData[msg.sender].unclaimedRewards -= (rewardAmount + penaltyAmount);

        //INTERACT
        fjordToken.safeTransfer(msg.sender, rewardAmount);

        emit EarlyRewardClaimed(msg.sender, rewardAmount, penaltyAmount);
    }

    /// @notice Comaplete claim receipt from specific epoch.
    /// @dev This function allows users to complete claim receipt from an epoch
    /// @return rewardAmount The reward amount that has been distributed.
    function completeClaimRequest()
        external
        checkEpochRollover
        redeemPendingRewards
        returns (uint256 rewardAmount)
    {
        ClaimReceipt memory cr = claimReceipts[msg.sender];

        //CHECK
        if (cr.requestEpoch < 1) revert ClaimReceiptNotFound();
        // to complete claim receipt, user must wait for at least 3 epochs
        if (currentEpoch - cr.requestEpoch <= claimCycle) revert CompleteRequestTooEarly();

        //EFFECT
        rewardAmount = cr.amount;

        userData[msg.sender].unclaimedRewards -= rewardAmount;

        totalRewards -= rewardAmount;
        delete claimReceipts[msg.sender];

        //INTERACT
        fjordToken.safeTransfer(msg.sender, rewardAmount);

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    /// @notice Check and update epoch rollover.
    /// @dev rollover to latest epoch, gap epoches will be filled with previous epoch reward per token
    function _checkEpochRollover() internal {
        uint16 latestEpoch = getEpoch(block.timestamp);

        if (latestEpoch > currentEpoch) {
            //Time to rollover
            currentEpoch = latestEpoch;

            if (totalStaked > 0) {
                uint256 currentBalance = fjordToken.balanceOf(address(this));

                // no distribute the rewards to the users coming in the current epoch
                uint256 pendingRewards = (currentBalance + totalVestedStaked + newVestedStaked)
                    - totalStaked - newStaked - totalRewards;
                uint256 pendingRewardsPerToken = (pendingRewards * PRECISION_18) / totalStaked;
                totalRewards += pendingRewards;
                for (uint16 i = lastEpochRewarded + 1; i < currentEpoch; i++) {
                    rewardPerToken[i] = rewardPerToken[lastEpochRewarded] + pendingRewardsPerToken;
                    emit RewardPerTokenChanged(i, rewardPerToken[i]);
                }
            } else {
                for (uint16 i = lastEpochRewarded + 1; i < currentEpoch; i++) {
                    rewardPerToken[i] = rewardPerToken[lastEpochRewarded];
                    emit RewardPerTokenChanged(i, rewardPerToken[i]);
                }
            }

            totalStaked += newStaked;
            totalVestedStaked += newVestedStaked;
            newStaked = 0;
            newVestedStaked = 0;

            lastEpochRewarded = currentEpoch - 1;
        }
    }

    /// @notice accumulate unclaimed rewards for the user from last non-zero unredeemed epoch
    /// This function should run before every tx user does, so state is correctly maintained everytime
    /// Last unredeemed epoch will be the last epoch user staked
    function _redeem(address sender) internal {
        //1. Get user data
        UserData storage ud = userData[sender];

        ud.unclaimedRewards +=
            calculateReward(ud.totalStaked, ud.lastClaimedEpoch, currentEpoch - 1);
        ud.lastClaimedEpoch = currentEpoch - 1;

        if (ud.unredeemedEpoch > 0 && ud.unredeemedEpoch < currentEpoch) {
            // 2. Calculate rewards for all deposits since last redeemed, there will be only 1 pending unredeemed epoch
            DepositReceipt memory deposit = deposits[sender][ud.unredeemedEpoch];

            // 3. Update last redeemed and pending rewards
            ud.unclaimedRewards += calculateReward(
                deposit.staked + deposit.vestedStaked, ud.unredeemedEpoch, currentEpoch - 1
            );

            ud.unredeemedEpoch = 0;
            ud.totalStaked += (deposit.staked + deposit.vestedStaked);
        }
    }

    /// @notice addReward should be called by master chef
    /// must be only call if it's can trigger update next epoch so the total staked won't increase anymore
    /// must be the action to trigger update epoch and the last action of the epoch
    /// @param _amount The amount of tokens to be added as rewards.
    function addReward(uint256 _amount) external onlyRewardAdmin {
        //CHECK
        if (_amount == 0) revert InvalidAmount();

        //EFFECT
        uint16 previousEpoch = currentEpoch;

        //INTERACT
        fjordToken.safeTransferFrom(msg.sender, address(this), _amount);

        _checkEpochRollover();

        emit RewardAdded(previousEpoch, msg.sender, _amount);
    }

    /// @notice Calculate reward for a given amount from _fromEpoch to _toEpoch
    /// @param _amount The amount of tokens staked.
    /// @param _fromEpoch The epoch from which reward calculation starts.
    /// @param _toEpoch The epoch till which reward calculation is done.
    /// @return rewardAmount The reward amount that has been distributed.
    function calculateReward(uint256 _amount, uint16 _fromEpoch, uint16 _toEpoch)
        internal
        view
        returns (uint256 rewardAmount)
    {
        rewardAmount =
            (_amount * (rewardPerToken[_toEpoch] - rewardPerToken[_fromEpoch])) / PRECISION_18;
    }

    /// @notice Responds to withdrawals triggered by either the stream's sender or an approved third party.
    /// @notice if onStreamWithdrawn is implemented inproperly, the execution flow still continues.
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    /// @param /*streamId*/ The id of the stream being withdrawn from.
    /// @param /*caller*/ The original `msg.sender` address that triggered the withdrawal.
    /// @param /*to*/ The staking contract address receiving the withdrawn assets.
    /// @param /*amount*/ The amount of assets withdrawn, denoted in units of the asset's decimals.
    function onStreamWithdrawn(
        uint256, /*streamId*/
        address, /*caller*/
        address, /*to*/
        uint128 /*amount*/
    ) external override onlySablier {
        // Left blank intentionally
    }

    /// @notice Responds to renouncements.
    /// @notice Renouncing a stream means that the sender of the stream will no longer be able to cancel it.
    /// This is useful if the sender wants to give up control of the stream.
    /// @notice onStreamRenounced never be called with non-cancelable stream
    /// and does nothing effect on the staking contract
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    /// @param /*streamId*/ The id of the renounced stream.
    function onStreamRenounced(uint256 /*streamId*/ ) external override onlySablier {
        // Left blank intentionally
    }

    /// @notice onStreamCanceled never be called with non-cancelable stream
    /// @notice Responds to sender-triggered cancellations.
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    /// @param streamId The id of the canceled stream.
    /// @param sender The stream's sender, who canceled the stream.
    /// @param senderAmount The amount of assets refunded to the stream's sender, denoted in units of the asset's
    /// decimals.
    /// @param /*recipientAmount*/ The amount of assets left for the stream's recipient to withdraw, denoted in units of
    /// the asset's decimals. This is the expected amount left in staking contract.
    function onStreamCanceled(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 /*recipientAmount*/
    ) external override onlySablier checkEpochRollover {
        address streamOwner = _streamIDOwners[streamId];

        if (streamOwner == address(0)) revert StreamOwnerNotFound();

        _redeem(streamOwner);

        NFTData memory nftData = _streamIDs[streamOwner][streamId];

        uint256 amount =
            uint256(senderAmount) > nftData.amount ? nftData.amount : uint256(senderAmount);

        _unstakeVested(streamOwner, streamId, amount);

        emit SablierCanceled(streamOwner, streamId, sender, amount);
    }
}
