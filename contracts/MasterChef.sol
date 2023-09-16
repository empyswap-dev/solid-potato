//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Token} from "./interfaces/uniswapV2/IUniswapV2Token.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of UniswapV2Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accUniswapV2TokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accUniswapV2TokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. UniswapV2Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that UniswapV2Tokens distribution occurs.
        uint256 accUniswapV2TokenPerShare; // Accumulated UniswapV2Tokens per share, times 1e12. See below.
    }
    // The UniswapV2Token TOKEN!
    IUniswapV2Token public rewardsToken;
    // UniswapV2Token tokens created per block.
    uint256 public rewardsPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when UniswapV2Token mining starts.
    uint256 public startBlock;
    uint256 public endBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        address _rewardsToken,
        uint256 _rewardsPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) {
        rewardsToken = IUniswapV2Token(_rewardsToken);
        rewardsPerBlock = _rewardsPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accUniswapV2TokenPerShare: 0
            })
        );
    }

    // Update the given pool's UniswapV2Token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to.sub(_from);
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock.sub(_from);
        }
    }

    function pendingRewards(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accUniswapV2TokenPerShare = pool.accUniswapV2TokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (
            block.number > pool.lastRewardBlock &&
            pool.lastRewardBlock < endBlock &&
            lpSupply != 0
        ) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 uniswapV2TokenReward = multiplier
                .mul(rewardsPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accUniswapV2TokenPerShare = accUniswapV2TokenPerShare.add(
                uniswapV2TokenReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accUniswapV2TokenPerShare).div(1e12).sub(
                user.rewardDebt
            );
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if ((block.number > endBlock) && (pool.lastRewardBlock > endBlock)) {
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 uniswapV2TokenReward = multiplier
            .mul(rewardsPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        rewardsToken.mint(address(this), uniswapV2TokenReward);
        pool.accUniswapV2TokenPerShare = pool.accUniswapV2TokenPerShare.add(
            uniswapV2TokenReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for UniswapV2Token allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accUniswapV2TokenPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeUniswapV2TokenTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accUniswapV2TokenPerShare).div(
            1e12
        );
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user
            .amount
            .mul(pool.accUniswapV2TokenPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        safeUniswapV2TokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accUniswapV2TokenPerShare).div(
            1e12
        );
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe UniswapV2Token transfer function, just in case if rounding error causes pool to not have enough UniswapV2Tokens.
    function safeUniswapV2TokenTransfer(address _to, uint256 _amount) internal {
        uint256 uniswapV2TokenBal = rewardsToken.balanceOf(address(this));

        if (_amount > uniswapV2TokenBal) {
            rewardsToken.transfer(_to, uniswapV2TokenBal);
        } else {
            rewardsToken.transfer(_to, _amount);
        }
    }
}
