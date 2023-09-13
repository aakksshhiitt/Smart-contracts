// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;
contract eCommerce{

//  declaring state variables 
    struct product{
        string productName;
        string productDescription;
        uint price;
        bool delivered;
        address seller;
        address buyer;
    }
    mapping(uint=>product) productList;
    mapping(address=>product[]) myProducts;
    uint productNumber;
// constructor
    constructor(){
        productNumber=1;
    }
// events declaration
    event productRegistered(uint indexed _productNumber,address indexed _seller);
    event productBought(uint indexed _productNumber,address indexed _buyer);
    event productHasDelivered(uint indexed _productNumber);

// function for sellers to register their new products for selling
    function registerProduct(string memory _productName,string memory _productDescription,uint  _price) public{
        require(_price>0,"product need to have some cost");
        product memory p=product(_productName,_productDescription,_price,false,msg.sender,address(0));
        productList[productNumber++]=p;
        emit productRegistered(productNumber-1,msg.sender);
    }

// function to buy a registered product 
    function buyProduct(uint _productNumber) payable public{
        require(_productNumber>0 &&_productNumber<=productNumber,"Sorry no such product available");
        require(productList[_productNumber].buyer==address(0),"this product is already bought");
        require(productList[_productNumber].seller!=msg.sender,"Sorry seller can't but its own product");
        require(msg.value==productList[_productNumber].price,"Please pay the exact price of the product");
        productList[_productNumber].buyer=msg.sender;
        myProducts[msg.sender].push(productList[_productNumber]);
        emit productBought(_productNumber,msg.sender);  
    }

// function for buyers to mark their product as delivred and pay the seller with the amount   
    function productDelivered(uint _productNumber) public{
        require(_productNumber>0 &&_productNumber<=productNumber,"Sorry no such product available");
        require(productList[_productNumber].buyer==msg.sender,"Sorry you are not the buyer of this product");
        require(productList[_productNumber].delivered==false,"Sorry this product is already delivered");
        productList[_productNumber].delivered=true;
        payable(productList[_productNumber].seller).transfer(productList[_productNumber].price);
        emit productHasDelivered(_productNumber);
    }

// function to get my bought products 
    function myProduct() public view returns(product [] memory){
        return myProducts[msg.sender];
    }

// fuction to get product details

    function getProductDetails(uint _productNumber) public view returns(product memory){
        require(_productNumber>0 &&_productNumber<=productNumber,"Sorry no such product available");
        return productList[_productNumber];
    }
}