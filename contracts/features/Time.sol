pragma solidity 0.4.18;

import "../loan/StructureLoan.sol";

contract Time is StructureLoan {

  struct TimeData {
      uint256 funding;
      uint256 funded;
      uint256 paying;
      uint256 accepted;
      uint256 ended;
  }

  TimeData public time;

  function Time(uint256 _fundingDate, uint256 _payingDate) 
      public
  {
      time.funding = _fundingDate;
      time.paying = _payingDate; 
  }

  modifier timeFund() {
      _;
      if (borrower.principal == requestedCapital) time.funded = block.timestamp;
  }

  modifier timeAccepted() {
      _;
      time.accepted = block.timestamp;
  }

  modifier timePayBack() {
      require(time.accepted > 0);
      if (time.paying > 0) require(block.timestamp < time.accepted.add(time.paying));
      _;
  }
}