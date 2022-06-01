import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import {
  IVault,
  IVault__factory,
  InvestmentPoolFactory,
  InvestmentPoolFactory__factory,
  WeightedPoolFactory,
  WeightedPoolFactory__factory,
} from '../typechain-types';

describe('Balancer', () => {
  //taken from: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/deployments/tasks/20210418-vault/output/arbitrum.json
  const balancerVaultAddress = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';
  // const investmentPoolFactoryAddress =
  //   '0xaCd615B3705B9c880E4E7293f1030B34e57B4c1c';
  // mainnet
  const investmentPoolFactoryAddress =
    '0x48767F9F868a4A7b86A90736632F6E44C2df7fa9';
  const weightedPoolFactoryAddress =
    '0x7dFdEF5f355096603419239CE743BfaF1120312B';

  let balancerVault: IVault;
  let investmentPoolFactory: InvestmentPoolFactory;
  let weightedPoolFactory: WeightedPoolFactory;

  before(async () => {
    const [deployer] = await ethers.getSigners();

    balancerVault = IVault__factory.connect(
      balancerVaultAddress,
      ethers.provider,
    );

    investmentPoolFactory = InvestmentPoolFactory__factory.connect(
      investmentPoolFactoryAddress,
      ethers.provider,
    );

    weightedPoolFactory = WeightedPoolFactory__factory.connect(
      weightedPoolFactoryAddress,
      ethers.provider,
    );

    // await investmentPoolFactory.create(
    //   'name',
    //   'sym',
    //   [],
    //   [],
    //   ethers.constants.Zero,
    //   ethers.constants.AddressZero,
    //   true,
    //   ethers.constants.Zero,
    // );
    //
    // console.log('dep');
    //
    // console.log(
    //   await balancerVault.getPool(ethers.utils.formatBytes32String('test')),
    // );
    // console.log('test');
  });

  describe('test', () => {
    it('tests', async () => {
      console.log(
        await balancerVault.getPool(ethers.utils.formatBytes32String('test')),
      );
      console.log('test');
    });
  });
});
