// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Jcol__InvalidAmount();
error Jcol__InsufficientBalance();
error Jcol__InsufficientAllowance();
error Jcol__InvalidAddress();

contract Jcol is ERC20, Ownable {
    constructor() ERC20("JCOLLATERAL", "JCOL") Ownable(msg.sender) {}

    function mintTo(address to, uint256 amount) external onlyOwner returns (bool) {
        if (to == address(0)) {
            revert Jcol__InvalidAddress();
        }
        if (amount == 0) {
            revert Jcol__InvalidAmount();
        }
        _mint(to, amount);
        return true;
    }
}
