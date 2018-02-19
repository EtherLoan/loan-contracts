pragma solidity 0.4.18;

import "@tokenfoundry/token-contracts/contracts/token/HumanStandardToken.sol";

/// @title HumanToken that uses HumanStandardToken.
contract HumanToken is HumanStandardToken {

    function HumanToken(uint256 amount) public {
      require(amount > 0);
      totalSupply_ = amount;
      balances[msg.sender] = amount;
    }
}