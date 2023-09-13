// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract auction{

// declaring state variables
    address manager;
    uint deployTime;
    uint initialPrice;
     struct bidder{
        address bidderAddress;
        uint bidAmount;
    }
    struct productDetail{
        string description;
        uint price;
    }
    productDetail internal product;
    bidder private largestBidder;
    mapping(address=>uint) biddingOf;
    address[] allBidders;

// constructor and default values
    constructor(string memory _productDetails,uint _productPrice){
        manager=msg.sender;
        deployTime=block.timestamp;
        product.description=_productDetails;
        product.price=_productPrice;
        largestBidder.bidderAddress=address(0);
        largestBidder.bidAmount=0;
    }

// events declaration
    event bidMade(address indexed bidder,uint indexed value);
    event biddingEnd(address indexed winner,uint indexed bidAmount);

// function for bidders to make a bid
    function makebid() public payable{
        require(msg.sender!=manager,"Manager can't make a bid");
        require(block.timestamp<=deployTime + 7 days,"Sorry the bidding time is over");
        require(msg.value+biddingOf[msg.sender]>largestBidder.bidAmount,"Sorry you need to make a bid larger than the previous one");
        if(biddingOf[msg.sender]==0){
            allBidders.push(msg.sender);
        }
        largestBidder.bidderAddress=msg.sender;
        largestBidder.bidAmount=msg.value+biddingOf[msg.sender];
         biddingOf[msg.sender]+=msg.value;

        emit bidMade(msg.sender,largestBidder.bidAmount);
    }

// function to get the user's total bid amount
    function showMycurrrentBid() public view returns(uint){
        return biddingOf[msg.sender];
    }

// function to get the highest bid made so far
    function highestBid() public view returns(uint){
        return largestBidder.bidAmount;
    }

// Description of the auction Item
    function productDescription() public view returns(productDetail memory){
        return product;
    }

// function to end the bidding process and transfer funds to the rest of people
    function endBidding() public{
        require(msg.sender==manager,"Only manager can end the bidding");
        require(block.timestamp>deployTime + 7 days,"Sorry bidding time is not over yet");
        for(uint i=0;i<allBidders.length;i++){
            uint refundAmount=0;
            if(allBidders[i]!=largestBidder.bidderAddress){
                refundAmount=biddingOf[allBidders[i]];  
                biddingOf[allBidders[i]]=0;                        //state variable changed before transfer to ensure no reentrancy attack
                payable(allBidders[i]).transfer(refundAmount);
            }
        }
        emit biddingEnd(largestBidder.bidderAddress,largestBidder.bidAmount);
    }

}