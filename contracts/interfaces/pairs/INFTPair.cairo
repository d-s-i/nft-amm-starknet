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
    func onERC721Received(
        operator: felt, 
        from_: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ) -> (selector: felt) {
    }
    func withdrawERC721(
        _nftAddress: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*
    ) {
    }
    func withdrawERC1155(
        erc1155Addr: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*
    ) {
    }
    func withdrawERC20(
        erc20Address: felt,
        amount: Uint256
    ) {
    }    
    func transferOwnership(
        newOwner: felt
    ) {
    }
    func renounceOwnership() {
    }
    func getAllHeldIds() -> (ids_len: felt, ids: Uint256*) {
    }
    func owner() -> (owner: felt) {
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
    func setInterfacesSupported(
        interfaceId: felt, 
        isSupported: felt
    ) {
    }
    func changeSpotPrice(
        newSpotPrice: Uint256
    ) {
    }
    func changeDelta(
        newDelta: Uint256
    ) {
    }
    func changeFee(
        newFee: felt
    ) {
    }
    func changeAssetRecipient(
        newRecipient: felt
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
    func supportsInterface(
        interfaceId: felt
    ) -> (isSupported: felt) {
    }
    func getAssetRecipient() -> (recipient: felt) {
    }
    func getAssetRecipientStorage() -> (recipient: felt) {
    }    
    func getFee() -> (_fee: felt) {
    }
    func getSpotPrice() -> (_spotPrice: Uint256) {
    }
    func getDelta() -> (_delta: Uint256) {
    }    
    func getPairVariant() -> (_pairVariant: felt) {
    }
    func getPoolType() -> (_poolType: felt) {
    }
    func getNFTAddress() -> (_nftAddress: felt) {
    }
    func getBondingCurve() -> (_bondingCurve: felt) {
    }
    func getFactory() -> (_factory: felt) {
    }
}