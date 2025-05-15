// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import "forge-std/Script.sol";
//import "forge-std/StdAssertions.sol";
import "src/NFTMetadata/MetadataNFT.sol";
import "src/NFTMetadata/utils/Utils.sol";
import "src/NFTMetadata/utils/FixedAssets.sol";

interface ISimpleProxyFactory {
    function deployDeterministic(bytes32 salt, address initialImplementation, bytes memory initCall) external payable returns (address proxy);
    function predictDeterministicAddress(bytes32 salt) external view returns (address addr);
}

contract MetadataDeployment is Script /* , StdAssertions */ {
    struct File {
        bytes data;
        uint256 start;
        uint256 end;
    }

    mapping(bytes4 => File) public files;

    address public pointer;

    FixedAssetReader public initializedFixedAssetReader;

    function deployMetadata(bytes32 _salt) public returns (MetadataNFT) {
        _loadFiles();
        _storeFile();
        _deployFixedAssetReader(_salt);

        MetadataNFT metadataNFT = _deployMetadata();

        return metadataNFT;
    }

    function _deployMetadata() internal returns (MetadataNFT _metadataNFT) {
        ISimpleProxyFactory _factory = ISimpleProxyFactory(0x156e0382068C3f96a629f51dcF99cEA5250B9eda);

        uint256 _pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address _deployer = vm.addr(_pk);

        // Set salt values
        bytes32 _salt = bytes32(abi.encodePacked(_deployer, uint96(0x0123456)));

        // Sanity check
        address _proxyAddr = _factory.predictDeterministicAddress(_salt);
        require(_proxyAddr != address(0), "!ADDRESS");

        // Deploy implementation
        address __implementation = address(new MetadataNFT());

        // Deploy proxy
        address _proxy = _factory.deployDeterministic(
            _salt,
            __implementation,
            ""
        );
        require(_proxy == _proxyAddr, "!PREDICT");

        _metadataNFT = MetadataNFT(_proxy);
        _metadataNFT.initialize(initializedFixedAssetReader);
    }

    function _loadFiles() internal {
        string memory root = string.concat(vm.projectRoot(), "/utils/assets/");
        uint256 offset;

        // Debt token (USDaf replacing BOLD)
        offset = _addAsset("USDaf", "USDaf.txt", root, offset);

        // BTC-related collaterals
        offset = _addAsset("wBTC", "wBTC.txt", root, offset);
        offset = _addAsset("tBTC", "tBTC.txt", root, offset);
        offset = _addAsset("cbBTC", "cbBTC.txt", root, offset);

        // USD-related collaterals
        offset = _addAsset("sUSDE", "sUSDE.txt", root, offset);
        offset = _addAsset("sUSDS", "sUSDS.txt", root, offset);
        offset = _addAsset("scrvUSD", "scrvUSD.txt", root, offset);
        offset = _addAsset("sfrxUSD", "sfrxUSD.txt", root, offset);
        offset = _addAsset("sDAI", "sDAI.txt", root, offset);

        // Font
        _addAsset("geist", "DM_Sans.txt", root, offset);
    }

    /**
     * @dev Reads an asset file from disk, stores it in the `files` mapping, and returns the next offset.
     * @param _sig      Asset signature (e.g., "wBTC", "USDaf") used as the mapping key.
     * @param _fileName Exact filename on disk (including extension).
     * @param _root     Base directory path for all asset files.
     * @param _offset   Current write offset into the concatenated data blob.
     * @return nextOffset The offset immediately after the written data.
     */
    function _addAsset(
        string memory _sig,
        string memory _fileName,
        string memory _root,
        uint256 _offset
    ) internal returns (uint256 nextOffset) {
        bytes memory data = bytes(vm.readFile(string.concat(_root, _fileName)));
        files[bytes4(keccak256(bytes(_sig)))] = File(data, _offset, _offset + data.length);
        return _offset + data.length;
    }

    function _storeFile() internal {
        // Concatenate all asset data in the order expected by readers
        bytes memory data;
        bytes4[10] memory sigOrder = [
            bytes4(keccak256("USDaf")),
            bytes4(keccak256("wBTC")),
            bytes4(keccak256("tBTC")),
            bytes4(keccak256("cbBTC")),
            bytes4(keccak256("sUSDE")),
            bytes4(keccak256("sUSDS")),
            bytes4(keccak256("scrvUSD")),
            bytes4(keccak256("sfrxUSD")),
            bytes4(keccak256("sDAI")),
            bytes4(keccak256("geist"))
        ];

        for (uint256 i; i < sigOrder.length; ++i) {
            data = bytes.concat(data, files[sigOrder[i]].data);
        }

        pointer = SSTORE2.write(data);
    }

    function _deployFixedAssetReader(bytes32 _salt) internal {
        // Prepare the same signature order used in _storeFile()
        bytes4[10] memory sigOrder = [
            bytes4(keccak256("USDaf")),
            bytes4(keccak256("wBTC")),
            bytes4(keccak256("tBTC")),
            bytes4(keccak256("cbBTC")),
            bytes4(keccak256("sUSDE")),
            bytes4(keccak256("sUSDS")),
            bytes4(keccak256("scrvUSD")),
            bytes4(keccak256("sfrxUSD")),
            bytes4(keccak256("sDAI")),
            bytes4(keccak256("geist"))
        ];

        bytes4[] memory sigs = new bytes4[](sigOrder.length);
        FixedAssetReader.Asset[] memory assets = new FixedAssetReader.Asset[](sigOrder.length);

        for (uint256 i; i < sigOrder.length; ++i) {
            bytes4 sig = sigOrder[i];
            sigs[i] = sig;
            assets[i] = FixedAssetReader.Asset(
                uint128(files[sig].start),
                uint128(files[sig].end)
            );
        }

        initializedFixedAssetReader = new FixedAssetReader{salt: _salt}(pointer, sigs, assets);
    }
}
