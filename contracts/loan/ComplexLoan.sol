pragma solidity 0.4.18;

import "./BasicLoan.sol";
import "../features/Time.sol";
import "../features/SimpleInterest.sol";
import "../features/Collateral.sol";
import "../features/Tokenized.sol";

/// @title BasicLoan
/// @author anibal.catalan@consensys.net andres.junge@consensys.net
contract ComplexLoan is BasicLoan, Time, SimpleInterest, Collateral, Tokenized {

    /// @notice Constructor, create a basic loan and set msg.sender as borrower, needs a token ERC20 address.
    /// @dev Constructor, create a basic loan and set msg.sender as borrower, needs a token ERC20 address.
    /// @param _token is a token ERC20 address.

    function ComplexLoan(
        address _token,
        address _borrower,
        address _loanToken,
        uint256 _fundingDate,
        uint256 _payingDate,
        uint256 _rate,
        uint256 _decimal)
        public
        validAttributes(_token, _borrower)
        Collateral(_loanToken)
        Time(_fundingDate, _payingDate)
        SimpleInterest(_rate, _decimal)
    {

        borrower.id = _borrower;
        token = ERC20(_token);
    }

    function begin()
        public
        returns (bool)
    {
        require(super.begin());

        return true;
    }

    /// @notice allows lenders to provide capital for this loan.
    /// @dev only in funding stage, allows lenders to provide capital for this loan. the capital must be previously approved by msg.sender. it uses the tranferFrom function of tokens ERC20 to transfer capital to itself, stores the msg.sender as lender, adds capital to the respective balances and trigger the Contribution event.
    /// @param _capital is the amount of token to contribute.
    function fund(uint256 _capital)
        public
        timeFund
        returns (bool)
    {
        if (block.timestamp > start.add(time.funding) && borrower.principal < requestedCapital)
        cancel();
        else require(super.fund(_capital));
        
        return true;
    }

    /// @notice allows lenders to retire capital from the loan.
    /// @dev allows lenders to retire capital from the loan. check if msg.sender has enough balance, subtract the capital from the balance, uses the transfer function of Tokens ERC20 to tranfer capital to msg.sender and trigger Withdraw event.
    /// @param _capital is the amount of token to retire.
    function withdraw(uint256 _capital)
        public
        isLender
        stageWithdraw(_capital)
        toquenizedWithdraw(_capital)
        returns (bool)
    {
        require(token.transfer(msg.sender, _capital));

        Withdraw(_capital);

        return true;
    }

    /// @notice allows cancel this loan.
    /// @dev only in funding stage, allows cancel this loan. check if msg.sender is the borrower, change the loan stage to canceled.
    function cancel()
        public
        atStage(Stages.Funding)
        isBorrower
        returns (bool)
    {
        stage = Stages.Canceled;

        Cancel();

        return true;
    }

    /// @notice allows to borrower accept the capital.
    /// @dev only in funding stage, allows to borrower accept the capital. check if msg.sender is the borrower, reset lenders balance, adds capital collected to borrower balance, change the loan stage to repayment.
    function accept()
        public
        isBorrower
        atStage(Stages.Funding)
        returns (bool)
    {
        require(token.transfer(msg.sender, borrower.principal));
        stage = Stages.Paying;
        
        Accept(borrower.principal);

        return true;
    }

    /// @notice allow borrower pay his due.
    /// @dev only in repayment stage, allow borrower pay his due. the payment must be previously approved by msg.sender, check if msg.sender is the borrower, it uses the tranferFrom function of tokens ERC20 to transfer payment to itself, adds payment to count the total amount paid, distribute the payment to lenders balance, check if total amount paid is equal or higer than total amount collected to change the stage to finished, and trigger PayBack event.
    /// @param _payment is the amount of token to payback.
    function payback(uint256 _payment)
        public
        isBorrower
        atStage(Stages.Paying)
        isApproved(_payment)
        returns (bool)
    {

        borrower.paid = borrower.paid.add(_payment);

        require(token.transferFrom(msg.sender, this, _payment));

        PayBack(_payment);

        return true;
    }

}
