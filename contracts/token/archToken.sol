// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARCHT is ERC20, Ownable {



    // =========================================================================
    //                               Storage
    // =========================================================================

    uint256 public nextIncreaseTimestamp;
    mapping (address => uint256) public pendingWithdrawals;
    mapping (address => mapping (address => uint256)) public deposits;
    
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
    function increaseSupply(uint256 amount) external onlyOwner {
        require(block.timestamp >= nextIncreaseTimestamp, "Increase not allowed yet");
        require(amount <= totalSupply() * 3 / 2, "Increase too large");

        _mint(owner(), amount);
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
    }
    
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
