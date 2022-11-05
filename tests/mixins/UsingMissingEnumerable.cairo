%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

namespace TokenImplementation {
    func setup721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        owner: felt
    ) -> (erc721Addr: felt) {
        tempvar erc721Addr;

        %{
            ids.erc721Addr = deploy_contract(
                "./contracts/mocks/ERC721.cairo", 
                [0, 0, ids.owner]
            ).contract_address
        %}
        return (erc721Addr=erc721Addr);
    }
}