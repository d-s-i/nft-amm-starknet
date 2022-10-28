%lang starknet

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
}