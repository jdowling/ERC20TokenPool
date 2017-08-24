pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC20TokenPool.sol";
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/BasicToken.sol';

contract TestToken is Ownable, BasicToken {
  function TestToken() {
    balances[owner] = 1000000;
  }
}

contract MoneyTrap {
  function() payable { }

  function buyShare(ERC20TokenPool pool, uint256 cost) {
    pool.buyShare.value(cost)();
  }

  function withdraw(ERC20TokenPool pool, uint256 amount) {
    pool.withdraw(amount);
  }
}

contract TestERC20TokenPool {

  uint public initialBalance = 1 ether;
  function() payable { }

  function testTestToken() {
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 1, 0 wei);
    Assert.equal(pool.token(), token, "The pool token should match the expected TestToken");
    Assert.equal(pool.owner(), this, "this should own the pool upon creation");
  }

  function testMaxShares() {
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 10, 0 wei);
    Assert.equal(pool.maxShares(), 10, "The pool should have 10 max shares");
    Assert.equal(pool.remainingShares(), 10, "The pool should have 10 remaining shares");
  }

  function testShareCost() {
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 10, 1 wei);
    Assert.equal(pool.shareCost(), 1 wei, "The share cost should be 1 wei");
  }

  function testBuyShare() {
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 10, 1 wei);
    pool.buyShare.value(1 wei)();
    Assert.equal(pool.shareCost(), 1 wei, "The share cost should be 1 wei");
    Assert.equal(pool.maxShares(), 10, "The pool should have 10 max shares");
    Assert.equal(pool.remainingShares(), 9, "The pool should have 9 remaining shares");
    Assert.equal(pool.shares(0), this, "this owns the first share");
  }

  function testWithdrawEther() {
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 10, 1 wei);
    uint256 initial = this.balance;
    Assert.equal(this.balance, initial, "Before buying a share");
    pool.buyShare.value(1 wei)();
    Assert.equal(this.balance, initial - 1 wei, "after buying a share");
    pool.withdrawEther();
    Assert.equal(this.balance, initial, "Before buying a share");
  }

  function testDistribute() {
    /*TestToken token = new TestToken();*/
    TestToken token = new TestToken();
    ERC20TokenPool pool = new ERC20TokenPool(token, 2, 1 wei);

    MoneyTrap helper1 = new MoneyTrap();
    helper1.transfer(1 wei);
    helper1.buyShare(pool, 1 wei);

    MoneyTrap helper2 = new MoneyTrap();
    helper2.transfer(1 wei);
    helper2.buyShare(pool, 1 wei);

    Assert.isTrue(token.transfer(pool, 7), "Transfer should succeed");
    Assert.equal(token.balanceOf(pool), 7, "pool should own 7 token tokens before distribution");
    bool result = pool.distribute();
    Assert.isTrue(result, "distribution should succeed");
    Assert.equal(token.balanceOf(pool), 7, "pool should own 7 token tokens after distribution");
    Assert.equal(pool.balanceOf(helper1), 3, "helper1 should be owed 3 token tokens after distribution");
    Assert.equal(pool.balanceOf(helper2), 3, "helper2 should be owed 3 token tokens after distribution");

    // test withdraw while we're here
    helper1.withdraw(pool, 1);
    Assert.equal(pool.balanceOf(helper1), 2, "helper1 should be owed 2 token tokens after withdrawing 1");
    Assert.equal(token.balanceOf(helper1), 1, "helper1 should own 1 token tokens after withdrawing 1");
    Assert.equal(token.balanceOf(pool), 6, "pool should own 6 token tokens after withdrawing");

    // check handling remainders
    Assert.isTrue(token.transfer(pool, 7), "Transfer should succeed");
    Assert.equal(token.balanceOf(pool), 13, "pool should own 13 token tokens after depositing more");
    Assert.equal(pool.unclaimed(), 5, "pool should have 5 unclaimed token tokens");
    result = pool.distribute();
    Assert.isTrue(result, "distribution should succeed");
    Assert.equal(token.balanceOf(pool), 13, "pool should own 13 token tokens after distribution");
    Assert.equal(pool.unclaimed(), 13, "pool should have 13 unclaimed token tokens");
    Assert.equal(pool.balanceOf(helper1), 6, "helper1 should be owed 6 token tokens after distribution");
    Assert.equal(pool.balanceOf(helper2), 7, "helper2 should be owed 7 token tokens after distribution");
  }

}
