pragma solidity 0.4.18;

import "../loan/StructureLoan.sol";

contract Collateral is StructureLoan {
    using SafeMath for uint;

    ERC20 loanToken;

    mapping(address => bool) public hasClaim;

    function Collateral(address _loanToken) 
        public
    {
        loanToken = ERC20(_loanToken);
    }

    function stake(uint256 _amount)
        public
        isBorrower
        atStage(Stages.Init)
        returns (bool)
    {
        require(loanToken.allowance(msg.sender, this) >= _amount);
        require(loanToken.transferFrom(msg.sender, this, _amount));
        return true;
    }

    function withdrawStake()
        public
        isBorrower
        atStage(Stages.Init)
        returns (bool)
    {
        uint256 loanBalance = loanToken.balanceOf(address(this));
        require(loanBalance > 0);
        require(loanToken.transfer(borrower.id, loanBalance));
        return true;
    }

    function claimStake()
        public
        isLender
        atStage(Stages.Defaulted)
        returns (bool)
    {
        require(!hasClaim[msg.sender]);
        loanToken.transfer(msg.sender, calculateClaim());
        hasClaim[msg.sender] = true;
        return true;
    }

    function calculateClaim()
        internal
        view
        returns (uint256)
    {
        uint256 loanBalance = loanToken.balanceOf(address(this));
        uint256 amountInvested = lenders[msg.sender].amountInvested;
        if (requestedCapital > 0) return loanBalance.mul(amountInvested).div(requestedCapital);
        else return loanBalance.mul(amountInvested).div(borrower.principal);
    }
}