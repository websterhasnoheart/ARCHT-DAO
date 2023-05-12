// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ARCHT is ERC20, AccessControl {

    // =========================================================================
    //                               Storage
    // =========================================================================

    uint256 public nextIncreaseTimestamp;
    mapping (address => uint256) public pendingWithdrawals;
    mapping (address => mapping (address => uint256)) public deposits;
    uint256 public monthlyTransactionCount;
    uint256 public lastMonthTransactionCount;

    
    // =========================================================================
    //                               Roles
    // =========================================================================
    bytes32 public ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // =========================================================================
    //                               Constructor
    // =========================================================================

    constructor() ERC20("ArchtDAO", "ARCHT") {
        _mint(msg.sender, 1000 * (10 ** uint256(decimals())));
        nextIncreaseTimestamp = block.timestamp + 30 days;
    }


    // =========================================================================
    //                               Functions
    // =========================================================================
    function increaseSupply() external onlyRole(ADMIN_ROLE) {
        require(block.timestamp >= nextIncreaseTimestamp, "Increase not allowed yet");
        
        if (monthlyTransactionCount > lastMonthTransactionCount) {
            uint256 increaseFactor = monthlyTransactionCount - lastMonthTransactionCount;
            uint256 increase_amount = increaseFactor * 100 * (10 ** uint256(decimals())); 
            if (increase_amount <= totalSupply() * 3 / 2) {
                increase_amount = totalSupply() * 3 / 2;
            }
            _mint(msg.sender, increase_amount);
        }
        lastMonthTransactionCount = monthlyTransactionCount;
        monthlyTransactionCount = 0;
        nextIncreaseTimestamp = block.timestamp + 30 days;    
        }

    function batchTransfer(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Mismatched inputs");

        for (uint256 i = 0; i < recipients.length; i++) {
            transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    function depositTokens(address recipient, uint256 amount) external {
        transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender][recipient] += amount;
    }

    function requestPayment(address payer) external {
        uint256 amount = deposits[payer][msg.sender];
        require(amount > 0, "No tokens to request");

        pendingWithdrawals[msg.sender] += amount;
        deposits[payer][msg.sender] = 0;
    }

    function confirmPayment(address payee) external {
        uint256 amount = pendingWithdrawals[payee];
        require(amount > 0, "No tokens to confirm");

        pendingWithdrawals[payee] = 0;
        transferFrom(address(this), payee, amount);
        monthlyTransactionCount++;
    }
    
    function burn(address from, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(from, amount);
    }
}
