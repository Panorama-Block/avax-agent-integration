// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract AgentInt {
    struct PriceFeedInfo {
        string pair;
        AggregatorV3Interface feed;
    }

    PriceFeedInfo[] public feeds;

    constructor() {
        feeds.push(PriceFeedInfo("AVAX/USD", AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156)));
        feeds.push(PriceFeedInfo("BTC/USD", AggregatorV3Interface(0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743)));
        feeds.push(PriceFeedInfo("ETH/USD", AggregatorV3Interface(0x976B3D034E162d8bD72D6b9C989d545b839003b0)));
        feeds.push(PriceFeedInfo("USDC/USD", AggregatorV3Interface(0xF096872672F44d6EBA71458D74fe67F9a77a23B9)));
        feeds.push(PriceFeedInfo("USDT/USD", AggregatorV3Interface(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a)));
        feeds.push(PriceFeedInfo("DAI/USD", AggregatorV3Interface(0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300)));
        feeds.push(PriceFeedInfo("LINK/USD", AggregatorV3Interface(0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a)));
        feeds.push(PriceFeedInfo("EUR/USD", AggregatorV3Interface(0x192f2DBA961Bb0277520C082d6bfa87D5961333E)));
        feeds.push(PriceFeedInfo("JPY/USD", AggregatorV3Interface(0xf8B283aD4d969ECFD70005714DD5910160565b94)));
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash UniswapV2
        )))));
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Identical addresses");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getPriceInUniswap(address tokenA, address tokenB, address factory) external view returns (uint256 price) {
        address pair = pairFor(factory, tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");

        (uint reserveA, uint reserveB) = getReserves(factory, tokenA, tokenB);
        require(reserveA > 0 && reserveB > 0, "No reserves");

        // preço de tokenB em tokenA (quantidade tokenB por 1 tokenA)
        price = reserveB * 1e18 / reserveA;
    }

    function getMediumPrice (string memory _pair) public view returns(uint) {
        for (uint i = 0; i < feeds.length; i++) {
            if (keccak256(bytes(_pair)) == keccak256(bytes(feeds[i].pair))) {
                (
                , 
                int price,
                ,
                ,
                
            ) = feeds[i].feed.latestRoundData();
            return uint(price);
            }
        }
        revert("Pair not found");
    }

    function makeSwap (string memory _pair) public payable returns (string memory) {

        // suzaku vai tentar fazer um swap em 3 dex e olhar o preço e o gás que dá

        // verifica na chainlink se ta um bom preço

        // se o preço tiver abaixo da media do mercado e ele for o menor, ele fará considerando um bom negócio

        // se estiver acima nos 3, ele só vai no que deu mais barato mesmo

        // vai pedir autenticação do usuario e as taxas e pagamento

        // vai executar erro se deu algum, ou retornar
    }

    function makeAnalysis (string memory _pair) public payable returns (string memory) {

        // avax vai verificar o preço em 3 dex e olhar o gás

        // verifica na chainlink se ta bom negócio pra fazer

        // se tiver ele vai fazer uma analise que é uma boa hora de fazer operações com o pair_token

        // caso não ele retornará que não vale a pena
    }

    receive() external payable {}
    fallback() external payable {}

    function balance() public view returns (uint) {
        return address(this).balance;
    }
}
