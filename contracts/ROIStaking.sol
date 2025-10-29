// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ROIStaking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable stakeToken;

    uint256 public constant ROI_PERCENT = 100; // 1% (100 basis points)
    uint256 public constant REFERRAL_PERCENT = 50; // 0.5% (50 basis points)
    uint256 public constant PERCENT_DIVIDER = 10000;
    uint256 public constant CLAIM_COOLDOWN = 1 days;

    struct User {
        uint256 amountStaked;
        uint256 lastClaim;
        address referrer;
        uint256 totalClaimed;
        uint256 totalReferred;
    }

    mapping(address => User) public users;

    event Staked(address indexed user, uint256 amount, address indexed referrer);
    event Claimed(address indexed user, uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event ReferralReward(address indexed referrer, address indexed user, uint256 reward);

    constructor(IERC20 _stakeToken) {
        stakeToken = _stakeToken;
    }

    function stake(uint256 amount, address referrer) external nonReentrant {
        require(amount > 0, "Amount must be > 0");

        User storage user = users[msg.sender];
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        // Set referrer if first time
        if (user.referrer == address(0) && referrer != msg.sender && users[referrer].amountStaked > 0) {
            user.referrer = referrer;
        }

        // Pay referral instantly
        if (user.referrer != address(0)) {
            uint256 refReward = (amount * REFERRAL_PERCENT) / PERCENT_DIVIDER;
            stakeToken.safeTransfer(user.referrer, refReward);
            users[user.referrer].totalReferred += refReward;
            emit ReferralReward(user.referrer, msg.sender, refReward);
        }

        user.amountStaked += amount;
        if (user.lastClaim == 0) user.lastClaim = block.timestamp;

        emit Staked(msg.sender, amount, user.referrer);
    }

    function pendingROI(address account) public view returns (uint256) {
        User storage user = users[account];
        if (user.amountStaked == 0) return 0;
        if (block.timestamp < user.lastClaim + CLAIM_COOLDOWN) return 0;
        return (user.amountStaked * ROI_PERCENT) / PERCENT_DIVIDER;
    }

    function claimROI() external nonReentrant {
        User storage user = users[msg.sender];
        require(user.amountStaked > 0, "No stake");
        require(block.timestamp >= user.lastClaim + CLAIM_COOLDOWN, "Wait 24h");

        uint256 reward = pendingROI(msg.sender);
        require(reward > 0, "No ROI yet");
        require(stakeToken.balanceOf(address(this)) >= reward, "Insufficient balance");

        user.lastClaim = block.timestamp;
        user.totalClaimed += reward;

        stakeToken.safeTransfer(msg.sender, reward);
        emit Claimed(msg.sender, reward);
    }

    function _claimROIInternal(address userAddress) internal {
        User storage user = users[userAddress];
        if (user.amountStaked == 0) return;
        if (block.timestamp < user.lastClaim + CLAIM_COOLDOWN) return;

        uint256 reward = (user.amountStaked * ROI_PERCENT) / PERCENT_DIVIDER;
        if (reward == 0) return;
        
        uint256 contractBalance = stakeToken.balanceOf(address(this));
        if (contractBalance < reward) {
            reward = contractBalance; // Pay what's available
            if (reward == 0) return;
        }

        user.lastClaim = block.timestamp;
        user.totalClaimed += reward;

        stakeToken.safeTransfer(userAddress, reward);
        emit Claimed(userAddress, reward);
    }

    function withdraw(uint256 amount) external nonReentrant {
        User storage user = users[msg.sender];
        require(amount > 0 && amount <= user.amountStaked, "Invalid amount");
        require(stakeToken.balanceOf(address(this)) >= amount, "Insufficient balance");

        // Harvest ROI if available
        _claimROIInternal(msg.sender);

        user.amountStaked -= amount;
        stakeToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    // --- View helpers ---
    function userInfo(address account)
        external
        view
        returns (
            uint256 staked,
            uint256 pending,
            uint256 lastClaim,
            address referrer,
            uint256 totalClaimed,
            uint256 totalReferred
        )
    {
        User storage u = users[account];
        return (
            u.amountStaked,
            pendingROI(account),
            u.lastClaim,
            u.referrer,
            u.totalClaimed,
            u.totalReferred
        );
    }
}