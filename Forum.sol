// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Forum {
    address payable public owner;
    uint256 public totalFunds;

    enum PostStatus { Ok, Reported, Banned }

    struct Post {
        string content;
        uint256 upvotes;
        address originalPoster;
        PostStatus status;
        Comment[] comments;
    }

    struct Comment {
        string content;
        address commenter;
    }

    mapping(address => bool) public admins;
    mapping(address => bool) public investors;
    mapping(address => bool) public bannedUsers;
    mapping(address => uint256) public badges; // Track badges for each user
    Post[] public posts;
    address[] public adminAddresses;

    event PostCreated(uint256 postId, address indexed poster, string content);
    event UserBanned(address indexed user);
    event PostBanned(uint256 postId);
    event PostReported(uint256 postId, address indexed reporter);
    event BadgePurchased(address indexed user, uint256 totalBadges);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    modifier notBanned() {
        require(!bannedUsers[msg.sender], "You are banned");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // Owner-only actions
    function addAdmin(address _admin) external onlyOwner {
        require(!admins[_admin], "Already an admin");
        admins[_admin] = true;
        adminAddresses.push(_admin);
    }

    function removeAdmin(address _admin) external onlyOwner {
        require(admins[_admin], "Not an admin");
        admins[_admin] = false;

        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == _admin) {
                adminAddresses[i] = adminAddresses[adminAddresses.length - 1];
                adminAddresses.pop();
                break;
            }
        }
    }

    function checkAdminList() external view onlyOwner returns (address[] memory) {
    uint256 count = 0;

        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (admins[adminAddresses[i]]) {
                count++;
            }
        }

        address[] memory activeAdmins = new address[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (admins[adminAddresses[i]]) {
                activeAdmins[index] = adminAddresses[i];
                index++;
            }
        }

        return activeAdmins;
    }

    function addInvestor(address _investor) external onlyOwner {
        require(!investors[_investor], "Already an investor");
        investors[_investor] = true;
    }

    function removeInvestor(address _investor) external onlyOwner {
         require(investors[_investor], "Not an investor");
         investors[_investor] = false;
    }

    function transferFunds(address payable _to, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient funds");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    // Admin actions
    function checkReports() external view onlyAdmin returns (uint256[] memory) {
        uint256[] memory reportedPostIds = new uint256[](posts.length);
        uint256 count = 0;

        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].status == PostStatus.Reported) {
                reportedPostIds[count] = i;
                count++;
            }
        }

        uint256[] memory filteredReports = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredReports[i] = reportedPostIds[i];
        }

        return filteredReports;
    }

    function banUser(address _user) external onlyAdmin {
        bannedUsers[_user] = true;
        emit UserBanned(_user);
    }

    function unbanUser(address _user) external onlyAdmin {
        bannedUsers[_user] = false;
    }

    function banPost(uint256 _postId) external onlyAdmin {
        require(_postId < posts.length, "Invalid post ID");
        posts[_postId].status = PostStatus.Banned;
        emit PostBanned(_postId);
    }

    function unbanPost(uint256 _postId) external onlyAdmin {
        require(_postId < posts.length, "Invalid post ID");
        posts[_postId].status = PostStatus.Ok;
    }

    // Investor actions
    function invest() external payable {
        require(msg.value > 0, "Must send ETH to invest");
        totalFunds += msg.value;
        investors[msg.sender] = true;
    }

    // User actions
    function createPost(string memory _content) external notBanned {
        posts.push();
        Post storage newPost = posts[posts.length - 1];
        newPost.content = _content;
        newPost.upvotes = 0;
        newPost.originalPoster = msg.sender;
        newPost.status = PostStatus.Ok;
        emit PostCreated(posts.length - 1, msg.sender, _content);
    }

    function commentOnPost(uint256 _postId, string memory _content) external notBanned {
        require(_postId < posts.length, "Invalid post ID");
        require(bytes(_content).length <= 200, "Comment too long");
        require(posts[_postId].status == PostStatus.Ok, "Post not active");

        posts[_postId].comments.push(Comment({
            content: _content,
            commenter: msg.sender
        }));
    }

    function upvotePost(uint256 _postId) external {
        require(_postId < posts.length, "Invalid post ID");
        require(posts[_postId].status == PostStatus.Ok, "Post not active");
        posts[_postId].upvotes += 1;
    }

    function reportPost(uint256 _postId) external {
        require(_postId < posts.length, "Invalid post ID");
        posts[_postId].status = PostStatus.Reported;
        emit PostReported(_postId, msg.sender);
    }

    function buyBadge() external payable {
        require(msg.value > 0, "Must send ETH to buy a badge");
        badges[msg.sender] += 1;
        totalFunds += msg.value;
        emit BadgePurchased(msg.sender, badges[msg.sender]);
    }

    // View functions
    function viewPostDetail(uint256 _postId) external view returns (Post memory) {
        require(_postId < posts.length, "Invalid post ID");
        return posts[_postId];
    }

    function checkPostList() external view returns (Post[] memory) {
        return posts;
    }

    function searchPosts(string memory _query) external view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](posts.length);
        uint256 count = 0;

        for (uint256 i = 0; i < posts.length; i++) {
            if (posts[i].status == PostStatus.Banned) continue;
            if (keccak256(abi.encodePacked(posts[i].content)) == keccak256(abi.encodePacked(_query))) {
                results[count] = i;
                count++;
            }
        }

        uint256[] memory filteredResults = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredResults[i] = results[i];
        }
        return filteredResults;
    }

    function getPostCount() external view returns (uint256) {
        return posts.length;
    }
}