// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Base.sol";

contract OraclesTest is Base {

    address public constant OWNER = 0xce352181C0f0350F1687e1a44c45BC9D96ee738B;

    uint256 public constant DIFF = 1e15; // 0.1%

    function setUp() override public {
        super.setUp();
    }

    function testMetaDataNftUpgrade() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[0];
        assertEq(metadataNFT.owner(), OWNER, "testMetaDataNftUpgrade: E0");
        assertEq(address(_contracts.metadataNFT), address(metadataNFT), "testMetaDataNftUpgrade: E1");
        assertEq(address(metadataNFT.assetReader()), address(initializedFixedAssetReader), "testMetaDataNftUpgrade: E2");

        address _newImpl = address(new MetadataNFT());
        vm.prank(OWNER);
        metadataNFT.upgradeToAndCall(_newImpl, "");
    }

    function testScrvUsdOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[0];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 1 ether, "testScrvUsdOracle: E0");
        assertFalse(_isOracleDownPrimary, "testScrvUsdOracle: E1");
        console2.log(_pricePrimary, "scrvUSD price primary");

        // Fallback
        vm.warp(block.timestamp + 1 days + 1 hours);
        (uint256 _priceFallback, bool _isOracleDownFallback) = _contracts.priceFeed.fetchPrice();
        assertGt(_priceFallback, 1 ether, "testScrvUsdOracle: E2");
        assertFalse(_isOracleDownFallback, "testScrvUsdOracle: E3");
        assertApproxEqRel(_priceFallback, _pricePrimary, DIFF, "testScrvUsdOracle: E4");
        console2.log(_priceFallback, "scrvUSD price fallback");

        // Shutdown fallback
        vm.prank(OWNER);
        scrvUsdFallbackOracle.disableFallback();
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _priceFallback, "testScrvUsdOracle: E5");
        assertTrue(_isOracleDownShutdown, "testScrvUsdOracle: E6");
    }

    function testSdaiOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[1];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 1 ether, "testSdaiOracle: E0");
        assertFalse(_isOracleDownPrimary, "testSdaiOracle: E1");
        console2.log(_pricePrimary, "sDAI price primary");

        // Shutdown
        vm.warp(block.timestamp + 2 hours);
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _pricePrimary, "testSdaiOracle: E2");
        assertTrue(_isOracleDownShutdown, "testSdaiOracle: E3");
    }

    function testSfrxEthOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[2];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 3000 ether, "testSfrxEthOracle: E0"); // if ETH goes below $3000 we're cooked anyways
        assertFalse(_isOracleDownPrimary, "testSfrxEthOracle: E1");
        console2.log(_pricePrimary, "sfrxETH price primary");

        // Fallback
        vm.warp(block.timestamp + 2 hours);
        (uint256 _priceFallback, bool _isOracleDownFallback) = _contracts.priceFeed.fetchPrice();
        assertGt(_priceFallback, 3000 ether, "testSfrxEthOracle: E2");
        assertFalse(_isOracleDownFallback, "testSfrxEthOracle: E3");
        assertApproxEqRel(_priceFallback, _pricePrimary, 2 * DIFF, "testSfrxEthOracle: E4"); // 0.2%
        console2.log(_priceFallback, "sfrxETH price fallback");

        // Shutdown fallback
        vm.prank(OWNER);
        sfrxEthFallbackOracle.disableFallback();
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _priceFallback, "testSfrxEthOracle: E5");
        assertTrue(_isOracleDownShutdown, "testSfrxEthOracle: E6");
    }

    function testTbtcOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[3];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 100_000 ether, "testTbtcOracle: E0");
        assertFalse(_isOracleDownPrimary, "testTbtcOracle: E1");
        console2.log(_pricePrimary, "tBTC price primary");

        // Fallback
        vm.warp(block.timestamp + 1 days + 1 hours);
        (uint256 _priceFallback, bool _isOracleDownFallback) = _contracts.priceFeed.fetchPrice();
        assertGt(_priceFallback, 100_000 ether, "testTbtcOracle: E2");
        assertFalse(_isOracleDownFallback, "testTbtcOracle: E3");
        assertApproxEqRel(_priceFallback, _pricePrimary, 3 * DIFF, "testTbtcOracle: E4"); // 0.3%
        console2.log(_priceFallback, "tBTC price fallback");

        // Shutdown fallback
        vm.prank(OWNER);
        tbtcFallbackOracle.disableFallback();
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _priceFallback, "testTbtcOracle: E5");
        assertTrue(_isOracleDownShutdown, "testTbtcOracle: E6");
    }

    function testWbtcOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[4];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 90_000 ether, "testWbtcOracle: E0");
        assertFalse(_isOracleDownPrimary, "testWbtcOracle: E1");
        console2.log(_pricePrimary, "wBTC price primary");

        // Fallback
        vm.warp(block.timestamp + 2 hours);
        (uint256 _priceFallback, bool _isOracleDownFallback) = _contracts.priceFeed.fetchPrice();
        assertGt(_priceFallback, 90_000 ether, "testWbtcOracle: E2");
        assertFalse(_isOracleDownFallback, "testWbtcOracle: E3");
        assertApproxEqRel(_priceFallback, _pricePrimary, 4 * DIFF, "testWbtcOracle: E4"); // 0.4%
        console2.log(_priceFallback, "wBTC price fallback");

        // Shutdown fallback
        vm.prank(OWNER);
        wbtcFallbackOracle.disableFallback();
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _priceFallback, "testWbtcOracle: E5");
        assertTrue(_isOracleDownShutdown, "testWbtcOracle: E6");
    }

    function testSusdsOracle() public {
        DeploymentResult memory _deployment = deploy();
        LiquityContractsTestnet memory _contracts = _deployment.contractsArray[5];

        // Primary
        (uint256 _pricePrimary, bool _isOracleDownPrimary) = _contracts.priceFeed.fetchPrice();
        assertGt(_pricePrimary, 1 ether, "testSusdsOracle: E0");
        assertFalse(_isOracleDownPrimary, "testSusdsOracle: E1");
        console2.log(_pricePrimary, "sUSD price primary");

        // Shutdown
        vm.warp(block.timestamp + 2 hours);
        (uint256 _priceShutdown, bool _isOracleDownShutdown) = _contracts.priceFeed.fetchPrice();
        assertEq(_priceShutdown, _pricePrimary, "testSusdsOracle: E2");
        assertTrue(_isOracleDownShutdown, "testSusdsOracle: E3");
    }

    function testRandomScenario() public {
        vm.startPrank(0xA024855a289D6947C0F5e0c402e6eA45F0bFe0e5);
        // CollateralRegistry _collateralRegistry = CollateralRegistry(0xd5D9C0D32890Be92D7680B65E785e4A95C366a35);
        // StabilityPool _stabilityPool = StabilityPool(0x4eE3751E853c550B8De2fCFA05bC41762970892A);
        // _stabilityPool.withdrawFromSP(type(uint256).max, true);
        // IBoldToken _boldToken = _collateralRegistry.boldToken();
        // uint256 attemptedBoldAmount = _boldToken.balanceOf(address(0xA024855a289D6947C0F5e0c402e6eA45F0bFe0e5));
        // uint256 maxFeePct = _collateralRegistry.getRedemptionRateForRedeemedAmount(attemptedBoldAmount);
        // _collateralRegistry.redeemCollateral(attemptedBoldAmount, 10, maxFeePct);
        BorrowerOperations _borrowerOperations = BorrowerOperations(0xdA8d4691C9C82c1c6635222195B669CF7E00A7a4); // sfrxeth
        // _borrowerOperations.withdrawColl(46343158787079786419892575071729800707009996652493280215780828700039003595742, 1 ether);
        // _borrowerOperations.adjustZombieTrove(
        //     46343158787079786419892575071729800707009996652493280215780828700039003595742,
        //     1 ether,
        //     false,
        //     0,
        //     false,
        //     0,
        //     0,
        //     0
        // );
        _borrowerOperations.closeTrove(46343158787079786419892575071729800707009996652493280215780828700039003595742);
    }
}
// 473 08428922 1147607425
// 08377496 2578379913