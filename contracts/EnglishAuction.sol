// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract EnglishAuction {
    event Start(address indexed seller, uint256 indexed tokenId);
    event Bid(address indexed bidder, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address indexed winner, uint256 amount);

    IERC721 public immutable nftContract;
    uint public immutable tokenId;

    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    uint public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    constructor(
        address _nftContract,
        uint _tokenId,
        uint32 _startingBid
    ) {
        nftContract = IERC721(_nftContract);
        tokenId = _tokenId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(msg.sender == seller, "Only seller can start the auction");
        require(!started, "Auction already started");
        started = true;
        endAt = uint32(block.timestamp) + 1 days;
        nftContract.transferFrom(seller, address(this), tokenId);
        emit Start(seller, tokenId);
    }

    function bid() external payable {
        require(started, "Auction not started");
        require(block.timestamp < endAt, "Auction ended");
        require(msg.value > highestBid, "Bid too low");
        bids[msg.sender] += msg.value;
        if (highestBidder != address(0)) {
            payable(highestBidder).transfer(highestBid);
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        require(ended != 0, "Auction not ended");
        require(
            msg.sender == seller || msg.sender == highestBidder,
            "Only seller or highest bidder can withdraw"
        );
        uint amount = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function end() external {
        require(started, "Auction not started");
        require(block.timestamp >= endAt, "Auction not ended");
        require(ended == 0, "Auction already ended");
        ended = block.timestamp;
        if (highestBidder != address(0)) {
            nftContract.transferFrom(address(this), highestBidder, tokenId);
            seller.transfer(highestBid);
        } else {
            nftContract.transferFrom(address(this), seller, tokenId);
        }
        emit End(highestBidder, highestBid);
    }
}
