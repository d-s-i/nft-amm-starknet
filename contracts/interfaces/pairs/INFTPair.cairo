%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

namespace INFTPair {
    func initializer(
        factoryAddr: felt,
        bondingCurveAddr: felt,
        _poolType: felt,
        _nftAddress: felt,
        _spotPrice: Uint256,
        _delta: Uint256,
        _fee: felt,
        owner: felt,
        _assetRecipient: felt,
        _pairVariant: felt
    ) {
    }

    func swapTokenForAnyNFTs(
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }

    func swapTokenForSpecificNFTs(
        nftIds_len: felt,
        nftIds: Uint256*,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }

    func swapNFTsForToken(
        nftIds_len: felt,
        nftIds: Uint256*,
        minExpectedTokenOutput: Uint256,
        tokenRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }

    func getBuyNFTQuote(
        numNFTs: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        inputAmount: Uint256,
        protocolFee: felt
    ) {
    }

    func getSellNFTQuote(
        numNFTs: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        outputAmount: Uint256,
        protocolFee: felt
    ) {
    }

    func getAssetRecipient() -> (recipient: felt) {
    }

    func getPairVariant() -> (_pairVariant: felt) {
    }

    func getNFtAddress() -> (_nftAddress: felt) {
    }

    func supportsInterface(
        interfaceId: felt
    ) -> (isSupported: felt) {
    }

    func setInterfacesSupported(
        interfaceId: felt, 
        isSupported: felt
    ) {
    }

    func onERC1155Received(
        operator: felt, 
        from_: felt, 
        token_id: Uint256, 
        amount: Uint256,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
    }

    func onERC1155BatchReceived(
        operator: felt, 
        from_: felt, 
        token_ids_len: felt,
        token_ids: Uint256*, 
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
    }   

    func _assertCorrectlyInitializedWithPoolType(
        _poolType: felt,
        _fee: felt,
        _assetRecipient: felt
    ) {
    }

    func _calculateBuyInfoAndUpdatePoolParams(
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        _bondingCurve: felt,
        _factory: felt
    ) -> (protocolFee: felt, inputAmount: Uint256) {
    }

    func _calculateSellInfoAndUpdatePoolParams(
        numNFTs: Uint256,
        minExpectedTokenOutput: Uint256,
        _bondingCurve: felt,
        _factory: felt
    ) -> (protocolFee: felt, outputAmount: Uint256) {
    }

    func _pullTokenInputAndPayProtocolFee(
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: felt
    ) {
    }

    func _sendAnyNFTsToRecipient(
        _nftAddress: felt, 
        nftRecipient: felt, 
        startIndex: Uint256, 
        numNFTs: Uint256
    ) {
    }

    func _sendSpecificNFTsToRecipient(
        _nftAddress: felt,
        nftRecipient: felt,
        startIndex: felt,
        nftIds_len: felt,
        nftIds: Uint256*
    ) {
    }

    func _sendTokenOutput(
        tokenRecipient: felt, 
        outputAmount: Uint256
    ) {
    }

    func _payProtocolFeeFromPair(
        _factory: felt, 
        protocolFee: felt
    ) {
    } 
}