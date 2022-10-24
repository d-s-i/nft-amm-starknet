%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_le,
    uint256_sub,
    uint256_eq,
    uint256_add
)

from contracts.libraries.felt_uint import (FeltUint)
from contracts.bonding_curves.FixedPointMathLib import (FixedPointMathLib)
from contracts.bonding_curves.CurveErrorCodes import (CurveErrorCodes)
from contracts.constants.library import (MAX_UINT_128)

// 1 gwei
const MIN_PRICE = 1000000000;

func validateDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    delta: Uint256
) -> (success: felt) {
    let (WAD) = FixedPointMathLib.WAD();
    let (greaterThanWAD) = uint256_lt(WAD, delta);
    return (success=greaterThanWAD);
}

func validateSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newSpotPrice: Uint256
) -> (success: felt) {
    let (minPriceUint) = FeltUint.feltToUint256(MIN_PRICE);
    let (isPositive) = uint256_le(minPriceUint, newSpotPrice);
    return (success=isPositive);
}

func getBuyInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    spotPrice: Uint256,
    delta: Uint256,
    numItems: Uint256,
    feeMultiplier: felt,
    protocolFeeMultiplier: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    alloc_locals;
    // NOTE: we assume delta is > 1, as checked by validateDelta()
    // We only calculate changes for buying 1 or more NFTs
    let (error) = CurveErrorCodes.ERROR();
    let (WAD) = FixedPointMathLib.WAD();

    let (numItemsZero) = uint256_eq(numItems, Uint256(low=0, high=0));
    if(numItemsZero == TRUE) {
        return (
            error.INVALID_NUMITEMS, 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0)
        );
    }

    let (deltaPoW) = FixedPointMathLib.fpow(delta, numItems, WAD);

    // For an exponential curve, the spot price is multiplied by delta for each item bought
    let (newSpotPrice) = FixedPointMathLib.fmul(spotPrice, deltaPoW, WAD);

    let (Lt_MAX_UINT_128) = uint256_lt(newSpotPrice, Uint256(low=MAX_UINT_128, high=0));
    if(Lt_MAX_UINT_128 == FALSE) {
        return (
            error.SPOT_PRICE_OVERFLOW, 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0)
        );
    }

    // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
    // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
    // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S * delta).
    // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
    // If spot price for buy and sell differ by delta, then buying costs (S * delta) ETH.
    // The new spot price would become (S * delta), so selling would also yield (S * delta) ETH.
    let (buySpotPrice) = FixedPointMathLib.fmul(spotPrice, delta, WAD);

    // If the user buys n items, then the total cost is equal to:
    // buySpotPrice + (delta * buySpotPrice) + (delta^2 * buySpotPrice) + ... (delta^(numItems - 1) * buySpotPrice)
    // This is equal to buySpotPrice * (delta^n - 1) / (delta - 1)
    let (_deltaPowN) = uint256_sub(deltaPoW, WAD);
    let (_delta) = uint256_sub(delta, WAD);
    let (val) = FixedPointMathLib.fdiv(_deltaPowN, _delta, WAD);
    let (temp_inputValue1) = FixedPointMathLib.fmul(buySpotPrice, val, WAD);

    // Account for the protocol fee, a flat percentage of the buy amount
    let (protocolFee) = FixedPointMathLib.fmul(
        temp_inputValue1, 
        protocolFeeMultiplier, 
        WAD
    );

    // Account for the trade fee, only for Trade pools
    let (_feeMultiplier) = FeltUint.feltToUint256(feeMultiplier);
    let (temp_inputValue2) = FixedPointMathLib.fmul(
        temp_inputValue1,
        _feeMultiplier,
        WAD
    );
    let (temp_inputValue3, temp_inputValue3Carry) = uint256_add(temp_inputValue1, temp_inputValue2);
    
    // Add the protocol fee to the required input amount
    let (inputValue, inputValueCarry) = uint256_add(temp_inputValue3, protocolFee);
    
    // Keep delta the same
    // and return with error.OK (= no errors)
    return (
        error.OK,
        newSpotPrice,
        delta,
        inputValue,
        protocolFee
    );
}

func getSellInfo{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    spotPrice: Uint256,
    delta: Uint256,
    numItems: Uint256,
    feeMultiplier: felt,
    protocolFeeMultiplier: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    outputAmount: Uint256,
    protocolFee: Uint256
) {

    alloc_locals;
    // NOTE: we assume delta is > 1, as checked by validateDelta()
    // We only calculate changes for buying 1 or more NFTs
    let (error) = CurveErrorCodes.ERROR();
    let (WAD) = FixedPointMathLib.WAD();

    let (numItemsZero) = uint256_eq(numItems, Uint256(low=0, high=0));
    if(numItemsZero == TRUE) {
        return (
            error.INVALID_NUMITEMS, 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0), 
            Uint256(low=0, high=0)
        );
    }

    let (invDelta) = FixedPointMathLib.fdiv(WAD, delta, WAD);
    let (invDeltaPowN) = FixedPointMathLib.fpow(invDelta, numItems, WAD);

    let (temp_newSpotPrice1) = FixedPointMathLib.fmul(spotPrice, invDeltaPowN, WAD);
    let (newSpotPrice) = _adjustSpotPriceToMin(temp_newSpotPrice1);

    let (val) = uint256_sub(WAD, invDeltaPowN);
    let (val2) = uint256_sub(WAD, invDelta);
    let (val3) = FixedPointMathLib.fdiv(val, val2, WAD);
    let (temp_outputValue1) = FixedPointMathLib.fmul(
        spotPrice,
        val3,
        WAD
    );

    // // Account for the protocol fee, a flat percentage of the sell amount
    let (protocolFee) = FixedPointMathLib.fmul(
        temp_outputValue1, 
        protocolFeeMultiplier, 
        WAD
    );

    // // Account for the trade fee, only for Trade pools
    let (feeMultiplierUint) = FeltUint.feltToUint256(feeMultiplier);
    let (val4) = FixedPointMathLib.fmul(temp_outputValue1, feeMultiplierUint, WAD);
    let (temp_outputValue2) = uint256_sub(temp_outputValue1, val4);

    let (outputValue) = uint256_sub(temp_outputValue2, protocolFee);

    // Keep delta the same
    // and return with error.OK (= no errors)
    return (
        error.OK,
        newSpotPrice,
        delta,
        outputValue,
        protocolFee
    );
}

func _adjustSpotPriceToMin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    spotPrice: Uint256
) -> (res: Uint256) {
    // minimum price to prevent numerical issues
    let MIN_PRICE_UINT = Uint256(low=MIN_PRICE, high=0);
    let (Lt_MIN_PRICE) = uint256_lt(spotPrice, MIN_PRICE_UINT);
    if(Lt_MIN_PRICE == TRUE) {
        return (res=MIN_PRICE_UINT);
    }
    return (res=spotPrice);
}