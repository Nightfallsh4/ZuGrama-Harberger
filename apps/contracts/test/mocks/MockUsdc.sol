// SPDX-License-Identifier: GPL-v3
pragma solidity 0.8.26;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUsdc is ERC20 {
    constructor() ERC20("USDC", "USDC") { }

    function mint(address _to, uint256 amount) external {
        _mint(_to, amount);
    }

    function decimals() public view override returns (uint8) {
        return 6;
    }
}
