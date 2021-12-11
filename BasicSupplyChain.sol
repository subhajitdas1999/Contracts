// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1 <0.9.0;

contract Ownable{
    address  public  owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner == msg.sender,"Only Owner is allowed");
        _;
    }

    function isOwner() public view returns(bool){
        return (owner == msg.sender);
    }
}

//contract Item is responsible for taking the payment and handling the payment back
//over to the ItemManager, So when we create an Item then we create a new instance of
//Item Contract
//Every time we create a smart contract , It's gets its own address 
contract Item {
    uint public priceInWei;
    uint public index;
    uint public pricePaid;

    ItemManager parentContract;
    constructor(ItemManager _parentContract,uint _index,uint _priceInWei){
        priceInWei = _priceInWei;
        index = _index;
        parentContract = _parentContract;
    }

    receive() external payable{
        require(priceInWei == msg.value,"We accept full payment");
        require(pricePaid==0,"Amount already paid");
       (bool success,)=address(parentContract).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)",index));
        require(success,"Transaction wasn't successfull ");
        pricePaid+=msg.value;
    }
}

contract ItemManager is Ownable{
    enum supplyChainState{created,paid,deliverd}

    struct S_Item{
        Item _item;
        string _identifier;
        uint _itemPrice;
        supplyChainState _state;
    }

    mapping(uint => S_Item) public items;
    uint itemIndex;

    event supplyChainStep(uint _itemIndex,uint _state,address _itemAddress);

    function createItem(string memory _identifier , uint _itemPrice) public onlyOwner {
        itemIndex++;
        Item item = new Item(this,itemIndex,_itemPrice);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = supplyChainState.created;
        emit supplyChainStep( itemIndex,uint(items[itemIndex]._state),address(items[itemIndex]._item));
    }

    function triggerPayment(uint _itemIndex) public payable{
        require(items[_itemIndex]._itemPrice == msg.value,"We except full payment");
        require(items[_itemIndex]._state == supplyChainState.created, "Amount of this item already paid or item is deliverd");
        items[_itemIndex]._state = supplyChainState.paid;
        emit supplyChainStep( itemIndex,uint(items[itemIndex]._state),address(items[itemIndex]._item));
    }

    function triggerDelivery(uint _itemIndex) public onlyOwner{
        require(items[_itemIndex]._state == supplyChainState.paid,"Amount for this item is not paid or item is already deliverd");
        items[_itemIndex]._state = supplyChainState.deliverd;
        emit supplyChainStep( itemIndex,uint(items[itemIndex]._state),address(items[itemIndex]._item));
    }
    
    
}
