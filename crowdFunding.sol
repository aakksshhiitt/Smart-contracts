// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract crowdFunding{

// declaring state variables
    address manager;
    uint public targetContribution;
    uint deployTime;
    uint public contributionDays;
    uint public minimumContribution;
    uint public totalContribution;
    uint public numberOfContributors;
    struct request{
        address recepientAddress;
        string description;
        uint requestAmount;
        uint votes;
        bool completed;
        mapping(address=>bool) hasVoted;
    }
    mapping(address=>uint) public myContribution;
    mapping(uint=>request) public requestList;
    uint requestNumber;

// constructor 
    constructor(uint _targetFund,uint _contributionDays,uint _minimumContribution){
        manager=msg.sender;
        targetContribution=_targetFund;
        deployTime=block.timestamp;
        contributionDays=_contributionDays; 
        minimumContribution=_minimumContribution;
        numberOfContributors=0;
        totalContribution=0;
        requestNumber=1;
    }

// event declaration
    event contributionMade(address indexed _contributor,uint indexed _amount);
    event amountRefunded(address indexed _contributor,uint indexed _amount);
    event requestCreated(uint indexed _requestNumber,uint indexed _amount);
    event voteSubmitted(address indexed _voter,uint indexed _requestNumber);
    event requestCompleted(uint indexed _requestNumber);


// function to make contribution by the contributors
    function makeContribution() public payable{
        require(msg.sender!=manager,"Manager can't contribute");
        require(msg.value>=minimumContribution,"Please contribute the minimum amount");
        require(block.timestamp<=deployTime + contributionDays,"Contribution days are over");
        require(totalContribution<=targetContribution,"Target contribution is completed");
        if(myContribution[msg.sender]==0){
            numberOfContributors++;
        }
        myContribution[msg.sender]+=msg.value;
        totalContribution+=msg.value;

        emit contributionMade(msg.sender,msg.value);
    }

// function for contributors to get refund
    function getRefund() public{
        // require((block.timestamp<=deployTime + contributionDays) || (totalContribution<targetContribution),"You can't take refund after contribution period is over");
        require(myContribution[msg.sender]>0,"You are not a contributor");
        totalContribution-=myContribution[msg.sender];
        numberOfContributors--;
        uint amount=myContribution[msg.sender];
        myContribution[msg.sender]=0;
        payable(msg.sender).transfer(amount);

        emit amountRefunded(msg.sender,amount);
    }

// function for manager to create request for some purpose
    function createRequest(address _recepientAddress,string memory _description,uint _requestAmount) public{
        // require((block.timestamp>deployTime + contributionDays) || (totalContribution>targetContribution),"Contribution period is not over yet");
        require(msg.sender==manager,"Only manager can create a request");
        require(_recepientAddress!=address(0),"Please provide a valid recepient address");
        require(_requestAmount<totalContribution,"Sorry required fund is not available");

        request storage r=requestList[requestNumber++];
        r.recepientAddress=_recepientAddress;
        r.description=_description;
        r.requestAmount=_requestAmount;
        r.votes=0;
        r.completed=false;
        r.hasVoted;

        emit requestCreated(requestNumber-1,_requestAmount);
    }

// function for contributors to vote for a particular request
    function voteRequest(uint _requestNumber) public{
        require(myContribution[msg.sender]>0,"Only contributors can vote for a request");
        require(_requestNumber>0 && _requestNumber<requestNumber,"Please provide valid request number");
        require(requestList[_requestNumber].completed==false,"Sorry this request is completed");
        require(requestList[_requestNumber].hasVoted[msg.sender]==false,"You have already voted");
        requestList[_requestNumber].hasVoted[msg.sender]==true;
        requestList[_requestNumber].votes++;

        emit voteSubmitted(msg.sender,_requestNumber);
    }

// function for manager to make payment to the request if the majority agrees
    function makePayment(uint _requestNumber) public{
        require(msg.sender==manager,"Only manager can make request payments");
        require(_requestNumber>0 && _requestNumber<requestNumber,"Please provide valid request number");
        require(requestList[_requestNumber].completed==false,"Sorry this request is already completed");
        require((requestList[_requestNumber].votes*100)/numberOfContributors>50,"Sorry majority is not with this request");
        requestList[_requestNumber].completed=true;
        totalContribution-=requestList[_requestNumber].requestAmount;
        payable(requestList[_requestNumber].recepientAddress).transfer(requestList[_requestNumber].requestAmount);

        emit requestCompleted(_requestNumber);
    }

// get contribution amount of particular contributor
    function myContributionAmount() public view returns(uint){
        return myContribution[msg.sender];
    }
}
