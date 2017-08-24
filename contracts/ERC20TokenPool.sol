pragma solidity ^0.4.13;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/ERC20Basic.sol';

contract ERC20TokenPool is Ownable {
  using SafeMath for uint256;

  ERC20Basic public token;
  address[] public shares;
  uint256 public maxShares;
  uint256 public shareCost;
  mapping(address => uint256) private balances;
  uint256 public unclaimed;

  function ERC20TokenPool(address _token, uint256 _maxShares, uint256 _shareCost) {
    require(_maxShares <= 100); // arbitrary; limits gas costs.
    token = ERC20Basic(_token);
    maxShares = _maxShares;
    shareCost = _shareCost;
    unclaimed = 0;
  }

  function remainingShares() returns (uint256 remaining) {
    return maxShares.sub(shares.length);
  }

  function buyShare() payable {
    require(msg.value == shareCost);
    require(shares.length < maxShares);

    shares.push(msg.sender);
  }

  function withdrawEther() onlyOwner {
    owner.transfer(this.balance);
  }

  function distribute() returns (bool success) {
    // only allow distribution if all shares are sold
    // this could be settable in constructor if necessary.
    require(shares.length == maxShares);

    // don't attempt to distributed already distributed but unclaimed funds.
    // make sure we have enough balance to distribute at least 1 token to all
    // shares.
    uint256 balance = token.balanceOf(this).sub(unclaimed);
    require(balance >= shares.length);

    // calculate an even distribution of tokens per share.
    // calculate out the total we're going to distribute to shares.
    // make sure we have enough; I suppose this check is unfailable.
    uint256 perShare = balance / shares.length;
    uint256 xferAmount = perShare.mul(shares.length);
    require(balance >= xferAmount);
    unclaimed = unclaimed.add(xferAmount); // lock the funds out.

    for(uint i=0; i<shares.length; i++) {
      // Re: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      // I don't believe this has the problem because an external call is not
      // setting the allowance and the allowance is calculated during execution
      // rather than passed in as a parameter. Further - there are no calls to
      // another contract between calculating perShare and executing
      // this line so should have no re-entrance issues.
      balances[shares[i]] = balances[shares[i]].add(perShare); // allocate allowance to each share.
    }
    return true;
  }

  function balanceOf(address _owner) returns (uint256 balance) {
    return balances[_owner];
  }

  function withdraw(uint256 amount) returns (bool success) {
    require(balances[msg.sender] >= amount);
    require(unclaimed >= amount);
    unclaimed = unclaimed.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    return token.transfer(msg.sender, amount);
  }
}
