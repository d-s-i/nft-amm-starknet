%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

namespace CurveErrorCodes {
    struct Error {
        OK: felt,
        INVALID_NUMITEMS: felt,
        SPOT_PRICE_OVERFLOW: felt,
    }

    func ERROR{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (error: Error) {
        let error = Error(
            OK=1, 
            INVALID_NUMITEMS=2,
            SPOT_PRICE_OVERFLOW=3
        );

        return (error=error);
    }
}