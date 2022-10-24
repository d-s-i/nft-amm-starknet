%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

struct PairVariant {
    ENUMERABLE_ETH: felt,
    MISSING_ENUMERABLE_ETH: felt,
    ENUMERABLE_ERC20: felt,
    MISSING_ENUMERABLE_ERC20: felt,
}

namespace PairVariants {
    func value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariants: PairVariant) {
        let _pairVariants = PairVariant(
            ENUMERABLE_ETH=0,
            MISSING_ENUMERABLE_ETH=1,
            ENUMERABLE_ERC20=2,
            MISSING_ENUMERABLE_ERC20=3
        );
        return (_pairVariants=_pairVariants);
    }
}