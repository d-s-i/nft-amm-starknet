%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.math import (assert_lt)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.bool import (TRUE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_lt,
    uint256_eq,
    uint256_add,
    assert_uint256_lt,
    assert_uint256_le
)

from contracts.libraries.felt_uint import (FeltUint)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)

from contracts.constants.PoolType import (PoolTypes)
from contracts.constants.library import (MAX_UINT_128, IERC721_RECEIVER_ID)
from contracts.constants.PairVariant import (PairVariants)

from contracts.pairs.NFTPairERC20 import (NFTPairERC20)
from contracts.pairs.NFTPairMissingEnumerableERC20.library import (NFTPairMissingEnumerableERC20Lib)

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
    _erc20Address: felt
) {
    NFTPairMissingEnumerableERC20Lib.initializer(
        factoryAddr,
        bondingCurveAddr,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        owner,
        _assetRecipient,
        _erc20Address
    );

    return ();
}

 /////////////////
// SWAP FUNCTIONS
@external
func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairMissingEnumerableERC20Lib.swapTokenForAnyNFTs(
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
    NFTPairMissingEnumerableERC20Lib.swapTokenForSpecificNFTs(
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

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    tokenId: Uint256, 
    data_len: felt,
    data: felt*
) -> (selector: felt) {
    let (selector) = NFTPairMissingEnumerableERC20Lib.onERC721Received(
        operator, 
        from_, 
        tokenId, 
        data_len,
        data
    );

    return (selector=selector);
}

////////
// GETTERS

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    alloc_locals;
    let (ids_len, ids) = NFTPairMissingEnumerableERC20Lib.getAllHeldIds();
    
    return (ids_len=ids_len, ids=ids);
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
    outputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = NFTPairERC20.getSellNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        outputAmount=outputAmount,
        protocolFee=protocolFee
    );
}

@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (poolTypes) = PoolTypes.value();

    let (_poolType) = NFTPairERC20.getPoolType();
    if(_poolType == poolTypes.TRADE) {
        let (thisAddress) = get_contract_address();
        return (recipient=thisAddress);
    }

    let (_assetRecipient) = NFTPairERC20.getAssetRecipient();
    if(_assetRecipient == 0) {
        let (thisAddress) = get_contract_address();
        return (recipient=thisAddress);
    }
    return (recipient=_assetRecipient);
}

@view
func getFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_fee: felt) {
    let (_fee) = NFTPairERC20.getFee();
    return (_fee=_fee);
}

@view
func getSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_spotPrice: Uint256) {
    let (_spotPrice) = NFTPairERC20.getSpotPrice();
    return (_spotPrice=_spotPrice);
}

@view
func getDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_delta: Uint256) {
    let (_delta) = NFTPairERC20.getDelta();
    return (_delta=_delta);
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

////////
// ADMIN

@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*
) {
    NFTPairMissingEnumerableERC20Lib.withdrawERC721(
        _nftAddress,
        tokenIds_len,
        tokenIds
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