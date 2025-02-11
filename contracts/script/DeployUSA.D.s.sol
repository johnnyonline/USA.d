// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {StdCheats} from "forge-std/StdCheats.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {StringFormatting} from "test/Utils/StringFormatting.sol";
import {Accounts} from "test/TestContracts/Accounts.sol";
import {ETH_GAS_COMPENSATION} from "src/Dependencies/Constants.sol";
import {IBorrowerOperations} from "src/Interfaces/IBorrowerOperations.sol";
import "src/AddressesRegistry.sol";
import "src/ActivePool.sol";
import "src/BoldToken.sol";
import "src/BorrowerOperations.sol";
import "src/CollSurplusPool.sol";
import "src/DefaultPool.sol";
import "src/GasPool.sol";
import "src/HintHelpers.sol";
import "src/MultiTroveGetter.sol";
import "src/SortedTroves.sol";
import "src/TroveManager.sol";
import "src/StabilityPool.sol";
import "src/TroveNFT.sol";
import "src/CollateralRegistry.sol";
import {MetadataDeployment, MetadataNFT} from "test/TestContracts/MetadataDeployment.sol";
import "src/Zappers/WETHZapper.sol";
import "src/Zappers/GasCompZapper.sol";
import "src/Zappers/LeverageLSTZapper.sol";
import "src/Zappers/LeverageWETHZapper.sol";
import "src/Zappers/Modules/Exchanges/HybridCurveUniV3ExchangeHelpers.sol";
import {BalancerFlashLoan} from "src/Zappers/Modules/FlashLoans/BalancerFlashLoan.sol";
import "src/Zappers/Modules/Exchanges/Curve/ICurveStableswapNGFactory.sol";
import "src/Zappers/Modules/Exchanges/UniswapV3/ISwapRouter.sol";
import "src/Zappers/Modules/Exchanges/UniswapV3/IQuoterV2.sol";
import "src/Zappers/Modules/Exchanges/UniswapV3/IUniswapV3Pool.sol";
import "src/Zappers/Modules/Exchanges/UniswapV3/IUniswapV3Factory.sol";
import "src/Zappers/Modules/Exchanges/UniswapV3/INonfungiblePositionManager.sol";
import "src/Zappers/Modules/Exchanges/HybridCurveUniV3Exchange.sol";
import "forge-std/console2.sol";
import {WETHPriceFeed} from "src/PriceFeeds/WETHPriceFeed.sol";
import {IWETH} from "src/Interfaces/IWETH.sol";
import {InterestRouter} from "src/InterestRouter.sol";
import {ScrvUsdOracle} from "src/PriceFeeds/USA.D/ScrvUsdOracle.sol";
import {SdaiOracle} from "src/PriceFeeds/USA.D/SdaiOracle.sol";
import {SfrxEthOracle} from "src/PriceFeeds/USA.D/SfrxEthOracle.sol";
import {TbtcOracle} from "src/PriceFeeds/USA.D/TbtcOracle.sol";
import {WbtcOracle} from "src/PriceFeeds/USA.D/WbtcOracle.sol";
import {SusdsOracle} from "src/PriceFeeds/USA.D/SusdsOracle.sol";
import {CrvUsdFallbackOracle} from "src/PriceFeeds/USA.D/Fallbacks/CrvUsdFallbackOracle.sol";
import {SfrxEthFallbackOracle} from "src/PriceFeeds/USA.D/Fallbacks/SfrxEthFallbackOracle.sol";
import {TbtcFallbackOracle} from "src/PriceFeeds/USA.D/Fallbacks/TbtcFallbackOracle.sol";
import {WbtcFallbackOracle} from "src/PriceFeeds/USA.D/Fallbacks/WbtcFallbackOracle.sol";
import {USAZapper} from "src/Zappers/USAZapper.sol";
import {WrappedWbtc} from "src/WrappedWbtc.sol";
import {WbtcZapper} from "src/Zappers/WbtcZapper.sol";

// ---- Usage ----

// deploy:
// forge script src/scripts/DeployUSA.D.s.sol:DeployUSADScript --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

contract DeployUSADScript is StdCheats, MetadataDeployment {
    using Strings for *;
    using StringFormatting for *;

    ICurveStableswapNGFactory constant curveStableswapFactory =
        ICurveStableswapNGFactory(0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf);
    uint128 constant BOLD_TOKEN_INDEX = 0;
    uint128 constant USDC_INDEX = 1;

    bytes32 SALT;
    address deployer;

    uint256 lastTroveIndex;

    CrvUsdFallbackOracle scrvUsdFallbackOracle;
    SfrxEthFallbackOracle sfrxEthFallbackOracle;
    TbtcFallbackOracle tbtcFallbackOracle;
    WbtcFallbackOracle wbtcFallbackOracle;

    struct LiquityContractsTestnet {
        IAddressesRegistry addressesRegistry;
        IActivePool activePool;
        IBorrowerOperations borrowerOperations;
        ICollSurplusPool collSurplusPool;
        IDefaultPool defaultPool;
        ISortedTroves sortedTroves;
        IStabilityPool stabilityPool;
        ITroveManager troveManager;
        ITroveNFT troveNFT;
        MetadataNFT metadataNFT;
        WETHPriceFeed priceFeed;
        GasPool gasPool;
        IInterestRouter interestRouter;
        IERC20Metadata collToken;
        address zapper;
        GasCompZapper gasCompZapper;
        ILeverageZapper leverageZapper;
        address oracle;
    }

    struct LiquityContractAddresses {
        address activePool;
        address borrowerOperations;
        address collSurplusPool;
        address defaultPool;
        address sortedTroves;
        address stabilityPool;
        address troveManager;
        address troveNFT;
        address metadataNFT;
        address priceFeed;
        address gasPool;
        address interestRouter;
    }

    struct Zappers {
        WETHZapper wethZapper;
        GasCompZapper gasCompZapper;
    }

    struct TroveManagerParams {
        uint256 CCR;
        uint256 MCR;
        uint256 SCR;
        uint256 LIQUIDATION_PENALTY_SP;
        uint256 LIQUIDATION_PENALTY_REDISTRIBUTION;
    }

    struct DeploymentVarsTestnet {
        uint256 numCollaterals;
        IERC20Metadata[] collaterals;
        IAddressesRegistry[] addressesRegistries;
        ITroveManager[] troveManagers;
        LiquityContractsTestnet contracts;
        bytes bytecode;
        address boldTokenAddress;
        uint256 i;
    }

    struct DeploymentResult {
        LiquityContractsTestnet[] contractsArray;
        ICollateralRegistry collateralRegistry;
        IBoldToken boldToken;
        IERC20 usdc;
        ICurveStableswapNGPool usdcCurvePool;
        HintHelpers hintHelpers;
        MultiTroveGetter multiTroveGetter;
        IExchangeHelpers exchangeHelpers;
    }

    MetadataNFT metadataNFT;
    WrappedWbtc wrappedWbtc;

    uint256 constant _24_HOURS = 86400;
    uint256 constant _1_HOUR = 3600;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant SCRVUSD = 0x0655977FEb2f289A4aB78af67BAB0d17aAb84367;
    address constant SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
    address constant SFRXETH = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address constant TBTC = 0x18084fbA666a33d37592fA2633fD49a74DD93a88;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant SUSDS = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;

    function run() public returns (DeploymentResult memory deployed) {
        SALT = keccak256(abi.encodePacked(block.timestamp));

        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        console2.log(deployer, "deployer");
        console2.log(deployer.balance, "deployer balance");

        TroveManagerParams[] memory troveManagerParamsArray = new TroveManagerParams[](6);
        troveManagerParamsArray[0] = TroveManagerParams(120e16, 110e16, 105e16, 5e16, 10e16); // scrvUSD
        troveManagerParamsArray[1] = TroveManagerParams(120e16, 110e16, 105e16, 5e16, 10e16); // sDAI
        troveManagerParamsArray[2] = TroveManagerParams(150e16, 120e16, 110e16, 5e16, 10e16); // sfrxETH
        troveManagerParamsArray[3] = TroveManagerParams(150e16, 125e16, 115e16, 5e16, 10e16); // tBTC
        troveManagerParamsArray[4] = TroveManagerParams(150e16, 120e16, 110e16, 5e16, 10e16); // WBTC
        troveManagerParamsArray[5] = TroveManagerParams(120e16, 110e16, 105e16, 5e16, 10e16); // sUSDS


        string[] memory collNames = new string[](6);
        string[] memory collSymbols = new string[](6);
        collNames[0] = "Savings crvUSD";
        collNames[1] = "Savings DAI";
        collNames[2] = "Staked Frax Ether";
        collNames[3] = "tBTC v2";
        collNames[4] = "Wrapped WBTC";
        collNames[5] = "Savings USDS";
        collSymbols[0] = "scrvUSD";
        collSymbols[1] = "sDAI";
        collSymbols[2] = "sfrxETH";
        collSymbols[3] = "tBTC";
        collSymbols[4] = "WBTC18";
        collSymbols[5] = "sUSDS";

        wrappedWbtc = new WrappedWbtc();

        deployed =
            _deployAndConnectContracts(troveManagerParamsArray, collNames, collSymbols);

        vm.stopBroadcast();

        string memory governanceManifest = "";
        vm.writeFile("deployment-manifest.json", _getManifestJson(deployed, governanceManifest));
    }

    // See: https://solidity-by-example.org/app/create2/
    function getBytecode(bytes memory _creationCode, address _addressesRegistry) public pure returns (bytes memory) {
        return abi.encodePacked(_creationCode, abi.encode(_addressesRegistry));
    }

    function _deployAndConnectContracts(
        TroveManagerParams[] memory troveManagerParamsArray,
        string[] memory _collNames,
        string[] memory _collSymbols
    ) internal returns (DeploymentResult memory r) {
        assert(_collNames.length == troveManagerParamsArray.length);
        assert(_collSymbols.length == troveManagerParamsArray.length);

        DeploymentVarsTestnet memory vars;
        vars.numCollaterals = troveManagerParamsArray.length;
        // Deploy Bold
        vars.bytecode = abi.encodePacked(type(BoldToken).creationCode, abi.encode(deployer));
        vars.boldTokenAddress = vm.computeCreate2Address(SALT, keccak256(vars.bytecode));
        r.boldToken = new BoldToken{salt: SALT}(deployer);
        assert(address(r.boldToken) == vars.boldTokenAddress);

        // USDC and USDC-BOLD pool
        r.usdc = IERC20(USDC);
        r.usdcCurvePool = _deployCurveBoldUsdcPool(r.boldToken, r.usdc);

        r.contractsArray = new LiquityContractsTestnet[](vars.numCollaterals);
        vars.collaterals = new IERC20Metadata[](vars.numCollaterals);
        vars.addressesRegistries = new IAddressesRegistry[](vars.numCollaterals);
        vars.troveManagers = new ITroveManager[](vars.numCollaterals);

        vars.collaterals[0] = IERC20Metadata(SCRVUSD);
        vars.collaterals[1] = IERC20Metadata(SDAI);
        vars.collaterals[2] = IERC20Metadata(SFRXETH);
        vars.collaterals[3] = IERC20Metadata(TBTC);
        vars.collaterals[4] = IERC20Metadata(wrappedWbtc);
        vars.collaterals[5] = IERC20Metadata(SUSDS);


        // Deploy AddressesRegistries and get TroveManager addresses
        for (vars.i = 0; vars.i < vars.numCollaterals; vars.i++) {
            (IAddressesRegistry addressesRegistry, address troveManagerAddress) =
                _deployAddressesRegistry(troveManagerParamsArray[vars.i]);
            vars.addressesRegistries[vars.i] = addressesRegistry;
            vars.troveManagers[vars.i] = ITroveManager(troveManagerAddress);
        }

        r.collateralRegistry = new CollateralRegistry(r.boldToken, vars.collaterals, vars.troveManagers);
        r.hintHelpers = new HintHelpers(r.collateralRegistry);
        r.multiTroveGetter = new MultiTroveGetter(r.collateralRegistry);

        metadataNFT = deployMetadata(SALT);

        // Deploy per-branch contracts for each branch
        for (vars.i = 0; vars.i < vars.numCollaterals; vars.i++) {
            vars.contracts = _deployAndConnectCollateralContractsMainnet(
                vars.collaterals[vars.i],
                r.boldToken,
                r.collateralRegistry,
                vars.addressesRegistries[vars.i],
                address(vars.troveManagers[vars.i]),
                r.hintHelpers,
                r.multiTroveGetter
            );
            r.contractsArray[vars.i] = vars.contracts;
        }

        r.boldToken.setCollateralRegistry(address(r.collateralRegistry));
    }

    function _deployAddressesRegistry(TroveManagerParams memory _troveManagerParams)
        internal
        returns (IAddressesRegistry, address)
    {
        IAddressesRegistry addressesRegistry = new AddressesRegistry(
            deployer,
            _troveManagerParams.CCR,
            _troveManagerParams.MCR,
            _troveManagerParams.SCR,
            _troveManagerParams.LIQUIDATION_PENALTY_SP,
            _troveManagerParams.LIQUIDATION_PENALTY_REDISTRIBUTION
        );
        address troveManagerAddress = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(TroveManager).creationCode, address(addressesRegistry)))
        );

        return (addressesRegistry, troveManagerAddress);
    }

    function _deployAndConnectCollateralContractsMainnet(
        IERC20Metadata _collToken,
        IBoldToken _boldToken,
        ICollateralRegistry _collateralRegistry,
        IAddressesRegistry _addressesRegistry,
        address _troveManagerAddress,
        IHintHelpers _hintHelpers,
        IMultiTroveGetter _multiTroveGetter
    ) internal returns (LiquityContractsTestnet memory contracts) {
        LiquityContractAddresses memory addresses;
        contracts.collToken = _collToken;

        // Deploy all contracts, using testers for TM and PriceFeed
        contracts.addressesRegistry = _addressesRegistry;

        // Deploy Metadata
        contracts.metadataNFT = metadataNFT;
        addresses.metadataNFT = address(metadataNFT);

        addresses.borrowerOperations = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(BorrowerOperations).creationCode, address(contracts.addressesRegistry)))
        );

        uint256 _stalenessThreshold;
        if (address(_collToken) == SCRVUSD) {
            _stalenessThreshold = _24_HOURS; // CL crvUSD/USD heartbeat. Fallback is block.timestamp
            CrvUsdFallbackOracle fallbackOracle = new CrvUsdFallbackOracle();
            contracts.oracle = address(new ScrvUsdOracle(address(fallbackOracle)));
            scrvUsdFallbackOracle = fallbackOracle;
        } else if (address(_collToken) == SDAI) {
            _stalenessThreshold = _1_HOUR; // CL DAI/USD heartbeat. No Fallback
            contracts.oracle = address(new SdaiOracle());
        } else if (address(_collToken) == SFRXETH) {
            _stalenessThreshold = _1_HOUR; // CL ETH/USD heartbeat. Fallback is block.timestamp
            SfrxEthFallbackOracle fallbackOracle = new SfrxEthFallbackOracle();
            contracts.oracle = address(new SfrxEthOracle(address(fallbackOracle)));
            sfrxEthFallbackOracle = fallbackOracle;
        } else if (address(_collToken) == TBTC) {
            _stalenessThreshold = _24_HOURS; // CL tBTC/USD heartbeat. Fallback is block.timestamp
            TbtcFallbackOracle fallbackOracle = new TbtcFallbackOracle();
            contracts.oracle = address(new TbtcOracle(address(fallbackOracle)));
            tbtcFallbackOracle = fallbackOracle;
        } else if (address(_collToken) == address(wrappedWbtc)) {
            _stalenessThreshold = _24_HOURS; // CL WBTC/BTC heartbeat. Fallback is block.timestamp
            WbtcFallbackOracle fallbackOracle = new WbtcFallbackOracle();
            contracts.oracle = address(new WbtcOracle(address(fallbackOracle)));
            wbtcFallbackOracle = fallbackOracle;
        } else if (address(_collToken) == SUSDS) {
            _stalenessThreshold = _1_HOUR; // CL DAI/USD heartbeat. No Fallback
            contracts.oracle = address(new SusdsOracle());
        } else {
            revert("Collateral not supported");
        }

        contracts.priceFeed = new WETHPriceFeed(addresses.borrowerOperations, contracts.oracle, _stalenessThreshold);
        contracts.interestRouter = new InterestRouter();

        addresses.troveManager = _troveManagerAddress;
        addresses.troveNFT = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(TroveNFT).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.stabilityPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(StabilityPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.activePool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(ActivePool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.defaultPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(DefaultPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.gasPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(GasPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.collSurplusPool = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(CollSurplusPool).creationCode, address(contracts.addressesRegistry)))
        );
        addresses.sortedTroves = vm.computeCreate2Address(
            SALT, keccak256(getBytecode(type(SortedTroves).creationCode, address(contracts.addressesRegistry)))
        );

        IAddressesRegistry.AddressVars memory addressVars = IAddressesRegistry.AddressVars({
            collToken: _collToken,
            borrowerOperations: IBorrowerOperations(addresses.borrowerOperations),
            troveManager: ITroveManager(addresses.troveManager),
            troveNFT: ITroveNFT(addresses.troveNFT),
            metadataNFT: IMetadataNFT(addresses.metadataNFT),
            stabilityPool: IStabilityPool(addresses.stabilityPool),
            priceFeed: contracts.priceFeed,
            activePool: IActivePool(addresses.activePool),
            defaultPool: IDefaultPool(addresses.defaultPool),
            gasPoolAddress: addresses.gasPool,
            collSurplusPool: ICollSurplusPool(addresses.collSurplusPool),
            sortedTroves: ISortedTroves(addresses.sortedTroves),
            interestRouter: contracts.interestRouter,
            hintHelpers: _hintHelpers,
            multiTroveGetter: _multiTroveGetter,
            collateralRegistry: _collateralRegistry,
            boldToken: _boldToken,
            WETH: IWETH(WETH)
        });
        contracts.addressesRegistry.setAddresses(addressVars);

        contracts.borrowerOperations = new BorrowerOperations{salt: SALT}(contracts.addressesRegistry);
        contracts.troveManager = new TroveManager{salt: SALT}(contracts.addressesRegistry);
        contracts.troveNFT = new TroveNFT{salt: SALT}(contracts.addressesRegistry);
        contracts.stabilityPool = new StabilityPool{salt: SALT}(contracts.addressesRegistry);
        contracts.activePool = new ActivePool{salt: SALT}(contracts.addressesRegistry);
        contracts.defaultPool = new DefaultPool{salt: SALT}(contracts.addressesRegistry);
        contracts.gasPool = new GasPool{salt: SALT}(contracts.addressesRegistry);
        contracts.collSurplusPool = new CollSurplusPool{salt: SALT}(contracts.addressesRegistry);
        contracts.sortedTroves = new SortedTroves{salt: SALT}(contracts.addressesRegistry);

        assert(address(contracts.borrowerOperations) == addresses.borrowerOperations);
        assert(address(contracts.troveManager) == addresses.troveManager);
        assert(address(contracts.troveNFT) == addresses.troveNFT);
        assert(address(contracts.stabilityPool) == addresses.stabilityPool);
        assert(address(contracts.activePool) == addresses.activePool);
        assert(address(contracts.defaultPool) == addresses.defaultPool);
        assert(address(contracts.gasPool) == addresses.gasPool);
        assert(address(contracts.collSurplusPool) == addresses.collSurplusPool);
        assert(address(contracts.sortedTroves) == addresses.sortedTroves);

        // Connect contracts
        _boldToken.setBranchAddresses(
            address(contracts.troveManager),
            address(contracts.stabilityPool),
            address(contracts.borrowerOperations),
            address(contracts.activePool)
        );

        if (address(_collToken) == address(wrappedWbtc)) {
            contracts.zapper = address(new WbtcZapper(contracts.addressesRegistry));
        } else {
            contracts.zapper = address(new USAZapper(contracts.addressesRegistry));
        }
    }

    function _deployCurveBoldUsdcPool(IBoldToken _boldToken, IERC20 _usdc) internal returns (ICurveStableswapNGPool) {
        // // deploy Curve StableswapNG pool
        // address[] memory coins = new address[](2);
        // coins[BOLD_TOKEN_INDEX] = address(_boldToken);
        // coins[USDC_INDEX] = address(_usdc);
        // uint8[] memory assetTypes = new uint8[](2); // 0: standard
        // bytes4[] memory methodIds = new bytes4[](2);
        // address[] memory oracles = new address[](2);
        // ICurveStableswapNGPool curvePool = curveStableswapFactory.deploy_plain_pool(
        //     "USDC-USA.d",
        //     "USDCUSA.d",
        //     coins,
        //     100, // A
        //     1000000, // fee
        //     20000000000, // _offpeg_fee_multiplier
        //     866, // _ma_exp_time
        //     0, // implementation id
        //     assetTypes,
        //     methodIds,
        //     oracles
        // );

        // return curvePool;
    }

    function _getBranchContractsJson(LiquityContractsTestnet memory c) internal pure returns (string memory) {
        return string.concat(
            "{",
            string.concat(
                // Avoid stack too deep by chunking concats
                string.concat(
                    string.concat('"addressesRegistry":"', address(c.addressesRegistry).toHexString(), '",'),
                    string.concat('"activePool":"', address(c.activePool).toHexString(), '",'),
                    string.concat('"borrowerOperations":"', address(c.borrowerOperations).toHexString(), '",'),
                    string.concat('"collSurplusPool":"', address(c.collSurplusPool).toHexString(), '",'),
                    string.concat('"defaultPool":"', address(c.defaultPool).toHexString(), '",'),
                    string.concat('"sortedTroves":"', address(c.sortedTroves).toHexString(), '",'),
                    string.concat('"stabilityPool":"', address(c.stabilityPool).toHexString(), '",'),
                    string.concat('"troveManager":"', address(c.troveManager).toHexString(), '",')
                ),
                string.concat(
                    string.concat('"troveNFT":"', address(c.troveNFT).toHexString(), '",'),
                    string.concat('"metadataNFT":"', address(c.metadataNFT).toHexString(), '",'),
                    string.concat('"priceFeed":"', address(c.priceFeed).toHexString(), '",'),
                    string.concat('"gasPool":"', address(c.gasPool).toHexString(), '",'),
                    string.concat('"interestRouter":"', address(c.interestRouter).toHexString(), '",'),
                    string.concat('"zapper":"', address(c.zapper).toHexString(), '",'),
                    string.concat('"gasCompZapper":"', address(c.gasCompZapper).toHexString(), '",'),
                    string.concat('"leverageZapper":"', address(c.leverageZapper).toHexString(), '",')
                ),
                string.concat(
                    string.concat('"collToken":"', address(c.collToken).toHexString(), '"') // no comma
                )
            ),
            "}"
        );
    }

    function _getDeploymentConstants() internal pure returns (string memory) {
        return string.concat(
            "{",
            string.concat(
                string.concat('"ETH_GAS_COMPENSATION":"', ETH_GAS_COMPENSATION.toString(), '",'),
                string.concat('"INTEREST_RATE_ADJ_COOLDOWN":"', INTEREST_RATE_ADJ_COOLDOWN.toString(), '",'),
                string.concat('"MAX_ANNUAL_INTEREST_RATE":"', MAX_ANNUAL_INTEREST_RATE.toString(), '",'),
                string.concat('"MIN_ANNUAL_INTEREST_RATE":"', MIN_ANNUAL_INTEREST_RATE.toString(), '",'),
                string.concat('"MIN_DEBT":"', MIN_DEBT.toString(), '",'),
                string.concat('"SP_YIELD_SPLIT":"', SP_YIELD_SPLIT.toString(), '",'),
                string.concat('"UPFRONT_INTEREST_PERIOD":"', UPFRONT_INTEREST_PERIOD.toString(), '"') // no comma
            ),
            "}"
        );
    }

    function _getManifestJson(DeploymentResult memory deployed, string memory _governanceManifest)
        internal
        pure
        returns (string memory)
    {
        string[] memory branches = new string[](deployed.contractsArray.length);

        // Poor man's .map()
        for (uint256 i = 0; i < branches.length; ++i) {
            branches[i] = _getBranchContractsJson(deployed.contractsArray[i]);
        }

        return string.concat(
            "{",
            string.concat(
                string.concat('"constants":', _getDeploymentConstants(), ","),
                string.concat('"collateralRegistry":"', address(deployed.collateralRegistry).toHexString(), '",'),
                string.concat('"boldToken":"', address(deployed.boldToken).toHexString(), '",'),
                string.concat('"hintHelpers":"', address(deployed.hintHelpers).toHexString(), '",'),
                string.concat('"multiTroveGetter":"', address(deployed.multiTroveGetter).toHexString(), '",'),
                string.concat('"exchangeHelpers":"', address(deployed.exchangeHelpers).toHexString(), '",'),
                string.concat('"branches":[', branches.join(","), "],"),
                string.concat('"governance":', _governanceManifest, '" ') // no comma
            ),
            "}"
        );
    }
}

// deployed: struct DeployUSADScript.DeploymentResult DeploymentResult({ contractsArray: [LiquityContractsTestnet({ addressesRegistry: 0xc8d81c4Fe3b778DD761dfce504dd2046C2335c8f, activePool: 0x29b6691e54c622fCd398E818837b0434E78769E3, borrowerOperations: 0xf9C3189e560F68FEFC4e27d0bA702b1ec87EfE3F, collSurplusPool: 0x209A0FdDaAFE7D2d05730f26F66Ef4E54b7D1F9A, defaultPool: 0x0C2b63BD55908102442AA595fde23C0bEc3c0e28, sortedTroves: 0x38d409d3c5b5b4F5a788fDf5C39597dae86BBb9C, stabilityPool: 0x08c008B799e81F50B918b331C6d632DB45D4c704, troveManager: 0xC492724000467e7428f447E623FA880f77222bd2, troveNFT: 0x38deC1FEB2E865A9FB6dB0Ae5719d5aAe37578Df, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0x1F9a1695C3BF126Cc1156E2beDad6399B3F5794C, gasPool: 0xa9EAbc1732DBa678d57cab24DC828813220ecc0C, interestRouter: 0x724371E00e939d3b9aDCBEA17cc584F6F7482E29, collToken: 0x0655977FEb2f289A4aB78af67BAB0d17aAb84367, zapper: 0x234134617C64A0B1A27C3d0C664976c73D4Eb174, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x5d5Dcb0821a9C9d8F2c5a4d5500f6C52b01d177c }), LiquityContractsTestnet({ addressesRegistry: 0xd1da8A03541EA81F121a38D2C3965A4023B51F12, activePool: 0xa93Cee2deB1994c2769FbC5303Ef5A776b84D9f0, borrowerOperations: 0x528Ce0b15D640f2Fc34577C1E4905e3856cD65d5, collSurplusPool: 0xc0B7c324014e788FAE82B53826Aba1fD69639757, defaultPool: 0x91528c6D828880274cA27D8657DB4B53d11f24cb, sortedTroves: 0x6EC0B3ec6CebF8d34a925210D618Cad9f507336D, stabilityPool: 0x30D94f227E409B84Ce39AA2fA48f251DCC0896a7, troveManager: 0x38811744529a4f69139F72E8D65fe974e1a26639, troveNFT: 0x9df7c560728f16d9C189489DA3E334182f532590, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0x7f0d7534735BC05D8Ee06083c27B698B97d8329c, gasPool: 0x4c14642F995ED2d39Db47cc88C1344E363c5cbCa, interestRouter: 0xd8828e02acd1Fa52Ee33b23f87f4B69c3a9E0B1e, collToken: 0x83F20F44975D03b1b09e64809B757c47f942BEeA, zapper: 0xb4c6f0a04C4d1aa8BE3C37E3A832061860Ca7c76, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x9181B9f2E4C853453F4ca72510b451889E7a9Bb0 }), LiquityContractsTestnet({ addressesRegistry: 0x1E32314e60414eD28ee3579c0c754CFE071d131e, activePool: 0x296B258403529006B2CFCB3017C37A17811C9deA, borrowerOperations: 0x3CaD0eeE4dC72c64909CdE64a5f38370Ba58173D, collSurplusPool: 0x50F3d006a31d6579e91E0bfc56BE09424627AFE7, defaultPool: 0x803eeD4A49611a3cf4613A32FD5fa3d5198FE907, sortedTroves: 0x9D60a5aD6aF260789108c54a4F6711891B6E097D, stabilityPool: 0xE01C600c5CF4d24ad88429d86f5Db4EEc0C99509, troveManager: 0x3e40EfFA6DA563f7Fe0351eB0232F1123905326D, troveNFT: 0x5548665dF7E76a480BD955E2904186a0444617B0, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0x36e01F055CDE0cC1A9a56c80AB8643E1b289aa87, gasPool: 0xe7755a173E82A560fF2Ed13Df75DB0FE01498f39, interestRouter: 0x895479B03f6d8620300A3939B3FA1475A9eAb819, collToken: 0xac3E018457B222d93114458476f3E3416Abbe38F, zapper: 0xe9C32Ea0508FA2C6C293eC3dcac8cE8650475557, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x5f5fb8d66413EAC535B0EBB08120F9B1c1eF8FF4 }), LiquityContractsTestnet({ addressesRegistry: 0x4995A3abB6304f12a7e730a08b33399Ead983c0c, activePool: 0xD161787A0F48061cE892E56A826aAb4548eBe467, borrowerOperations: 0x17736b2C96Da351dc28D5525633F91461A7e26C6, collSurplusPool: 0xeA524490Df3d5bf0C232eD7910D09081b443A65a, defaultPool: 0x43084eBDC64dd47807ED0c30806aac26F1D81354, sortedTroves: 0x5610ad9a5F937432DAE064712e705df907cFF71D, stabilityPool: 0xcD0E01C140413663f452a055eBb086ccFD3718aE, troveManager: 0x771066Fd05243af530f7d2BF6a9425df3d9c7d80, troveNFT: 0xB285B451f0055c64E51F1Cec2eb4cc832a94e549, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0x041d537da301027A439460F6b86785898e6A545D, gasPool: 0x32bC60Ba5Eb40747894fCD9446282E87197D8381, interestRouter: 0xD46FCa0D72712C02Fb9D9a2D94d2e3ca0cE348B7, collToken: 0x18084fbA666a33d37592fA2633fD49a74DD93a88, zapper: 0x6967dFd94738380568C64FcD5b07851bbC02dc1a, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x83E800858CA65D34758344EFDA39D63D77cE94d3 }), LiquityContractsTestnet({ addressesRegistry: 0x2D598C684611fcea588e1fef6d4c50D7BD09c705, activePool: 0xDAb08e10F08e45BC9Fd1eF30f0222f9E302C9613, borrowerOperations: 0x02F238163b11714DC02659d0EB5876C417ad2C95, collSurplusPool: 0xd98919e623074b46eBC8a511b4F3DD50C204f6B7, defaultPool: 0x6BAcda941AAe9994c14cD4b37066A10B3e85D0b2, sortedTroves: 0xF08fDDD8EEd08fCf55842D750cf6274431dA29DD, stabilityPool: 0xb4992903E80058DCF2dC015a32a147Dba8B9c7D1, troveManager: 0x692EAE4f2F1DBF18eC86307b84fDeBfc042C0f82, troveNFT: 0x0cF77546D6612B047B029d3286004Fd1E27DC7C4, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0xF9Ea885AD3994AaB776AFE8502a19A6E54197355, gasPool: 0x10f602F4eb49C1721e3A57B95F5eB4Da8084edA3, interestRouter: 0xf9E241491Df7f97F45D6f160Eb35Fb4ed5015705, collToken: 0x99b36ED441Cd2936ae3742C9CBA62d261a468752, zapper: 0x323e6B95C5c4BFcAe4C0da5179D31c836E9A8179, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x71FF3CF44c685B5BF8105DCdd7e7857f7a552891 }), LiquityContractsTestnet({ addressesRegistry: 0x3A38508Bb69a86bD3BA85d8064E4c2574d18EA16, activePool: 0xc9F8FBD550FE09F56455fdBdc4Cf2DBb0f6aB0Ee, borrowerOperations: 0xC99791CF86690aE29F416F4cAE2b691E73Ae8698, collSurplusPool: 0x8b6898e3Ef4F6A4b49FE0ED0A88E6cfbF81C6aF7, defaultPool: 0xe72b5647C71c687cCcd83579d41a4a18C5B829c9, sortedTroves: 0xFa2C2D43d9Fc99fB9985e9E1EF1d13361E37DB16, stabilityPool: 0x1BcBF58cae63800681828425c3b7fe80B5534907, troveManager: 0x52e01ef45369c5B0dA28a4B9bDD3D5c3925c2389, troveNFT: 0xDD4332906EeCAD213fBCFF0BC52eDD6dAF5B3B09, metadataNFT: 0xa9b5DdCb46EFB91E5b00Fa1d908aa5ad1526b7ed, priceFeed: 0xA3A83df4f0905C3B976906E90158F86DA755c563, gasPool: 0xae47801297dFB9E9646d02116c42d75C41e25E47, interestRouter: 0x3224071FC67656Bf17a735A9F4ba434c95c52409, collToken: 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD, zapper: 0x039F0333692DF867b23F15d749d16F20A7bAe050, gasCompZapper: 0x0000000000000000000000000000000000000000, leverageZapper: 0x0000000000000000000000000000000000000000, oracle: 0x24Bf596A4ccd5148FC816A7371cDF75d0706765C })], collateralRegistry: 0x447fd8743A7a545Fc95A42bf4aFD4122BdCaEFf4, boldToken: 0xD86D67708040D039D777BD2cc2De379e8aBA4c7F, usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, usdcCurvePool: 0x0000000000000000000000000000000000000000, hintHelpers: 0xA2796E55212acC734680b24f71943412DDcFe3CE, multiTroveGetter: 0x77e49282F03168896F4b745D801CD19F28b66380, exchangeHelpers: 0x0000000000000000000000000000000000000000 })