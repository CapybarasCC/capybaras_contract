// SPDX-License-Identifier: MIT

/**
Capybaras Country Club

             ▄▄▄▌██████████████████████████▌▌█▄ 
      ▄██████████████████████████████████████████████▌
   ▄██████▌                                      ▀███████
  █████                                              ▀████▄
 ████          ███████▌              ▄███████▒         ████
 ███            █████████          ▓████████▀           ███▌
▐███               ▀██████        ███████               ▐███
 ██▌                 ▀████▌  ▄█   █████                  ███
 ███                         ██▌                         ██▌
 ███                         ██▌                        ███▀
 ▓██▌                       ▐███                        ███
  ███                       ║███                       ███▌
  ╙███                      ║███                       ███
   ███▌                     ▐███                      ███
    ███▌                    ║███                     ███
     ████                   ▐███                   ▄███
      ▀███▄                 ▐███                  ████
        ████▄                ██▌                ████▀
         ▐████▌              ██▌             ▄█████
           ▀█████▄           ██           ,██████
             "██████▌                  ▄██████▀
                ╙████████▄        ,▄███████▀
                    ╜██████████████████▀                                                 
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

/// @title Capybaras Country Club NFT mint contract
/// @author Capybaras Country Club Team
/// @dev The contract uses Azukis ERC721 implementation {see ER721A.sol for more details}
/// @dev source for ERC721A: https://github.com/chiru-labs/ERC721A
contract CCCMintContract is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public costPublic = 0.06 ether;
    uint256 public costWL = 0.04 ether;
    uint256 public costOG = 0.03 ether;
    uint256 public maxSupply = 7700;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public nftPerAddressLimit = 5;
    uint256 public nftPerAddressLimitPreSale = 3;
    uint256 public maxSupplyForDevs = 120;

    bool public paused = true;
    bool public revealed = false;
    bool public presale = true;
    mapping(address => uint256) public addressMintedBalance;

    bytes32 rootWl;
    bytes32 rootOg;

    constructor() ERC721A("Capybara", "CCC") {
        setHiddenMetadataUri("ipfs://TO_UPDATE/hidden_metadata.json");
    }

    /// @dev Runs before every mint
    modifier mintCompliance(uint256 _mintAmount) {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    /// @dev Runs before every mint for Owner
    modifier mintComplianceOwner(uint256 _mintAmount) {
        require(
            totalSupply() + _mintAmount <= maxSupplyForDevs,
            "Max supply exceeded!"
        );
        _;
    }

    /// @notice Mints for public sale at full price. WL and OG can go up to 5 NFT (3 in pre-sale and 2 in public sale).
    /// @param _mintAmount is to number of NFTs to mint
    /// @dev Mints NFTs for public sale when presale is false at a discount
    function mintPublicSale(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(!presale, "Not valid user for pre sale");
        require(msg.value >= costPublic * _mintAmount, "Insufficient funds!");
        require(
            addressMintedBalance[msg.sender] + _mintAmount <=
                nftPerAddressLimit,
            "max NFT per address exceeded"
        );

        addressMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /// @notice Mints for OGs with a 20% discount
    /// @param _mintAmount is to number of NFTs to mint
    /// @param proof is an array of byte32 hashes
    /// @dev Mints NFTs for the private sale when presale is true
    function mintOG(uint256 _mintAmount, bytes32[] memory proof)
        external
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(presale, "Not in pre sale");
        require(
            MerkleProof.verify(
                proof,
                rootOg,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not og"
        );
        require(msg.value >= costOG * _mintAmount, "insufficient funds");
        require(
            addressMintedBalance[msg.sender] + _mintAmount <=
                nftPerAddressLimitPreSale,
            "max NFT per address exceeded"
        );
        addressMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /// @notice Mints for whitelisted users with a 10% discount
    /// @param _mintAmount is to number of NFTs to mint
    /// @param proof is an array of byte32 hashes
    /// @dev Mints NFTs for the private sale when presale is true
    function mintWL(uint256 _mintAmount, bytes32[] memory proof)
        external
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(presale, "Not in pre sale");
        require(
            MerkleProof.verify(
                proof,
                rootWl,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not whitelisted"
        );
        require(msg.value >= costWL * _mintAmount, "insufficient funds");
        require(
            addressMintedBalance[msg.sender] + _mintAmount <=
                nftPerAddressLimitPreSale,
            "max NFT per address exceeded"
        );

        addressMintedBalance[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    /// @param _mintAmount quantity of tokens to transfer
    /// @param _receiver wallet of the recipient
    /// @dev Mints NFTs for the private sale when presale is true
    function mintForAddress(uint256 _mintAmount, address _receiver)
        external
        mintComplianceOwner(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    /// @notice Queries contract tokens by id
    /// @param _tokenId id of the token eg: 1,2,3,4,5
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    /// @notice Reveals the metadata of the tokens
    /// @param _state true or false
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    /// @notice Updates the mint cost
    /// @param _cost new cost of minting
    function setCostPublic(uint256 _cost) public onlyOwner {
        costPublic = _cost;
    }

    /// @notice Updates the mint cost
    /// @param _cost new cost of minting
    function setCostWL(uint256 _cost) public onlyOwner {
        costWL = _cost;
    }

    /// @notice Updates the mint cost
    /// @param _cost new cost of minting
    function setCostOG(uint256 _cost) public onlyOwner {
        costOG = _cost;
    }

    /// @notice Sets the maximum amount of tokens to be minted per transaction
    /// @param _maxMintAmountPerTx new max amount of tokens to be minted per tx
    /// @dev It's a cap to avoid network congestion
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /// @notice Sets the uri where the metadata is stored when the contract is not revealed
    /// @param _hiddenMetadataUri new uri where the metadata is stored
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /// @notice Sets the uri prefix for the metadata Eg: ipfs//:
    /// @param _uriPrefix new uri prefix for the metadata
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    /// @notice Sets the uri suffix for the metadata Eg: png
    /// @param _uriSuffix new uri suffix for the metadata
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /// @notice Sets paused contract state
    /// @param _state true or false
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    /// @notice Sets presale state
    /// @param _state true or false
    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }

    /// @notice Sets Merkle root hash for the list of whitelisted addresses
    /// @param _root new Merkle root hash for the list of whitelisted addresses
    function setRootWl(bytes32 _root) public onlyOwner {
        rootWl = _root;
    }

    /// @notice Sets Merkle root hash for the list of og addresses
    /// @param _root new Merkle root hash for the list of Og addresses
    function setRootOg(bytes32 _root) public onlyOwner {
        rootOg = _root;
    }

    /// @notice Withdraws balance from the contract wallet
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /// @notice Returns the base URI
    /// @dev Returns a string in the form of an ipfs url
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    /// @notice uses MerkleRoot to verify if the hash is valid
    /// @param root can be rootOg or rootWl
    /// @param proof is the Merkle proof in the form of a bytes32 array
    /// @dev Returns a boolean
    function verify(bytes32 root, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }
}
