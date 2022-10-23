%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

@storage_var
func interfacesSupported(interfaceId: felt) -> (isSupported: felt) {
}

namespace ERC1155Receiver {
    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = interfacesSupported.read(interfaceId);
        return (isSupported=isSupported);
    }

    func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        interfacesSupported.write(interfaceId, isSupported);
        return ();
    }
}