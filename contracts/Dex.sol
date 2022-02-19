// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import './Wallet.sol';
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Dex is Wallet {
    using SafeMath for uint256;

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    uint public nextOrderId = 0;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    

    function getOrderBook(bytes32 ticker, Side side) view public returns(Order[] memory){
        return orderBook[ticker][uint(side)];
    }

    function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public {
        if(side == Side.BUY){
            require(balances[msg.sender]["ETH"] >= amount.mul(price));
        } 
        else if(side == Side.SELL){
            require(balances[msg.sender]["ETH"] >= amount);
        }
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(
            Order(nextOrderId, msg.sender, side, ticker, amount, price, _)
        );

        // Bubble Sort
        uint i = orders.length > 0 ? orders.length - 1 : 0;

        if(side == Side.BUY){
            while(i > 0){
                if(orders[i - 1].price > orders[i].price){
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        } 
        else if(side == Side.SELL){
            while(i > 0){
                if(orders[i - 1].price < orders[i].price){
                    break;
                }
                Order memory orderToMove = orders[i - 1];
                orders[i - 1] = orders[i];
                orders[i] = orderToMove;
                i--;
            }
        }

        nextOrderId++;   
    }   


    function createMarketOrder(Side side, bytes32 ticker, uint amount) public {
       if(side == Side.SELL){
           require(balances[msg.sender][ticker] >= amount, "Insufficient Balance");
       }
       
       uint orderBookSide;
       if(side == Side.BUY){
           orderBookSide = 1;
       } else {
           orderBookSide = 0;
       }
        Order[] storage orders = orderBook[ticker][uint(side)];

        uint totalFilled;

        for (uint256 i = 0; i < orders.length && totalFilled < amount; i++) {
            uint leftToFill = amount.sub(totalFilled);
            uint availableToFill = orders[i].amount.sub(orders[i].filled);
            uint filled = 0;
            if(availableToFill > leftToFill){
                filled = leftToFill; // Filled the entire market order
            } else {
                filled = availableToFill; // Fill as much as is available in order[i]
            }
            
            totalFilled = totalFilled.add(filled);
            orders[i].filled = orders[i].filled.add(filled);
            uint cost = filled.mul(orders[i].price);


            // Execute the actual trade
            if(side == Side.BUY){
                require(balances[msg.sender]["ETH"] >= filled.mul(orders[i].price));

                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);

            } else if(side == Side.SELL){
                balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
                balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);

                balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
                balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
                
            }

           
            // Verify that the buyer has enough eth to cover(require)

        }

        // Loop through the order book and remove 100% filled orders
        while(orders[0].filled == orders[0].amount && orders.length > 0){
            for (uint256 i = 0; i < orders.length - 1; i++) {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }
}
