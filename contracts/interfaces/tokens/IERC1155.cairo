%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace IERC1155 {
    func initializer(
        uri: felt, proxy_admin: felt
    ) {
    }
    func supportsInterface(
        interfaceId: felt
    ) -> (success: felt) {
    }
    func balanceOf(
        account: felt, id: Uint256
    ) -> (balance: Uint256) {
    }
    func balanceOfBatch(
        accounts_len: felt, accounts: felt*, ids_len: felt, ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*) {
    }
    func isApprovedForAll(
        account: felt, operator: felt
    ) -> (is_approved: felt) {
    }
    func setApprovalForAll(
        operator: felt, approved: felt
    ) {
    }
    func safeTransferFrom(
        from_: felt, 
        to: felt, 
        id: Uint256, 
        amount: Uint256, 
        data_len: felt, 
        data: felt*
    ) {
    }
    func safeBatchTransferFrom(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
    }
    func mint(
        to: felt, 
        id: Uint256, 
        amount: Uint256, 
        data_len: felt, 
        data: felt*
    ) {
    }
    func mintBatch(
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
    }
    func burn(
        from_: felt, id: Uint256, amount: Uint256
    ) {

    }
    func burnBatch(
        from_: felt, ids_len: felt, ids: Uint256*, amounts_len: felt, amounts: Uint256*
    ) {

    }    
}