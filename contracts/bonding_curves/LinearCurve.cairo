%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_eq,
    uint256_le,
    uint256_lt,
    uint256_sub,
    uint256_mul,
    uint256_add,
    assert_uint256_eq,
    uint256_unsigned_div_rem
)

from contracts.bonding_curves.CurveErrorCodes import (Error)
from contracts.bonding_curves.FixedPointMathLib import (FixedPointMathLib)
from contracts.libraries.felt_uint import (FeltUint)
from contracts.constants.library import (MAX_UINT_128)

// @dev see {ICurve::validateDelta}
@external
func validateDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    delta: Uint256
) -> (success: felt) {
    return (success=TRUE);
}

// @dev see {ICurve::validateSpotPrice}
@external
func validateSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    delta: Uint256
) -> (success: felt) {
    return (success=TRUE);
}

// @dev see {ICurve::getBuyInfo}
@view
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

    let (WAD) = FixedPointMathLib.WAD();
    
    // We only calculate changes for buying 1 or more NFTs
    let (isNoItem) = uint256_eq(numItems, Uint256(low=0, high=0));
    if(isNoItem == TRUE) {
        return _returnErrorInput(Error.INVALID_NUMITEMS);
    }

    // For a linear curve, the spot price increases by delta for each item bought
    let (deltaPerNumItemsLow, deltaPerNumItemsHigh) = uint256_mul(delta, numItems);
    // if 0 < delta == true -> delta > 0 -> overflow
    let (deltaPerNumItemsOverflow) = uint256_lt(Uint256(low=0, high=0), deltaPerNumItemsHigh);
    if(deltaPerNumItemsOverflow == TRUE) {
        return _returnErrorInput(Error.SPOT_PRICE_OVERFLOW);
    }
    let (newSpotPrice, newSpotPriceCarry) = uint256_add(spotPrice, deltaPerNumItemsLow);
    let (newSpotPriceOverflow) = uint256_lt(Uint256(low=MAX_UINT_128, high=0), newSpotPrice);
    if(newSpotPriceOverflow == TRUE) {
        return _returnErrorInput(Error.SPOT_PRICE_OVERFLOW);
    }

    // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
    // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
    // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
    // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
    // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
    // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
    let (buySpotPrice, buySpotPriceCarry) = uint256_add(spotPrice, delta);

    // If we buy n items, then the total cost is equal to:
    // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
    // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
    // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
    let (temp_inputValue1) = _calcTempInputValue(numItems, buySpotPrice, delta);

    // Account for the protocol fee, a flat percentage of the buy amount
    let (protocolFee) = FixedPointMathLib.fmul(temp_inputValue1, protocolFeeMultiplier, WAD);

    // Account for the trade fee, only for Trade pools
    let (feeMultiplierUint) = FeltUint.feltToUint256(feeMultiplier);
    let (val1) = FixedPointMathLib.fmul(temp_inputValue1, feeMultiplierUint, WAD);
    let (temp_inputValue2, temp_inputValue2Carry) = uint256_add(temp_inputValue1, val1);

    // Add the protocol fee to the required input amount
    let (inputValue, inputValueCarry) = uint256_add(temp_inputValue2, protocolFee);

    // Keep delta the same
    // and return with error.OK (= no errors)
    return (
        Error.OK,
        newSpotPrice,
        delta,
        inputValue,
        protocolFee
    );
    
}

// @dev see {ICurve::getSellInfo}
@view
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
    let (WAD) = FixedPointMathLib.WAD();
    
    // We only calculate changes for buying 1 or more NFTs
    let (isNoItem) = uint256_eq(numItems, Uint256(low=0, high=0));
    if(isNoItem == TRUE) {
        return _returnErrorOutput(Error.INVALID_NUMITEMS);
    }

    // We first calculate the change in spot price after selling all of the items
    let (totalPriceDecrease, totalPriceDecreaseHigh) = uint256_mul(delta, numItems);
    // if 0 < priceDecrease == true -> priceDecrease > 0 -> overflow
    let (priceDecreaseOverflow) = uint256_lt(Uint256(low=0, high=0), totalPriceDecreaseHigh);
    if(priceDecreaseOverflow == TRUE) {
        return _returnErrorOutput(Error.SPOT_PRICE_OVERFLOW);
    }

    // If the current spot price is less than the total amount that the spot price should change by...
    let (newSpotPrice, newNumItems) = _getNewSpotPriceWithDecrease(
        totalPriceDecrease,
        spotPrice,
        delta,
        numItems
    );

    // If we sell n items, then the total sale amount is:
    // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
    // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
    let (temp_outputValue1) = _calcTempOutputValue(newNumItems, spotPrice, delta);
        
    // Account for the protocol fee, a flat percentage of the sell amount
    let (protocolFee) = FixedPointMathLib.fmul(temp_outputValue1, protocolFeeMultiplier, WAD);

    // Account for the trade fee, only for Trade pools
    let (feeMultiplierUint) = FeltUint.feltToUint256(feeMultiplier);
    let (val1) = FixedPointMathLib.fmul(temp_outputValue1, feeMultiplierUint, WAD);
    let (temp_outputValue2) = uint256_sub(temp_outputValue1, val1);

    // Subtract the protocol fee from the output amount to the seller
    let (outputValue) = uint256_sub(temp_outputValue2, protocolFee);

    // Keep delta the same
    // and return with error.OK (= no errors)
    return (
        Error.OK,
        newSpotPrice,
        delta,
        outputValue,
        protocolFee
    );
    
}

// @dev Calculate
// inputValue = numItems * buySpotPrice + (numItems * (numItems - 1) * delta) / 2;
func _calcTempInputValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numItems: Uint256,
    buySpotPrice: Uint256,
    delta: Uint256
) -> (inputValue: Uint256) {
    alloc_locals;

    let (leftLow, leftHigh) = uint256_mul(numItems, buySpotPrice);
    assert_uint256_eq(leftHigh, Uint256(low=0, high=0));

    let (numItemsSubOne) = uint256_sub(numItems, Uint256(low=1, high=0));
    let (rightFirstPartLow, rightFirstPartHigh) = uint256_mul(numItems, numItemsSubOne);
    assert_uint256_eq(rightFirstPartHigh, Uint256(low=0, high=0));

    let (rightMidPartLow, rightMidPartHigh) = uint256_mul(rightFirstPartLow, delta);
    assert_uint256_eq(rightMidPartHigh, Uint256(low=0, high=0));

    let (right, rightRem) = uint256_unsigned_div_rem(rightMidPartLow, Uint256(low=2, high=0));

    let (res, resCarry) = uint256_add(leftLow, right);

    return (inputValue=res);
}

// @dev - Calculate 
// outputValue = numItems * spotPrice - (numItems * (numItems - 1) * delta) / 2;
func _calcTempOutputValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numItems: Uint256,
    spotPrice: Uint256,
    delta: Uint256
) -> (outputValue: Uint256) {
    alloc_locals;

    let (leftLow, leftHigh) = uint256_mul(numItems, spotPrice);
    assert_uint256_eq(leftHigh, Uint256(low=0, high=0));

    let (numItemsSubOne) = uint256_sub(numItems, Uint256(low=1, high=0));
    let (rightFirstPartLow, rightFirstPartHigh) = uint256_mul(numItems, numItemsSubOne);
    assert_uint256_eq(rightFirstPartHigh, Uint256(low=0, high=0));

    let (rightMidPartLow, rightMidPartHigh) = uint256_mul(rightFirstPartLow, delta);
    assert_uint256_eq(rightMidPartHigh, Uint256(low=0, high=0));

    let (right, rightRem) = uint256_unsigned_div_rem(rightMidPartLow, Uint256(low=2, high=0));

    let (res) = uint256_sub(leftLow, right);

    return (outputValue=res);
}

func _getNewSpotPriceWithDecrease{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    totalPriceDecrease: Uint256,
    spotPrice: Uint256,
    delta: Uint256,
    numItems: Uint256
) -> (
    newSpotPrice: Uint256,
    numItems: Uint256
) {
    let (spotPriceLtDecrease) = uint256_lt(spotPrice, totalPriceDecrease);
    if(spotPriceLtDecrease == TRUE) {
        let newSpotPrice = Uint256(low=0, high=0);
                
        let (div, divRem) = uint256_unsigned_div_rem(spotPrice, delta);
        let (numItemsTillZeroPrice, numItemsTillZeroPriceCarry) = uint256_add(div, Uint256(low=1, high=0));
        return (newSpotPrice=newSpotPrice, numItems=numItemsTillZeroPrice);
    }

    let (newSpotPrice) = uint256_sub(spotPrice, totalPriceDecrease);
    return (newSpotPrice=newSpotPrice, numItems=numItems);
}

func _returnErrorInput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    error: felt
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    return (
        error, 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0)
    );
}

func _returnErrorOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    error: felt
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    outputAmount: Uint256,
    protocolFee: Uint256
) {
    return (
        error, 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0), 
        Uint256(low=0, high=0)
    );
}



    
