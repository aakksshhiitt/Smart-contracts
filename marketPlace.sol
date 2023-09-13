// SPDX-License_Identifier:MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketPlace is ERC721URIStorage,Ownable{

    Counters.Counter private tokenId;        //uniques value for all tokens listed on the market place.   
    uint256 listingPrice= 1 ether;           //price that all the users have to pay while listing the NFT on the market place.
    struct MarketItem{
        uint256 tokenId;
        address owner;
        uint256 price;
        bool sold;
    }
    mapping(uint256=>MarketItem) marketItemAt;
    mapping(uint256=>mapping(address=>uint256)) offerList;           //offer given on a token id by a buyer (tokenId => buyer => amount)
    mapping(uint256=>mapping(address=>bool)) acceptedOffers;         //to check if offer on particular token id is accepted or not.

    constructor() ERC721("NFT MarketPlace","MYNFT"){}

    event itemCreatedAndRegistered(uint256 indexed tokenId,address indexed owner,uint indexed price);    //emitted when NFT minted and added to the market place.
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId,uint256 price);                  //emitted when a particular NFT purchased by a buyer.
    event NFTPriceUpdated(uint256 indexed tokenId,uint256 indexed newPrice);                             //emitted when price of a particular NFT is changed.
    event NFTSetForSale(uint256 indexed tokenId,uint256 indexed newPrice);                             // emitted when a minted NFT is set on re sale by owner.
    event offerProposed(uint256 indexed tokenId,uint256 indexed amount);                                 //emitted when someone proposed an offer on already sold NFT.
    event OfferAccepted(uint256 indexed _tokenId,address indexed buyer);                               // when owner accept a particular offer request.
    event NFTTraded(address indexed from, address indexed to, uint256 indexed price);                    // when NFT is finally traded and payment is made.


/* @dev function used to mint NFT and register that to the marketplace.
   @param_ takes token uri and price of the NFT as argument.
*/
    function createAndRegisterToken(string memory _uri,uint _price) public payable{
        require(msg.value==listingPrice,"You need to pay the listing price to register yourr NFT to the Market Place.");
        require(_price>0,"Please provide a valid price");

        uint256 _tokenId=Counters.current(tokenId);      //fetching the current tokenId
        _mint(msg.sender,_tokenId);     
        _setTokenURI(_tokenId, _uri);
        registerMarketItem(_tokenId,msg.sender,_price);   //calling registerMarketItem() function to register NFT to market place.
        Counters.increment(tokenId);
    }


/* @dev function used register the NFT to the market place.
    used in createAndRegisterToken() method.
   @param_ takes token owner address and price of the NFT as argument.
*/
    function registerMarketItem(uint256 _tokenId,address _owner,uint256 _price) internal{
        require(_owner!=address(0),"Please provide the valid addresses");

        MarketItem memory m=MarketItem(_tokenId,_owner,_price,false);    //creating MarketItem according to the data provided by the user.
        marketItemAt[Counters.current(tokenId)]=m;           //storing MarketItem to the mapping.
        _transfer(msg.sender,address(this),_tokenId);   // transferring the token to contract address for future security and transactions.
        
        emit itemCreatedAndRegistered(_tokenId,_owner,_price);
    }


/* @dev function used to purchase NFT by the buyers.
   @param_ takes token id as argument.
*/
    function purchaseNFT(uint256 _tokenId) public payable{
        require(msg.sender!=marketItemAt[_tokenId].owner,"Sorry, owner can't buy his own NFT");
        require(msg.value==marketItemAt[_tokenId].price,"Please pay the extact price of the NFT");
        require(marketItemAt[_tokenId].sold==false,"Sorry this product is already sold, you can offer the owner");

        address owner=marketItemAt[_tokenId].owner;
        marketItemAt[_tokenId].sold=true;
        marketItemAt[_tokenId].owner=msg.sender;
        payable(owner).transfer(msg.value);

        emit NFTPurchased(msg.sender,_tokenId,msg.value);
    }


/* @dev function used to make an already sold NFT available for the sale.
   @param_ takes token id and new price of the NFT as argument.
*/
    function reSellNFT(uint256 _tokenId,uint256 _newPrice) public{
        require(marketItemAt[_tokenId].sold==true,"This NFT is already on sale, no need to resell.");
        require(marketItemAt[_tokenId].owner==msg.sender,"Sorry you are not the owner of this NFT.");

        marketItemAt[_tokenId].sold=false;           //marking the NFT as not sold.
        marketItemAt[_tokenId].price=_newPrice;     //setting new price for the future sale of this NFT.

        emit NFTSetForSale(_tokenId,_newPrice);
    }


/* @dev function used to give offer for a NFT that is not on sale.
   @param_ takes token id and the offer amount of the NFT as argument.
*/
    function giveOffer(uint256 _tokenId,uint256 _amount) public{
        require(_tokenId<=Counters.current(tokenId),"Please provide a valid token Id");
        offerList[_tokenId][msg.sender]=_amount;      // settting the offer amount given to a particular token id by the msg.sender

        emit offerProposed(_tokenId,_amount);
    }


/* @dev function used to accept the offer of a particular buyer
   @param_ takes token id and address of the buyer who has made the offer for the NFT.
*/
    function AcceptOffer(uint256 _tokenId,address _buyer) public{
        require(marketItemAt[_tokenId].owner==msg.sender,"Sorry you can't accept the offer, as you are not the owner of this NFT");
        require(_buyer!=address(0),"Please provide a valid buyer address");
        require(acceptedOffers[_tokenId][_buyer]==false,"Offer is already accepted.");
        require(offerList[_tokenId][_buyer]>0,"Sorry, no offers had been made by this buyer till now");

        acceptedOffers[_tokenId][_buyer]=true;      //mark the offer accepted as true.

        emit OfferAccepted(_tokenId,_buyer);
    }


/* @dev function to check the offer status of msg.sender for a particular token id, if the offer is accepted by the owner or not.
   @param_ takes token id as parameter.
*/
    function offerStatus(uint256 _tokenId) public view returns(bool){
        return  acceptedOffers[_tokenId][msg.sender];
    }


/* @dev function for the buyers to make the payment if their offer for a particular tokenId is accepted by the buyer.
   @param_ takes token id as parameter.
*/
    function makeOfferPayment(uint256 _tokenId) public payable{
        require(msg.value==offerList[_tokenId][msg.sender],"Either you haven't made any offer or you are paying the wrong price.");
        require(offerStatus(_tokenId),"Sorry you are not allowed to avail offer at this price");

        address previousOwner=marketItemAt[_tokenId].owner;
        marketItemAt[_tokenId].owner=msg.sender;                         //changing the owner of the token.
        marketItemAt[_tokenId].price=offerList[_tokenId][msg.sender];    //updating the nft price.
        payable(previousOwner).transfer(msg.value);

        emit NFTTraded(previousOwner,msg.sender,msg.value);

    }


/* @dev function used to change the selling price of the NFT
   @param_ takes new price and tokenId of the NFT as argument.
*/
    function changeNFTPrice(uint256 _newPrice,uint256 _tokenId) public{
        require(msg.sender==marketItemAt[_tokenId].owner,"Sorry, only owner can change the price of the NFT");
        marketItemAt[_tokenId].price=_newPrice;
        emit NFTPriceUpdated(_tokenId,_newPrice);
    }


/* @dev function used to update the listing price of the NFT by the owner of the contract.
   @param_ takes new price as argument.
*/
    function updateListingPrice(uint256 _value) public onlyOwner{
        require(_value>0,"Please provide a valid amount");
        listingPrice=_value;
    }


/* @dev function used to fetch the listing price for this contract
*/
    function getListingPrice() public view returns(uint){
        return listingPrice;
    }

/* @dev function used to fetch the current price for the NFT of given tokenId
*/
function getCurrentPriceOfItem(uint256 _tokenId) public view returns(uint256){
    return marketItemAt[_tokenId].price;
}


/* @dev function used to fetch a particular market item details.
  @param_ tokenId as parameter of required NFT
*/
    function FetchMarketItem(uint256 _tokenId) public view returns(MarketItem memory){
        return marketItemAt[_tokenId];
    }


}