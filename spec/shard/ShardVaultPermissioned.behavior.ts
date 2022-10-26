import hre, { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { expect } from 'chai';
import {
  ICryptoPunkMarket,
  ICryptoPunkMarket__factory,
  IShardVault,
} from '../../typechain-types';

export interface ShardVaultPermissionedBehaviorArgs {
  getProtocolOwner: () => Promise<SignerWithAddress>;
}

export function describeBehaviorOfShardVaultPermissioned(
  deploy: () => Promise<IShardVault>,
  args: ShardVaultPermissionedBehaviorArgs,
  skips?: string[],
) {
  describe.only('::ShardVaultPermissioned', () => {
    let depositor: SignerWithAddress;
    let owner: SignerWithAddress;
    let nonOwner: SignerWithAddress;
    let instance: IShardVault;
    let cryptoPunkMarket: ICryptoPunkMarket;

    const punkId = BigNumber.from('2534');
    const CRYPTO_PUNKS_MARKET = '0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB';

    before(async () => {
      cryptoPunkMarket = await ethers.getContractAt(
        'ICryptoPunkMarket',
        CRYPTO_PUNKS_MARKET,
      );
    });

    beforeEach(async () => {
      instance = await deploy();
      [depositor, nonOwner] = await ethers.getSigners();
      owner = await args.getProtocolOwner();
    });

    describe('#purchasePunk(uint256)', () => {
      it('purchases punk from CryptoPunkMarket', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance.connect(owner).purchasePunk(punkId);

        expect(
          await cryptoPunkMarket['punkIndexToAddress(uint256)'](punkId),
        ).to.eq(instance.address);
      });

      it('uses vault ETH for punk purchase', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        const [, , , price] = await cryptoPunkMarket[
          'punksOfferedForSale(uint256)'
        ](punkId);

        await expect(() =>
          instance.connect(owner).purchasePunk(punkId),
        ).to.changeEtherBalances(
          [instance, cryptoPunkMarket],
          [price.mul(ethers.constants.NegativeOne), price],
        );
      });

      it('sets `invested` flag to true', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance.connect(owner).purchasePunk(punkId);

        expect(await instance.invested()).to.be.true;
      });

      it('adds punkId to `ownedTokenIds`', async () => {
        await instance.connect(owner).setMaxSupply(BigNumber.from('100'));
        await instance
          .connect(depositor)
          .deposit({ value: ethers.utils.parseEther('100') });

        await instance.connect(owner).purchasePunk(punkId);

        const [id] = await instance['ownedTokenIds()']();
        expect(id).to.eq(punkId);
      });

      describe('reverts if', () => {
        it('called by non-owner', async () => {
          await expect(
            instance.connect(nonOwner)['purchasePunk(uint256)'](punkId),
          ).to.be.revertedWith('ShardVault__OnlyProtocolOwner()');
        });
        it('collection is not punks', async () => {
          console.log('TODO');
        });
      });
    });
  });
}
