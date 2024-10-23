// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MONFT.sol";

contract Asset is MultiOwnerNFT, IAssets {
    
    struct Asset {
        uint256 AssetId;
        string assetName;
        string CID;
        uint256 size;
        uint256 totalValue;
    }

    mapping(uint256 => Asset) private _assets;

    // Events
    event AssetUploaded(uint256 indexed assetId, uint64 indexed size);
    event AssetTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed assetId
    );

    constructor() payable MultiOwnerNFT(msg.sender) {}

    
    function getCID(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "Asset: Token does not exist");
        return _assets[tokenId].CID;
    }

    function getAssetsTotalSupply() public view override returns (uint256) {
        return totalSupply();
    }

    function getAssetDetails(
        uint256 assetId
    ) public view override returns (AssetDetails memory) {
        require(_exists(assetId), "Asset: Asset does not exist");

        Asset storage asset = _assets[assetId];

        return
            AssetDetails({
                assetId: asset.assetId,
                assetName: asset.assetName,
                CID: asset.CID,
                size: asset.size,
                totalValue: asset.totalValue
            });
    }

    function upload(
        uint256 initValue,
        string memory assetName,
        string memory CID,
        uint64 size
    ) external returns (uint256) {
        uint256 assetId = mintToken();
        _assets[assetId] = Asset({
            assetId: assetId,
            assetName: assetName,
            CID: CID,
            size: size,
            totalValue: initValue
        });
        emit AssetUploaded(assetId, size);
        return assetId;
    }
}