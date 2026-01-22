// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine is ReentrancyGuard {
    //////////////////
    //// Errors ////
    /////////////////

    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorIsBroken();
    error DSCEngine__MintFailed();

    //////////////////////
    //// State Vars ////
    /////////////////////

    DecentralizedStableCoin private immutable i_dsc;

    /////////////////////
    //// Modifiers ////
    ////////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    ///////////////////////////
    //// Array & Mapping ////
    //////////////////////////

    mapping(address => address) private s_priceFeed;
    mapping(address => mapping(address => uint256))
        private s_collateralDeposited;
    mapping(address => uint256) private s_DSCMinted;

    address[] private s_collateralTokens;

    /////////////////////
    //// Constants ////
    /////////////////////

    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dsc
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }

        for (uint i = 0; i < s_collateralTokens.length; i++) {
            s_priceFeed[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
    }

    ////////////////////////////
    //// Public Functions ////
    ////////////////////////////

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 amountCollateral
    )
        public
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][
            tokenCollateralAddress
        ] += amountCollateral;

        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );

        if (!success) revert DSCEngine__TransferFailed();
    }

    function mintDsc(
        uint256 amountDscToMint
    ) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);

        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    /////////////////////////////
    //// Private Functions ////
    /////////////////////////////

    function _getUsdValue(
        address token,
        uint256 amount
    ) private view returns (uint256 usdValue) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * amount) / 1e18;
    }

    function _healtherFactor(address user) private view returns (uint256) {
        (
            uint256 totalDscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(user);
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    //////////////////////////////
    //// Interanl Functions ////
    //////////////////////////////

    // To find the value of collatereal adjusted to liquidation threshold
    // collateralValue * liquidationThreshold / liquidationPrecision
    // let's pussose user deposited $200 of collateral
    // $200 * 50 / 100 = $100 worth of debt can be minted'

    function _calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    ) internal pure returns (uint256 healthFactor) {
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjusted = (collateralValueInUsd *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralValueInUsd * PRECISION) / totalDscMinted;
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 hf = _healtherFactor(user);
        if (hf < MIN_HEALTH_FACTOR) revert DSCEngine__HealthFactorIsBroken();
    }

    ////////////////////////////
    //// Getter Functions ////
    ////////////////////////////

    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        for (uint i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function _getAccountInformation(
        address user
    ) private view returns (uint256 dscMinted, uint256 collateralValueInUsd) {
        dscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }
}
