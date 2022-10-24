%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace IERC1155 {
    func safeTransferFrom(
        from_: felt, to: felt, id: Uint256, amount: Uint256, data_len: felt, data: felt*
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
}