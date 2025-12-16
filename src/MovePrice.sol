// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./JcolDEX.sol";

contract MovePrice {
    JcolDEX jcolDex;

    constructor(address _cornDex, address _cornToken) {
        jcolDex = JcolDEX(_cornDex);
        IERC20(_cornToken).approve(address(jcolDex), type(uint256).max);
    }

    function movePrice(int256 size) public {
        if (size > 0) {
            jcolDex.swap{value: uint256(size)}(uint256(size));
        } else {
            jcolDex.swap(uint256(-size));
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
