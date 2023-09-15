// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {BEP20} from "./libraries/BEP20/BEP20.sol";

//import "@openzeppelin/contracts/token/BEP20/extensions/draft-BEP20Permit.sol";
//import "@openzeppelin/contracts/token/BEP20/extensions/BEP20Votes.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is BEP20 {
    mapping(uint => address) public crossChain;

    constructor(uint256 _amount) BEP20("MyToken", "MTK", 18) {
        _mint(msg.sender, _amount);
    }

    /* 
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal  {
        super._afterTokenTransfer(from, to, amount);
    }
 */
    function _mint(address to, uint256 amount) internal override(BEP20) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(BEP20) {
        super._burn(account, amount);
    }

    // Mint function required for Masterchef contract to create new tokens
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function addCrossChainContract(
        uint256 _chainId,
        address _tokenContractAddress
    ) public {
        crossChain[_chainId] = _tokenContractAddress;
    }

    function removeCrossChainContract(uint256 _chainId) public {
        delete crossChain[_chainId];
    }

    function crossChainLookup(uint256 _chainId) public view returns (address) {
        return crossChain[_chainId];
    }
}
