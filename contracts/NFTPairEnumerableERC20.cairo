%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address)
from starkware.cairo.common.math import (assert_lt)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_sub,
    uint256_lt, 
    uint256_le,
    assert_uint256_lt,
    assert_uint256_le    
)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.openzeppelin.Ownable import (Ownable)
from contracts.openzeppelin.ReentrancyGuard import (ReentrancyGuard)
from contracts.libraries.felt_uint import (FeltUint)
from contracts.pairs.NFTPairEnumerableERC20.library import (NFTPairEnumerableERC20)
from contracts.pairs.NFTPairERC20.library import (NFTPairERC20)

from contracts.interfaces.tokens.IERC721 import (IERC721)

from contracts.constants.structs import (PoolType)

//////////////
// Events

@event
func SwapNFTOutPair() {
}

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
    _pairVariant: felt,
    _erc20Address: felt
) {
    alloc_locals;

    with_attr error_mesage("initializer - Pair already initialized") {
        let (_owner) = Ownable.owner();
        assert _owner = 0;
    }
    Ownable.initializer(owner);
    NFTPairERC20.initializer(
        factoryAddr=factoryAddr,
        bondingCurveAddr=bondingCurveAddr,
        _poolType=_poolType,
        _nftAddress=_nftAddress,
        _spotPrice=_spotPrice,
        _delta=_delta,
        _fee=_fee,
        _assetRecipient=_assetRecipient,
        _pairVariant=_pairVariant,
        _erc20Address=_erc20Address
    );

    return ();
}

//
// NFTPairEnumerableERC20 FUNCTIONS
//

// Public functions

@external
func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) -> (inputAmount: Uint256) {
    alloc_locals;

    ReentrancyGuard._start();

    let (_factory) = NFTPairERC20.getFactory();
    let (_bondingCurve) = NFTPairERC20.getBondingCurve();
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (_poolType) = NFTPairERC20.getPoolType();

    if(_poolType == PoolType.TOKEN) {
        with_attr error_message("NFTPairEnumerableERC20::swapTokenForAnyNFTs - Wrong Pool type (value: {_poolType})") {
            assert 1 = 2;
        }
    }

    let (thisAddress) = get_contract_address();
    let (balance) = IERC721.balanceOf(_nftAddress, thisAddress);

    with_attr error_mesage("NFTPairEnumerableERC20::swapTokenForAnyNFTs - Must buy at least 1 NFT") {
        assert_uint256_lt(Uint256(low=0, high=0), numNFTs);
    }

    with_attr error_message("NFTPairEnumerableERC20::swapTokenForAnyNFTs - Contract has not enough balances for trade") {
        assert_uint256_le(numNFTs, balance);
    }

    let (protocolFee, inputAmount) = NFTPairERC20._calculateBuyInfoAndUpdatePoolParams(
        numNFTs,
        maxExpectedTokenInput,
        _bondingCurve,
        _factory
    );

    NFTPairERC20._pullTokenInputAndPayProtocolFee(
        inputAmount,
        isRouter,
        routerCaller,
        _factory,
        protocolFee
    );

    let (lastIndex) = uint256_sub(balance, Uint256(low=1, high=0));
    NFTPairEnumerableERC20._sendAnyNFTsToRecipient(
        _nftAddress=_nftAddress, 
        nftRecipient=nftRecipient, 
        startIndex=Uint256(low=0, high=0), 
        lastIndex=lastIndex,
        numNFTs=numNFTs
    );

    // NFTPairEnumerableERC20._sendAnyNFTsToRecipient(
    //     _nftAddress=_nftAddress, 
    //     nftRecipient=nftRecipient, 
    //     startIndex=Uint256(low=0, high=0), 
    //     numNFTs=numNFTs
    // );    

    SwapNFTOutPair.emit();

    ReentrancyGuard._end();
    
    return (inputAmount=inputAmount);
}

@external
func swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) -> (inputAmount: Uint256) {
    alloc_locals;

    ReentrancyGuard._start();

    let (_factory) = NFTPairERC20.getFactory();
    let (_bondingCurve) = NFTPairERC20.getBondingCurve();
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (_poolType) = NFTPairERC20.getPoolType();

    if(_poolType == PoolType.TOKEN) {
        with_attr error_message("Wrong Pool type") {
            assert 1 = 2;
        }
    }
    with_attr error_message("Must ask for more than 0 NFTs") {
        assert_lt(0, nftIds_len);
    }

    let (numNFTsUint) = FeltUint.feltToUint256(nftIds_len);
    let (protocolFee, inputAmount) = NFTPairERC20._calculateBuyInfoAndUpdatePoolParams(
        numNFTsUint,
        maxExpectedTokenInput,
        _bondingCurve,
        _factory
    );

    NFTPairERC20._pullTokenInputAndPayProtocolFee(
        inputAmount,
        isRouter,
        routerCaller,
        _factory,
        protocolFee
    );

    NFTPairEnumerableERC20._sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        0,
        nftIds_len,
        nftIds
    );

    SwapNFTOutPair.emit();

    ReentrancyGuard._end();

    return (inputAmount=inputAmount);
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    tokenId: Uint256, 
    data_len: felt,
    data: felt*
) -> (selector: felt) {
    let (collectionAddress) = NFTPairERC20.getNFTAddress();
    let (selector) = NFTPairEnumerableERC20.onERC721Received(
        collectionAddress,
        operator, 
        from_, 
        tokenId, 
        data_len,
        data
    );
    return (selector=selector);
}

// Only owner functions

@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*
) {
    Ownable.assert_only_owner();
    let (_collectionAddress) = NFTPairERC20.getNFTAddress();
    NFTPairEnumerableERC20.withdrawERC721(
        _collectionAddress,
        _nftAddress,
        tokenIds_len,
        tokenIds
    );
    return ();
}

@external
func withdrawERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc1155Addr: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*
) {
    Ownable.assert_only_owner();

    NFTPairERC20.withdrawERC1155(
        erc1155Addr,
        ids_len,
        ids,
        amounts_len,
        amounts
    );
    return ();
}

// @dev assert_only_owner alreach checked within the Ownable function already
@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

// @dev assert_only_owner alreach checked within the Ownable function already
@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    Ownable.renounce_ownership();
    return ();
}

// Getters

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (ids_len, ids) = NFTPairEnumerableERC20.getAllHeldIds(_nftAddress);
    return (ids_len=ids_len, ids=ids);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (owner: felt) {
    let (owner) = Ownable.owner();
    return (owner=owner);
}

//
// REGULAR FUNCTIONS
//

// @notice Sends a set of NFTs to the pair in exchange for token
// @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
// @param nftIds The list of IDs of the NFTs to sell to the pair
// @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
// amount is less than this value, the transaction will be reverted.
// @param tokenRecipient The recipient of the token output
// @param isRouter True (1) if calling from LSSVMRouter, false (0) otherwise. Not used for
// ETH pairs.
// @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
// ETH pairs.
// @return outputAmount The amount of token received
@external
func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    minExpectedTokenOutput: Uint256,
    tokenRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) -> (outputAmount: Uint256) {

    ReentrancyGuard._start();

    let (outputAmount) = NFTPairERC20.swapNFTsForToken(
        nftIds_len,
        nftIds,
        minExpectedTokenOutput,
        tokenRecipient,
        isRouter,
        routerCaller
    );

    ReentrancyGuard._end();

    return (outputAmount=outputAmount);
}

// Only owner functions

@external
func withdrawERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Address: felt,
    amount: Uint256
) {
    Ownable.assert_only_owner();
    NFTPairERC20.withdrawERC20(erc20Address, amount);
    return ();
}

@external
func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt, 
    isSupported: felt
) {
    Ownable.assert_only_owner();
    NFTPairERC20.setInterfacesSupported(interfaceId, isSupported);
    return ();
}

@external
func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newSpotPrice: Uint256
) {
    Ownable.assert_only_owner();
    NFTPairERC20.changeSpotPrice(newSpotPrice);
    return ();
}

@external
func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newDelta: Uint256
) {
    Ownable.assert_only_owner();
    NFTPairERC20.changeDelta(newDelta);
    return ();
}

@external
func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newFee: felt
) {
    Ownable.assert_only_owner();
    NFTPairERC20.changeFee(newFee);
    return ();
}

@external
func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newRecipient: felt
) {
    Ownable.assert_only_owner();
    NFTPairERC20.changeAssetRecipient(newRecipient);
    return ();
}

// Public functions

@external
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

@external
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

// Getters

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
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt
) -> (isSupported: felt) {
    let (isSupported) = NFTPairERC20.supportsInterface(interfaceId);
    return (isSupported=isSupported);
}

@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (recipient) = NFTPairERC20.getAssetRecipient();
    return (recipient=recipient);
}

@view
func getAssetRecipientStorage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (_assetRecipient) = NFTPairERC20.getAssetRecipientStorage();
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