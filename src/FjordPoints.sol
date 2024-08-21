// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from
    "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { SafeMath } from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import { IFjordPoints } from "./interfaces/IFjordPoints.sol";
/**
 * @title FjordPoints
 * @dev ERC20 token to represent points distributed based on locked tokens in Staking contract.
 */

contract FjordPoints is ERC20, ERC20Burnable, IFjordPoints {
    using SafeMath for uint256;

    /**
     * @notice Thrown when an invalid address (e.g., zero address) is provided to a function or during initialization.
     */
    error InvalidAddress();

    /**
     * @notice Thrown when a distribution attempt is made before the allowed time (e.g., before the epoch duration has passed).
     */
    error DistributionNotAllowedYet();

    /**
     * @notice Thrown when an unauthorized caller attempts to execute a restricted function.
     */
    error NotAuthorized();

    /**
     * @notice Thrown when a user attempts to unstake an amount that exceeds their currently staked balance.
     */
    error UnstakingAmountExceedsStakedAmount();

    /**
     * @notice Thrown when an operation requires a non-zero total staked amount, but the total staked amount is zero.
     */
    error TotalStakedAmountZero();

    /**
     * @notice Thrown when a disallowed caller attempts to execute a function that is restricted to specific addresses.
     */
    error CallerDisallowed();

    /// @notice The owner of the contract
    address public owner;

    /// @notice The staking contract address
    address public staking;

    /// @notice Duration of each epoch for points distribution
    uint256 public constant EPOCH_DURATION = 1 weeks;

    /// @notice Timestamp of the last points distribution
    uint256 public lastDistribution;

    /// @notice Total amount of tokens staked in the contract
    uint256 public totalStaked;

    /// @notice Points distributed per token staked
    uint256 public pointsPerToken;

    /// @notice Total points distributed by the contract
    uint256 public totalPoints;

    /// @notice Points to be distributed per epoch
    uint256 public pointsPerEpoch;

    /// @notice Structure to hold user-specific information
    struct UserInfo {
        /// @notice Amount of tokens staked by the user
        uint256 stakedAmount;
        /// @notice Points accumulated and pending for the user
        uint256 pendingPoints;
        /// @notice Last recorded points per token for the user
        uint256 lastPointsPerToken;
    }

    /// @notice Mapping of user addresses to their information
    mapping(address => UserInfo) public users;

    /// @notice Constant
    uint256 public constant PRECISION_18 = 1e18;

    /**
     * @notice Emitted when a user stakes tokens.
     * @param user The address of the user staking tokens.
     * @param amount The amount of tokens staked.
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when a user unstakes tokens.
     * @param user The address of the user unstaking tokens.
     * @param amount The amount of tokens unstaked.
     */
    event Unstaked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when points are distributed to stakers.
     * @param points The total number of points distributed.
     * @param pointsPerToken The amount of points distributed per token staked.
     */
    event PointsDistributed(uint256 points, uint256 pointsPerToken);

    /**
     * @notice Emitted when a user claims their accumulated points.
     * @param user The address of the user claiming points.
     * @param amount The amount of points claimed.
     */
    event PointsClaimed(address indexed user, uint256 amount);

    /**
     * @dev Sets the staking contract address and initializes the ERC20 token.
     */
    constructor() ERC20("BjordBoint", "BJB") {
        owner = msg.sender;
        lastDistribution = block.timestamp;
        pointsPerEpoch = 100 ether;
    }

    /**
     * @dev Modifier to check if the caller is the owner of the contract.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert CallerDisallowed();
        _;
    }

    /**
     * @dev Modifier to check if the caller is the staking contract.
     */
    modifier onlyStaking() {
        if (msg.sender != staking) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @dev Modifier to update pending points for a user.
     * @param user The address of the user to update points for.
     */
    modifier updatePendingPoints(address user) {
        UserInfo storage userInfo = users[user];
        uint256 owed = userInfo.stakedAmount.mul(pointsPerToken.sub(userInfo.lastPointsPerToken))
            .div(PRECISION_18);
        userInfo.pendingPoints = userInfo.pendingPoints.add(owed);
        userInfo.lastPointsPerToken = pointsPerToken;
        _;
    }

    /**
     * @dev Modifier to check and distribute points.
     */
    modifier checkDistribution() {
        distributePoints();
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidAddress();
        owner = _newOwner;
    }

    /**
     * @notice Updates the staking contract.
     * @param _staking The address of the staking contract.
     */
    function setStakingContract(address _staking) external onlyOwner {
        if (_staking == address(0)) {
            revert InvalidAddress();
        }

        staking = _staking;
    }

    /**
     * @notice Updates the points distributed per epoch.
     * @param _points The amount of points to be distributed per epoch.
     */
    function setPointsPerEpoch(uint256 _points) external onlyOwner checkDistribution {
        if (_points == 0) {
            revert();
        }

        pointsPerEpoch = _points;
    }

    /**
     * @notice Records the amount of tokens staked by a user.
     * @param user The address of the user staking tokens.
     * @param amount The amount of tokens being staked.
     */
    function onStaked(address user, uint256 amount)
        external
        onlyStaking
        checkDistribution
        updatePendingPoints(user)
    {
        UserInfo storage userInfo = users[user];
        userInfo.stakedAmount = userInfo.stakedAmount.add(amount);
        totalStaked = totalStaked.add(amount);
        emit Staked(user, amount);
    }

    /**
     * @notice Records the amount of tokens unstaked by a user.
     * @param user The address of the user unstaking tokens.
     * @param amount The amount of tokens being unstaked.
     */
    function onUnstaked(address user, uint256 amount)
        external
        onlyStaking
        checkDistribution
        updatePendingPoints(user)
    {
        UserInfo storage userInfo = users[user];
        if (amount > userInfo.stakedAmount) {
            revert UnstakingAmountExceedsStakedAmount();
        }
        userInfo.stakedAmount = userInfo.stakedAmount.sub(amount);
        totalStaked = totalStaked.sub(amount);
        emit Unstaked(user, amount);
    }

    /**
     * @notice Distributes points based on the locked amounts in the staking contract.
     */
    function distributePoints() public {
        if (block.timestamp < lastDistribution + EPOCH_DURATION) {
            return;
        }

        if (totalStaked == 0) {
            return;
        }

        uint256 weeksPending = (block.timestamp - lastDistribution) / EPOCH_DURATION;
        pointsPerToken =
            pointsPerToken.add(weeksPending * (pointsPerEpoch.mul(PRECISION_18).div(totalStaked)));
        totalPoints = totalPoints.add(pointsPerEpoch * weeksPending);
        lastDistribution = lastDistribution + (weeksPending * 1 weeks);

        emit PointsDistributed(pointsPerEpoch, pointsPerToken);
    }

    /**
     * @notice Allows users to claim their accumulated points.
     */
    function claimPoints() external checkDistribution updatePendingPoints(msg.sender) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 pointsToClaim = userInfo.pendingPoints;
        if (pointsToClaim > 0) {
            userInfo.pendingPoints = 0;
            _mint(msg.sender, pointsToClaim);
            emit PointsClaimed(msg.sender, pointsToClaim);
        }
    }
}
