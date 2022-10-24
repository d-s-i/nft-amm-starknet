%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace ICurve {
    // @notice Validates if a delta value is valid for the curve. The criteria for
    //  validity can be different for each type of curve, for instance ExponentialCurve
    //  requires delta to be greater than 1.
    //  @param delta The delta value to be validated
    //  @return valid True if delta is valid, false otherwise
    func validateDelta(delta: Uint256) -> (success: felt) {
    }

    func validateSpotPrice(newSpotPrice: Uint256) -> (success: felt) {
    }

    // @notice Given the current state of the pair and the trade, computes how much the user
    // should pay to purchase an NFT from the pair, the new spot price, and other values.
    // @param spotPrice The current selling spot price of the pair, in tokens
    // @param delta The delta parameter of the pair, what it means depends on the curve
    // @param numItems The number of NFTs the user is buying from the pair
    // @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
    // @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
    // @return error Any math calculation errors, only Error.OK means the returned values are valid
    // @return newSpotPrice The updated selling spot price, in tokens
    // @return newDelta The updated delta, used to parameterize the bonding curve
    // @return inputValue The amount that the user should pay, in tokens
    // @return protocolFee The amount of fee to send to the protocol, in tokens
    func getBuyInfo(
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
    }

    func getSellInfo(
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
    }
}