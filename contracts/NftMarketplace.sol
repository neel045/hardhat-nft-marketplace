// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// errors
error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed();
error NftMarketplace__OnlyOwner();

contract NftMarketplace {
    // type declaration
    struct Listing {
        uint256 price;
        address seller;
    }

    //events
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    //state Variables
    // NFT contract address => NFT token Id => Listing(token details)
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    ////////////////////
    //   Modifiers    //
    ////////////////////

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed();
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (owner != spender) {
            revert NftMarketplace__OnlyOwner();
        }
        _;
    }

    ////////////////////
    // Main Functions //
    ////////////////////

    /**
     * @notice Method for listing your NFT on the marketplace
     * @param nftAddress: Address of the NFT
     * @param tokenId: token id of the nft
     * @param price: selling price of the listed nft
     */

    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        /**
         * two ways of listing the nft to the marketplace
         * 1. send nft to the contract. Transfer -> Contract "hold" the NFT. it costs a lot of gas
         * 2. owners can still hold their NFT, and give the marketplace approval to Sell the NFT for them.
         * */

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }
}
