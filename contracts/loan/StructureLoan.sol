pragma solidity 0.4.18;

import "@etherloan/loan-standard/contracts/standard/LoanBasic.sol";

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/// @title BasicLoan
/// @author anibal.catalan@consensys.net andres.junge@consensys.net
contract StructureLoan is Ownable, LoanBasic {
  using SafeMath for uint;

  enum Stages {
        Init,
        Funding,
        Canceled,
        Paying,
        Finished,
        Defaulted
  }

  Stages public stage = Stages.Init;

  modifier validAttributes(address _token, address _borrower) {
      require(_token != address(0));
      require(_borrower != address(0));
      _;
  }

  modifier isBorrower() {
    require(msg.sender == borrower.id);
    _;
  }

  modifier isLender() {
    require(lenders[msg.sender].amountInvested > 0);
    _;
  }

  modifier atStage(Stages _stage) {
    require(stage == _stage);
    _;
  }

  modifier isApproved(uint256 _amount) {
    require(token.allowance(msg.sender, this) >= _amount);
    _;
  }

  modifier stageWithdraw(uint256 _capital) {
    require(stage != Stages.Init);
    if (stage == Stages.Funding || stage == Stages.Canceled) {
        require(lenders[msg.sender].amountInvested >= _capital);
        lenders[msg.sender].amountInvested = lenders[msg.sender].amountInvested.sub(_capital);
        borrower.principal = borrower.principal.sub(_capital);
        _;
    } else {
          require(lenders[msg.sender].amountRedeemed.add(_capital) <= (lenders[msg.sender].amountInvested.mul(borrower.paid)).div(borrower.principal));
          lenders[msg.sender].amountRedeemed = lenders[msg.sender].amountRedeemed.add(_capital);
          _;
    }
  }

  struct Borrower {
        address id;
        uint256 principal;
        uint256 paid;
  }

  Borrower public borrower;

  struct Lender {
      uint256 amountInvested;
      uint256 amountRedeemed;
  }

  mapping(address => Lender) public lenders;

  ERC20 public token;
  uint256 public start;
 
  /// @notice return loan current stage.
  /// @dev return loan current stage converting in uint8, Init = 0; Funding = 1; Canceled = 2;  Paying = 3; Finished = 4; Defaulted.
  /// @return current stage.
  function stage() public view returns (uint8) {
    return uint8(stage);
  }

}