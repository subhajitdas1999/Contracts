// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

///////////////////////////////This one is for allowence validity///////////////////

contract Allowence is Ownable{

    event allowenceChanged(address indexed _who,address indexed _toWhom, uint  _oldAmount,uint _newAmount);
    mapping (address => uint) public allowence;

    function isOwner() public view returns(bool){
        if (owner()==msg.sender){
            return true;
        }
        return false;
    }

    modifier ownerOrallowence(uint _amount){
       require(isOwner() || allowence[msg.sender] >= _amount ,"You Are not owner or you dont have allowence");
       _;
   }

   function addAllowence(address _who, uint _amount) public onlyOwner{
       emit allowenceChanged(_who,msg.sender,allowence[_who],_amount);
       allowence[_who]=_amount;
   }

   function reduceAllowence(address _who, uint _amount) internal {
       emit allowenceChanged(_who,msg.sender,allowence[_who],allowence[_who]-_amount);
       allowence[_who] -= _amount;
   }

}

/********************************************/

/******This is the wallet****/////

contract Wallet is Allowence{
   
   event moneyRecieved(address _fromWhom,uint _amount);
   event moneySent(address _to,uint _amount);


   function withdrawMoney(address payable _to , uint _amount) external ownerOrallowence(_amount){
       require (address(this).balance >= _amount,"Not enough funds to the contract");
       if(!isOwner()){
           reduceAllowence(msg.sender,_amount);
       }
       emit moneySent(_to,_amount);
       _to.transfer(_amount);

   }

   function renounceOwnership() override public pure{
       revert("Cannot renounce owner here");
   }

   function getBal() public view returns(uint){
       return address(this).balance;
   }

   fallback () external payable{
       emit moneyRecieved(msg.sender,msg.value);
   }


}
