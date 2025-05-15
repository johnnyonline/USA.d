// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../../../src/NFTMetadata/MetadataNFT.sol";
import "../../../src/Interfaces/ITroveManager.sol";
import "../../../src/NFTMetadata/MetadataNFT.sol" as IMetadataNFTContract;
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// This contract is for previewing NFTs as they would be rendered by MetadataNFT.sol
contract NFTPreview {
    MetadataNFT public metadataNFT;

    // Define a local struct to mirror TroveData from MetadataNFT for compatibility
    struct TroveData {
        uint256 _tokenId;
        address _owner;
        address _collToken;
        address _boldToken;
        uint256 _collAmount;
        uint256 _debtAmount;
        uint256 _interestRate;
        ITroveManager.Status _status;
    }

    constructor(address _metadataNFT) {
        metadataNFT = MetadataNFT(_metadataNFT);
    }

    function previewNFT(
        uint256 tokenId,
        address owner,
        address collToken, // Use addresses representing supported collaterals like wBTC, tBTC, cbBTC, sUSDe, etc.
        address boldToken, // Should represent USDaf as the debt token
        uint256 collAmount, // Set realistic amounts based on collateral type (e.g., lower for BTC, higher for USD)
        uint256 debtAmount, // Realistic debt in USDaf
        uint256 interestRate, // Realistic interest rate, e.g., 0.05 ether for 5%
        ITroveManager.Status status
    ) external view returns (string memory) {
        TroveData memory localData = TroveData({
            _tokenId: tokenId,
            _owner: owner,
            _collToken: collToken,
            _boldToken: boldToken,
            _collAmount: collAmount,
            _debtAmount: debtAmount,
            _interestRate: interestRate,
            _status: status
        });

        // Explicitly construct IMetadataNFT.TroveData to avoid type mismatch
        IMetadataNFTContract.IMetadataNFT.TroveData memory troveData = IMetadataNFTContract.IMetadataNFT.TroveData({
            _tokenId: localData._tokenId,
            _owner: localData._owner,
            _collToken: localData._collToken,
            _boldToken: localData._boldToken,
            _collAmount: localData._collAmount,
            _debtAmount: localData._debtAmount,
            _interestRate: localData._interestRate,
            _status: localData._status
        });

        return metadataNFT.uri(troveData);
    }

    function previewSVG(
        uint256 tokenId,
        address owner,
        address collToken, // Use addresses representing supported collaterals like wBTC, tBTC, cbBTC, sUSDe, etc.
        address boldToken, // Should represent USDaf as the debt token
        uint256 collAmount, // Set realistic amounts based on collateral type (e.g., lower for BTC, higher for USD)
        uint256 debtAmount, // Realistic debt in USDaf
        uint256 interestRate, // Realistic interest rate, e.g., 0.05 ether for 5%
        ITroveManager.Status status
    ) external view returns (string memory) {
        TroveData memory localData = TroveData({
            _tokenId: tokenId,
            _owner: owner,
            _collToken: collToken,
            _boldToken: boldToken,
            _collAmount: collAmount,
            _debtAmount: debtAmount,
            _interestRate: interestRate,
            _status: status
        });

        // Explicitly construct IMetadataNFT.TroveData to avoid type mismatch
        IMetadataNFTContract.IMetadataNFT.TroveData memory troveData = IMetadataNFTContract.IMetadataNFT.TroveData({
            _tokenId: localData._tokenId,
            _owner: localData._owner,
            _collToken: localData._collToken,
            _boldToken: localData._boldToken,
            _collAmount: localData._collAmount,
            _debtAmount: localData._debtAmount,
            _interestRate: localData._interestRate,
            _status: localData._status
        });

        return metadataNFT.renderSVGImage(troveData);
    }
}
