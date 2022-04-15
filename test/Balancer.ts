import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { IVault, IVault__factory } from '../typechain-types';

describe.only('Balancer', () => {
  //taken from: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/deployments/tasks/20210418-vault/output/arbitrum.json
  const balancerVaultAddress = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';

  let balancerVault: IVault;

  before(async () => {
    balancerVault = IVault__factory.connect(
      balancerVaultAddress,
      ethers.provider,
    );

    console.log(
      await balancerVault.getPool(ethers.utils.formatBytes32String('test')),
    );
    console.log('test');
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
