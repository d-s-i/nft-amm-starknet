%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.bonding_curves.XykCurve import (getBuyInfo)

@external
func test_getBuyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    // Should reverse
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = getBuyInfo(
        Uint256(low=5, high=0),
        Uint256(low=10, high=0),
        Uint256(low=0, high=0),
        0,
        Uint256(low=0, high=0)
    );

    return ();
}