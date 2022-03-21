// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MetawoodToken is ERC20 {

    uint256 public constant MAX_SUPPLY  = 1000000 * 10**18;

    constructor() ERC20("Metawood Token", "MTWD") {
        _mint(msg.sender, MAX_SUPPLY );
        approve(address(this), MAX_SUPPLY);
    }

    function requestToken(address requestor, uint256 amount) external {
        transfer(requestor, amount);
    }
}
