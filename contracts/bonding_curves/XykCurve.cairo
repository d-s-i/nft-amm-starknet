%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_eq,
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

// @dev - See {ICurve::validateDelta}
@external
func validateDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    delta: Uint256
) -> (success: felt) {
    return (success=TRUE);
}

// @dev - See {ICurve::validateSpotPrice}
@external
func validateSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    delta: Uint256
) -> (success: felt) {
    return (success=TRUE);
}

// @dev - See {ICurve::getBuyInfo}
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
        return _returnInputError(Error.INVALID_NUMITEMS);
    }

    // get the pair's virtual nft and eth/erc20 reserves
    let tokenBalance = spotPrice;
    let nftBalance = delta;

    // If numItems is too large, we will get divide by zero error
    let (moreItemsThanBalance) = uint256_lt(tokenBalance, numItems);
    if(moreItemsThanBalance == TRUE) {
        return _returnInputError(Error.INVALID_NUMITEMS);
    }

    // calculate the amount to send in
    let (inputValueWithoutFee) = _calcInputValueWithoutFee(numItems, tokenBalance, nftBalance);

    // add the fees to the amount to send in
    let (protocolFee) = FixedPointMathLib.fmul(inputValueWithoutFee, protocolFeeMultiplier, WAD);
    let (feeMultiplierUint) = FeltUint.feltToUint256(feeMultiplier);
    let (fee) = FixedPointMathLib.fmul(inputValueWithoutFee, feeMultiplierUint, WAD);

    let (feeAddition, feeAdditionCarry) = uint256_add(fee, protocolFee);
    let (inputValue, inputValueCarry) = uint256_add(inputValueWithoutFee, feeAddition);

    // set the new virtual reserves
    let (newSpotPrice, newSpotPriceCarry) = uint256_add(spotPrice, inputValueWithoutFee);
    let (newDelta) = uint256_sub(nftBalance, numItems);

    return (
        Error.OK,
        newSpotPrice,
        newDelta,
        inputValue,
        protocolFee
    );

}

// @dev - See {ICurve::getSellInfo}
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
        return _returnOutputError(Error.INVALID_NUMITEMS);
    }

    // get the pair's virtual nft and eth/erc20 balance
    let tokenBalance = spotPrice;
    let nftBalance = delta;

    // calculate the amount to send out
    let (outputValueWithoutFee) = _calcOutputValueWithoutFee(numItems, tokenBalance, nftBalance);

    // subtract fees from amount to send out
    let (protocolFee) = FixedPointMathLib.fmul(outputValueWithoutFee, protocolFeeMultiplier, WAD);
    let (feeMultiplierUint) = FeltUint.feltToUint256(feeMultiplier);
    let (fee) = FixedPointMathLib.fmul(outputValueWithoutFee, feeMultiplierUint, WAD);

    let (feeSubstraction) = uint256_sub(fee, protocolFee);
    let (outputValue) = uint256_sub(outputValueWithoutFee, feeSubstraction);

    // set the new virtual reserves
    let (newSpotPrice) = uint256_sub(spotPrice, outputValueWithoutFee);
    let (newDelta, newDeltaCarry) = uint256_add(nftBalance, numItems);

    return (
        Error.OK,
        newSpotPrice,
        newDelta,
        outputValue,
        protocolFee
    );
    
} 

func _calcInputValueWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numItems: Uint256,
    tokenBalance: Uint256,
    nftBalance: Uint256
) -> (inputValueWithoutFee: Uint256) {
    alloc_locals;
    let (left, leftHigh) = uint256_mul(numItems, tokenBalance);
    assert_uint256_eq(leftHigh, Uint256(low=0, high=0));
    let (right) = uint256_sub(nftBalance, numItems);

    let (inputValueWithoutFee, remainder) = uint256_unsigned_div_rem(left, right);

    return (inputValueWithoutFee=inputValueWithoutFee);
}

func _calcOutputValueWithoutFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numItems: Uint256,
    tokenBalance: Uint256,
    nftBalance: Uint256
) -> (inputValueWithoutFee: Uint256) {
    alloc_locals;
    let (left, leftHigh) = uint256_mul(numItems, tokenBalance);
    assert_uint256_eq(leftHigh, Uint256(low=0, high=0));
    let (right, rightCarry) = uint256_add(nftBalance, numItems);

    let (inputValueWithoutFee, remainder) = uint256_unsigned_div_rem(left, right);

    return (inputValueWithoutFee=inputValueWithoutFee);
}

func _returnInputError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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

func _returnOutputError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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