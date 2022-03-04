// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ownable{
    address payable public owner;
    constructor(){
        owner=payable(msg.sender);
    }

    modifier onlyOwner(){
        require(isOwner(),"Owner is required");
        _;
    }

    function isOwner() public view returns(bool){
        return msg.sender == owner;
    }
}

contract Item{
    uint public priceInWei;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor (ItemManager _parentContract,uint _priceInWei,uint _index){
        parentContract = _parentContract;
        priceInWei = _priceInWei;
        index = _index;
    }

    receive() external payable{
        require(pricePaid ==0,"Item is already paid");
        require(priceInWei == msg.value,"only full payment accepted");
        //payable(address(parentContract)).transfer(msg.value);
        //you only send gas depend (2300) and we cannot do anything with that(update data etc)
        //from item we want more gas available in order to use trigger payment function
        //thats why we are using low label function
        ///////////////////////////////////////////////function signature////////////////////////////////Argument
        //we have to listen return value. Gives two return values one is bool (successfull or not), another return value if the given func have any 
        (bool success,)=(address(parentContract)).call{value:msg.value}(abi.encodeWithSignature("triggerPayment(uint256)",index));

        require(success,"Tx is not successfull.Cancelling transaction");
        pricePaid+=msg.value;
    }
}

contract ItemManager is Ownable{
    enum SupplyChainState{Created,Paid,Deliverd}

    struct S_Item{
        string _identifier;
        uint _itemPrice;
        Item _item;
        SupplyChainState _state;
    }

    uint itemIndex;
    mapping (uint => S_Item) public items;

    event SupplyChainStep(uint _itemIndex,uint _step, address _itemAddress);

   

    function createItem(string memory _identifier, uint _itemPrice) public onlyOwner {
        Item item = new Item(this,_itemPrice,itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice = _itemPrice;
        items[itemIndex]._state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex, uint(items[itemIndex]._state),address(items[itemIndex]._item));
        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable{
        require(items[_itemIndex]._itemPrice == msg.value,"pay the full amount");
        require(items[_itemIndex]._state == SupplyChainState.Created,"Item is further in chains");

        items[_itemIndex]._state = SupplyChainState.Paid;
        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state),address(items[_itemIndex]._item));

    }

    function triggerDelivery(uint _itemIndex) public onlyOwner{
        require(items[_itemIndex]._state == SupplyChainState.Paid,"Item is further in chains");

        items[_itemIndex]._state = SupplyChainState.Deliverd;
        emit SupplyChainStep(_itemIndex, uint(items[_itemIndex]._state),address(items[_itemIndex]._item));

    }
    
}
