// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./lib/DN404.sol";
import "dn404/src/DN404Mirror.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {LibString} from "solady/src/utils/LibString.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {MerkleProofLib} from "solady/src/utils/MerkleProofLib.sol";



contract NFTMintDN404 is DN404, ERC20Permit, Ownable {
    string private _name;
    string private _symbol;
    string private _baseURI;
    bytes32 private allowlistRoot;
    uint120 public publicPrice;
    uint120 public allowlistPrice;
    bool public live;
    uint256 public numMinted;
    uint256 public MAX_SUPPLY;

    error InvalidProof();
    error InvalidPrice();
    error ExceedsMaxMint();
    error TotalSupplyReached();
    error NotLive();

    modifier isValidMint(uint256 price, uint256 amount) {
        require(live, "NotLive");
        require(price * amount == msg.value, "InvalidPrice");
        require(numMinted + amount <= MAX_SUPPLY, "TotalSupplyReached");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _MAX_SUPPLY,
        uint120 publicPrice_,
        uint96 initialTokenSupply,
        address initialSupplyOwner
    ) ERC20Permit("NFTMintDN404") {
        _initializeOwner(msg.sender);
        _name = name_;
        _symbol = symbol_;
        MAX_SUPPLY = _MAX_SUPPLY;
        publicPrice = publicPrice_;
        address mirror = address(new DN404Mirror(msg.sender));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
    }

    function mint(uint256 amount) public payable isValidMint(publicPrice, amount) {
        numMinted += amount;
        _mint(msg.sender, amount);
    }

    function allowlistMint(uint256 amount, bytes32[] calldata proof) public payable isValidMint(allowlistPrice, amount) {
        if (!MerkleProofLib.verifyCalldata(proof, allowlistRoot, keccak256(abi.encodePacked(msg.sender)))) {
            revert InvalidProof();
        }
        numMinted += amount;
        _mint(msg.sender, amount);
    }
}



