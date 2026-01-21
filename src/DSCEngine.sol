// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard {
    //////////////////
    //// Errors ////
    /////////////////

    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TransferFailed();

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
            revert TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }

        for (uint i = 0; i < array.length; i++) {
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

        bool success = IERC20.transferFrom(
            msg.sender,
            address(this),
            amountCollateral
        );

        if (!success) revert DSCEngine__TransferFailed();
    }

    /////////////////////////////
    //// Private Functions ////
    /////////////////////////////

    function _getUsdValue(
        address token,
        uint256 amount
    ) private returns (uint256 usdValue) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * amount) / 1e18;
    }

    ////////////////////////////
    //// Getter Functions ////
    ////////////////////////////

    function getAccountCollateralValue(
        address user
    ) public view returns (uint256 collateralValueInUsd) {
        for (uint i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
    }
}
