%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
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
        _pairVariant: felt,
        _erc20Address: felt
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
    func withdrawERC721(
        _nftAddress: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*
    ) {
    }
    func withdrawERC20(
        _erc20Address: felt,
        amount: Uint256
    ) {
    }
    func withdrawERC1155(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*
    ) {
    }    
    func getBuyNFTQuote(
        numNFTs: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        inputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
    func getSellNFTQuote(
        numNFTs: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        outputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
    func getAssetRecipient() -> (recipient: felt) {
    }
    func getPairVariant() -> (_pairVariant: felt) {
    }
    func getNFtAddress() -> (_nftAddress: felt) {
    }
    func getAllHeldIds(_nftAddress: felt) -> (tokenIds_len: felt, tokenIds: Uint256*) {
    }
    func owner() -> (owner: felt) {
    }
    func supportsInterface(
        interfaceId: felt
    ) -> (isSupported: felt) {
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
    func setInterfacesSupported(
        interfaceId: felt, 
        isSupported: felt
    ) {
    }
    func transferOwnership(newOwner: felt) {
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