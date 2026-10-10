// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ICryptoBank.sol";
import "./BankBase.sol";

contract CryptoBank is ICryptoBank, BankBase {

    // =========================================
    // State Variables
    // =========================================

    string public bankName;

    // Total ETH deposited by users BEFORE the 2% fee
    uint256 public totalBankDeposits;

    // Total ETH withdrawn by users
    uint256 public totalWithdrawals;

    // 2% fees accumulated for the bank owner
    uint256 public bankFees;


    // =========================================
    // Enum
    // =========================================

    enum BankStatus {
        Active,
        Paused,
        Closed
    }

    BankStatus public status = BankStatus.Active;


    // =========================================
    // Struct
    // =========================================

    struct Deposit {
        uint256 amount;
        uint256 fee;
        uint256 netAmount;
        uint256 timestamp;
    }


    // =========================================
    // Mappings
    // =========================================

    mapping(address => uint256)
        public balances;

    mapping(address => Deposit[])
        private depositHistory;


    // =========================================
    // Errors
    // =========================================

    error BankIsPaused();
    error BankIsClosed();
    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();


    // =========================================
    // Events
    // =========================================

    event Deposited(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 netAmount
    );

    event Withdrawn(
        address indexed user,
        uint256 amount
    );

    event BankFeeWithdrawn(
        uint256 amount
    );

    event BankStatusChanged(
        BankStatus newStatus
    );




    // =========================================
    // Modifiers
    // =========================================

    modifier whenActive() {
        if (status == BankStatus.Paused) {
            revert BankIsPaused();
        }

        if (status == BankStatus.Closed) {
            revert BankIsClosed();
        }

        _;
    }


    // =========================================
    // Constructor
    // =========================================

    constructor(string memory _bankName) {
        bankName = _bankName;
    }


    // =========================================
    // Calculate 2% Fee
    // =========================================

    function calculateFee(uint256 amount)
        public
        pure
        returns (uint256 )
    {
        return (amount * 2) / 100;
    }


    // =========================================
    // Internal addFound Function
    // =========================================

    function _addFound(
        address user,
        uint256 amount
    )
        internal
    {
        uint256 fee = calculateFee(amount);

        uint256 netAmount = amount - fee;

        balances[user] += netAmount;

        bankFees += fee;

        depositHistory[user].push(
            Deposit({
                amount: amount,
                fee: fee,
                netAmount: netAmount,
                timestamp: block.timestamp
            })
        );

        totalBankDeposits += amount;

        emit Deposited(
            user,
            amount,
            fee,
            netAmount
        );
    }


    // =========================================
    // Deposit
    // =========================================

    function deposit()
        external
        payable
        override
        whenActive
    {
        if (msg.value == 0) {
            revert ZeroAmount();
        }

        _addFound(
            msg.sender,
            msg.value
        );
    }


    // =========================================
    // Balance Of
    // =========================================

    function balanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return balances[user];
    }


    // =========================================
    // My Balance
    // =========================================

    function myBalance()
        external
        view
        returns (uint256)
    {
        return balances[msg.sender];
    }


    // =========================================
    // Withdraw User Funds
    // Checks → Effects → Interactions

    // CHECKS
    //  ↓
    // بررسی موجودی

    // EFFECTS
    //  ↓
    // کاهش موجودی

    // INTERACTION
    //  ↓
    // ارسال ETH

    // =========================================

    function withdraw(uint256 amount)
        external
        override
        whenActive
    {
        if (amount == 0) {
            revert ZeroAmount();
        }

        if (balances[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        // Effects
        balances[msg.sender] -= amount;
        totalWithdrawals += amount;

        // Interaction
        (bool success, ) = payable(msg.sender).call{
            value: amount
        }("");

        if (!success) {
            revert TransferFailed();
        }

        emit Withdrawn(
            msg.sender,
            amount
        );
    }


    // =========================================
    // Withdraw Bank Fees
    // Only Owner
    // =========================================

    function withdrawBankFees(uint256 amount)
        external
        override
        onlyOwner
    {
        if (amount == 0) {
            revert ZeroAmount();
        }

        if (bankFees < amount) {
            revert InsufficientBalance();
        }

        bankFees -= amount;

        (bool success, ) = payable(owner).call{
            value: amount
        }("");

        if (!success) {
            revert TransferFailed();
        }

        emit BankFeeWithdrawn(
            amount
        );
    }


    // =========================================
    // Deposit Count
    // =========================================

    function getDepositCount(address user)
        external
        view
        returns (uint256)
    {
        return depositHistory[user].length;
    }


    // =========================================
    // Total Deposited By User
    // =========================================

    function getTotalDeposited(address user)
        external
        view
        returns (uint256 total)
    {
        for (
            uint256 i = 0;
            i < depositHistory[user].length;
            i++
        ) {
            total += depositHistory[user][i].netAmount;
        }
    }


    // =========================================
    // Get Deposit Details
    // =========================================

    function getDeposit(
        address user,
        uint256 index
    )
        external
        view
        returns (
            uint256 amount,
            uint256 bankFee,
            uint256 netAmount,
            uint256 timestamp
        )
    {
        Deposit memory userDeposit =
            depositHistory[user][index];

        return (
            userDeposit.amount,
            userDeposit.fee,
            userDeposit.netAmount,
            userDeposit.timestamp
        );
    }


    // =========================================
    // Change Bank Status
    // =========================================

    function setBankStatus(
        BankStatus newStatus
    )
        external
        onlyOwner
    {
        status = newStatus;

        emit BankStatusChanged(
            newStatus
        );
    }


    // =========================================
    // Receive ETH
    // =========================================

    receive()
        external
        payable
    {
        if (msg.value == 0) {
            revert ZeroAmount();
        }

        _addFound(
            msg.sender,
            msg.value
        );
    }


    // =========================================
    // Fallback
    // =========================================

    fallback()
        external
        payable
    {
    }
}