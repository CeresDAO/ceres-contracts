pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CES is ERC20Burnable {
    address mintAdderss;

    constructor(string memory name_, string memory symbol_, address addr_)
        ERC20(name_, symbol_)
    {
        require(addr_ != address(0),"ZERO ADDRESS ERROR");
        mintAdderss = addr_;
        _mint(mintAdderss,  10**12 * 10**18);
    }
}