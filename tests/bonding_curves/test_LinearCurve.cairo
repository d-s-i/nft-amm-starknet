%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_unsigned_div_rem,
    uint256_mul,
    uint256_add,
    uint256_lt,
    uint256_le,
    uint256_eq,
    assert_uint256_eq,
    assert_uint256_le
)

from contracts.constants.library import (MAX_UINT_128)

from contracts.libraries.felt_uint import (FeltUint)
from contracts.bonding_curves.FixedPointMathLib import (FixedPointMathLib)
from contracts.bonding_curves.CurveErrorCodes import (CurveErrorCodes)
from contracts.bonding_curves.LinearCurve import (getBuyInfo, getSellInfo)

@external
func setup_getBuyInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ 
        given(
            _spotPrice = strategy.integers(0, 340282366920938463463374607431768211455),
            _delta = strategy.integers(0, 340282366920938463463374607431768211455),
            _numItems = strategy.integers(1, 255)
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
            _numItems = strategy.integers(1, 255)
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
    let (_0_1_WETH) = FeltUint.feltToUint256(100000000000000000);
    let (_3_WETH) = FeltUint.feltToUint256(3000000000000000000);
    let (_3_5_WETH) = FeltUint.feltToUint256(3500000000000000000);
    let (_16_632_WETH) = FeltUint.feltToUint256(16632000000000000000);
    let (_0_0495_WETH) = FeltUint.feltToUint256(49500000000000000);

    // 3 WETH
    let spotPrice = _3_WETH;
    // 2 WETH
    let delta = _0_1_WETH;
    let numItems = Uint256(low=5, high=0);
    // 0.5%
    let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    let (feeMultiplier) = FeltUint.uint256ToFelt(feeMultiplierUint);
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

    assert error = errors.OK;
    assert_uint256_eq(newSpotPrice, _3_5_WETH);
    assert_uint256_eq(newDelta, _0_1_WETH);
    assert_uint256_eq(inputValue, _16_632_WETH);
    assert_uint256_eq(protocolFee, _0_0495_WETH);

    return ();
}

@external
func test_getBuyInfoError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

// _spotPrice = 0
// _delta = 340282366920938463463374607431768211455
// _numItems = 1

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();
    let (fiveWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=5, high=0));
    let (threeWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=3, high=0));

    // 3 WETH
    let spotPrice = Uint256(low=0, high=0);
    // 2 WETH
    let (delta) = FeltUint.feltToUint256(340282366920938463463374607431768211455);
    let numItems = Uint256(low=1, high=0);
    // 0.5%
    let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    let (feeMultiplier) = FeltUint.uint256ToFelt(feeMultiplierUint);
    // 0.3%
    let (protocolFeeMultiplier, protocolFeeMultiplierRem) = uint256_unsigned_div_rem(threeWAD, Uint256(low=1000, high=0));

    %{
        print(f"feeMultiplier: {ids.feeMultiplier}") 
        print(f"protocolFeeMultiplier: {ids.protocolFeeMultiplier.low + ids.protocolFeeMultiplier.high}")
    %}

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

    assert error = errors.OK;

    return ();
}

@external
func test_getBuyInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    let (errors) = CurveErrorCodes.ERROR();

    let (spotPrice) = FeltUint.feltToUint256(_spotPrice);
    let (delta) = FeltUint.feltToUint256(_delta);
    let (numItems) = FeltUint.feltToUint256(_numItems);

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
        0,
        Uint256(low=0, high=0)
    );

    let (deltaXnumItems, deltaXnumItemsHigh) = uint256_mul(delta, numItems);
    with_attr error_message("getBuyInfoWithoutFee - deltaXnumItems overflow") {
        assert_uint256_eq(deltaXnumItemsHigh, Uint256(low=0, high=0));
    }
    let (expectedSpotPrice, exppectedSpotPriceCarry) = uint256_add(spotPrice, deltaXnumItems);
    let (spotPriceShouldOverflow) = uint256_lt(Uint256(low=MAX_UINT_128, high=0), expectedSpotPrice);
    if(spotPriceShouldOverflow == TRUE) {
        with_attr error_message("getBuyInfoWithoutFee - Error should be overflow, found {error}") {
            assert error = errors.SPOT_PRICE_OVERFLOW;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        with_attr error_message("getBuyInfoWithoutFee - Error should be ok if no overflow planned, found {error}") {
            assert error = errors.OK;
        }

        let (spotPriceIdle) = uint256_eq(newSpotPrice, spotPrice);
        let (deltaIdle) = uint256_eq(newDelta, delta);

        if(spotPriceIdle == TRUE) {
            with_attr error_message("getBuyInfoWithoutFee - If spot price idle, delta should be equal to 0, found {delta}") {
                assert deltaIdle = TRUE;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            let (spotPriceIncreased) = uint256_lt(spotPrice, newSpotPrice);
            let (deltaPositive) = uint256_lt(Uint256(low=0, high=0), delta);
            with_attr error_message("getBuyInfoWithoutFee - Price update incorrect, expected price to increase (old price: {spotPrice}, new price: {newSpotPrice})") {
                assert spotPriceIncreased = TRUE;
            }
            with_attr error_message("getBuyInfoWithoutFee - Price update incorrect, expected delta to be greater than 0, found {delta}") {
                assert deltaPositive = TRUE;
            }

            let (minInputValue, minInputValueHigh) = uint256_mul(numItems, spotPrice);
            with_attr error_message("getBuyInfoWithoutFee - minInputValue overflow") {
                assert_uint256_eq(minInputValueHigh, Uint256(low=0, high=0));
            }

            let (inputValueCorrect) = uint256_lt(minInputValue, inputValue);
            with_attr error_message("getBuyInfoWithoutFee - Input value incorrect (should be gt {minInputValue}, found {inputValue}") {
                assert inputValueCorrect = TRUE;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
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
    let (_0_1_WETH) = FeltUint.feltToUint256(100000000000000000);
    let (_3_WETH) = FeltUint.feltToUint256(3000000000000000000);
    let (_2_5_WETH) = FeltUint.feltToUint256(2500000000000000000);
    let (_13_888_WETH) = FeltUint.feltToUint256(13888000000000000000);
    let (_0_0442_WETH) = FeltUint.feltToUint256(42000000000000000);

    // 3 WETH
    let spotPrice = _3_WETH;
    // 2 WETH
    let delta = _0_1_WETH;
    let numItems = Uint256(low=5, high=0);
    // 0.5%
    let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    let (feeMultiplier) = FeltUint.uint256ToFelt(feeMultiplierUint);
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
        print(f"outputValue: {ids.outputValue.low + ids.outputValue.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}

    assert error = errors.OK;
    assert_uint256_eq(newSpotPrice, _2_5_WETH);
    assert_uint256_eq(newDelta, _0_1_WETH);
    assert_uint256_eq(outputValue, _13_888_WETH);
    assert_uint256_eq(protocolFee, _0_0442_WETH);

    return ();
}

@external
func test_getSellInfoError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

// _spotPrice = 1
// _delta = 1
// _numItems = 2

    let (WAD) = FixedPointMathLib.WAD();
    let (errors) = CurveErrorCodes.ERROR();
    let (fiveWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=5, high=0));
    let (threeWAD, fiveWADHigh) = uint256_mul(WAD, Uint256(low=3, high=0));

    let spotPrice = Uint256(low=1, high=0);
    let (delta) = FeltUint.feltToUint256(1);
    let numItems = Uint256(low=2, high=0);
    // // 0.5%
    // let (feeMultiplierUint, feeMultiplierUintRem) = uint256_unsigned_div_rem(fiveWAD, Uint256(low=1000, high=0));
    // let (feeMultiplier) = FeltUint.uint256ToFelt(feeMultiplierUint);
    let feeMultiplier = 0;
    // // 0.3%
    // let (protocolFeeMultiplier, protocolFeeMultiplierRem) = uint256_unsigned_div_rem(threeWAD, Uint256(low=1000, high=0));
    let protocolFeeMultiplier = Uint256(low=0, high=0);

    local _spotPrice: Uint256 = spotPrice;
    local _numItems: Uint256 = numItems;
    local _protocolFeeMultiplier: Uint256 = protocolFeeMultiplier;
    %{
        print(f"running getSellInfo with: ");
        print(f"spotPrice: {ids._spotPrice.low + ids._spotPrice.high}")
        print(f"delta: {ids.delta.low + ids.delta.high}")
        print(f"numItems: {ids._numItems.low + ids._numItems.high}")
        print(f"feeMultiplier: {ids.feeMultiplier}") 
        print(f"protocolFeeMultiplier: {ids._protocolFeeMultiplier.low + ids._protocolFeeMultiplier.high}")
    %}

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

    %{
        print("\n --- RESULT --- ")
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"outputValue: {ids.outputValue.low + ids.outputValue.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}
    
    assert error = errors.OK;
    with_attr error_message("getSellInfoError - newSpotPrice value incorrect") {
        assert_uint256_eq(newSpotPrice, Uint256(low=0, high=0));
    }
    with_attr error_message("getSellInfoError - newDelta value incorrect") {
        assert_uint256_eq(newDelta, Uint256(low=1, high=0));
    }
    with_attr error_message("getSellInfoError - outputValue value incorrect") {
        assert_uint256_eq(outputValue, Uint256(low=0, high=0));
    }
    with_attr error_message("getSellInfoError - protocolFee value incorrect") {
        assert_uint256_eq(protocolFee, Uint256(low=0, high=0));
    }

    return ();
}

@external
func test_getSellInfoWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    let (errors) = CurveErrorCodes.ERROR();

    let (spotPrice) = FeltUint.feltToUint256(_spotPrice);
    let (delta) = FeltUint.feltToUint256(_delta);
    let (numItems) = FeltUint.feltToUint256(_numItems);

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

    // %{
    //     print(f"error: {ids.error}")
    //     print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
    //     print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
    //     print(f"outputValue: {ids.outputValue.low + ids.outputValue.high}")
    //     print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    // %}

    with_attr error_message("getSellInfoWithoutFee - Error code should be OK, found {error}") {
        assert error = errors.OK;
    }

    let (totalPriceDecrease, totalPriceDecreaseRem) = uint256_unsigned_div_rem(delta, numItems);
    let (spotPriceShouldBeZero) = uint256_lt(spotPrice, totalPriceDecrease);
    if(spotPriceShouldBeZero == TRUE) {
        with_attr error_message("getSellInfoWithoutFee - New spot price should be zero, found {newSpotPrice}") {
            assert_uint256_eq(newSpotPrice, Uint256(low=0, high=0));
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;

    let (spotPricePositive) = uint256_lt(Uint256(low=0, high=0), spotPrice);
    if(spotPricePositive == TRUE) {
        let (spotPriceIdle) = uint256_eq(spotPrice, newSpotPrice);
        if(spotPriceIdle == TRUE) {
            with_attr error_message("getSellInfoWithoutFee - If spot price idle, delta sould be 0, found {delta}") {
                assert_uint256_eq(delta, Uint256(low=0, high=0));
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            let (spotPriceDecreased) = uint256_lt(newSpotPrice, spotPrice);
            let (deltaPositive) = uint256_lt(Uint256(low=0, high=0), delta);
            with_attr error_message("getSellInfoWithoutFee - Price update incorrect, expected price to decrease (old price: {spotPrice}, new price: {newSpotPrice})") {
                assert spotPriceDecreased = TRUE;
            }
            with_attr error_message("getSellInfoWithoutFee - Price update incorrect, expected delta to be greater than 0, found {delta}") {
                assert deltaPositive = TRUE;
            }
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar syscall_ptr = syscall_ptr;
    tempvar pedersen_ptr = pedersen_ptr;
    tempvar range_check_ptr = range_check_ptr;

    let (expectedOutputValue, expectedOutputValueHigh) = uint256_mul(numItems, spotPrice);
    // %{
    //     print(f"expectedOutputValue: {ids.expectedOutputValue.low + ids.expectedOutputValue.high}")
    //     print(f"outputValue: {ids.outputValue.low + ids.outputValue.high}")
    // %}
    with_attr error_message("getSellInfoWithoutFee - expectedOutputValue overflow") {
        assert_uint256_eq(expectedOutputValueHigh, Uint256(low=0, high=0));
    }
    with_attr error_message("getSellInfoWithoutFee - Output value incorrect (expected: {expectedOutputValue}, found {outputValue}") {
        assert_uint256_le(outputValue, expectedOutputValue);
    }

    return ();
}