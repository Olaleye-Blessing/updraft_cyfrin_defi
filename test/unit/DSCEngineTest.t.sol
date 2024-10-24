/// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {ERC20Mock} from "./../mocks/MockERC20.sol";

contract DSCEngineTest is Test {
  DeployDSC deployer;
  DecentralizedStableCoin dsc;
  DSCEngine engine;
  HelperConfig config;
  address weth;
  address wbtc;

  address public USER = makeAddr("user");
  uint256 public constant AMOUNT_COLLATERAL = 10 ether;
  uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

  function setUp() public {
    deployer = new DeployDSC();
    (dsc, engine, config) = deployer.run();
    (,, weth, wbtc,) = config.activeNetworkConfig();

    ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
  }

  function test_getUsdValue() public {
    uint256 ethAmount = 15e18;
    // 15e18 * 2000/ETH = 30,000e18
    uint256 expectedUsd = 30000e18;
    uint256 actualUsd = engine.getUsdValue(weth, ethAmount);
    assertEq(expectedUsd, actualUsd);
  }

  function test_revertIfCollateralZero() public {
    vm.startPrank(USER);
    vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
    engine.depositCollateral(weth, 0);
    vm.stopPrank();
  }
}
