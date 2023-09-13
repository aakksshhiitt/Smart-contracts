// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import statements
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import 'https://github.com/sushiswap/v3-periphery/blob/master/contracts/libraries/TransferHelper.sol';
import 'https://github.com/sushiswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Router01.sol';
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


// 0x72Eb7Dd517FFA33aB9fAF531a3a9CE11e20A9347  address of the deployed contract
// 0xc8c0Cf9436F4862a8F60Ce680Ca5a9f0f99b5ded DAI token address from AAVE
// 0x9DFf9E93B1e513379cf820504D642c6891d8F7CC Link address from AAVE



// contract for flashLoan and arbitrage
contract SimpleFlashLoan is FlashLoanSimpleReceiverBase{
   
// address for the uniswap and sushiSwap router
    ISwapRouter public immutable uniSwapRouter=ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);              //uniswap router address
    IUniswapV2Router01 public immutable swapRouter=IUniswapV2Router01(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);  //sushiswap router address

// variables used   
    address public constant DAI = 0xc8c0Cf9436F4862a8F60Ce680Ca5a9f0f99b5ded;
    address public constant LINK = 0x9DFf9E93B1e513379cf820504D642c6891d8F7CC;
    address[] path= [LINK,DAI];
    uint24 public constant poolFee = 3000;
    uint256 public returnedValue;
    
    

// constructor that takes address of the address provider
    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)){}     //0x4CeDCB57Af02293231BAA9D39354D6BFDFD251e0

// function that calls the flash loan method and at the end return profit to the user.
// @params address of the token to take loan and the loan amount. 
    function takeLoanAndArbitrage(address _token, uint256 _amount) public {
        flashLoan(_token,_amount);
        returnedValue=IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(msg.sender,IERC20(DAI).balanceOf(address(this)));
    }
// function used to take the flashloan from the AAVE
// @params address of the token to take loan and the amount required. 
    function flashLoan(address _token, uint256 _amount) internal {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;
        POOL.flashLoanSimple(receiverAddress,asset,amount,params,referralCode);
    }
// function for calling the arbitrage and returning back the loan amount taken.
    function  executeOperation(address asset, uint256 amount, uint256 premium, address initiator,bytes calldata params)  external override returns (bool) {
        arbitrage(amount);
        uint256 totalAmount = amount + premium;
        IERC20(asset).approve(address(POOL), totalAmount);
        return true;
    }


// function to swap the DAI tokens taken as loan from AAVE to LINK tokens.
// @params amount of tokens to swap
    function uniswap(uint256 amountIn) internal returns (uint256 amountOut) {

        TransferHelper.safeApprove(DAI, address(uniSwapRouter), amountIn);  //approve the uniswap router to take funds out from the contract.

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: LINK,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = uniSwapRouter.exactInputSingle(params);
    }

// function to swap back the LINK tokens to DAI tokens with a price difference using the swapExactTokensForTokens method.
    function sushiSwap() internal returns (bool){
        uint256 amt=IERC20(LINK).balanceOf(address(this));
        // no need to transfer from user as this contract get LINK from uniswap that run before.
        TransferHelper.safeApprove(LINK, address(swapRouter), amt);
         swapRouter.swapExactTokensForTokens(amt,amt,path,address(this),block.timestamp);
         return true;
    }

    function arbitrage(uint256 _amount) internal returns(bool){
        uniswap(_amount);
        sushiSwap();
        return true;
    }
    receive() external payable {}
}