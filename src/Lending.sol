// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Jcol.sol";
import "./JcolDEX.sol";

error Lending__InvalidAmount();
error Lending__TransferFailed();
error Lending__UnsafePositionRatio();
error Lending__BorrowingFailed();
error Lending__RepayingFailed();
error Lending__PositionSafe();
error Lending__NotLiquidatable();
error Lending__InsufficientLiquidatorCorn();

contract Lending is Ownable {
    uint256 private constant COLLATERAL_RATIO = 120;
    uint256 private constant LIQUIDATOR_REWARD = 10;

    Jcol private i_jcol;
    JcolDEX private i_jcolDEX;

    mapping(address => uint256) public s_userCollateral;
    mapping(address => uint256) public s_userBorrowed;

    event CollateralAdded(address indexed user, uint256 indexed amount, uint256 price);
    event CollateralWithdrawn(address indexed user, uint256 indexed amount, uint256 price);
    event AssetBorrowed(address indexed user, uint256 indexed amount, uint256 price);
    event AssetRepaid(address indexed user, uint256 indexed amount, uint256 price);
    event Liquidation(
        address indexed user,
        address indexed liquidator,
        uint256 amountForLiquidator,
        uint256 liquidatedUserDebt,
        uint256 price
    );

    constructor(address _cornDEX, address _corn) Ownable(msg.sender) {
        i_jcolDEX = JcolDEX(_cornDEX);
        i_jcol = Jcol(_corn);
        i_jcol.approve(address(this), type(uint256).max);
    }

    function addCollateral() public payable {
        if (msg.value == 0) {
            revert Lending__InvalidAmount();
        }

        s_userCollateral[msg.sender] += msg.value;

        emit CollateralAdded(msg.sender, msg.value, i_jcolDEX.currentPrice());
    }

    function withdrawCollateral(uint256 amount) public {
        if (amount == 0 || s_userCollateral[msg.sender] < amount) {
            revert Lending__InvalidAmount();
        }

        s_userCollateral[msg.sender] -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert Lending__TransferFailed();
        }

        emit CollateralWithdrawn(msg.sender, amount, i_jcolDEX.currentPrice());
    }

    function calculateCollateralValue(address user) public view returns (uint256) {
        uint256 userCollateral = s_userCollateral[user];
        return (i_jcolDEX.currentPrice() * userCollateral) / 1e18;
    }

    function _calculatePositionRatio(address user) internal view returns (uint256) {
        uint256 userCollateralValue = calculateCollateralValue(user);
        uint256 userBorrowed = s_userBorrowed[user];

        if (userBorrowed == 0) return type(uint256).max;

        return (userCollateralValue * 1e18) / userBorrowed;
    }

    function isLiquidatable(address user) public view returns (bool) {
        uint256 userRatio = _calculatePositionRatio(user);
        return (userRatio * 100) < COLLATERAL_RATIO * 1e18;
    }

    function _validatePosition(address user) internal view {
        if (isLiquidatable(user)) {
            revert Lending__UnsafePositionRatio();
        }
    }

    function borrowCorn(uint256 borrowAmount) public {
        if (borrowAmount == 0) {
            revert Lending__InvalidAmount();
        }

        s_userBorrowed[msg.sender] += borrowAmount;

        _validatePosition(msg.sender);

        bool success = i_jcol.transfer(msg.sender, borrowAmount);
        if (!success) {
            revert Lending__BorrowingFailed();
        }

        emit AssetBorrowed(msg.sender, borrowAmount, i_jcolDEX.currentPrice());
    }

    function repayCorn(uint256 repayAmount) public {
        if (repayAmount == 0) {
            revert Lending__InvalidAmount();
        }

        s_userBorrowed[msg.sender] -= repayAmount;

        bool success = i_jcol.transferFrom(msg.sender, address(this), repayAmount);
        if (!success) {
            revert Lending__RepayingFailed();
        }

        emit AssetRepaid(msg.sender, repayAmount, i_jcolDEX.currentPrice());
    }

    function liquidate(address user) public {
        if (!isLiquidatable(user)) {
            revert Lending__NotLiquidatable();
        }

        uint256 userBorrowed = s_userBorrowed[user];
        uint256 liquidatorAmount = i_jcol.balanceOf(msg.sender);
        uint256 userCollateral = s_userCollateral[user];
        uint256 collateralValue = calculateCollateralValue(user);

        if (liquidatorAmount < userBorrowed) {
            revert Lending__InsufficientLiquidatorCorn();
        }

        i_jcol.transferFrom(msg.sender, address(this), userBorrowed);

        s_userBorrowed[user] = 0;

        uint256 collateralPurchased = (userBorrowed * userCollateral) / collateralValue;
        uint256 liquidatorReward = (collateralPurchased * LIQUIDATOR_REWARD) / 100;
        uint256 amountForLiquidator = collateralPurchased + liquidatorReward;
        amountForLiquidator = amountForLiquidator > userCollateral ? userCollateral : amountForLiquidator;
        s_userCollateral[user] = userCollateral - amountForLiquidator;

        (bool success,) = payable(msg.sender).call{value: amountForLiquidator}("");
        if (!success) {
            revert Lending__TransferFailed();
        }

        emit Liquidation(user, msg.sender, amountForLiquidator, userBorrowed, i_jcolDEX.currentPrice());
    }
}
