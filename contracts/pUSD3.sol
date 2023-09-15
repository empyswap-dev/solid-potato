// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BEP20} from "./libraries/BEP20/BEP20.sol";
import {IBEP20} from "./interfaces/BEP20/IBEP20.sol";
import {IWBNB10} from "./interfaces/BEP20/IWBNB.sol";
import {IBEP4626} from "./libraries/BEP20/BEP4626.sol";
import {TransferHelper} from "./libraries/uniswapV2/TransferHelper.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

/// Deposit, Withdraw, Mint, Redeem exists for Stable.
/// Fund & Defund exists for Volatility.
/// All reserve asset accounting (WBNB) is done inside of Stable Vault. There is only one accounting.
/// Preserves 4626 expected interface (eg vault mint/burn operating on one underlying).

contract VolatilityToken is BEP20 {
    constructor() BEP20("Volatility Token", "VOLT", 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract pUSD3StableVault is IBEP4626, BEP20 {
    using TransferHelper for BEP20;

    uint256 public volatilityBuffer;
    uint256 public constant depositFee = 100; // 0.1%
    uint256 public constant withdrawFee = 9500; // 99.5%
    uint256 public constant maxFloatFee = 10000; // 100%

    VolatilityToken public immutable volt;
    IWBNB10 public immutable wbnb;
    AggregatorV3Interface internal immutable priceFeed;

    event Withdraw(
        address from,
        address to,
        uint256 amountReserve,
        uint256 wbnbOut
    );

    constructor() BEP20("PUSD Stable Vault", "PUSD", 18) {
        volt = new VolatilityToken();
        wbnb = IWBNB10(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    /// @notice Stablecoin
    /// Give WBNB amount, get STABLE amount
    function deposit(
        uint256 wbnbIn,
        address to
    ) public override returns (uint256 stableCoinAmount) {
        require(
            (stableCoinAmount = previewDeposit(wbnbIn)) != 0,
            "ZERO_SHARES"
        );
        require(wbnb.transferFrom(msg.sender, address(this), wbnbIn));
        _mint(to, stableCoinAmount);
        emit Deposit(msg.sender, to, wbnbIn, stableCoinAmount);
        afterDeposit(wbnbIn);
    }

    /// @notice Stablecoin
    /// Mint specific AMOUNT OF STABLE by giving WBNB
    function mint(
        uint256 stableCoinAmount,
        address to
    ) public override returns (uint256 wbnbIn) {
        require(
            wbnb.transferFrom(
                msg.sender,
                address(this),
                wbnbIn = previewMint(stableCoinAmount)
            )
        );
        _mint(to, stableCoinAmount);
        emit Deposit(msg.sender, to, wbnbIn, stableCoinAmount);
        afterDeposit(wbnbIn);
    }

    /// @notice Stablecoin
    /// Withdraw from Vault underlying. Amount of WBNB by burning equivalent amount of STABLECOIN
    function withdraw(
        uint256 amountReserve,
        address to,
        address from
    ) public override returns (uint256 wbnbOut) {
        uint256 allowed = allowance[from][msg.sender];
        if (msg.sender != from && allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amountReserve;
        wbnbOut = (previewWithdraw(amountReserve) * withdrawFee) / maxFloatFee;
        _burn(from, amountReserve);
        emit Withdraw(from, to, amountReserve, wbnbOut);
        wbnb.transferFrom(address(this), msg.sender, wbnbOut);
    }

    /// @notice Stablecoin
    /// Redeem from Vault underlying. (WBNB) equivalent to AMOUNTSTABLE
    function redeem(
        uint256 amountStable,
        address to,
        address from
    ) public override returns (uint256 wbnbOut) {
        uint256 allowed = allowance[from][msg.sender];
        if (msg.sender != from && allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amountStable;
        require((wbnbOut = previewRedeem(amountStable)) != 0, "ZERO_ASSETS");
        wbnbOut = (previewRedeem(amountStable) * withdrawFee) / maxFloatFee;
        _burn(from, amountStable);
        emit Withdraw(from, to, wbnbOut, amountStable);
        wbnb.transferFrom(address(this), msg.sender, wbnbOut);
    }

    /// @notice Volatility/Funding token
    /// Give amount of WBNB, receive VolatilityToken
    function fund(
        uint256 volCoinAmount,
        address to
    ) public returns (uint256 wbnbIn) {
        require(
            wbnb.transferFrom(
                msg.sender,
                address(this),
                wbnbIn = previewFund(volCoinAmount)
            )
        );
        volt.mint(to, volCoinAmount);
        volatilityBuffer += wbnbIn;
        emit Deposit(msg.sender, to, wbnbIn, volCoinAmount);
    }

    /// @notice Volatility/Funding token
    /// Redeem number of SHARES (VolToken) for WBNB at current price (at loss or profit) + fees accrued
    function defund(
        uint256 volCoinAmount,
        address to,
        address from
    ) public returns (uint256 wbnbOut) {
        require((wbnbOut = previewDefund(volCoinAmount)) != 0, "ZERO_ASSETS");
        volt.burn(to, volCoinAmount);
        volatilityBuffer -= wbnbOut;
        wbnb.transferFrom(address(this), msg.sender, wbnbOut);
        emit Withdraw(from, to, wbnbOut, volCoinAmount);
    }

    function previewFund(
        uint256 amount
    ) public view returns (uint256 stableVaultShares) {
        return amount / (getLatestPrice() / 1e8); // AMOUNT / (ETH/USD)
    }

    /// @notice Volatility token
    /// The only function that claims yield from Vault
    /// https://jacob-eliosoff.medium.com/a-cheesy-analogy-for-people-who-find-usm-confusing-1fd5e3d73a79
    function previewDefund(
        uint256 amount
    ) public view returns (uint256 wbnbOut) {
        uint256 sharesGrowth = (amount *
            (volatilityBuffer * (getLatestPrice() / 1e8))) / volt.totalSupply();
        wbnbOut = sharesGrowth / (getLatestPrice() / 1e8);
    }

    /// @notice Stablecoin
    /// Return how much STABLECOIN does user receive for AMOUNT of WBNB
    function previewDeposit(
        uint256 amount
    ) public view override returns (uint256 stableCoinAmount) {
        return (getLatestPrice() / 1e8) * amount; // (ETH/USD) * AMOUNT
    }

    /// @notice Stablecoin
    /// Return how much WBNB is needed to receive AMOUNT of STABLECOIN
    function previewMint(
        uint256 amount
    ) public view override returns (uint256 stableCoinAmount) {
        return amount / (getLatestPrice() / 1e8); // AMOUNT / (ETH/USD)
    }

    /// @notice Stablecoin
    /// Return how much WBNB to transfer by calculating equivalent amount of burn to given AMOUNT of WBNB
    function previewWithdraw(
        uint256 amount
    ) public view override returns (uint256 wbnbOut) {
        return (getLatestPrice() / 1e8) * amount; // AMOUNT * (ETH/USD)
    }

    /// @notice Stablecoin
    /// Return how much WBNB to transfer equivalent to given AMOUNT of STABLECOIN
    function previewRedeem(
        uint256 amount
    ) public view override returns (uint256 wbnbOut) {
        return amount / (getLatestPrice() / 1e8); // AMOUNT / (ETH/USD)
    }

    /// @notice Add fee from user WBNB collateral to volatilityBuffer as FUNDers fee
    function afterDeposit(uint256 amount) internal {
        uint256 fee = (amount * depositFee) / maxFloatFee;
        volatilityBuffer += fee;
    }

    function beforeWithdraw(uint256 amount) internal {}

    function totalAssets() public view override returns (uint256) {
        return wbnb.balanceOf(address(this));
    }

    function assetsOf(address user) public view returns (uint256) {
        return balanceOf[user];
    }

    function voltAssetsOf(address user) public view returns (uint256) {
        return volt.balanceOf(user);
    }

    function assetsPerShare() public view returns (uint256) {
        return previewRedeem(10 ** decimals);
    }

    function maxDeposit(address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address user) public view override returns (uint256) {
        return assetsOf(user);
    }

    function maxRedeem(address user) public view override returns (uint256) {
        return balanceOf[user];
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }
}
