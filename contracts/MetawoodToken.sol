// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetawoodToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 200000000 * 10**18;
    IERC20 private _self;

    constructor() ERC20("Metawood Token", "MTWD") {
        _mint(msg.sender, MAX_SUPPLY);
        approve(address(this), MAX_SUPPLY);
        _self = IERC20(address(this));
    }

    function requestToken(address requestor, uint256 amount) external {
        approve(msg.sender, amount);
        _self.transferFrom(owner(), requestor, amount);
    }
}
