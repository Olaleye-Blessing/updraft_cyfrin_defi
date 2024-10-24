// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity 0.8.24;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DSCEngine is ReentrancyGuard {
    // error
    error DSCEngine__NeedMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    DecentralizedStableCoin private immutable i_dsc;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) revert DSCEngine__NeedMoreThanZero();

        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) revert DSCEngine__NotAllowedToken();
        _;
    }

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscCoin) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeTheSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }

        i_dsc = DecentralizedStableCoin(dscCoin);
    }

    /// @dev Follows CEI -> Check - Effect - Interaction
    /// @param tokenCollateral The address of the token to deposit as collateral
    /// @param amount The amount of collateral to deposit
    function depositCollateral(address tokenCollateral, uint256 amount)
        external
        moreThanZero(amount)
        isAllowedToken(tokenCollateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateral] += amount;
        emit CollateralDeposited(msg.sender, tokenCollateral, amount);
        bool success = IERC20(tokenCollateral).transferFrom(msg.sender, address(this), amount);

        if (!success) revert DSCEngine__TransferFailed();
    }
}
