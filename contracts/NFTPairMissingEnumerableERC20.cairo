%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

from contracts.constants.PairVariant import (PairVariants)

from contracts.NFTPairERC20 import (NFTPairERC20)
from contracts.NFTPairMissingEnumerable import (NFTPairMissingEnumerable)

/////////
// NFTPairERC20

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    factoryAddr: felt,
    bondingCurveAddr: felt,
    _poolType: felt,
    _nftAddress: felt,
    _spotPrice: Uint256,
    _delta: Uint256,
    _fee: felt,
    owner: felt,
    _assetRecipient: felt,
    _tokenAddress: felt
) {
    let (pairVariants) = PairVariants.value();
    NFTPairERC20.initializer(
        factoryAddr,
        bondingCurveAddr,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        owner,
        _assetRecipient,
        pairVariants.MISSING_ENUMERABLE_ERC20,
        _tokenAddress
    );
    return ();
}

@external
func withdrawERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Address: felt,
    amount: Uint256
) {
    NFTPairERC20.withdrawERC20(erc20Address, amount);
    return ();
}

@external
func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairERC20.swapTokenForAnyNFTs(
        numNFTs,
        maxExpectedTokenInput,
        nftRecipient,
        isRouter,
        routerCaller
    );
    
    return ();
}

@external
func swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairERC20.swapTokenForSpecificNFTs(
        nftIds_len,
        nftIds,
        maxExpectedTokenInput,
        nftRecipient,
        isRouter,
        routerCaller
    );
    return ();

}

@external
func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    minExpectedTokenOutput: Uint256,
    tokenRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairERC20.swapNFTsForToken(
        nftIds_len,
        nftIds,
        minExpectedTokenOutput,
        tokenRecipient,
        isRouter,
        routerCaller
    );
    return ();
}

@view
func getBuyNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = NFTPairERC20.getBuyNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        inputAmount=inputAmount,
        protocolFee=protocolFee
    );
}

@view
func getSellNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = NFTPairERC20.getSellNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        inputAmount=inputAmount,
        protocolFee=protocolFee
    );
}

@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (_assetRecipient) = NFTPairERC20.getAssetRecipient();
    return (recipient=_assetRecipient);
}

@view
func getPairVariant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariant: felt) {
    let (_pairVariant) = NFTPairERC20.getPairVariant();
    return (_pairVariant=_pairVariant);
}

@view
func getPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_poolType: felt) {
    let (_poolType) = NFTPairERC20.getPoolType();
    return (_poolType=_poolType);
}

@view
func getNFTAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_nftAddress: felt) {
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    return (_nftAddress=_nftAddress);
}

@view
func getBondingCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_bondingCurve: felt) {
    let (_bondingCurve) = NFTPairERC20.getBondingCurve();
    return (_bondingCurve=_bondingCurve);
}

@view
func getFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_factory: felt) {
    let (_factory) = NFTPairERC20.getFactory();
    return (_factory=_factory);
}

@external
func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newSpotPrice: Uint256
) {
    NFTPairERC20.changeSpotPrice(newSpotPrice);
    return ();
}

@external
func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newDelta: Uint256
) {
    NFTPairERC20.changeDelta(newDelta);
    return ();
}

@external
func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newFee: felt
) {
    NFTPairERC20.changeFee(newFee);
    return ();
}

@external
func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newRecipient: felt
) {
    NFTPairERC20.changeAssetRecipient(newRecipient);
    return ();
}

@external
func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt, 
    isSupported: felt
) {
    NFTPairERC20.setInterfacesSupported(interfaceId, isSupported);
    return ();
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt
) -> (isSupported: felt) {
    let (isSupported) = NFTPairERC20.supportsInterface(interfaceId);
    return (isSupported=isSupported);
}

@view
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    token_id: Uint256, 
    amount: Uint256,
    data_len: felt, 
    data: felt*
) -> (selector: felt) {
    let (selector) = NFTPairERC20.onERC1155Received(
        operator,
        from_,
        token_id,
        amount,
        data_len,
        data
    );
    return (selector=selector);
}

@view
func onERC1155BatchReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    token_ids_len: felt,
    token_ids: Uint256*, 
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt, 
    data: felt*
) -> (selector: felt) {
    let (selector) = NFTPairERC20.onERC1155BatchReceived(
        operator,
        from_,
        token_ids_len,
        token_ids,
        amounts_len,
        amounts,
        data_len,
        data
    );
    return (selector=selector);
}

//////////
// NFTPairMissingEnumerable

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    let (ids_len, ids) = NFTPairMissingEnumerable.getAllHeldIds();
    return (ids_len=ids_len, ids=ids);
}
