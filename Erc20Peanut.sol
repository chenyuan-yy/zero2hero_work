// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces.sol";

contract PeanutErc20 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _banlance;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    constructor() {
      _name = "Peanut Token";
      _symbol = "NUT";
      _decimals = 18;
      _totalSupply = 9999 * 10**18;
      _banlance[msg.sender] = _totalSupply;

      emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    // function getOwer() external view override returns (address) {
    //     return owner();
    // }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _banlance[owner];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address recipient, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _spendAllowance(sender, _msgSender(), amount);
       // _approve(sender, _msgSender(), recipient, _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address sender, uint256 addValue) public returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender].add(addValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require (currentAllowance > subtractedValue, "decreased allowance below zero");

        unchecked {
            _approve(owner, spender, currentAllowance.sub(subtractedValue));
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        uint256 fromBalance = _banlance[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _banlance[from] -= amount;
            _banlance[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }
 }
