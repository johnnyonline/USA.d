//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "lib/Solady/src/utils/SSTORE2.sol";
import "./utils/JSON.sol";

import "./utils/baseSVG.sol";
import "./utils/bauhaus.sol";

import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../Dependencies/Ownable.sol";

import {ITroveManager} from "src/Interfaces/ITroveManager.sol";

interface IMetadataNFT {
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

    function uri(TroveData memory _troveData) external view returns (string memory);
}

contract MetadataNFT is IMetadataNFT, Ownable {
    FixedAssetReader public assetReader;

    event AssetReaderUpdated(address indexed _assetReader);

    address public constant OWNER = 0x263b03BbA0BbbC320928B6026f5eAAFAD9F1ddeb;

    string public constant name = "USA.d Trove";
    string public constant description = "USA.d Trove position";

    constructor(FixedAssetReader _assetReader) Ownable(OWNER) {
        assetReader = _assetReader;
    }

    function updateAssetReader(FixedAssetReader _assetReader) external onlyOwner {
        assetReader = _assetReader;
        emit AssetReaderUpdated(address(_assetReader));
    }

    function uri(TroveData memory _troveData) public view returns (string memory) {
        string memory attr = attributes(_troveData);
        return json.formattedMetadata(name, description, renderSVGImage(_troveData), attr);
    }

    function renderSVGImage(TroveData memory _troveData) internal view returns (string memory) {
        return svg._svg(
            baseSVG._svgProps(),
            string.concat(
                baseSVG._baseElements(assetReader),
                bauhaus._bauhaus(IERC20Metadata(_troveData._collToken).symbol(), _troveData._tokenId),
                dynamicTextComponents(_troveData)
            )
        );
    }

    function attributes(TroveData memory _troveData) public pure returns (string memory) {
        //include: collateral token address, collateral amount, debt token address, debt amount, interest rate, status
        return string.concat(
            '[{"trait_type": "Collateral Token", "value": "',
            LibString.toHexString(_troveData._collToken),
            '"}, {"trait_type": "Collateral Amount", "value": "',
            LibString.toString(_troveData._collAmount),
            '"}, {"trait_type": "Debt Token", "value": "',
            LibString.toHexString(_troveData._boldToken),
            '"}, {"trait_type": "Debt Amount", "value": "',
            LibString.toString(_troveData._debtAmount),
            '"}, {"trait_type": "Interest Rate", "value": "',
            LibString.toString(_troveData._interestRate),
            '"}, {"trait_type": "Status", "value": "',
            _status2Str(_troveData._status),
            '"} ]'
        );
    }

    function dynamicTextComponents(TroveData memory _troveData) public view returns (string memory) {
        string memory id = LibString.toHexString(_troveData._tokenId);
        id = string.concat(LibString.slice(id, 0, 6), "...", LibString.slice(id, 38, 42));

        return string.concat(
            baseSVG._formattedIdEl(id),
            baseSVG._formattedAddressEl(_troveData._owner),
            baseSVG._collLogo(IERC20Metadata(_troveData._collToken).symbol(), assetReader),
            baseSVG._statusEl(_status2Str(_troveData._status)),
            baseSVG._dynamicTextEls(_troveData._debtAmount, _troveData._collAmount, _troveData._interestRate)
        );
    }

    function _status2Str(ITroveManager.Status status) internal pure returns (string memory) {
        if (status == ITroveManager.Status.active) return "Active";
        if (status == ITroveManager.Status.closedByOwner) return "Closed";
        if (status == ITroveManager.Status.closedByLiquidation) return "Liquidated";
        if (status == ITroveManager.Status.zombie) return "Below Min Debt";
        return "";
    }
}
