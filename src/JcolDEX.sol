// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JcolDEX {
    IERC20 token;
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    event Swap(address swapper, address inputToken, uint256 inputAmount, address outputToken, uint256 outputAmount);
    event PriceUpdated(uint256 price);
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);

    event LiquidityRemoved(
        address liquidityRemover, uint256 liquidityWithdrawn, uint256 tokensOutput, uint256 ethOutput
    );

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr);
    }

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: init - already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init - transfer did not transact");
        return totalLiquidity;
    }

    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 numerator = xInput * yReserves;
        uint256 denominator = (xReserves) + xInput;
        return (numerator / denominator);
    }

    function currentPrice() public view returns (uint256 _currentPrice) {
        _currentPrice = price(1 ether, address(this).balance, token.balanceOf(address(this)));
    }

    function calculateXInput(uint256 yOutput, uint256 xReserves, uint256 yReserves)
        public
        pure
        returns (uint256 xInput)
    {
        uint256 numerator = yOutput * xReserves;
        uint256 denominator = yReserves - yOutput;

        return (numerator / denominator) + 1;
    }

    function ethToToken() internal returns (uint256 tokenOutput) {
        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap.");
        emit Swap(msg.sender, address(0), msg.value, address(token), tokenOutput);
        return tokenOutput;
    }

    function tokenToEth(uint256 tokenInput) internal returns (uint256 ethOutput) {
        require(tokenInput > 0, "cannot swap 0 tokens");
        require(token.balanceOf(msg.sender) >= tokenInput, "insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= tokenInput, "insufficient allowance");
        uint256 tokenReserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap.");
        (bool sent,) = msg.sender.call{value: ethOutput}("");
        require(sent, "tokenToEth: revert in transferring eth to you!");
        emit Swap(msg.sender, address(token), tokenInput, address(0), ethOutput);
        return ethOutput;
    }

    function swap(uint256 inputAmount) public payable returns (uint256 outputAmount) {
        if (msg.value > 0 && inputAmount == msg.value) {
            outputAmount = ethToToken();
        } else {
            outputAmount = tokenToEth(inputAmount);
        }
        emit PriceUpdated(currentPrice());
    }

    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "Must send value when depositing");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit;

        tokenDeposit = ((msg.value * tokenReserve) / ethReserve) + 1;

        require(token.balanceOf(msg.sender) >= tokenDeposit, "insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= tokenDeposit, "insufficient allowance");

        uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
        return tokenDeposit;
    }

    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "withdraw: sender does not have enough liquidity to withdraw.");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethWithdrawn;

        ethWithdrawn = (amount * ethReserve) / totalLiquidity;

        tokenAmount = (amount * tokenReserve) / totalLiquidity;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        (bool sent,) = payable(msg.sender).call{value: ethWithdrawn}("");
        require(sent, "withdraw(): revert in transferring eth to you!");
        require(token.transfer(msg.sender, tokenAmount));
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethWithdrawn);
        return (ethWithdrawn, tokenAmount);
    }
}
