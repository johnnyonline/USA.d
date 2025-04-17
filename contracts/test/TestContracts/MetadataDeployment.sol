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
        string memory basePath = string.concat(vm.projectRoot(), "/contracts/src/NFTMetadata/utils/SVGsBase64/");
        uint256 offset = 0;

        // BOLD logo
        bytes memory boldFile = bytes(vm.readFile(string.concat(basePath, "USA.d.txt")));
        File memory bold = File(boldFile, offset, offset + boldFile.length);
        offset += boldFile.length;
        files[bytes4(keccak256("USA.d"))] = bold;

        // tBTC logo
        bytes memory tbtcFile = bytes(vm.readFile(string.concat(basePath, "tBTC.txt")));
        File memory tbtc = File(tbtcFile, offset, offset + tbtcFile.length);
        offset += tbtcFile.length;
        files[bytes4(keccak256("tBTC"))] = tbtc;

        // wBTC logo
        bytes memory wbtcFile = bytes(vm.readFile(string.concat(basePath, "wBTC.txt")));
        File memory wbtc = File(wbtcFile, offset, offset + wbtcFile.length);
        offset += wbtcFile.length;
        files[bytes4(keccak256("wBTC"))] = wbtc;

        // cbBTC logo
        bytes memory cbbtcFile = bytes(vm.readFile(string.concat(basePath, "cbBTC.txt")));
        File memory cbbtc = File(cbbtcFile, offset, offset + cbbtcFile.length);
        offset += cbbtcFile.length;
        files[bytes4(keccak256("cbBTC"))] = cbbtc;

        // sUSDS logo
        bytes memory susdsFile = bytes(vm.readFile(string.concat(basePath, "sUSDS.txt")));
        File memory susds = File(susdsFile, offset, offset + susdsFile.length);
        offset += susdsFile.length;
        files[bytes4(keccak256("sUSDS"))] = susds;

        // sfrxUSD logo
        bytes memory sfrxusdFile = bytes(vm.readFile(string.concat(basePath, "sfrxUSD.txt")));
        File memory sfrxusd = File(sfrxusdFile, offset, offset + sfrxusdFile.length);
        offset += sfrxusdFile.length;
        files[bytes4(keccak256("sfrxUSD"))] = sfrxusd;

        // sDAI logo
        bytes memory sdaiFile = bytes(vm.readFile(string.concat(basePath, "sDAI.txt")));
        File memory sdai = File(sdaiFile, offset, offset + sdaiFile.length);
        offset += sdaiFile.length;
        files[bytes4(keccak256("sDAI"))] = sdai;

        // scrvUSD logo
        bytes memory scrvusdFile = bytes(vm.readFile(string.concat(basePath, "scrvUSD.txt")));
        File memory scrvusd = File(scrvusdFile, offset, offset + scrvusdFile.length);
        offset += scrvusdFile.length;
        files[bytes4(keccak256("scrvUSD"))] = scrvusd;

        // DM Sans font
        bytes memory dmSansFile = bytes(vm.readFile(string.concat(basePath, "DM_Sans.txt")));
        File memory dmSans = File(dmSansFile, offset, offset + dmSansFile.length);
        offset += dmSansFile.length;
        files[bytes4(keccak256("dmSans"))] = dmSans;

        // Leverage logo (ASF-logo)
        bytes memory leverageFile = bytes(vm.readFile(string.concat(basePath, "ASF-logo.txt")));
        File memory leverage = File(leverageFile, offset, offset + leverageFile.length);
        offset += leverageFile.length;
        files[bytes4(keccak256("leverageLogo"))] = leverage;

        // sfrxETH logo
        bytes memory sfrxethFile = bytes(vm.readFile(string.concat(basePath, "sfrxETH.txt")));
        File memory sfrxeth = File(sfrxethFile, offset, offset + sfrxethFile.length);
        offset += sfrxethFile.length;
        files[bytes4(keccak256("sfrxETH"))] = sfrxeth;
    }

    function _storeFile() internal {
        bytes memory data = bytes.concat(
            files[bytes4(keccak256("USA.d"))].data,
            files[bytes4(keccak256("tBTC"))].data,
            files[bytes4(keccak256("wBTC"))].data,
            files[bytes4(keccak256("cbBTC"))].data,
            files[bytes4(keccak256("sUSDS"))].data,
            files[bytes4(keccak256("sfrxUSD"))].data,
            files[bytes4(keccak256("sDAI"))].data,
            files[bytes4(keccak256("scrvUSD"))].data,
            files[bytes4(keccak256("dmSans"))].data,
            files[bytes4(keccak256("leverageLogo"))].data,
            files[bytes4(keccak256("sfrxETH"))].data
        );

        pointer = SSTORE2.write(data);
    }

    function _deployFixedAssetReader(bytes32 _salt) internal {
        bytes4[] memory sigs = new bytes4[](11);
        sigs[0] = bytes4(keccak256("USA.d"));
        sigs[1] = bytes4(keccak256("tBTC"));
        sigs[2] = bytes4(keccak256("wBTC"));
        sigs[3] = bytes4(keccak256("cbBTC"));
        sigs[4] = bytes4(keccak256("sUSDS"));
        sigs[5] = bytes4(keccak256("sfrxUSD"));
        sigs[6] = bytes4(keccak256("sDAI"));
        sigs[7] = bytes4(keccak256("scrvUSD"));
        sigs[8] = bytes4(keccak256("dmSans"));
        sigs[9] = bytes4(keccak256("leverageLogo"));
        sigs[10] = bytes4(keccak256("sfrxETH"));

        FixedAssetReader.Asset[] memory FixedAssets = new FixedAssetReader.Asset[](11);
        FixedAssets[0] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("USA.d"))].start), 
            uint128(files[bytes4(keccak256("USA.d"))].end)
        );
        FixedAssets[1] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("tBTC"))].start), 
            uint128(files[bytes4(keccak256("tBTC"))].end)
        );
        FixedAssets[2] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("wBTC"))].start), 
            uint128(files[bytes4(keccak256("wBTC"))].end)
        );
        FixedAssets[3] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("cbBTC"))].start), 
            uint128(files[bytes4(keccak256("cbBTC"))].end)
        );
        FixedAssets[4] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("sUSDS"))].start), 
            uint128(files[bytes4(keccak256("sUSDS"))].end)
        );
        FixedAssets[5] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("sfrxUSD"))].start), 
            uint128(files[bytes4(keccak256("sfrxUSD"))].end)
        );
        FixedAssets[6] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("sDAI"))].start), 
            uint128(files[bytes4(keccak256("sDAI"))].end)
        );
        FixedAssets[7] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("scrvUSD"))].start), 
            uint128(files[bytes4(keccak256("scrvUSD"))].end)
        );
        FixedAssets[8] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("dmSans"))].start), 
            uint128(files[bytes4(keccak256("dmSans"))].end)
        );
        FixedAssets[9] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("leverageLogo"))].start), 
            uint128(files[bytes4(keccak256("leverageLogo"))].end)
        );
        FixedAssets[10] = FixedAssetReader.Asset(
            uint128(files[bytes4(keccak256("sfrxETH"))].start), 
            uint128(files[bytes4(keccak256("sfrxETH"))].end)
        );

        initializedFixedAssetReader = new FixedAssetReader{salt: _salt}(pointer, sigs, FixedAssets);
    }
}
