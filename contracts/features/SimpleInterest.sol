pragma solidity 0.4.18;

import "../loan/StructureLoan.sol";

/// @title Interest
/// @author anibal.catalan@consensys.net andres.junge@consensys.net
contract SimpleInterest is StructureLoan {

    struct Interest {
        uint256 rate;
        uint256 decimal;
        uint256 total;
    }

    Interest public interest;

    function SimpleInterest(uint256 _rate, uint256 _decimal) public {
        require(_rate > 0);
        interest.rate = _rate;
        interest.decimal = ((uint256(10))**_decimal).mul(100);
    }

    modifier setTotal() {
        _;
        interest.total = calculateInterest();
    }

    function calculateInterest() 
        internal
        view
        returns (uint256) 
    {
        if (requestedCapital > 0) {
            return interest.decimal.add(interest.rate).mul(requestedCapital).div(interest.decimal);
        } else {
            return interest.decimal.add(interest.rate).mul(borrower.principal).div(interest.decimal); 
        }
    }
}