// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/BEP20/extensions/BEP4626.sol)

pragma solidity ^0.8.6;

import {IBEP20} from "../../interfaces/BEP20/IBEP20.sol";
import {BEP20} from "./BEP20.sol";
import {TransferHelper} from "../uniswapV2/TransferHelper.sol";
import {IBEP4626} from "../../interfaces/BEP20/IBEP4626.sol";
import {SafeMath} from "../openzeppelin/SafeMath.sol";

/**
 * @dev Implementation of the BEP4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the BEP20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the BEP20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) BEP-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/BEP4626#erc4626router-and-base[BEP4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[BEP-4626 guide].
 * ====
 */
abstract contract BEP4626 is IBEP4626, BEP20 {
    using SafeMath for uint256;

    IBEP20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error BEP4626ExceededMaxDeposit(
        address receiver,
        uint256 assets,
        uint256 max
    );

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error BEP4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error BEP4626ExceededMaxWithdraw(
        address owner,
        uint256 assets,
        uint256 max
    );

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error BEP4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an BEP20-compatible contract (BEP20 or BEP777).
     */
    constructor(address asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(
            IBEP20(asset_)
        );
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = IBEP20(asset_);
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(
        IBEP20 asset_
    ) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_)
            .staticcall(abi.encodeCall(IBEP20.decimals, ()));
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IBEP20Metadata-decimals}.
     */
    function decimalsOffset() public view virtual returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IBEP4626-asset}. */
    function asset() public view returns (address) {
        return address(_asset);
    }

    /** @dev See {IBEP4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IBEP4626-convertToShares}. */
    function convertToShares(uint256 assets) public view returns (uint256) {
        return _convertToShares(assets, SafeMath.Rounding.Floor);
    }

    /** @dev See {IBEP4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        return _convertToAssets(shares, SafeMath.Rounding.Floor);
    }

    /** @dev See {IBEP4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IBEP4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IBEP4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf[owner], SafeMath.Rounding.Floor);
    }

    /** @dev See {IBEP4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /** @dev See {IBEP4626-previewDeposit}. */
    function previewDeposit(
        uint256 assets
    ) public view virtual returns (uint256) {
        return _convertToShares(assets, SafeMath.Rounding.Floor);
    }

    /** @dev See {IBEP4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, SafeMath.Rounding.Ceil);
    }

    /** @dev See {IBEP4626-previewWithdraw}. */
    function previewWithdraw(
        uint256 assets
    ) public view virtual returns (uint256) {
        return _convertToShares(assets, SafeMath.Rounding.Ceil);
    }

    /** @dev See {IBEP4626-previewRedeem}. */
    function previewRedeem(
        uint256 shares
    ) public view virtual returns (uint256) {
        return _convertToAssets(shares, SafeMath.Rounding.Floor);
    }

    /** @dev See {IBEP4626-deposit}. */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert BEP4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IBEP4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert BEP4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IBEP4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert BEP4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IBEP4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert BEP4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(
        uint256 assets,
        SafeMath.Rounding rounding
    ) internal view virtual returns (uint256) {
        return
            assets.mulDiv(
                totalSupply + 10 ** _decimalsOffset(),
                totalAssets() + 1,
                rounding
            );
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(
        uint256 shares,
        SafeMath.Rounding rounding
    ) internal view virtual returns (uint256) {
        return
            shares.mulDiv(
                totalAssets() + 1,
                totalSupply + 10 ** _decimalsOffset(),
                rounding
            );
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is BEP777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        TransferHelper.safeTransferFrom(
            address(_asset),
            caller,
            address(this),
            assets
        );
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is BEP777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        TransferHelper.safeTransfer(address(_asset), receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
}
