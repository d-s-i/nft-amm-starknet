%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_mul,
    uint256_le,
    uint256_lt,
    uint256_eq,
    uint256_unsigned_div_rem,
    assert_uint256_eq
)

from contracts.constants.library import (MAX_UINT_128)

from contracts.libraries.felt_uint import (FeltUint)
from contracts.bonding_curves.CurveErrorCodes import (CurveErrorCodes)
from contracts.bonding_curves.FixedPointMathLib import (FixedPointMathLib)
from contracts.bonding_curves.ExponentialCurve import (getBuyInfo, getSellInfo)

// 1 gwei
const MIN_PRICE = 1000000000;

@external
func setup_getBuyInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ 
        given(
            _spotPrice = strategy.integers(0, 340282366920938463463374607431768211455),
            _delta = strategy.integers(0, 18446744073709551615),
            _numItems = strategy.integers(0, 255)
        ) 
    %}
    return ();
}

@external
func setup_getSellInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ 
        given(
            _spotPrice = strategy.integers(0, 340282366920938463463374607431768211455),
            _delta = strategy.integers(0, 340282366920938463463374607431768211455),
            _numItems = strategy.integers(0, 255)
        ) 
    %}
    return ();
}

@external
func test_getBuyInfoExample{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();
    let (fiveWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=5, high=0));
    let (threeWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=3, high=0));
    let (_96_WETH) = FeltUint.feltToUint256(96000000000000000000);
    let (_2_WETH) = FeltUint.feltToUint256(2000000000000000000);
    let (_3_WETH) = FeltUint.feltToUint256(3000000000000000000);
    let (_187_488_WETH) = FeltUint.feltToUint256(187488000000000000000);
    let (_0588_WETH) = FeltUint.feltToUint256(558000000000000000);

    // 3 WETH
    let spotPrice = _3_WETH;
    // 2 WETH
    let delta = _2_WETH;
    let (numItems) = FeltUint.feltToUint256(5);
    // 0.5%
    let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    let (feeMultiplier) = FeltUint.Uint256ToFelt(feeMultiplierUint);
    // 0.3%
    let (protocolFeeMultiplier, protocolFeeMultiplierRem) = uint256_unsigned_div_rem(threeWAD, Uint256(low=1000, high=0));

    let (
        error,
        newSpotPrice,
        newDelta,
        inputValue,
        protocolFee
    ) = getBuyInfo(
        spotPrice,
        delta,
        numItems,
        feeMultiplier,
        protocolFeeMultiplier
    );

    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"inputAmount: {ids.inputValue.low + ids.inputValue.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}
    
    assert error = errors.OK;
    assert_uint256_eq(newSpotPrice, _96_WETH);
    assert_uint256_eq(newDelta, _2_WETH);
    assert_uint256_eq(inputValue, _187_488_WETH);
    assert_uint256_eq(protocolFee, _0588_WETH);

    return ();
}

@external
func test_getBuyInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();

    let (spotPrice) = FeltUint.feltToUint256(_spotPrice);
    let (delta) = FeltUint.feltToUint256(_delta);
    let (numItems) = FeltUint.feltToUint256(_numItems);

    let (deltaLtWAD) = uint256_lt(delta, WAD);
    let (numItemsGtTen) = uint256_lt(Uint256(low=10, high=0), numItems);
    let (spotPriceLtMin) = uint256_lt(spotPrice, Uint256(low=MIN_PRICE, high=0));
    let (noItems) = uint256_eq(numItems, Uint256(low=0, high=0));

    if(deltaLtWAD == TRUE) {
        return ();
    } 
    if(numItemsGtTen == TRUE) {
        return ();
    } 
    if(spotPriceLtMin == TRUE) {
        return ();
    } 
    if(noItems == TRUE) {
        return ();
    } 
    let (
        error,
        newSpotPrice,
        newDelta,
        inputValue,
        protocolFee
    ) = getBuyInfo(spotPrice, delta, numItems, 0, Uint256(low=0, high=0));

    let (deltaPowN) = FixedPointMathLib.fpow(delta, numItems, WAD);
    let (fullWidthNewSpotPrice) = FixedPointMathLib.fmul(spotPrice, deltaPowN, WAD);

    let (fullWidthGtMax) = uint256_lt(Uint256(low=MAX_UINT_128, high=0), fullWidthNewSpotPrice);
    if(fullWidthGtMax == TRUE) {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
        with_attr error_message("Error code should be SPOT_PRICE_OVERFLOW") {
            assert error = errors.SPOT_PRICE_OVERFLOW;
        }
    } else {
        with_attr error_message("Error code should be OK") {
            assert error = errors.OK;
        }

        let (spotPricePositive) = uint256_lt(Uint256(low=0, high=0), spotPrice);
        let (numItemsPositive) = uint256_lt(Uint256(low=0, high=0), numItems);

        if(spotPricePositive == TRUE) {
            
            if(numItemsPositive == TRUE) {
                let (newSpotPriceIncreased) = uint256_lt(spotPrice, newSpotPrice);
                let (deltaGtWAD) = uint256_lt(WAD, delta);

                // (newSpotPrice > spotPrice && delta > FixedPointMathLib.WAD)
                if(newSpotPriceIncreased == TRUE) {
                    assert deltaGtWAD = TRUE;
                    tempvar syscall_ptr = syscall_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                } else {
                    let (spotPriceIdle) = uint256_eq(spotPrice, newSpotPrice);
                    let (deltaIdle) = uint256_eq(delta, WAD);

                    if(spotPriceIdle == TRUE) {
                        assert deltaIdle = TRUE;
                        tempvar syscall_ptr = syscall_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                        tempvar range_check_ptr = range_check_ptr;
                    } else {
                        with_attr error_message("Price update incorrect") {
                            assert 1 = 2;
                        }
                        tempvar syscall_ptr = syscall_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                        tempvar range_check_ptr = range_check_ptr;
                    }
                }
            } else {
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            }
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;

        let (numItemsXspotPrice, numItemsXspotPriceHigh) = uint256_mul(numItems, spotPrice);
        assert_uint256_eq(numItemsXspotPriceHigh, Uint256(low=0, high=0));
        let (inputValueCorrect) = uint256_le(numItemsXspotPrice, inputValue);
        assert inputValueCorrect = TRUE;

        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;

    } 

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;

    return ();
}

@external
func test_getSellInfoExample{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();
    let (fiveWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=5, high=0));
    let (threeWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=3, high=0));
    let (_2_WETH) = FeltUint.feltToUint256(2000000000000000000);
    let (_3_WETH) = FeltUint.feltToUint256(3000000000000000000);
    // 0.09375 WETH
    let (_0_09375_WETH) = FeltUint.feltToUint256(93750000000000000);
    // 5.766 WETH
    let (_5_766_WETH) = FeltUint.feltToUint256(5766000000000000000);
    // 0.0174375 WETH
    let (_0_0174375_WETH) = FeltUint.feltToUint256(17437500000000000);

    // 3 WETH
    let spotPrice = _3_WETH;
    // 2 WETH
    let delta = _2_WETH;
    let (numItems) = FeltUint.feltToUint256(5);
    // 0.5%
    let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    let (feeMultiplier) = FeltUint.Uint256ToFelt(feeMultiplierUint);
    // 0.3%
    let (protocolFeeMultiplier, protocolFeeMultiplierRem) = uint256_unsigned_div_rem(threeWAD, Uint256(low=1000, high=0));

    let (
        error,
        newSpotPrice,
        newDelta,
        outputValue,
        protocolFee
    ) = getSellInfo(
        spotPrice,
        delta,
        numItems,
        feeMultiplier,
        protocolFeeMultiplier
    );

    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"outputAmount: {ids.outputValue.low + ids.outputValue.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}
    
    // error.OK = 1
    assert error = errors.OK;
    assert_uint256_eq(newSpotPrice, _0_09375_WETH);
    assert_uint256_eq(newDelta, _2_WETH);
    assert_uint256_eq(outputValue, _5_766_WETH);
    assert_uint256_eq(protocolFee, _0_0174375_WETH);

    return ();
}

@external
func test_getSellInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    %{
        print(f"_spotPrice: {ids._spotPrice}")
        print(f"_delta: {ids._delta}")
        print(f"_numItems: {ids._numItems}")
    %}

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();

    let (spotPrice) = FeltUint.feltToUint256(_spotPrice);
    let (delta) = FeltUint.feltToUint256(_delta);
    let (numItems) = FeltUint.feltToUint256(_numItems);

    let (deltaLtWAD) = uint256_lt(delta, WAD);
    let (spotPriceLtMin) = uint256_lt(spotPrice, Uint256(low=MIN_PRICE, high=0));
    let (noItems) = uint256_eq(numItems, Uint256(low=0, high=0));

    if(deltaLtWAD == TRUE) {
        return ();
    } 
    if(spotPriceLtMin == TRUE) {
        return ();
    } 
    if(noItems == TRUE) {
        return ();
    } 

    let (
        error,
        newSpotPrice,
        newDelta,
        outputValue,
        protocolFee
    ) = getSellInfo(
        spotPrice, 
        delta, 
        numItems, 
        0, 
        Uint256(low=0, high=0)
    );

    let (numItemsXspotPrice, numItemsXspotPriceHigh) = uint256_mul(numItems, spotPrice);
    assert_uint256_eq(numItemsXspotPriceHigh, Uint256(low=0, high=0));
    let (outputValueCorrect) = uint256_le(outputValue, numItemsXspotPrice);
    assert outputValueCorrect = TRUE;

    let (spotPriceGtMin) = uint256_lt(Uint256(low=MIN_PRICE, high=0), spotPrice);
    let (numItemsPositive) = uint256_lt(Uint256(low=0, high=0), numItems);
    if(spotPriceGtMin == TRUE) {
        if(numItemsPositive == TRUE) {
            let (spotPriceIdle) = uint256_eq(spotPrice, newSpotPrice);
            if(spotPriceIdle == TRUE) {
                with_attr error_message("Price update incorrect (delta no equal to 0)") {
                    assert_uint256_eq(delta, Uint256(low=0, high=0));
                }
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                let (spotPriceDecreased) = uint256_lt(newSpotPrice, spotPrice);
                let (deltaPositive) = uint256_lt(Uint256(low=0, high=0), delta);
                if(spotPriceDecreased == TRUE) {
                    with_attr error_message("Price update incorrect (delta should be positive)") {
                        assert deltaPositive = TRUE;
                    }
                    tempvar syscall_ptr = syscall_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                } else {
                    with_attr error_message("Price update incorrect") {
                        assert 1 = 2;
                    }
                    tempvar syscall_ptr = syscall_ptr;
                    tempvar pedersen_ptr = pedersen_ptr;
                    tempvar range_check_ptr = range_check_ptr;
                }
            }
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;


    return ();
}