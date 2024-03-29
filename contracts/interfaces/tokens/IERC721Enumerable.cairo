// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts for Cairo v0.4.0 (token/erc721/enumerable/IERC721Enumerable.cairo)

%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace IERC721Enumerable {
    func totalSupply() -> (totalSupply: Uint256) {
    }
    func tokenByIndex(index: Uint256) -> (tokenId: Uint256) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
    func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    }
    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }
    func setApprovalForAll(operator: felt, approved: felt) {
    }    
}