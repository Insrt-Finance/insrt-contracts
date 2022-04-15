import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import IVault from '../artifacts/@balancer-labs/v2-vault/contracts/interfaces/IVault.sol/IVault.json';

describe.only('Balancer', () => {
  //taken from: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/deployments/tasks/20210418-vault/output/arbitrum.json
  const balancerVaultAddress = '0xBA12222222228d8Ba445958a75a0704d566BF2C8';

  before(async () => {
    const balancerVault = await ethers.getContractAt(
      IVault.abi,
      balancerVaultAddress,
    );

    console.log(
      await balancerVault.getPool(ethers.utils.formatBytes32String('test')),
    );
    console.log('test');
  });

  describe('test', () => {
    it('tests', async () => {
      const balancerVault = await ethers.getContractAt(
        IVault.abi,
        balancerVaultAddress,
      );
      console.log(
        await balancerVault.getPool(ethers.utils.formatBytes32String('test')),
      );
      console.log('test');
    });
  });
});
