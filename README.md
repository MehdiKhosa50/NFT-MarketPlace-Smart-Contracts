# NFT Marketplace with Lazy Minting

A decentralized NFT marketplace built on Ethereum that implements lazy minting functionality, allowing creators to mint NFTs without paying upfront gas fees until the first purchase occurs.

## Features

- **Traditional NFT Minting**: Standard ERC721 token minting functionality
- **Lazy Minting**: Gas-less NFT creation using signed vouchers
- **Signature Verification**: EIP-712 compliant signature verification for secure lazy minting
- **Enumerable NFTs**: Keep track of all tokens and their owners
- **Token URI Storage**: Store and retrieve metadata URIs for NFTs
- **Owner Controls**: Special functions restricted to contract owner

## Smart Contracts

The project consists of two main contracts:

1. **PDT_NFT.sol**: A basic NFT contract with signature-based minting
2. **NFTContract.sol**: The main marketplace contract with lazy minting functionality

## Technical Details

### Prerequisites

- Node.js v14+ and npm
- Hardhat or Truffle
- OpenZeppelin Contracts v4.8+
- MetaMask or similar Web3 wallet

### Contract Dependencies

```solidity
@openzeppelin/contracts/token/ERC721/ERC721.sol
@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol
@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol
@openzeppelin/contracts/utils/cryptography/ECDSA.sol
@openzeppelin/contracts/utils/cryptography/EIP712.sol

How It Works
Creator Flow:
Creator prepares NFT metadata
Creates a signed voucher containing NFT details
Shares the voucher off-chain
Buyer Flow:
Receives the signed voucher
Calls lazyMintNFT with the voucher
Pays the specified price
NFT is minted directly to their address
Verification:
Contract verifies the signature
Checks expiration time
Validates payment amount
Processes the minting and payment
Security Features
Signature verification using EIP-712
Reentrancy protection
Expiration timestamps for vouchers
Owner-only administrative functions
Secure payment handling

Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

License
This project is licensed under the MIT License - see the LICENSE file for details.

Acknowledgments
OpenZeppelin for their secure contract implementations
The Ethereum community for EIP-712 standards
Contact
For questions and support, please open an issue in the repository.

Made with ❤️ for the NFT community