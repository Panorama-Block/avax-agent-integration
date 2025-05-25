// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ICollateral} from "../interfaces/ICollateral.sol";
import {IDefaultCollateral} from "../interfaces/defaultCollateral/IDefaultCollateral.sol";

contract Staking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    IDefaultCollateral public collateralToken;
    
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 collateralIssued;
        uint256 collateralBalance;
    }
    
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public minStakingPeriod;
    uint256 public collateralRatio; 

    event Staked(address indexed user, uint256 amount, uint256 collateralMinted);
    event Unstaked(address indexed user, uint256 amount, uint256 collateralBurned);
    event CollateralIssued(address indexed user, uint256 amount);
    
    constructor(
        address _stakingToken,
        address _collateralToken,
        uint256 _minStakingPeriod,
        uint256 _collateralRatio
    ) {
        require(_stakingToken != address(0), "Invalid staking token");
        require(_collateralToken != address(0), "Invalid collateral token");
        require(_collateralRatio > 0 && _collateralRatio <= 10000, "Invalid collateral ratio");
        
        stakingToken = IERC20(_stakingToken);
        collateralToken = IDefaultCollateral(_collateralToken);
        minStakingPeriod = _minStakingPeriod;
        collateralRatio = _collateralRatio;
    }
    
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        require(stakes[msg.sender].amount == 0, "Already staking");
        
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        stakingToken.safeApprove(address(collateralToken), _amount);
        
        uint256 collateralMinted = collateralToken.deposit(msg.sender, _amount);
        
        // Update staking info
        stakes[msg.sender] = StakeInfo({
            amount: _amount,
            timestamp: block.timestamp,
            collateralIssued: 0,
            collateralBalance: collateralMinted
        });
        
        totalStaked += _amount;
        
        emit Staked(msg.sender, _amount, collateralMinted);
    }
    
    function unstake() external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        require(block.timestamp >= userStake.timestamp + minStakingPeriod, "Staking period not met");
        
        uint256 amount = userStake.amount;
        uint256 collateralBalance = userStake.collateralBalance;
        
        if (userStake.collateralIssued > 0) {
            require(
                collateralToken.issuerDebt(msg.sender) == 0,
                "Must repay collateral debt first"
            );
        }
        
        collateralToken.withdraw(msg.sender, collateralBalance);
        
        delete stakes[msg.sender];
        totalStaked -= amount;
        
        emit Unstaked(msg.sender, amount, collateralBalance);
    }
    
    function issueCollateral(uint256 _amount) external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");
        require(_amount <= userStake.collateralBalance, "Insufficient collateral balance");
        
        uint256 maxCollateral = (userStake.amount * collateralRatio) / 10000;
        require(_amount <= maxCollateral, "Amount exceeds collateral limit");
        
        userStake.collateralIssued += _amount;
        userStake.collateralBalance -= _amount;
        
        collateralToken.issueDebt(msg.sender, _amount);
        
        emit CollateralIssued(msg.sender, _amount);
    }
    
    function getStakeInfo(address _user) external view returns (
        uint256 amount,
        uint256 timestamp,
        uint256 collateralIssued,
        uint256 collateralBalance
    ) {
        StakeInfo memory userStake = stakes[_user];
        return (
            userStake.amount,
            userStake.timestamp,
            userStake.collateralIssued,
            userStake.collateralBalance
        );
    }
    
    function canUnstake(address _user) external view returns (bool) {
        StakeInfo memory userStake = stakes[_user];
        return userStake.amount > 0 && 
               block.timestamp >= userStake.timestamp + minStakingPeriod &&
               (userStake.collateralIssued == 0 || collateralToken.issuerDebt(_user) == 0);
    }
}
