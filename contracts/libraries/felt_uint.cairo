%lang starknet

from starkware.cairo.common.math import (split_felt, assert_lt_felt)
from starkware.cairo.common.uint256 import (Uint256)

namespace FeltUint {
    func feltToUint256{range_check_ptr: felt}(x: felt) -> (uint_x: Uint256) {
        let (high, low) = split_felt(x);
        return (Uint256(low=low, high=high),);
    }

    func uint256ToFelt{range_check_ptr: felt}(value: Uint256) -> (value: felt) {
        assert_lt_felt(value.high, 2 ** 123);
        return (value.high * (2 ** 128) + value.low,);
    }
}