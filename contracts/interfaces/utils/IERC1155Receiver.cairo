%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace IERC1155Receiver {
    func supportsInterface(
        interfaceId: felt
    ) -> (isSupported: felt) {
    }

    func setInterfacesSupported(
        interfaceId: felt, 
        isSupported: felt
    ) {
    }
    func onERC1155Received(
        operator: felt, 
        from_: felt, 
        token_id: Uint256, 
        amount: Uint256,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
    }
    func onERC1155BatchReceived(
        operator: felt, 
        from_: felt, 
        token_ids_len: felt,
        token_ids: Uint256*, 
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
    }    
}