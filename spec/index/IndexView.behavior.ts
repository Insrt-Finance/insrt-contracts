import { ethers } from 'hardhat';
import { IIndex, IVault, IVault__factory } from '../../typechain-types';
import { expect } from 'chai';
import { getBalancerContractAddress } from '@balancer-labs/v2-deployments';

export interface IndexViewBehaviorArgs {}

export function describeBehaviorOfIndexView(
  deploy: () => Promise<IIndex>,
  args: IndexViewBehaviorArgs,
  skips?: string[],
) {
  let instance: IIndex;
  let balancerVault: IVault;

  before(async () => {
    const balancerVaultAddress = await getBalancerContractAddress(
      '20210418-vault',
      'Vault',
      'arbitrum',
    );

    balancerVault = IVault__factory.connect(
      balancerVaultAddress,
      ethers.provider,
    );
  });

  beforeEach(async () => {
    instance = await deploy();
  });

  describe('#getPoolId()', () => {
    it('returns Balancer pool id', async function () {
      const id = await instance.callStatic.getPoolId();
      const [pool] = await balancerVault.callStatic.getPool(id);
      expect(pool).to.equal(await instance.callStatic.asset());
    });
  });

  describe('#getExitFee()', () => {
    it('todo', async () => {});
  });
}
