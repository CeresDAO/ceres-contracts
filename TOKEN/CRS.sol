pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';


contract CRS is ERC20Burnable {
    using SafeMath for uint256;
    address mintAdderss;

    constructor(string memory name_, string memory symbol_,address addr_)
        ERC20(name_, symbol_)
    {
         mintAdderss = addr_;
        _mint(mintAdderss,  10**12 * 10**18);
    }
}