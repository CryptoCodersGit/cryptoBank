// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICryptoBank {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function withdrawBankFees(uint256 amount) external;

    function balanceOf(address user)
        external
        view
        returns (uint256);
}


