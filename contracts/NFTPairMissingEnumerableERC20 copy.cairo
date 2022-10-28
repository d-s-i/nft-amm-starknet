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
from contracts.constants.library import (MAX_UINT_128)
from contracts.constants.library import (IERC721_RECEIVER_ID)
from contracts.constants.PairVariant import (PairVariants)

from contracts.NFTPairERC20 import (NFTPairERC20)

@storage_var
func idSet_len() -> (res: felt) {
}

@storage_var
func idSet(id: felt) -> (tokenId: Uint256) {
}

@event
func NFTWithdrawal() {
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
    _erc20Address: felt
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
        _erc20Address
    );
    setInterfacesSupported(IERC721_RECEIVER_ID, TRUE);
    let (thisAddress) = get_contract_address();
    IERC721.setApprovalForAll(_nftAddress, thisAddress, TRUE);
    IERC20.approve(_erc20Address, thisAddress, Uint256(low=MAX_UINT_128, high=MAX_UINT_128));

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
    alloc_locals;

    NFTPairERC20._reentrancyStart();

    let (poolTypes) = PoolTypes.value();
    let (_factory) = NFTPairERC20.getFactory();
    let (_bondingCurve) = NFTPairERC20.getBondingCurve();
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (_poolType) = NFTPairERC20.getPoolType();

    if(_poolType == poolTypes.TOKEN) {
        with_attr error_message("NFTPairMissingEnumerableERC20::swapTokenForAnyNFTs - Wrong Pool type (value: {_poolType})") {
            assert 1 = 2;
        }
    }

    let (thisAddress) = get_contract_address();
    let (balance) = IERC721.balanceOf(_nftAddress, thisAddress);

    with_attr error_mesage("NFTPairMissingEnumerableERC20::swapTokenForAnyNFTs - Must by at least 1 NFT") {
        assert_uint256_lt(Uint256(low=0, high=0), numNFTs);
    }

    with_attr error_message("NFTPairMissingEnumerableERC20::swapTokenForAnyNFTs - Contract has not enough balances for trade") {
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

    _sendAnyNFTsToRecipient(_nftAddress, nftRecipient, Uint256(low=0, high=0), numNFTs);

    NFTPairERC20._emitSwapNFTOutPair();

    NFTPairERC20._reentrancyEnd();
    
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
    alloc_locals;

    NFTPairERC20._reentrancyStart();

    let (poolTypes) = PoolTypes.value();
    let (_factory) = NFTPairERC20.getFactory();
    let (_bondingCurve) = NFTPairERC20.getBondingCurve();
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (_poolType) = NFTPairERC20.getPoolType();

    if(_poolType == poolTypes.TOKEN) {
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

    _sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        0,
        nftIds_len,
        nftIds
    );

    NFTPairERC20._emitSwapNFTOutPair();

    NFTPairERC20._reentrancyEnd();

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

// Enumerable-specific functions
@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*
) {
    NFTPairERC20._assertOnlyOwner();

    let (collectionAddress) = NFTPairERC20.getNFTAddress();
    let(thisAddress) = get_contract_address();
    let (caller) = get_caller_address();
    if(_nftAddress != collectionAddress) {
        IERC721.setApprovalForAll(_nftAddress, thisAddress, TRUE);
        _withdrawExternalERC721_loop(
            0,
            tokenIds_len,
            _nftAddress,
            thisAddress,
            caller,
            tokenIds
        );
    } else {
        _withdrawERC721_loop(
            0,
            tokenIds_len,
            _nftAddress,
            thisAddress,
            caller,
            tokenIds
        );
    }

    return ();
}

func _withdrawExternalERC721_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt,
    _nftAddress: felt,
    from_: felt,
    to: felt,
    tokenIds: Uint256*
) {
    if(start == end) {
        return ();
    }
    IERC721.transferFrom(_nftAddress, from_, to, [tokenIds]);
    return _withdrawExternalERC721_loop(
        start + 1,
        end,
        _nftAddress,
        from_,
        to,
        tokenIds + 1
    );
}

func _withdrawERC721_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt,
    _nftAddress: felt,
    from_: felt,
    to: felt,
    tokenIds: Uint256*
) {
    if(start == end) {
        return ();
    }
    
    IERC721.transferFrom(_nftAddress, from_, to, [tokenIds]);

    let (maxIndex) = idSet_len.read();
    _removeNFTInEnumeration([tokenIds], 0, maxIndex);
    NFTWithdrawal.emit();
    
    return _withdrawERC721_loop(
        start + 1,
        end,
        _nftAddress,
        from_,
        to,
        tokenIds + 1
    );
}

func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    nftRecipient: felt,
    startIndex: felt,
    nftIds_len: felt,
    nftIds: Uint256*
) {
    if(startIndex == nftIds_len) {
        return ();
    } 

    let (thisAddress) = get_contract_address();
    IERC721.safeTransferFrom(
        _nftAddress,
        thisAddress,
        nftRecipient,
        [nftIds],
        0,
        cast(0, felt*)
    );

    let (end) = idSet_len.read();
    _removeNFTInEnumeration([nftIds], 0, end);

    return _sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        startIndex + 1,
        nftIds_len,
        nftIds + 1
    );
}

func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    _nftRecipient: felt,
    start: Uint256,
    numNFTs: Uint256
) {
    alloc_locals;
    let (len) = idSet_len.read();

    let (maxReached) = uint256_eq(start, numNFTs);
    if(maxReached == TRUE) {
        return ();
    } 

    let lastIndex = len - 1;
    let (lastTokenId) = idSet.read(lastIndex);
    let (thisAddress) = get_contract_address();
    IERC721.safeTransferFrom(
        _nftAddress,
        thisAddress,
        _nftRecipient,
        lastTokenId,
        0,
        cast(0, felt*)
    );

    _removeNFTInEnumeration(lastTokenId, lastIndex, len);

    let (newStart, _) = uint256_add(start, Uint256(low=1, high=0));
    return _sendAnyNFTsToRecipient(_nftAddress, _nftRecipient, newStart, numNFTs);
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    tokenId: Uint256, 
    data_len: felt,
    data: felt*
) -> (selector: felt) {
    let (_nftAddress) = NFTPairERC20.getNFTAddress();
    let (caller) = get_caller_address();

    // with_attr error_message("NFTPairMissingEnumerable::onERC721Received - Can only receive NFTs from pooled collection") {
    //     assert caller = _nftAddress;
    // }
    if(caller == _nftAddress) {
        _addNFTInEnumeration(tokenId);

        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;        
    } else {
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;    
    }

    return (selector=IERC721_RECEIVER_ID);
}

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    alloc_locals;
    let (ids: Uint256*) = alloc();
    let (end) = idSet_len.read();

    _getAllHeldIds_loop(ids, 0, end);
    
    return (ids_len=end, ids=ids);
}

func _getAllHeldIds_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _ids: Uint256*,
    start: felt,
    end: felt
) {

    if(start == end) {
        return ();
    }

    let (currentId) = idSet.read(start);
    assert [_ids] = currentId;

    return _getAllHeldIds_loop(
        _ids + 2,
        start + 1,
        end
    );
}

func _addNFTInEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(tokenId: Uint256) {
    let (currentIdSetLen) = idSet_len.read();
    idSet.write(currentIdSetLen, tokenId);

    idSet_len.write(currentIdSetLen + 1);

    return ();
}

func _removeNFTInEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    targetId: Uint256, 
    startIndex: felt, 
    max: felt
) {
    alloc_locals;

    if(startIndex == max) {
        with_attr error_message("NFTPairMissingEnumerable::_removeNFTInEnumeration - Can't remove NFT from enumeration") {
            assert 1 = 2;
        }
    }
        
    let (currentId) = idSet.read(startIndex);
    let (idFound) = uint256_eq(currentId, targetId);
    if(idFound == TRUE) {
        // remove value by replacing with last value
        let (lastValue) = idSet.read(max - 1);
        idSet.write(startIndex, lastValue);
        // set last value to 0 (bc is now set to current index)
        idSet.write(max - 1, Uint256(low=0, high=0));

        // update length
        let (currLen) = idSet_len.read();
        idSet_len.write(currLen - 1);
        return ();
    } else {
        return _removeNFTInEnumeration(targetId, startIndex + 1, max);
    }
}
    ////////
    // GETTERS

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