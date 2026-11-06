// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Ticker Royale staking: stake your project token, earn a fixed APR.
 * - Rewards are paid from tokens you (the owner) send to this contract.
 *   Anything above totalStaked is the reward pool.
 * - Deploy on Robinhood Chain testnet (chain 46630) with Remix:
 *   constructor(_token = your token address, _aprBps = 2000 for 20% APR)
 * - Fund it: send reward tokens straight to the contract address.
 */
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract TickerStaking {
    IERC20 public immutable token;
    address public owner;
    uint256 public aprBps;          // 2000 = 20% per year
    uint256 public totalStaked;

    struct Info {
        uint256 amount;
        uint256 rewards;            // rewards accrued but not yet claimed
        uint64  lastUpdate;
        uint64  since;              // when the current stake started
    }
    mapping(address => Info) public info;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event AprChanged(uint256 aprBps);

    modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }

    constructor(address _token, uint256 _aprBps) {
        require(_token != address(0), "token = 0");
        token = IERC20(_token);
        owner = msg.sender;
        aprBps = _aprBps;
    }

    // ---------- views ----------
    function pending(address user) public view returns (uint256) {
        Info memory i = info[user];
        if (i.amount == 0) return i.rewards;
        uint256 elapsed = block.timestamp - i.lastUpdate;
        return i.rewards + (i.amount * aprBps * elapsed) / (10000 * 365 days);
    }
    function stakedOf(address user) external view returns (uint256) { return info[user].amount; }
    function stakedSince(address user) external view returns (uint256) { return info[user].since; }
    function rewardPool() public view returns (uint256) {
        uint256 bal = token.balanceOf(address(this));
        return bal > totalStaked ? bal - totalStaked : 0;
    }

    // ---------- user actions ----------
    function stake(uint256 amount) external {
        require(amount > 0, "amount = 0");
        _update(msg.sender);
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        Info storage i = info[msg.sender];
        if (i.amount == 0) i.since = uint64(block.timestamp);
        i.amount += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        Info storage i = info[msg.sender];
        require(amount > 0 && amount <= i.amount, "bad amount");
        _update(msg.sender);
        i.amount -= amount;
        totalStaked -= amount;
        if (i.amount == 0) i.since = 0;
        require(token.transfer(msg.sender, amount), "transfer failed");
        emit Unstaked(msg.sender, amount);
    }

    function claim() external {
        _update(msg.sender);
        uint256 r = info[msg.sender].rewards;
        require(r > 0, "nothing to claim");
        require(r <= rewardPool(), "reward pool empty");
        info[msg.sender].rewards = 0;
        require(token.transfer(msg.sender, r), "transfer failed");
        emit Claimed(msg.sender, r);
    }

    // ---------- owner ----------
    function setApr(uint256 _aprBps) external onlyOwner {
        require(_aprBps <= 100000, "max 1000%");
        aprBps = _aprBps;
        emit AprChanged(_aprBps);
    }
    /// Take back unused reward tokens (never touches staked tokens).
    function withdrawPool(uint256 amount) external onlyOwner {
        require(amount <= rewardPool(), "more than pool");
        require(token.transfer(owner, amount), "transfer failed");
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "owner = 0");
        owner = newOwner;
    }

    function _update(address user) internal {
        info[user].rewards = pending(user);
        info[user].lastUpdate = uint64(block.timestamp);
    }
}
