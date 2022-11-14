%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_le,
    uint256_lt,
    uint256_mul,
    uint256_add
)
from starkware.cairo.common.bool import (TRUE)

from contracts.bonding_curves.FixedPointMathLib import (FixedPointMathLib)

from tests.utils.units import (ONE_GWEI)

namespace Curve {
    func setupCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (bondingCurveAddr: felt) {
        tempvar bondingCurveAddr;
        %{
            ids.bondingCurveAddr = deploy_contract(f"./contracts/bonding_curves/XykCurve.cairo").contract_address
        %}
        return (bondingCurveAddr=bondingCurveAddr);        
    }
    func modifyDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        delta: Uint256
    ) -> (_delta: Uint256) {
        return (_delta=Uint256(low=11, high=0));
    }
    func modifySpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        spotPrice: Uint256
    ) -> (_spotPrice: Uint256) {
        // 0.01 ether
        return (_spotPrice=Uint256(low=10000000000000000, high=0));
    }
    func getParamsForPartialFillTest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (spotPrice: Uint256, delta: Uint256) {
        return (spotPrice=Uint256(low=10**16, high=0), delta=Uint256(low=11, high=0));
    }
}