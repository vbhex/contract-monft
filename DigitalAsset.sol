// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MONFT.sol";

contract DigitAsset is MultiOwnerNFT {
    
    struct DigitAssetInfo {
        uint256 assetId;
        string assetName;
        uint256 size;
        bytes32 fileHash;
        address provider;
        uint256 transferValue;
    }

    mapping(uint256 => DigitAssetInfo) private _assets;

    // Events
    event AssetProvided(
        uint256 indexed assetId, 
        uint256 indexed size,
        address indexed provider,
        bytes32 fileHash,
        uint256 transferValue
    );
    event AssetTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed assetId,
        uint256 transferValue
    );
    event TransferValueUpdated(
        uint256 indexed assetId,
        uint256 oldTransferValue,
        uint256 newTransferValue
    );

    constructor() payable MultiOwnerNFT(msg.sender) {}

    function getAssetDetails(
        uint256 assetId
    ) public view returns (
        uint256 id,
        string memory name,
        uint256 size,
        bytes32 fileHash,
        address provider,
        uint256 transferValue
    ) {
        require(_exists(assetId), "Asset: Asset does not exist");

        DigitAssetInfo storage asset = _assets[assetId];
        return (
            asset.assetId,
            asset.assetName,
            asset.size,
            asset.fileHash,
            asset.provider,
            asset.transferValue
        );
    }

    function provide(
        string memory assetName,
        uint256 size,
        bytes32 fileHash,
        address provider,
        uint256 transferValue
    ) external returns (uint256) {
        uint256 assetId = mintToken();
        _assets[assetId] = DigitAssetInfo({
            assetId: assetId,
            assetName: assetName,
            size: size,
            fileHash: fileHash,
            provider: provider,
            transferValue: transferValue
        });
        emit AssetProvided(
            assetId, 
            size,
            provider,
            fileHash,
            transferValue
        );
        return assetId;
    }

    function setTransferValue(uint256 assetId, uint256 newTransferValue) external {
        require(_exists(assetId), "Asset: Asset does not exist");
        DigitAssetInfo storage asset = _assets[assetId];
        require(msg.sender == asset.provider, "Only provider can update transfer value");

        uint256 oldTransferValue = asset.transferValue;
        asset.transferValue = newTransferValue;

        emit TransferValueUpdated(assetId, oldTransferValue, newTransferValue);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            isOwner(tokenId, from),
            "MO-NFT: Transfer from incorrect account"
        );
        require(to != address(0), "MO-NFT: Transfer to the zero address");

        _transferWithProviderPayment(from, to, tokenId);
    }

    function _transferWithProviderPayment(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        DigitAssetInfo storage asset = _assets[tokenId];
        
        // Pay the provider the transferValue for this asset
        require(
            address(this).balance >= asset.transferValue,
            "Insufficient contract balance for provider payment"
        );
        payable(asset.provider).transfer(asset.transferValue);

        // Call the internal transfer function in MultiOwnerNFT
        _transfer(from, to, tokenId);

        emit AssetTransferred(from, to, tokenId, asset.transferValue);
    }

    // Allow the contract to receive ETH to fund transfers
    receive() external payable {}
}
