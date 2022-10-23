%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace IERC20 {
    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }
    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}