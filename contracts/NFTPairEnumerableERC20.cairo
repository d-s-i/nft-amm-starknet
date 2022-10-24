%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.constants.PairVariant import (PairVariants)
from contracts.constants.library import (IERC721_RECEIVER_ID)

from contracts.NFTPairERC20 import (NFTPairERC20)
from contracts.NFTPairEnumerable import (NFTPairEnumerable)

// Initializing NFTPairERC20 because it had one more required value
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
        pairVariants.ENUMERABLE_ERC20,
        _tokenAddress
    );
    return ();
}

//////////
// NFTPairERC20
func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    inputAmount: Uint256,
    isRouter: felt,
    routerCaller: felt,
    _factory: felt,
    protocolFee: felt
) {
    NFTPairERC20._pullTokenInputAndPayProtocolFee(
        inputAmount,
        isRouter,
        routerCaller,
        _factory,
        protocolFee
    );
    return ();
}

// protocolFee paid directly from the this address to the factory
func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _factory: felt,
    protocolFee: Uint256
) {
    NFTPairERC20._payProtocolFeeFromPair(_factory, protocolFee);
    return ();
}

func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    tokenRecipient: felt,
    outputAmount: Uint256
) {
    NFTPairERC20._sendTokenOutput(tokenRecipient, outputAmount);
    return ();
}

func _refundTokenToSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(amount: Uint256) {
    NFTPairERC20._refundTokenToSender(amount);
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

//////////
// NFTPairEnumerable

func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    nftRecipient: felt,
    startIndex: Uint256,
    numNFTs: Uint256
) {
    NFTPairEnumerable._sendAnyNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        startIndex,
        numNFTs
    );

    return (); 
}

func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    nftRecipient: felt,
    startIndex: felt,
    nftIds_len: felt,
    nftIds: Uint256*
) {
    NFTPairEnumerable._sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        startIndex,
        nftIds_len,
        nftIds
    );
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
    NFTPairEnumerable.swapTokenForAnyNFTs(
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
    NFTPairEnumerable.swapTokenForSpecificNFTs(
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
    NFTPairEnumerable.swapNFTsForToken(
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
    ) = NFTPairEnumerable.getBuyNFTQuote(numNFTs);
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
    outputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = NFTPairEnumerable.getSellNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        outputAmount=outputAmount,
        protocolFee=protocolFee
    );
}

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (tokenIds_len: felt, tokenIds: Uint256*) {
    let (tokenIds_len, tokenIds) = NFTPairEnumerable.getAllHeldIds();

    return (tokenIds_len, tokenIds);
}

@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (_assetRecipient) = NFTPairEnumerable.getAssetRecipient();
    return (recipient=_assetRecipient);
}

@view
func getPairVariant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariant: felt) {
    let (_pairVariant) = NFTPairEnumerable.getPairVariant();
    return (_pairVariant=_pairVariant);
}

@view
func getPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_poolType: felt) {
    let (_poolType) = NFTPairEnumerable.getPoolType();
    return (_poolType=_poolType);
}

@view
func getNFTAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_nftAddress: felt) {
    let (_nftAddress) = NFTPairEnumerable.getNFTAddress();
    return (_nftAddress=_nftAddress);
}

@view
func getBondingCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_bondingCurve: felt) {
    let (_bondingCurve) = NFTPairEnumerable.getBondingCurve();
    return (_bondingCurve=_bondingCurve);
}

@view
func getFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_factory: felt) {
    let (_factory) = NFTPairEnumerable.getFactory();
    return (_factory=_factory);
}


@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt
) -> (isSupported: felt) {
    let (isSupported) = NFTPairEnumerable.supportsInterface(interfaceId);
    return (isSupported=isSupported);
}

@view
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (interfaceId: felt) {
    return (interfaceId=IERC721_RECEIVER_ID);
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
    let (selector) = NFTPairEnumerable.onERC1155Received(
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
    let (selector) = NFTPairEnumerable.onERC1155BatchReceived(
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

@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    tokenIds_len,
    tokenIds: Uint256*
) {
    NFTPairEnumerable.withdrawERC721(
        _nftAddress,
        tokenIds_len,
        tokenIds
    );
    
    return ();
}

@external
func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newSpotPrice: Uint256
) {
    NFTPairEnumerable.changeSpotPrice(newSpotPrice);
    return ();
}

@external
func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newDelta: Uint256
) {
    NFTPairEnumerable.changeDelta(newDelta);
    return ();
}

@external
func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newFee: felt
) {
    NFTPairEnumerable.changeFee(newFee);
    return ();
}

@external
func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newRecipient: felt
) {
    NFTPairEnumerable.changeAssetRecipient(newRecipient);
    return ();
}

@external
func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt, 
    isSupported: felt
) {
    NFTPairEnumerable.setInterfacesSupported(interfaceId, isSupported);
    return ();
}