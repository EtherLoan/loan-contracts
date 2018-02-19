pragma solidity 0.4.18;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

/// @title ERC20Token that uses StandardToken.
contract ERC20Token is StandardToken {

    function ERC20Token(uint256 amount) public {
      require(amount > 0);
      totalSupply_ = amount;
      balances[msg.sender] = amount;
    }
}