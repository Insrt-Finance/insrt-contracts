import hre, { ethers } from 'hardhat';
import {
  ICore,
  ICore__factory,
  Core__factory,
  IShardVault,
  IShardVault__factory,
  ShardVaultDiamond__factory,
  ShardVaultManager__factory,
  ShardVaultIO__factory,
  ShardVaultView__factory,
} from '../../typechain-types';

import { describeBehaviorOfShardVaultProxy } from '../../spec/shard/ShardVaultProxy.behavior';
import { expect } from 'chai';

describe('ShardVaultProxy', () => {
  const ethers = hre.ethers;
  let snapshotId: number;
  let core: ICore;
  let instance: IShardVault;

  let deployer: any;
  const id = 1;
  const shardValue = ethers.utils.parseEther('1.0');

  const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB'; //mainnet

  before(async () => {
    // TODO: must skip signers because they're not parameterized in SolidState spec
    [, , , deployer] = await ethers.getSigners();

    const coreDiamond = await new Core__factory(deployer).deploy();
    const shardVaultDiamond = await new ShardVaultDiamond__factory(
      deployer,
    ).deploy();

    const coreFacetCuts = [
      await new ShardVaultManager__factory(deployer).deploy(
        shardVaultDiamond.address,
      ),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions).map((fn) =>
          f.interface.getSighash(fn),
        ),
      };
    });

    const shardVaultSelectors = new Set();

    const shardVaultFacetCuts = [
      await new ShardVaultIO__factory(deployer).deploy(),
      await new ShardVaultView__factory(deployer).deploy(),
    ].map(function (f) {
      return {
        target: f.address,
        action: 0,
        selectors: Object.keys(f.interface.functions)
          .filter(
            (fn) => !shardVaultSelectors.has(fn) && shardVaultSelectors.add(fn),
          )
          .map((fn) => f.interface.getSighash(fn)),
      };
    });

    await coreDiamond.diamondCut(
      coreFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    await shardVaultDiamond.diamondCut(
      shardVaultFacetCuts,
      ethers.constants.AddressZero,
      '0x',
    );

    core = ICore__factory.connect(coreDiamond.address, ethers.provider);

    const deployShardVaultTx = await core
      .connect(deployer)
      ['deployShardVault(address,uint256)'](CRYPTO_PUNKS_MARKET, shardValue);

    const { events } = await deployShardVaultTx.wait();
    const { deployment } = events.find(
      (e) => e.event === 'ShardVaultDeployed',
    ).args;

    instance = IShardVault__factory.connect(deployment, deployer);

    beforeEach(async () => {
      snapshotId = await ethers.provider.send('evm_snapshot', []);
    });

    afterEach(async () => {
      await ethers.provider.send('evm_revert', [snapshotId]);
    });

    describeBehaviorOfShardVaultProxy(async () => instance, {});
  });
});
