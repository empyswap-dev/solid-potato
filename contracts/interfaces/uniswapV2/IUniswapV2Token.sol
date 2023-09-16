// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IUniswapV2Token {
    function mint(address _to, uint256 _amount) external;

    function transfer(address _to, uint256 _amount) external;

    function balanceOf(address _user) external returns (uint256);
}
