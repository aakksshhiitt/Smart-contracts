// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract vendingMachine{

    address private owner;
    uint totalCapacity;   // maximum units of single product
    uint sectionsAvailable;  // types of products that can be registered

    constructor(uint _totalCapacity,uint _sectionsAvailable){
        owner=msg.sender;
        totalCapacity=_totalCapacity;
        sectionsAvailable=_sectionsAvailable;
    }
    struct product{
        string name;
        string description;
        uint price;
        uint quantityLeft;
    }
    mapping(uint=>product) productList;
    uint productId=1;
    event productResgitered(string _prodcutName,uint _productId);
    event productBought(address _buyer,uint _productId,uint _quantity);
    event machineRestocked(uint _restockTime);

// function to register a new product
    function registerProduct(string memory _name,string memory _description,uint _price) public{
        require(msg.sender==owner,"Only owner can register new products");
        require(productId<=sectionsAvailable,"Sorry this machine can't add more item types");
        product memory p=product(_name,_description,_price,totalCapacity);
        emit productResgitered(_name,productId);
        productList[productId++]=p;
    }

// function to buy products by the buyers
    function buyProduct(uint _productId,uint _quantity) public payable{
        require(msg.sender!=owner,"Owner can't buy its own products");
        require(_quantity<=productList[_productId].quantityLeft,"Sorry less number of products are available");
        require(msg.value==productList[_productId].price*_quantity,"Please pay the exact amount to buy specified quantity");
        productList[_productId].quantityLeft-=_quantity;
        emit productBought(msg.sender,_productId,_quantity);
    }

// to restock the vending machine
    function restock() public{
        require(msg.sender==owner,"Only owner can restock the machine");
        require(address(this).balance>0,"Sorry the machine is already full");
        for(uint8 i=1;i<=productId;i++){
            productList[i].quantityLeft=totalCapacity;
        }
        emit machineRestocked(block.timestamp);
        payable(owner).transfer(address(this).balance);
    }

// function to get details of a particular product
    function getProductDetails(uint _productId) public view returns(product memory){
        require(_productId<=productId,"Please enter a valid product");
        return productList[_productId];
    }
}