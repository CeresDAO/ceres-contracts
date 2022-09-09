
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRelation {
function Inviter(address addr) external view returns (address);
function Nodes(address addr) external view returns (address);
function Daos(address addr) external view returns (address);
function record(address addr0, address token, uint256 amount,address addr,bool pid) external;
function claimed(address addr0, address addr, uint256 amount) external;
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract CERESNFT is Ownable, ERC721A, ReentrancyGuard {
  using SafeERC20 for IERC20;
  // using Address for address payable;

  uint256 public maxNodePerAddressDuringMint;
  uint256 public maxDaoPerAddressDuringMint;
  uint256 public amountForDao;
  uint256 public amountForNode;
  address public Relation;
  address public constant _operationAddress = 0xF4CdcA7fcd78Eeb983AD2834b049192C9Ac1aDBe;
  address public constant _vaultAddress = 0x558662EC0c2fdB2e83b8Dddb849ddA9F20Cb47C2;
  address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;//bsc
  uint256 public constant nodePrice = 10 ** 16;
  uint256 public constant daoPrice = 10 ** 17;
  address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;//bsc
  bool public constant auctionMintOpen = true;


  mapping(address => uint256) public allowlist;

  constructor(
    uint256 maxDaoBatchSize_,
    uint256 maxNodeBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDao_,
    uint256 amountForNode_,
    address relation_
  ) ERC721A("MOCKDAO", "MOCKDAO", maxDaoBatchSize_,maxNodeBatchSize_,collectionSize_) {
    maxDaoPerAddressDuringMint = maxDaoBatchSize_;
    maxNodePerAddressDuringMint = maxNodeBatchSize_;
    amountForDao = amountForDao_;
    amountForNode = amountForNode_;
    Relation = relation_;
  }


  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function auctionMintDao(uint256 quantity, uint256 pid) external nonReentrant callerIsUser {
    require(
      totalSupplyDao() + quantity <= amountForDao,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(
      numberMintedDao(msg.sender) + quantity <= maxDaoPerAddressDuringMint,
      "can not mint this many"
    );

   if(pid == 0){
      require(auctionMintOpen,"Free Mint Not Open");
      require((IRelation(Relation).Inviter(msg.sender) != address(0)) || (allowlist[msg.sender] > 0), "Need to Bind");

    }
    if(pid > 0){
      require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    }

    _safeMintDao(msg.sender, quantity);
    uint256 amount = quantity * daoPrice;
    // require(msg.value == amount, "Pay error");
    // IWETH(WETH).deposit{value : amount}();
    IERC20(USDT).safeTransferFrom(msg.sender,address(this),amount);
    IERC20(USDT).safeTransfer(_vaultAddress,amount * 50/100);
    IERC20(USDT).safeTransfer(_operationAddress,amount * 30/100);
    IERC20(USDT).safeTransfer(Relation,amount * 20/100);
    address daos = IRelation(Relation).Daos(msg.sender);
    address nodes = IRelation(Relation).Nodes(msg.sender);
    IRelation(Relation).record(daos,USDT,amount * 10/100,msg.sender,true);
    IRelation(Relation).record(nodes,USDT,amount * 10/100,msg.sender,true);
    // IERC20(WETH).transfer(IRelation(Relation).inviterAddr(msg.sender),amount * 25/100);
  }

  function auctionMintNode(uint256 quantity, uint256 pid) external nonReentrant callerIsUser {
    require(
      totalSupplyNode() + quantity <= amountForNode,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(
      numberMintedNode(msg.sender) + quantity <= maxNodePerAddressDuringMint,
      "can not mint this many"
    );

    if(pid == 0){
      require(auctionMintOpen,"Free Mint Not Open");
      require((IRelation(Relation).Inviter(msg.sender) != address(0)) || (allowlist[msg.sender] > 0), "Need to Bind");
    }
    if(pid > 0){
      require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    }

    _safeMintNode(msg.sender, quantity);
    uint256 amount = quantity * nodePrice;
    // require(msg.value == amount, "Pay error");
    // IWETH(WETH).deposit{value : amount}();
    IERC20(USDT).safeTransferFrom(msg.sender,address(this),amount);
    IERC20(USDT).safeTransfer(_vaultAddress,amount * 50/100);
    IERC20(USDT).safeTransfer(_operationAddress,amount * 30/100);
    IERC20(USDT).safeTransfer(Relation,amount * 20/100);
    address daos = IRelation(Relation).Daos(msg.sender);
    address nodes = IRelation(Relation).Nodes(msg.sender);
    IRelation(Relation).record(daos,USDT,amount * 10/100,msg.sender,true);
    IRelation(Relation).record(nodes,USDT,amount * 10/100,msg.sender,true);

    // IERC20(WETH).transfer(IRelation(Relation).inviterAddr(msg.sender),amount * 25/100);
  }


  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }


  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function numberMintedDao(address owner) public view returns (uint256) {
    return _numberMintedDao(owner);
  }

  function numberMintedNode(address owner) public view returns (uint256) {
    return _numberMintedNode(owner);
  }

  function DaosNum(uint256 tokenId) external view returns (uint256) {
    return tokenId;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}
