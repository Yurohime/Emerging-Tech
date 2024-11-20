// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingApplication {
    address public admin;
    
    // The Election Phase
    enum ElectionPhase 
    { 
        NotStarted, 
        Open, 
        Closed 
    }
    ElectionPhase public electionPhase;

    // Candidate structure
    struct Candidate 
    {
        string name;
        uint id;
        uint voteCount;
    }

    // Voter structure
    struct Voter 
    {
        bool authorized;
        bool hasVoted;
        uint candidateId;
    }

    // Mappings to store candidates and voters
    mapping(uint => Candidate) public candidates;
    mapping(address => Voter) public voters;

    // Candidate count for unique candidate IDs
    uint public candidateCount;
    
    // Events for tracking actions
    event CandidateAdded(string name, uint id);
    event VoterAdded(address voter);
    event VoteCast(address voter, uint candidateId);
    event VotingOpened();
    event VotingClosed();

    // Modifier to restrict access to only the admin
    modifier onlyAdmin() 
    {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Modifier to ensure the caller is an authorized voter
    modifier onlyVoter() 
    {
        require(voters[msg.sender].authorized, "You are not authorized to vote");
        _;
    }

    // Modifier to restrict voting to the open phase
    modifier onlyDuringVoting() 
    {
        require(electionPhase == ElectionPhase.Open, "Voting is not open");
        _;
    }

    // Modifier to ensure voters can only vote once
    modifier onlyOnce() 
    {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }

    // Constructor to set the admin
    constructor() 
    {
        admin = msg.sender;
        electionPhase = ElectionPhase.NotStarted;
    }

    // Function to add a candidate, only admin can call
    function addCandidate(string memory _name) public onlyAdmin 
    {
        require(electionPhase == ElectionPhase.NotStarted, "Cannot add candidates after voting has started");
        
        candidates[candidateCount] = Candidate(_name, candidateCount, 0);
        emit CandidateAdded(_name, candidateCount);
        candidateCount++;
    }

    // Function to add a voter, only admin can call
    function addVoter(address _voter) public onlyAdmin 
    {
        require(electionPhase == ElectionPhase.NotStarted, "Cannot add voters after voting has started");
        
        voters[_voter].authorized = true;
        emit VoterAdded(_voter);
    }

    // Function to open voting, only admin can call
    function openVoting() public onlyAdmin 
    {
        require(candidateCount > 0, "No candidates to vote for");
        require(electionPhase == ElectionPhase.NotStarted, "Election already started or ended");
        
        electionPhase = ElectionPhase.Open;
        emit VotingOpened();
    }

    // Function to close voting, only admin can call
    function closeVoting() public onlyAdmin 
    {
        require(electionPhase == ElectionPhase.Open, "Voting is not open");
        
        electionPhase = ElectionPhase.Closed;
        emit VotingClosed();
    }

    // Function for an authorized voter to cast a vote
    function vote(uint _candidateId) public onlyVoter onlyDuringVoting onlyOnce 
    {
        require(_candidateId < candidateCount, "Invalid candidate ID");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].candidateId = _candidateId;
        candidates[_candidateId].voteCount++;
        
        emit VoteCast(msg.sender, _candidateId);
    }

    // View function to get the vote count of a candidate
    function getCandidateVotes(uint _candidateId) public view returns (uint) 
    {
        require(_candidateId < candidateCount, "Invalid candidate ID");
        
        return candidates[_candidateId].voteCount;
    }

    // View function to get the current election status
    function getElectionStatus() public view returns (string memory) 
    {
        if (electionPhase == ElectionPhase.NotStarted) return "Not Started";
        if (electionPhase == ElectionPhase.Open) return "Open";
        if (electionPhase == ElectionPhase.Closed) return "Closed";
        return "Unknown";
    }
}
