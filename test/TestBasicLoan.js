import expectThrow from './helpers/expectThrow';

const Loan = artifacts.require('BasicLoan');
const ERC20Token = artifacts.require('ERC20Token');

contract('Basic Loan', (accounts) => {

  let token;
  let loan;
  let owner = accounts[0];
  let initialAmount = 1000;
  let lenderOne = accounts[1];
  let lenderTwo = accounts[2];
  let lenderThree = accounts[3];
  let requestedCapital = 100;

  before(async () => {
    token = await ERC20Token.new(initialAmount);
    loan = await Loan.new(token.address, owner, requestedCapital);
    token.transfer(lenderOne, 40);
    token.transfer(lenderTwo, 60);
    token.transfer(lenderThree, 50);
  });

  it('should set the start values properly', async () => {
    //Loan start values
    let stage =  await loan.stage();
    assert.equal(stage.valueOf(), 0, 'should be 0');

    let _requestedCapital = await loan.getAmount();
    assert.equal(_requestedCapital, requestedCapital, 'should be the same');

    let tokenAddress = await loan.getTokenAddress();
    assert.equal(tokenAddress, token.address, 'should be the same');

    let borrower = await loan.getBorrower()
    assert.equal(borrower, owner, 'should be the same');

    let loanOwner = await loan.owner.call();
    assert.equal(loanOwner, owner, 'should be the same');
    
    // token start values
    let supply = await token.totalSupply();
    assert.equal(supply.valueOf(), initialAmount, 'should be the same');

    let balanceLenderOne = await token.balanceOf(lenderOne);
    assert.equal(balanceLenderOne.valueOf(), 40, 'should be 40');

    let balanceLenderTwo = await token.balanceOf(lenderTwo);
    assert.equal(balanceLenderTwo.valueOf(), 60, 'should be 60');

    let balanceLenderThree = await token.balanceOf(lenderThree);
    assert.equal(balanceLenderThree.valueOf(), 50, 'should be 50');

    let balanceOwner = await token.balanceOf(owner);
    assert.equal(balanceOwner.valueOf(), initialAmount- balanceLenderOne - balanceLenderTwo - balanceLenderThree, 'should be the same');
  });

  it('should not begin the loan if is call from an address that is not the owner', async () => {
    await expectThrow(loan.begin({from: accounts[7]}));
  });

  it('should begin the loan properly', async () => {
    loan.begin();

    let loanOwner = await loan.owner.call();
    assert.equal(loanOwner, "0x0000000000000000000000000000000000000000", 'should be 0x0');

    let stage =  await loan.stage();
    assert.equal(stage.valueOf(), 1, 'should be 1');
  });

  it('should accept funds by lenders', async () => {
    // first lender
    let firstAmount = 35;
    await token.approve(loan.address, firstAmount, {from: lenderOne});
    let allowance = await token.allowance(lenderOne, loan.address);
    assert.equal(allowance.valueOf(), firstAmount, 'should be the same');
    await loan.fund(firstAmount, {from: lenderOne});
    let balanceLenderOne = await token.balanceOf(lenderOne);
    assert.equal(balanceLenderOne.valueOf(), 40-firstAmount, 'should be 5');
    let balanceLoan = await token.balanceOf(loan.address);
    assert.equal(balanceLoan.valueOf(), firstAmount, 'should be 35');
    let borroweStruct = await loan.borrower.call();
    let borrowerPrincpipal = borroweStruct[1].valueOf()
    assert.equal(borrowerPrincpipal, firstAmount, 'should be the same');
    let lenderOneStruct = await loan.lenders.call(lenderOne);
    let amountInvestedByLenderOne = lenderOneStruct[0].valueOf();
    assert.equal(amountInvestedByLenderOne, firstAmount, 'should be the same');
    // second lender
    let secondAmount = 55;
    await token.approve(loan.address, secondAmount, {from: lenderTwo});
    allowance = await token.allowance(lenderTwo, loan.address);
    assert.equal(allowance.valueOf(), secondAmount, 'should be the same');
    await loan.fund(secondAmount, {from: lenderTwo});
    let balanceLenderTwo = await token.balanceOf(lenderTwo);
    assert.equal(balanceLenderTwo.valueOf(), 60-secondAmount, 'should be 5');
    balanceLoan = await token.balanceOf(loan.address);
    assert.equal(balanceLoan.valueOf(), firstAmount + secondAmount, 'should be 90');
    borroweStruct = await loan.borrower.call();
    borrowerPrincpipal = borroweStruct[1].valueOf()
    assert.equal(borrowerPrincpipal, firstAmount + secondAmount, 'should be the same');
    let lenderTwoStruct = await loan.lenders.call(lenderTwo);
    let amountInvestedByLenderTwo = lenderTwoStruct[0].valueOf();
    assert.equal(amountInvestedByLenderTwo, secondAmount, 'should be the same');
  });

  it('should accept only the amount necessary to reach the request capital', async () => {
    // third lender
    let thirdAmount = 20;
    await token.approve(loan.address, thirdAmount, {from: lenderThree});
    let allowance = await token.allowance(lenderThree, loan.address);
    assert.equal(allowance.valueOf(), thirdAmount, 'should be the same');
    await loan.fund(thirdAmount, {from: lenderThree});
    let balanceLenderThree = await token.balanceOf(lenderThree);
    assert.equal(balanceLenderThree.valueOf(), 40, 'should be 40');
    let balanceLoan = await token.balanceOf(loan.address);
    assert.equal(balanceLoan.valueOf(), 100, 'should be 100');
    let borroweStruct = await loan.borrower.call();
    let borrowerPrincpipal = borroweStruct[1].valueOf()
    assert.equal(borrowerPrincpipal, 100, 'should be the same');
    let lenderThreeStruct = await loan.lenders.call(lenderThree);
    let amountInvestedByLenderThree = lenderThreeStruct[0].valueOf();
    assert.equal(amountInvestedByLenderThree, 10, 'should be the same');
  });

  it('should not accept more funds', async () => {
    let thirdAmountAgain = 20;
    await token.approve(loan.address, thirdAmountAgain, {from: lenderThree});
    let allowance = await token.allowance(lenderThree, loan.address);
    assert.equal(allowance.valueOf(), thirdAmountAgain, 'should be the same');
    await expectThrow(loan.fund(thirdAmountAgain, {from: lenderThree}));
  });

  



});
