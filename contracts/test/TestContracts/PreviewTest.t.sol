// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/NFTMetadata/MetadataNFT.sol";
import "./NFTPreview.sol";
import "../../src/Interfaces/ITroveManager.sol";
import "../../src/NFTMetadata/utils/FixedAssets.sol"; // For type reference
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MockAssetReader {
    // Mock asset reader that embeds real base64 SVGs for icons
    mapping(bytes4 => string) private _assets;

    constructor(string memory asf, string memory usdaf, string memory wbtc) {
        _assets[bytes4(keccak256("ASF"))] = asf;
        _assets[bytes4(keccak256("USDaf"))] = usdaf;
        _assets[bytes4(keccak256("wBTC"))] = wbtc;
    }

    function readAsset(bytes4 sig) external view returns (string memory) {
        return _assets[sig];
    }
}

contract DummyToken is IERC20Metadata {
    string private _symbol;
    constructor(string memory symbol_) { _symbol = symbol_; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return 18; }
    function totalSupply() external pure override returns (uint256) { return 0; }
    function balanceOf(address) external pure override returns (uint256) { return 0; }
    function transfer(address, uint256) external pure override returns (bool) { return false; }
    function allowance(address, address) external pure override returns (uint256) { return 0; }
    function approve(address, uint256) external pure override returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure override returns (bool) { return false; }
}

contract NFTPreviewTest is Test {
    NFTPreview nftPreview;
    MetadataNFT metadataNFT;

    address _collAddr;
    address _debtAddr;

    function setUp() public {
        // Load real asset base64 SVGs from files
        string memory asfData = vm.readFile("utils/assets/ASF-logo.txt");
        string memory usdafData = vm.readFile("utils/assets/USDaf.txt");
        string memory wbtcData = vm.readFile("utils/assets/wBTC.txt");

        // Deploy mock reader with real data
        MockAssetReader mockReader = new MockAssetReader(asfData, usdafData, wbtcData);
        FixedAssetReader assetReader = FixedAssetReader(address(mockReader));

        MetadataNFT implementation = new MetadataNFT();
        bytes memory initData = abi.encodeWithSelector(MetadataNFT.initialize.selector, assetReader);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        metadataNFT = MetadataNFT(address(proxy));

        DummyToken collToken = new DummyToken("wBTC");
        DummyToken debtToken = new DummyToken("USDaf");
        _collAddr = address(collToken);
        _debtAddr = address(debtToken);
        vm.label(_collAddr, "wBTC");
        vm.label(_debtAddr, "USDaf");

        nftPreview = new NFTPreview(address(metadataNFT));
    }

    function testPreviewNFT() public view {
        string memory result = nftPreview.previewNFT(
            1,
            address(0x456),
            _collAddr,
            _debtAddr,
            2 ether,
            50000 ether,
            0.05 ether,
            ITroveManager.Status.active
        );
        assertTrue(bytes(result).length > 0, "Metadata empty");
        console.log("Metadata:", result);
    }

    function testPreviewSVG() public view {
        string memory svgOutput = nftPreview.previewSVG(
            1,
            address(0x456),
            _collAddr,
            _debtAddr,
            2 ether,
            50000 ether,
            0.05 ether,
            ITroveManager.Status.active
        );
        assertTrue(bytes(svgOutput).length > 0, "SVG empty");
        console.log("SVG:", svgOutput);
    }
}
