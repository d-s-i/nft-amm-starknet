%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import (assert_not_zero, assert_lt)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_add,
    uint256_sub,
    uint256_lt, 
    uint256_le,
    uint256_eq,
    assert_uint256_lt,
    assert_uint256_le,
    assert_uint256_eq
)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.openzeppelin.Ownable import (Ownable)
from contracts.openzeppelin.ReentrancyGuard import (ReentrancyGuard)
from contracts.libraries.ERC1155Holder import (ERC1155Holder)
from contracts.libraries.felt_uint import (FeltUint)
from contracts.NFTPairLibExample import (NFTPairLibExample)

from contracts.interfaces.bonding_curves.ICurve import (ICurve)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.INFTRouter import (INFTRouter)

from contracts.constants.PoolType import (PoolTypes)
from contracts.constants.library import (MAX_UINT_128, IERC721_RECEIVER_ID)

const MAX_FEE = 10**17;

@storage_var
func factory() -> (address: felt) {
}

@storage_var
func bondingCurve() -> (address: felt) {
}

@storage_var
func pairVariant() -> (res: felt) {
}

@storage_var
func poolType() -> (res: felt) {
}

@storage_var
func nftAddress() -> (address: felt) {
}

@storage_var
func spotPrice() -> (res: Uint256) {
}

@storage_var
func delta() -> (res: Uint256) {
}

@storage_var
func assetRecipient() -> (res: felt) {
}

@storage_var
func erc20Address() -> (res: felt) {
}

// is uint256 in ICurve.getBuyInfo but uint96 in the LSSVMPair constructor
// Choosed Uint96/felt beause MAX_FEE (which is a const) can be stored in a felt
@storage_var
func fee() -> (res: felt) {
}

//////////////
// Events
@event
func SwapNFTInPair() {
}

@event
func SwapNFTOutPair() {
}

@event
func TokenDeposit(amount: Uint256) {
}

@event
func TokenWithdrawal(amount: Uint256) {
}

@event
func SpotPriceUpdate(newSpotPrice: Uint256) {
}

@event
func DeltaUpdate(newDelta: Uint256) {
}

@event
func FeeUpdate(newFee: felt) {
}

@event
func AssetRecipientChange(newRecipient: felt) {
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
    Ownable.initializer(owner);

    _assertCorrectlyInitializedWithPoolType(_poolType, _fee, _assetRecipient);

    let (deltaSuccess) = ICurve.validateDelta(bondingCurveAddr, _delta);
    with_attr error_message("NFTPair::initializer - Invalid delta for curve") {
        assert deltaSuccess = TRUE;
    }
    let (spotPriceSuccess) = ICurve.validateSpotPrice(bondingCurveAddr, _spotPrice);
    with_attr error_message("NFTPair::initializer - Invalid new spot price for curve") {
        assert spotPriceSuccess = TRUE;
    }
    
    factory.write(factoryAddr);
    bondingCurve.write(bondingCurveAddr);
    poolType.write(_poolType);
    nftAddress.write(_nftAddress);
    spotPrice.write(_spotPrice);
    delta.write(_delta);
    fee.write(_fee);
    pairVariant.write(_pairVariant);
    erc20Address.write(_erc20Address);

    setInterfacesSupported(IERC721_RECEIVER_ID, TRUE);
    let (thisAddress) = get_contract_address();
    IERC721.setApprovalForAll(_nftAddress, thisAddress, TRUE);
    IERC20.approve(_erc20Address, thisAddress, Uint256(low=MAX_UINT_128, high=MAX_UINT_128));

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
    alloc_locals;

    ReentrancyGuard._start();

    let (poolTypes) = PoolTypes.value();
    let (_factory) = factory.read();
    let (_bondingCurve) = bondingCurve.read();
    let (_nftAddress) = nftAddress.read();
    let (_poolType) = poolType.read();

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

    let (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
        numNFTs,
        maxExpectedTokenInput,
        _bondingCurve,
        _factory
    );

    _pullTokenInputAndPayProtocolFee(
        inputAmount,
        isRouter,
        routerCaller,
        _factory,
        protocolFee
    );

    NFTPairLibExample._sendAnyNFTsToRecipient(_nftAddress, nftRecipient, Uint256(low=0, high=0), numNFTs);

    SwapNFTOutPair.emit();

    ReentrancyGuard._end();
    
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

    ReentrancyGuard._start();

    let (poolTypes) = PoolTypes.value();
    let (_factory) = factory.read();
    let (_bondingCurve) = bondingCurve.read();
    let (_nftAddress) = nftAddress.read();
    let (_poolType) = poolType.read();

    if(_poolType == poolTypes.TOKEN) {
        with_attr error_message("Wrong Pool type") {
            assert 1 = 2;
        }
    }
    with_attr error_message("Must ask for more than 0 NFTs") {
        assert_lt(0, nftIds_len);
    }

    let (numNFTsUint) = FeltUint.feltToUint256(nftIds_len);
    let (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
        numNFTsUint,
        maxExpectedTokenInput,
        _bondingCurve,
        _factory
    );

    _pullTokenInputAndPayProtocolFee(
        inputAmount,
        isRouter,
        routerCaller,
        _factory,
        protocolFee
    );

    NFTPairLibExample._sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        0,
        nftIds_len,
        nftIds
    );

    SwapNFTOutPair.emit();

    ReentrancyGuard._end();

    return ();
}

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
) {
    alloc_locals;

    ReentrancyGuard._start();

    let (poolTypes) = PoolTypes.value();
    let (_factory) = factory.read();
    let (_bondingCurve) = bondingCurve.read();
    let (_poolType) = poolType.read();
    let (_nftAddress) = nftAddress.read();

    if(_poolType == poolTypes.NFT) {
        with_attr error_message("NFTPair::swapNFTsForToken - Wrong Pool type") {
            assert 1 = 2;
        }
    }
    with_attr error_message("NFTPair::swapNFTsForToken - Must ask for more than 0 NFTs") {
        assert_lt(0, nftIds_len);
    }

    let (nftIdsLenUint) = FeltUint.feltToUint256(nftIds_len);
    let (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(
        nftIdsLenUint,
        minExpectedTokenOutput,
        _bondingCurve,
        _factory
    );

    _sendTokenOutput(tokenRecipient, outputAmount);

    _payProtocolFeeFromPair(_factory, protocolFee);

    _takeNFTsFromSender(
        _nftAddress=_nftAddress,
        startIndex=0,
        nftIds_len=nftIds_len,
        nftIds=nftIds,
        _factory=_factory,
        isRouter=isRouter,
        routerCaller=routerCaller
    );

    SwapNFTInPair.emit();

    ReentrancyGuard._end();

    return ();
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
    let (_factory) = factory.read();
    let (_bondingCurve) = bondingCurve.read();

    let (_spotPrice) = spotPrice.read();
    let (_delta) = delta.read();
    let (_fee) = fee.read();
    let (protocolFeeMultiplier) = INFTPairFactory.getProtocolFeeMultiplier(_factory);
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = ICurve.getBuyInfo(
        _bondingCurve,
        _spotPrice,
        _delta,
        numNFTs,
        _fee,
        protocolFeeMultiplier
    );
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

    let (_factory) = factory.read();
    let (_bondingCurve) = bondingCurve.read();

    let (_spotPrice) = spotPrice.read();
    let (_delta) = delta.read();
    let (_fee) = fee.read();
    let (protocolFeeMultiplier) = INFTPairFactory.getProtocolFeeMultiplier(_factory);
    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = ICurve.getSellInfo(
        _bondingCurve,
        _spotPrice,
        _delta,
        numNFTs,
        _fee,
        protocolFeeMultiplier
    );
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        outputAmount=outputAmount,
        protocolFee=protocolFee
    );
}

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    let (ids_len, ids) = NFTPairLibExample.getAllHeldIds();
    return (ids_len=ids_len, ids=ids);
}

@view
func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
    let (poolTypes) = PoolTypes.value();

    let (_poolType) = poolType.read();
    if(_poolType == poolTypes.TRADE) {
        let (thisAddress) = get_contract_address();
        return (recipient=thisAddress);
    }

    let (_assetRecipient) = assetRecipient.read();
    if(_assetRecipient == 0) {
        let (thisAddress) = get_contract_address();
        return (recipient=thisAddress);
    }
    return (recipient=_assetRecipient);
}

@view
func getFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_fee: felt) {
    let (_fee) = fee.read();
    return (_fee=_fee);
}

@view
func getSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_spotPrice: Uint256) {
    let (_spotPrice) = spotPrice.read();
    return (_spotPrice=_spotPrice);
}

@view
func getDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_delta: Uint256) {
    let (_delta) = delta.read();
    return (_delta=_delta);
}    

@view
func getPairVariant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariant: felt) {
    let (_pairVariant) = pairVariant.read();
    return (_pairVariant=_pairVariant);
}

@view
func getPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_poolType: felt) {
    let (_poolType) = poolType.read();
    return (_poolType=_poolType);
}

@view
func getNFTAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_nftAddress: felt) {
    let (_nftAddress) = nftAddress.read();
    return (_nftAddress=_nftAddress);
}

@view
func getBondingCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_bondingCurve: felt) {
    let (_bondingCurve) = bondingCurve.read();
    return (_bondingCurve=_bondingCurve);
}

@view
func getFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_factory: felt) {
    let (_factory) = factory.read();
    return (_factory=_factory);
}

////////
// INTERNAL

func _calculateBuyInfoAndUpdatePoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    maxExpectedTokenInput: Uint256,
    _bondingCurve: felt,
    _factory: felt
) -> (protocolFee: Uint256, inputAmount: Uint256) {
    
    alloc_locals;
    let (currentSpotPrice) = spotPrice.read();
    let (currentDelta) = delta.read();
    let (_fee) = fee.read();
    let (protocolFeeMultiplier) = INFTPairFactory.getProtocolFeeMultiplier(_factory);
    
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = ICurve.getBuyInfo(
        _bondingCurve, 
        currentSpotPrice, 
        currentDelta, 
        numNFTs, 
        _fee, 
        protocolFeeMultiplier
    );

    _revertIfError(error);

    let (input_is_lower) = uint256_le(inputAmount, maxExpectedTokenInput);
    assert_not_zero(input_is_lower);

    // if(currentSpotPrice != newSpotPrice) {
    //     spotPrice.write(newSpotPrice);
    //     SpotPriceUpdate.emit(newSpotPrice);
    // }
    // if(currentDelta != newDelta) {
    //     delta.write(newDelta);
    //     DeltaUpdate(newDelta);
    // }
    spotPrice.write(newSpotPrice);
    SpotPriceUpdate.emit(newSpotPrice);
    
    delta.write(newDelta);
    DeltaUpdate.emit(newDelta);

    return (protocolFee=protocolFee, inputAmount=inputAmount);
}

func _calculateSellInfoAndUpdatePoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    minExpectedTokenOutput: Uint256,
    _bondingCurve: felt,
    _factory: felt
) -> (protocolFee: Uint256, outputAmount: Uint256) {
    alloc_locals;

    let (currentSpotPrice) = spotPrice.read();
    let (currentDelta) = delta.read();
    let (protocolFeeMultiplier) = INFTPairFactory.getProtocolFeeMultiplier(_factory);
    let (_fee) = fee.read();

    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = ICurve.getSellInfo(
        _bondingCurve,
        currentSpotPrice,
        currentDelta,
        numNFTs,
        _fee,
        protocolFeeMultiplier
    );

    _revertIfError(error);

    with_attr error_message("NFTPair::_calculateSellInfoAndUpdatePoolParams - Out too little tokens") {
        let (isLower) = uint256_lt(minExpectedTokenOutput, outputAmount);
        assert isLower = TRUE;
    }

    spotPrice.write(newSpotPrice);
    delta.write(newDelta);

    SpotPriceUpdate.emit(newSpotPrice);
    DeltaUpdate.emit(newDelta);

    return (protocolFee=protocolFee, outputAmount=outputAmount);
            
}

func _takeNFTsFromSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    startIndex: felt,
    nftIds_len: felt,
    nftIds: Uint256*,
    _factory: felt,
    isRouter: felt,
    routerCaller: felt
) {
    alloc_locals;

    let (_assetRecipient) = getAssetRecipient();

    if(isRouter == TRUE) {
        let (routerAllowed) = INFTPairFactory.routerStatus(_factory, routerCaller);
        with_attr error_message("NFTPair::_takeNFTsFromSender - Router Not Allowed") {
            assert routerAllowed = 1;
        }
        let (_pairVariant) = pairVariant.read();

        let (nftIdsLenUint) = FeltUint.feltToUint256(nftIds_len);
        let (moreThanOneNFT) = uint256_lt(Uint256(low=1, high=0), nftIdsLenUint);  
        if(moreThanOneNFT == TRUE) {
            let (beforeBalance) = IERC721.balanceOf(_nftAddress, _assetRecipient);
            if(startIndex == nftIds_len) {
                return ();
            }                  
            INFTRouter.pairTransferNFTFrom(
                routerCaller,
                _nftAddress,
                routerCaller,
                _assetRecipient,
                [nftIds],
                _pairVariant
            );
            let (afterBalance) = IERC721.balanceOf(_nftAddress, _assetRecipient);
            let (expectedAfterBalance, expectedAfterBalanceCarry) = uint256_add(beforeBalance, Uint256(low=1, high=0));
            with_attr error_mesage("NFTPair::_takeNFTsFromSender - One NFT not transfered") {
                assert_uint256_eq(afterBalance, expectedAfterBalance);
            }

            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;

            return _takeNFTsFromSender(
                _nftAddress,
                startIndex + 1,
                nftIds_len,
                nftIds + 1,
                _factory,
                isRouter,
                routerCaller
            );

        } else {
            INFTRouter.pairTransferNFTFrom(
                routerCaller,
                _nftAddress,
                routerCaller,
                _assetRecipient,
                [nftIds],
                _pairVariant
            );
            let (owner) = IERC721.ownerOf(_nftAddress, [nftIds]);
            with_attr error_mesage("NFTPair::_takeNFTsFromSender - NFT not transferred") {
                assert owner = _assetRecipient;
            }
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;

            return ();
        }
    } else {
        if(startIndex == nftIds_len) {
            return ();
        }          
        let (caller) = get_caller_address();
        IERC721.safeTransferFrom(
            contract_address=_nftAddress,
            from_=caller,
            to=_assetRecipient, 
            tokenId=[nftIds], 
            data_len=0, 
            data=cast (new (0,), felt*)
        );

        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;

        return _takeNFTsFromSender(
            _nftAddress,
            startIndex + 1,
            nftIds_len,
            nftIds + 1,
            _factory,
            isRouter,
            routerCaller
        );
    }
}

func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    inputAmount: Uint256,
    isRouter: felt,
    routerCaller: felt,
    _factory: felt,
    protocolFee: Uint256
) {
    alloc_locals;

    let (_token) = erc20Address.read();
    let (_assetRecipient) = getAssetRecipient();
    let (_pairVariant) = getPairVariant();

    let (amount) = uint256_sub(inputAmount, protocolFee);

    if(isRouter == TRUE) {
        let (routerAllowed) = INFTPairFactory.routerStatus(
            _factory,
            routerCaller
        );
        with_attr error_message("NFTPair::_pullTokenInputAndPayProtocolFee - Router not allowed") {
            assert_not_zero(routerCaller);
        }
        let (beforeBalance) = IERC20.balanceOf(
            _token,
            _assetRecipient
        );
        INFTRouter.pairTransferERC20From(
            routerCaller,
            _token,
            routerCaller,
            _assetRecipient,
            amount,
            _pairVariant
        );

        let (currentBalance) = IERC20.balanceOf(
            _token,
            _assetRecipient
        );
        let (transferedAmount) = uint256_sub(currentBalance, beforeBalance);
        let (supposedAmount) = uint256_sub(inputAmount, protocolFee);

        with_attr error_message("NFTPair::_pullTokenInputAndPayProtocolFee - ERC20 not transfered in") {
            uint256_eq(transferedAmount, supposedAmount);
        }

        INFTRouter.pairTransferERC20From(
            routerCaller,
            _token,
            routerCaller,
            _factory,
            protocolFee,
            _pairVariant
        );
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        let (caller) = get_caller_address();
        IERC20.transferFrom(
            _token,
            caller,
            _assetRecipient,
            amount
        );

        let (isPositive) = uint256_lt(Uint256(low=0, high=0), protocolFee);
        if(isPositive == TRUE) {
            IERC20.transferFrom(
                _token,
                caller,
                _factory,
                protocolFee
            );
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    return ();
}

// func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
//     _nftAddress: felt, 
//     nftRecipient: felt, 
//     startIndex: Uint256, 
//     numNFTs: Uint256
// ) {
//     with_attr error_message("NFTPair::_sendAnyNFTsToRecipient - Function must be implemented in parent contract") {
//         assert 1 = 2;
//     }
//     return ();
// }

// func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
//     _nftAddress: felt,
//     nftRecipient: felt,
//     startIndex: felt,
//     nftIds_len: felt,
//     nftIds: Uint256*
// ) {
//     with_attr error_message("NFTPair::_sendSpecificNFTsToRecipient - Function must be implemented in parent contract") {
//         assert 1 = 2;
//     }
//     return ();
// }

func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    tokenRecipient: felt,
    outputAmount: Uint256
) {
    let (outputExist) = uint256_lt(Uint256(low=0, high=0), outputAmount);
    if(outputExist == TRUE) {
        let (token) = erc20Address.read();
        let (thisAddress) = get_contract_address();
        IERC20.transferFrom(token, thisAddress, tokenRecipient, outputAmount);
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;            
    } else {
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }        
    return ();
}

// protocolFee paid directly from the this address to the factory
func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _factory: felt,
    protocolFee: Uint256
) {
    let (protocolFeeExist) = uint256_lt(Uint256(low=0, high=0), protocolFee);
    if(protocolFeeExist == TRUE) {
        let (token) = erc20Address.read();
        let (thisAddress) = get_contract_address();
        let (pairTokenBalance) = IERC20.balanceOf(token, thisAddress);

        let (protocolFeeGtBalance) = uint256_lt(pairTokenBalance, protocolFee);
        if(protocolFeeGtBalance == TRUE) {
            let (balanceExist) = uint256_lt(Uint256(low=0, high=0), pairTokenBalance);
            if(balanceExist == TRUE) {
                IERC20.transferFrom(token, thisAddress, _factory, pairTokenBalance); // transfer pairBalance
                tempvar range_check_ptr = range_check_ptr;
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
            } else {
                tempvar range_check_ptr = range_check_ptr;
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
            }
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;                
        } else {
            IERC20.transferFrom(token, thisAddress, _factory, protocolFee); // transfer protocolFee
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;                
        }
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }        

    return ();
}

////////
// ADMIN

@external
func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    tokenIds_len: felt,
    tokenIds: Uint256*
) {
    Ownable.assert_only_owner();
    let (_collectionAddress) = nftAddress.read();
    NFTPairLibExample.withdrawERC721(
        _collectionAddress,
        _nftAddress,
        tokenIds_len,
        tokenIds
    );
    return ();
}

@external
func withdrawERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _erc20Address: felt,
    amount: Uint256
) {
    Ownable.assert_only_owner();

    let (caller) = get_caller_address();
    let (thisAddress) = get_contract_address();
    IERC20.transferFrom(_erc20Address, thisAddress, caller, amount);

    let (pairErc20) = erc20Address.read();
    if(_erc20Address == pairErc20) {
        TokenWithdrawal.emit(amount);
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    return ();
}

@external
func withdrawERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt,
    data: felt*
) {
    // with_attr error_message("NFTPair::withdrawERC1155 - Function must be implemented in parent") {
    //     assert 1 = 2;
    // }
    NFTPairLibExample.withdrawERC1155(
        from_,
        to,
        ids_len,
        ids,
        amounts_len,
        amounts,
        data_len,
        data,
    );
    return ();
}

@external
func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newSpotPrice: Uint256
) {
    Ownable.assert_only_owner();

    let (_bondingCurve) = bondingCurve.read();
    let (spotPriceValid) = ICurve.validateSpotPrice(_bondingCurve, newSpotPrice);
    
    with_attr error_message("NFTPair::changeSpotPrice - Invalid new spot price for curve") {
        assert spotPriceValid = TRUE;
    }

    spotPrice.write(newSpotPrice);

    SpotPriceUpdate.emit(newSpotPrice);
    return ();
}

@external
func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newDelta: Uint256
) {
    Ownable.assert_only_owner();

    let (_bondingCurve) = bondingCurve.read();
    let (deltaValid) = ICurve.validateDelta(_bondingCurve, newDelta);
    
    with_attr error_message("NFTPair::changeDelta - Invalid new delta for curve") {
        assert deltaValid = TRUE;
    }

    delta.write(newDelta);

    DeltaUpdate.emit(newDelta);
    return ();
}

@external
func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newFee: felt
) {
    Ownable.assert_only_owner();

    let (_poolType) = poolType.read();
    let (poolTypes) = PoolTypes.value();
    
    with_attr error_message("NFTPair::changeFee - Only for trade pools") {
        assert _poolType = poolTypes.TRADE;
    }

    with_attr error_message("NFTPair::changeFee - Trade fee must be less than 90%") {
        assert_lt(newFee, MAX_FEE);
    }

    fee.write(newFee);

    FeeUpdate.emit(newFee);
    return ();
}

@external
func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newRecipient: felt
) {
    Ownable.assert_only_owner();

    let (_poolType) = poolType.read();
    let (poolTypes) = PoolTypes.value();
    
    if(_poolType == poolTypes.TRADE) {
        with_attr error_message("NFTPair::changeAssetRecipient - Not for trade pools") {
            assert 1 = 2;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    assetRecipient.write(newRecipient);
    AssetRecipientChange.emit(newRecipient);

    return ();
}

@external
func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt, 
    isSupported: felt
) {
    Ownable.assert_only_owner();
    ERC1155Holder.setInterfacesSupported(interfaceId, isSupported);
    return ();
}

// Not implementing call
// Not implementing multicall
// Not implementing _getRevertMsg

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt
) -> (isSupported: felt) {
    let (isSupported) = ERC1155Holder.supportsInterface(interfaceId);
    return (isSupported=isSupported);
}

@external
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    tokenId: Uint256, 
    data_len: felt,
    data: felt*
) -> (selector: felt) {
    let (collectionAddress) = nftAddress.read();
    let (selector) = NFTPairLibExample.onERC721Received(
        collectionAddress,
        operator, 
        from_, 
        tokenId, 
        data_len,
        data
    );
    return (selector=selector);
}

@external
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    token_id: Uint256, 
    amount: Uint256,
    data_len: felt, 
    data: felt*
) -> (selector: felt) {
    let (selector) = ERC1155Holder.onERC1155Received(
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
    let (selector) = ERC1155Holder.onERC1155BatchReceived(
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

////////
// ADDED FUNCTIONS

func _assertCorrectlyInitializedWithPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _poolType: felt,
    _fee: felt,
    _assetRecipient: felt
) {
    alloc_locals;
    let (poolTypes) = PoolTypes.value();
    if(_poolType == poolTypes.TOKEN) {
        with_attr error_message("NFTPair::initializer - Only Trade Pools can have non zero fees") {
            assert _fee = 0;
        }
        assetRecipient.write(_assetRecipient);
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
            if(_poolType == poolTypes.NFT) {
                with_attr error_message("NFTPair::initializer - Only Trade Pools can have non zero fees") {
                    assert _fee = 0;
                }
                tempvar range_check_ptr = range_check_ptr;
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
            } else {
                tempvar range_check_ptr = range_check_ptr;
                tempvar syscall_ptr = syscall_ptr;
                tempvar pedersen_ptr = pedersen_ptr;
                    if(_poolType == poolTypes.TRADE) {
                        assert_lt(_fee, MAX_FEE);
                        with_attr error_message("NFTPair::initializer - Trade pools can't set asset recipient") {
                            assert _assetRecipient = 0;
                        }
                        fee.write(_fee);
                        tempvar range_check_ptr = range_check_ptr;
                        tempvar syscall_ptr = syscall_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                    } else {
                        with_attr error_message("NFTPair::initializer - Wrong pool type (value: {_poolType})") {
                            assert 1 = 2;
                        }
                        tempvar range_check_ptr = range_check_ptr;
                        tempvar syscall_ptr = syscall_ptr;
                        tempvar pedersen_ptr = pedersen_ptr;
                    }
            }
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }

    return ();
}

func _revertIfError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(error: felt) {
    let (isError) = uint256_lt(Uint256(low=0, high=0), Uint256(low=error, high=0));
    if(isError == TRUE) {
        with_attr error_message(
            "NFTPair - There was an error with the bonding curve (code: {error})"
        ) {
            assert 1 = 2;
        }
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    } else {
        tempvar range_check_ptr = range_check_ptr;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
    }
    return ();
}