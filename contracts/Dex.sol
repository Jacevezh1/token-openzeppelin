// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import './Wallet.sol';

contract Dex is Wallet {

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        bool buyOrder;
        bytes32 ticker;
        uint amount;
        uint price;
    }

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    /* function createLimitOrder() public {

    } */

}