// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract DutchAuction {
    uint private constant DURATION = 7 days;

    IERC721 private immutable nft;
    uint private immutable tokenId;

    address payable public immutable seller;
    uint public immutable startPrice;
    uint public immutable startAt;
    uint public immutable endAt;
    uint public immutable discountRate;

    constructor(
        IERC721 _nft,
        uint _tokenId,
        uint _startPrice,
        uint _discountRate
    ) {
        require(_discountRate < 100, "discount rate must be less than 100");
        require(
            _startPrice >= _discountRate * DURATION,
            "start price must be greater than discount rate * duration"
        );
        nft = _nft;
        tokenId = _tokenId;
        seller = payable(msg.sender);
        startPrice = _startPrice;
        startAt = block.timestamp;
        endAt = block.timestamp + DURATION;
        discountRate = _discountRate;
    }

    function getPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - startAt;
        uint discount = timeElapsed * discountRate;
        return startPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < endAt, "auction has ended");
        uint price = getPrice();
        require(msg.value >= price, "insufficient amount");
        nft.transferFrom(address(this), msg.sender, tokenId);
        seller.transfer(msg.value);
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        selfdestruct(seller);
    }
}
