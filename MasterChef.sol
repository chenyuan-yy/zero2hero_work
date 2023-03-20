// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./NacyToken.sol";


contract MasterChef {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 nacyToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accNacyPerShare;
    }

    NacyToken public nacy;
    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock = 0;
    uint256 public nacyPerBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(NacyToken _nacy) {
        nacy = _nacy;
        nacyPerBlock = 100*1e18;

    }

    function add(IERC20 _nacyToken) public {
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(100);
        poolInfo.push(PoolInfo({
            nacyToken: _nacyToken,
            allocPoint: 100,
            lastRewardBlock: lastRewardBlock,
            accNacyPerShare: 0
        }));

    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNacyPerShare).div(1e12).sub(user.rewardDebt);
            nacy.transfer(msg.sender, pending);
        }
        pool.nacyToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accNacyPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNacyPerShare).div(1e12).sub(user.rewardDebt);
        nacy.transfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accNacyPerShare).div(1e12);
        pool.nacyToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);

    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 nacySupply = pool.nacyToken.balanceOf(address(this));
        if (nacySupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nacyReward =
            multiplier.mul(nacyPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        nacy.mint(address(this), nacyReward);
        pool.accNacyPerShare = pool.accNacyPerShare.add(nacyReward.mul(1e12).div(nacySupply));
        pool.lastRewardBlock = block.number;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns(uint256) {
        return _to.sub(_from);
    }
}
