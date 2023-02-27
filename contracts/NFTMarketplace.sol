//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//Console functions to help debug the smart contract just like in Javascript
import "hardhat/console.sol";
//OpenZeppelin's NFT Standard Contracts. We will extend functions from this in our implementation
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {

    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listPrice = 0.01 ether;

    constructor() ERC721("NFTMarketplace", "NFTM"){
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }

    mapping(uint256 => ListedToken) private idToListedToken;

    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only Owner can update the listing price");
        listPrice = _listPrice;
    }

    function getListPrice() public view returns(uint256) {
        return listPrice;
    }

    function getLatestIdToListedToken() public view returns(ListedToken memory){
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    } 

    function getListedForTokenId(uint256 tokenId) public view returns (ListedToken memory){
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256){
        return _tokenIds.current();
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint){
        require(msg.value == listPrice, "Send enough ether to List.");
        require(price>0,"Make sure the price isn't negative");
        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);
        createListedToken(currentTokenId, price);
        return currentTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true)
        ;

        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllNFTs() public view returns(ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);

        uint currentIndex = 0;
        for(uint i=0;i<nftCount;i++){
            uint currentId = i+1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex++;
        }
        return tokens;
    }

    function getMyNFTs() public view returns(ListedToken[] memory){
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        for(uint i=0;i<totalItemCount;i++){
            if(idToListedToken[i+1].owner == payable(msg.sender) || idToListedToken[i+1].seller == payable(msg.sender)){
                itemCount++;
            }
        }
        ListedToken[] memory items = new ListedToken[](itemCount);
        for(uint i=0;i<totalItemCount;i++){
            if(idToListedToken[i+1].owner == address(msg.sender) || idToListedToken[i+1].seller == msg.sender){
                uint currentId = i+1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint price = idToListedToken[tokenId].price; 
        require(msg.value == price, "Please submit the asking price for the NFT in order to purchase");
        address seller = idToListedToken[tokenId].seller;
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }

}