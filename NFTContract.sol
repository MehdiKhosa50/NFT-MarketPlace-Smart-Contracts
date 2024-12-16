// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin\contracts\utils\cryptography\EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721, EIP712, ReentrancyGuard, Ownable, ERC721Enumerable, ERC721URIStorage {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    bytes32 private constant LAZY_MINT_TYPEHASH =
        keccak256(
            "LazyMint(uint256 tokenId,string tokenURI,uint256 price,address creator,uint256 expirationTime)"
        );

    struct LazyMintVoucher {
        uint256 tokenId;
        string tokenURI;
        uint256 price;
        address creator;
        uint256 expirationTime;
        bytes signature;
    }

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256[]) public sellerListings;
    mapping(uint256 => bool) public isLazyMinted;

    address public minter;

    event NFTMinted(uint256 indexed tokenId, address indexed creator, string tokenURI);
    event NFTLazyMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string tokenURI,
        uint256 price,
        uint256 expirationTime
    );
    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    constructor(
        string memory name,
        string memory symbol,
        address _minter
    ) ERC721(name, symbol) EIP712("LazyMint", "1") Ownable(msg.sender) {
        minter = _minter;
    }

    function safeMint(string memory tokenURI) external {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit NFTMinted(newTokenId, msg.sender, tokenURI);
    }

    function lazyMintNFT(LazyMintVoucher calldata voucher)
        external
        payable
        nonReentrant
    {
        require(msg.value >= voucher.price, "Insufficient payment");
        _verify(voucher);
        require(
            block.timestamp <= voucher.expirationTime,
            "Voucher has expired"
        );

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, voucher.tokenURI);

        sellerListings[voucher.creator].push(newTokenId);
        isLazyMinted[newTokenId] = true;

        payable(voucher.creator).transfer(voucher.price);

        if (msg.value > voucher.price) {
            payable(msg.sender).transfer(msg.value - voucher.price);
        }

        emit NFTLazyMinted(
            newTokenId,
            voucher.creator,
            voucher.tokenURI,
            voucher.price,
            voucher.expirationTime
        );
        emit NFTSold(newTokenId, voucher.creator, msg.sender, voucher.price);
    }

    function _verify(LazyMintVoucher calldata voucher) internal returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LAZY_MINT_TYPEHASH,
                    voucher.tokenId,
                    keccak256(bytes(voucher.tokenURI)),
                    voucher.price,
                    voucher.creator,
                    voucher.expirationTime
                )
            )
        );

        address signer = ECDSA.recover(digest, voucher.signature);
        // return signer == minter;

        emit DebugLog("Recovered signer", signer);
        emit DebugLog("Expected minter", minter);
    }
    event DebugLog(string message, address addr);

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        override
    {
        require(
            ownerOf(tokenId) != address(0),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function getNextTokenId() external view returns (uint256) {
        return _tokenIds.current() + 1;
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isLazyMintedNFT(uint256 tokenId) external view returns (bool) {
        return isLazyMinted[tokenId];
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getTypedDataHash(LazyMintVoucher calldata voucher)
        public
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        LAZY_MINT_TYPEHASH,
                        voucher.tokenId,
                        keccak256(bytes(voucher.tokenURI)),
                        voucher.price,
                        voucher.creator,
                        voucher.expirationTime
                    )
                )
            );
    }

    function getSellerListings(address seller)
        external
        view
        returns (uint256[] memory)
    {
        return sellerListings[seller];
    }

    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }
}