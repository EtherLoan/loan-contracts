pragma solidity 0.4.18;

import "@tokenfoundry/token-contracts/contracts/token/ERC223BasicToken.sol";

/// @title ERC223Token that uses ERC223BasicToken.
contract ERC223Token is ERC223BasicToken {

    function ERC223Token(uint256 amount) public {
      require(amount > 0);
      totalSupply_ = amount;
      balances[msg.sender] = amount;
    }
}
