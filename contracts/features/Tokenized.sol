pragma solidity 0.4.18;

import "../loan/StructureLoan.sol";
import "zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "@tokenfoundry/token-contracts/contracts/token/ERC223BasicToken.sol";


/// @title Tokenized that uses StructureLoan, MintableToken, DetailedERC20 and ERC223BasicToken.
contract Tokenized is StructureLoan, DetailedERC20, MintableToken, ERC223BasicToken {
    string constant NAME = "Loan Token";
    string constant SYMBOL = "LT";
    uint8 constant DECIMALS = 18;

    /// @dev Constructor that sets the details of the ERC20 token.
    function Tokenized()
        public
        DetailedERC20(NAME, SYMBOL, DECIMALS)
    {}

    modifier validTransfer() {
        require(stage != Stages.Funding || stage != Stages.Init);
        _;
    }

    modifier toquenizedWithdraw(uint256 _capital) {
        require(stage != Stages.Init);
        if (stage == Stages.Funding || stage == Stages.Canceled) {
            require(balances[msg.sender] >= _capital);
            balances[msg.sender] = balances[msg.sender].sub(_capital);
            totalSupply_ = totalSupply_.sub(_capital);
            _;
        } else {
            require(balances[msg.sender] >= _capital);
            balances[msg.sender] = balances[msg.sender].sub(_capital);
            balances[this] = balances[this].add(_capital);
            _;
        }
    }

    modifier tokenizedTransfer(address _to, uint256 _amount) {
        require(_amount <= lenders[msg.sender].amountInvested.sub(lenders[msg.sender].amountRedeemed));
        _;
        lenders[msg.sender].amountInvested = lenders[msg.sender].amountInvested.sub(_amount);
        lenders[_to].amountInvested = lenders[_to].amountInvested.add(_amount);
    }

    function transfer(address _to, uint256 _amount)
        public
        validTransfer
        tokenizedTransfer(_to, _amount)
        returns (bool)
    {
        require(super.transfer(_to, _amount));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        validTransfer
        tokenizedTransfer(_to, _amount)
        returns (bool)
    {
        require(super.transferFrom(_from, _to, _amount));
        return true;

    }
}