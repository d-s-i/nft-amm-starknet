%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

@external
func setBondingCurveAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    bondingCurveAddr: felt,
    factoryAddr: felt,
    factoryOwnerAddr: felt
) {
    %{stop_prank_factory = start_prank(ids.factoryOwnerAddr, ids.factoryAddr)%}
    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
    %{stop_prank_factory()%}
    return ();
}