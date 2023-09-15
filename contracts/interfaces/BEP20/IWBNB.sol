// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity 0.8.20;

import "./IBEP20.sol";
import "./IBEP2612.sol";

interface IBEP3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "BEP3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IBEP3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IBEP3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

/// @dev Wrapped BNB v10 (WBNB10) is an BNB (BNB) BEP-20 wrapper. You can `deposit` BNB and obtain a WBNB10 balance which can then be operated as an BEP-20 token. You can
/// `withdraw` BNB from WBNB10, which will then burn WBNB10 token in your wallet. The amount of WBNB10 token in any wallet is always identical to the
/// balance of BNB deposited minus the BNB withdrawn with that specific wallet.
interface IWBNB10 is IBEP20, IBEP2612, IBEP3156FlashLender {
    /// @dev Returns current amount of flash-minted WBNB10 token.
    function flashMinted() external view returns (uint256);

    /// @dev `msg.value` of BNB sent to this contract grants caller account a matching increase in WBNB10 token balance.
    /// Emits {Transfer} event to reflect WBNB10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of BNB sent to this contract grants `to` account a matching increase in WBNB10 token balance.
    /// Emits {Transfer} event to reflect WBNB10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WBNB10 token from caller account and withdraw matching BNB to the same.
    /// Emits {Transfer} event to reflect WBNB10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WBNB10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WBNB10 token from caller account and withdraw matching BNB to account (`to`).
    /// Emits {Transfer} event to reflect WBNB10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WBNB10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WBNB10 token from account (`from`) and withdraw matching BNB to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WBNB10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WBNB10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WBNB10 token, unless `from` and caller are the same account.
    function withdrawFrom(
        address from,
        address payable to,
        uint256 value
    ) external;

    /// @dev `msg.value` of BNB sent to this contract grants `to` account a matching increase in WBNB10 token balance,
    /// after which a call is executed to an BEP677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(
        address to,
        bytes calldata data
    ) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WBNB10 token,
    /// after which a call is executed to an BEP677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    /// @dev Moves `value` WBNB10 token from caller's account to account (`to`),
    /// after which a call is executed to an BEP677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an BNB withdraw matching the sent WBNB10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WBNB10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(
        address to,
        uint value,
        bytes calldata data
    ) external returns (bool);
}
