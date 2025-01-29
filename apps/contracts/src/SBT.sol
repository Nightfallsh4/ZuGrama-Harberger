// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "src/utils/Errors.sol";

contract SBT is ERC721, Ownable {
    address public harberger;

    modifier onlyHarberger() {
        if (msg.sender != harberger) {
            revert SBT_Only_Harberger();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _harberger,
        address _initialOwner
    )
        ERC721(_name, _symbol)
        Ownable(_initialOwner)
    {
        harberger = _harberger;
    }

    function mint(address _to, uint256 _tokenId) external onlyHarberger {
        _mint(_to, _tokenId);
    }

    function approve(address to, uint256 tokenId) public override onlyHarberger {
        _approve(to, tokenId, _msgSender());
    }

    function setApprovalForAll(
        address,
        /**
         * operator
         */
        bool
    )
        /**
         * approved
         */
        public
        override
    {
        revert SBT_Function_Disabled();
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyHarberger {
        super.transferFrom(from, to, tokenId);
    }

    function changeHarberger(address _newHarberger) external onlyOwner {
        harberger = _newHarberger;
    }

    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view override {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else if (msg.sender == harberger) {
                return ;
            }else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }
}
