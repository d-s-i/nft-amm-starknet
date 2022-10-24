%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

struct PoolType {
    TOKEN: felt,
    NFT: felt,
    TRADE: felt,
}

namespace PoolTypes {
    func value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_poolType: PoolType) {
        let _poolType = PoolType(TOKEN=0, NFT=1, TRADE=2);
        return (_poolType=_poolType);
    }
}