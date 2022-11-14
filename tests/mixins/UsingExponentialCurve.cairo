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
            ids.bondingCurveAddr = deploy_contract(f"./contracts/bonding_curves/ExponentialCurve.cairo").contract_address
        %}
        return (bondingCurveAddr=bondingCurveAddr);        
    }
    func modifyDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        delta: Uint256
    ) -> (_delta: Uint256) {
        let (WAD) = FixedPointMathLib.WAD();
        let (lteWAD) = uint256_le(delta, WAD);
        if(lteWAD == TRUE) {
            let (_delta, _deltaCarry) = uint256_add(
                WAD, 
                Uint256(low=delta.low + 1, high= delta.high)
            );
            return (_delta=_delta);
        } else {
            let (doubleWADLow, doubleWADHigh) = uint256_mul(WAD, Uint256(low=2, high=0));
            let (deltaTooBig) = uint256_lt(doubleWADLow, delta);
            if(deltaTooBig == TRUE) {
                return (_delta=doubleWADLow);
            }
        }
        return (_delta=delta);
    }
    func modifySpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        spotPrice: Uint256
    ) -> (_spotPrice: Uint256) {
        let (spotPriceTooSmall) = uint256_lt(spotPrice, Uint256(low=ONE_GWEI, high=0));
        if(spotPriceTooSmall == TRUE) {
            return (_spotPrice=Uint256(low=ONE_GWEI, high=0));
        }
        return (_spotPrice=spotPrice);
    }
    func getParamsForPartialFillTest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (spotPrice: Uint256, delta: Uint256) {
        // Return 1 eth as spot price and 10% as the delta scaling
        return (spotPrice=Uint256(low=10**18, high=0), delta=Uint256(low=11*10**17, high=0));
    }
}