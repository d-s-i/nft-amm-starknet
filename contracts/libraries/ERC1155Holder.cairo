%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.libraries.ERC1155Receiver import (ERC1155Receiver)

from contracts.constants.library import (ON_ERC1155_RECEIVED_SELECTOR, ON_ERC1155_BATCH_RECEIVED_SELECTOR, IERC1155_RECEIVER_ID)

namespace ERC1155Holder {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        setInterfacesSupported(IERC1155_RECEIVER_ID, TRUE);
        setInterfacesSupported(interfaceId, isSupported);
        return ();
    }
    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = ERC1155Receiver.supportsInterface(interfaceId);
        return (isSupported=isSupported);
    }

    func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        ERC1155Receiver.setInterfacesSupported(interfaceId, isSupported);
        return ();
    }

    func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        operator: felt, 
        from_: felt, 
        token_id: Uint256, 
        amount: Uint256,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
        return (selector=ON_ERC1155_RECEIVED_SELECTOR);
    }

    func onERC1155BatchReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        operator: felt, 
        from_: felt, 
        token_ids_len: felt,
        token_ids: Uint256*, 
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
        return (selector=ON_ERC1155_BATCH_RECEIVED_SELECTOR);
    }        
}