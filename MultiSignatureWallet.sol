// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract MultiSignatureWallet {
    address public manager;

    struct Request{
        address payable to;
        uint amount;
        uint32 approveCount;
        bool approved;
        mapping(address => bool) approvals;

    }

    mapping (address => bool) public validators;
    mapping (address => uint256) public balance;
    mapping (uint32 => Request) private allRequests;

    uint32 private totalValidatorsCount;
    uint32 public requestCount;

    modifier onlyValidators{
        require(validators[msg.sender] == true,"You are not in the list of validators");
        _;
    }

    constructor(){
        manager = msg.sender;
        totalValidatorsCount++;
        validators[manager]=true;
    }

    function addValidators(address _validatorAddress) public onlyValidators{
        totalValidatorsCount++;
        validators[_validatorAddress]=true;
    }
    function getBal() public view returns(uint){
       return address(this).balance;
   }

    function deposite() public payable{
        balance[msg.sender]+=msg.value;
    }

    function createRequest(address payable _to, uint _amount) public onlyValidators{
        
        Request storage newRequest = allRequests[++requestCount];
        newRequest.to = _to;
        newRequest.amount = _amount;
        newRequest.approveCount = 0;
        newRequest.approved = false ; 
        

    }

    function approveTx(uint32 _id) public onlyValidators{
        Request storage newRequest = allRequests[_id];
        require(!newRequest.approvals[msg.sender],"You can not approve the same request more than one time :(");
        // require(!newRequest.approved,"transaction already sent");  Not nessesary
        newRequest.approveCount++;
        newRequest.approvals[msg.sender] = true;

    }

    function sendTx(uint32 _id) public onlyValidators{
        Request storage newRequest = allRequests[_id];
        require(newRequest.approveCount == totalValidatorsCount , "All validators should approve :(");
        // require(!newRequest.approved,"transaction already sent"); Not nessesary
        require(newRequest.amount<=address(this).balance,"Not enough Money on Contract :(");
        newRequest.approved = true;
        
        newRequest.to.transfer(newRequest.amount);
    }
}
