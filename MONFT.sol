// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Import EnumerableSet

contract MultiOwnerNFT is Context, ERC165, IERC721, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet; // Use EnumerableSet for address sets

    uint256 private _nextTokenId;

    // Replace array with EnumerableSet for owners
    mapping(uint256 => EnumerableSet.AddressSet) internal _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) private _balances;

    event TokenMinted(uint256 tokenId, address owner);
    event TokenTransferred(uint256 tokenId, address from, address to);

    constructor(address owner) Ownable(owner) {}

    function mintToken() public onlyOwner returns (uint256) {
        _nextTokenId++;

        // Add the sender to the set of owners for the new token
        _owners[_nextTokenId].add(_msgSender());

        // Increment the balance of the owner
        _balances[_msgSender()] += 1;

        emit TokenMinted(_nextTokenId, _msgSender());
        return _nextTokenId;
    }

    function isOwner(
        uint256 tokenId,
        address account
    ) public view returns (bool) {
        require(_exists(tokenId), "MO-NFT: Token does not exist");

        // Check if the account is in the owners set for the token
        return _owners[tokenId].contains(account);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId].length() > 0;
    }

    // IERC721 Functions

    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    function balanceOf(
        address owner
    ) external view override returns (uint256 balance) {
        require(
            owner != address(0),
            "MO-NFT: Balance query for the zero address"
        );

        // Return the balance from the _balances mapping
        return _balances[owner];
    }

    function ownerOf(
        uint256 tokenId
    ) external view override returns (address owner) {
        require(_exists(tokenId), "MO-NFT: Owner query for nonexistent token");

        // Return the first owner in the set (since this is an EnumerableSet, order is not guaranteed)
        return _owners[tokenId].at(0);
    }

    function getOwnersCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "MO-NFT: Token does not exist");

        // Return the number of owners for the given tokenId
        return EnumerableSet.length(_owners[tokenId]);
    }

    function approve(address, uint256) external pure override {
        revert("MO-NFT: Approve is forbidden");
    }

    function getApproved(uint256) public pure override returns (address) {
        revert("MO-NFT: Approve is forbidden");
    }

    function setApprovalForAll(address, bool) external pure override {
        revert("MO-NFT: Approve is forbidden");
    }

    function isApprovedForAll(
        address,
        address
    ) public pure override returns (bool) {
        revert("MO-NFT: Approve is forbidden");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            isOwner(tokenId, _msgSender()),
            "MO-NFT: Transfer from incorrect account"
        );
        require(to != address(0), "MO-NFT: Transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            isOwner(tokenId, _msgSender()),
            "MO-NFT: Trigger from incorrect account"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _data; // silence the warning
        _transfer(from, to, tokenId);
        //    require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(
            isOwner(tokenId, from),
            "MO-NFT: Transfer from incorrect owner"
        );
        require(to != address(0), "MO-NFT: Transfer to the zero address");
        require(!isOwner(tokenId, to), "MO-NFT: Recipient is already an owner");

        // Add the new owner to the EnumerableSet
        _owners[tokenId].add(to);

        // Update balances
        _balances[to] += 1;

        emit TokenTransferred(tokenId, from, to);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}