
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ScholarshipStaking {
    address public owner;
    uint256 public totalStaked;
    uint256 public rewardRate; // Percentage rate for rewards (e.g., 5 for 5%)
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function stake() external payable {
        require(msg.value > 0, "Stake amount must be greater than zero");

        // If user has an existing stake, calculate and store the pending reward
        if (stakes[msg.sender].amount > 0) {
            rewards[msg.sender] += calculateReward(msg.sender);
        }

        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].timestamp = block.timestamp;
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 _amount) external {
        require(stakes[msg.sender].amount >= _amount, "Insufficient stake");

        // Calculate and store the pending reward
        rewards[msg.sender] += calculateReward(msg.sender);

        stakes[msg.sender].amount -= _amount;
        totalStaked -= _amount;

        payable(msg.sender).transfer(_amount);

        emit Unstaked(msg.sender, _amount);
    }

    function claimReward() external {
        uint256 reward = rewards[msg.sender] + calculateReward(msg.sender);
        require(reward > 0, "No rewards available to claim");

        rewards[msg.sender] = 0;
        stakes[msg.sender].timestamp = block.timestamp;

        payable(msg.sender).transfer(reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _staker) internal view returns (uint256) {
        Stake memory stakeInfo = stakes[_staker];
        uint256 stakingDuration = block.timestamp - stakeInfo.timestamp;
        return (stakeInfo.amount * rewardRate * stakingDuration) / (100 * 365 days);
    }

    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance - totalStaked;
        require(balance > 0, "No available funds to withdraw");
        payable(owner).transfer(balance);
    }
}
