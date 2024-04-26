const deploymentHelper = require("../utils/deploymentHelpers.js");
const { TestHelper: th, MoneyValues: mv } = require("../utils/testHelpers.js");

const GasPool = artifacts.require("./GasPool.sol");
const BorrowerOperationsTester = artifacts.require("./BorrowerOperationsTester.sol");

contract("All Liquity functions with onlyOwner modifier", async (accounts) => {
  const [owner, alice, bob] = accounts;

  const [bountyAddress, lpRewardsAddress, multisig] = accounts.slice(997, 1000);

  let contracts;
  let boldToken;
  let sortedTroves;
  let troveManager;
  let activePool;
  let stabilityPool;
  let defaultPool;
  let borrowerOperations;

  before(async () => {
    contracts = await deploymentHelper.deployLiquityCore();
    contracts.borrowerOperations = await BorrowerOperationsTester.new(contracts.WETH.address);
    contracts = await deploymentHelper.deployBoldToken(contracts);

    boldToken = contracts.boldToken;
    sortedTroves = contracts.sortedTroves;
    troveManager = contracts.troveManager;
    activePool = contracts.activePool;
    stabilityPool = contracts.stabilityPool;
    defaultPool = contracts.defaultPool;
    borrowerOperations = contracts.borrowerOperations;
  });

  const testZeroAddress = async (contract, params, method = "setAddresses", skip = 0) => {
    await testWrongAddress(contract, params, th.ZERO_ADDRESS, method, skip, "Account cannot be zero address");
  };
  const testNonContractAddress = async (contract, params, method = "setAddresses", skip = 0) => {
    await testWrongAddress(contract, params, bob, method, skip, "Account code size cannot be zero");
  };
  const testWrongAddress = async (contract, params, address, method, skip, message) => {
    for (let i = skip; i < params.length; i++) {
      const newParams = [...params];
      newParams[i] = address;
      await th.assertRevert(contract[method](...newParams, { from: owner }), message);
    }
  };

  const testSetAddresses = async (contract, numberOfAddresses) => {
    const dumbContract = await GasPool.new();
    const params = Array(numberOfAddresses).fill(dumbContract.address);

    // Attempt call from alice
    await th.assertRevert(contract.setAddresses(...params, { from: alice }));

    // Attempt to use zero address
    await testZeroAddress(contract, params);
    // Attempt to use non contract
    await testNonContractAddress(contract, params);

    // Owner can successfully set any address
    const txOwner = await contract.setAddresses(...params, { from: owner });
    assert.isTrue(txOwner.receipt.status);
    // fails if called twice
    await th.assertRevert(contract.setAddresses(...params, { from: owner }));
  };

  describe("TroveManager", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      await testSetAddresses(troveManager, 9);
    });
  });

  describe("BorrowerOperations", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      await testSetAddresses(borrowerOperations, 9);
    });
  });

  describe("DefaultPool", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      await testSetAddresses(defaultPool, 2);
    });
  });

  describe("StabilityPool", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      await testSetAddresses(stabilityPool, 6);
    });
  });

  describe("ActivePool", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      await testSetAddresses(activePool, 6);
    });
  });

  describe("SortedTroves", async (accounts) => {
    it("setAddresses(): reverts when called by non-owner, with wrong addresses, or twice", async () => {
      const dumbContract = await GasPool.new();
      const params = [dumbContract.address, dumbContract.address];

      // Attempt call from alice
      await th.assertRevert(sortedTroves.setAddresses(...params, { from: alice }));

      // Attempt to use zero address
      await testZeroAddress(sortedTroves, params, "setAddresses", 1);
      // Attempt to use non contract
      await testNonContractAddress(sortedTroves, params, "setAddresses", 1);

      // Owner can successfully set params
      const txOwner = await sortedTroves.setAddresses(...params, { from: owner });
      assert.isTrue(txOwner.receipt.status);

      // fails if called twice
      await th.assertRevert(sortedTroves.setAddresses(...params, { from: owner }));
    });
  });
});
