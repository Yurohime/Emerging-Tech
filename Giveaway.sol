// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Giveaway {
    // Struct to hold the giveaway coupon information
    struct Coupon {
        bool isClaimed;
        address winner;
    }

    // Owner of the contract (creator of the giveaway)
    address public owner;

    // Mapping to store the coupons and donation amounts
    mapping(address => uint) public donations; // Address -> Amount donated
    mapping(address => Coupon) public coupons;  // Address -> Coupon details

    // Total Ether pool for the giveaway
    uint public totalDonations;

    // Event declaration for donations
    event DonationReceived(address indexed donor, uint amount, uint totalPool);
    
    // Event declaration for giveaway winner assignment
    event GiveawayWinnerAssigned(address indexed winner, uint amount);
    
    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyWinner(address _winner) {
        require(coupons[_winner].winner == _winner, "You are not a winner");
        _;
    }

    // Constructor to initialize the contract with the owner
    constructor() {
        owner = msg.sender;
    }

    // Payable function to donate Ether and generate a coupon
    function donate() external payable {
        require(msg.value > 0, "Donation must be greater than 0");

        // Update donations and total pool
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;

        // Generate a coupon for the donor
        coupons[msg.sender] = Coupon({
            isClaimed: false,
            winner: address(0)
        });

        emit DonationReceived(msg.sender, msg.value, totalDonations);
    }

    // Only the owner can assign a giveaway winner
    function assignWinner(address _winner) external onlyOwner {
        require(donations[_winner] > 0, "Winner must have donated");
        require(!coupons[_winner].isClaimed, "Coupon already claimed");

        // Assign the winner's coupon
        coupons[_winner].winner = _winner;

        emit GiveawayWinnerAssigned(_winner, donations[_winner]);
    }

    // Winner can withdraw Ether based on their coupon
    function claimPrize() external onlyWinner(msg.sender) {
        require(!coupons[msg.sender].isClaimed, "Coupon already claimed");

        uint amount = donations[msg.sender];
        require(amount > 0, "No funds to claim");

        // Mark coupon as claimed
        coupons[msg.sender].isClaimed = true;

        // Transfer the donation (Ether) to the winner
        payable(msg.sender).transfer(amount);
    }

    // Public view function to get the balance of the contract
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }

    // Public view function to get the donation amount of a user
    function getDonationAmount(address _donor) external view returns (uint) {
        return donations[_donor];
    }

    // Public view function to check if a user has won
    function hasWon(address _donor) external view returns (bool) {
        return coupons[_donor].winner == _donor && !coupons[_donor].isClaimed;
    }
}