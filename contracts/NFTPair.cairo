
%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.math import (assert_not_zero, assert_lt)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_le
)
from starkware.starknet.common.syscalls import (get_contract_address)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.openzeppelin.Ownable import (Ownable)
from contracts.openzeppelin.ReentrancyGuard import (ReentrancyGuard)
from contracts.libraries.ERC1155Holder import (ERC1155Holder)

from contracts.libraries.felt_uint import (FeltUint)

from contracts.interfaces.ICurve import (ICurve)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.IERC721 import (IERC721)
from contracts.interfaces.INFTRouter import (INFTRouter)

from contracts.constants.structs import (PoolType)

const MAX_FEE = 9*10**17;

//////////////
// NFTPair
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
func SwpaNFTOutPair() {
}

@event
func SpotPriceUpdate(newSpotPrice: Uint256) {
}

@event
func DeltaUpdate(newDelta: Uint256) {
}

namespace NFTPair {
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
        _pairVariant: felt
    ) {
        alloc_locals;
        Ownable.initializer(owner);

        _assertCorrectlyInitializedWithPoolType(_poolType, _fee, _assetRecipient);

        let (deltaSuccess) = ICurve.validateDelta(bondingCurveAddr, _delta);
        with_attr error_message("NFTPair::initializer - Invalid delta for curve") {
            assert deltaSuccess = TRUE;
        }
        let (spotPriceSuccess) = ICurve.validateSpotPrice(bondingCurveAddr, _spotPrice);
        with_attr error_message("NFTPair::initializer - Invalid new spt price for curve") {
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
        return ();
    }

    func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
        alloc_locals;

        ReentrancyGuard._start();

        let (_factory) = factory.read();
        let (_bondingCurve) = bondingCurve.read();
        let (_nftAddress) = nftAddress.read();
        let (_poolType) = poolType.read();

        // _poolType == EnumPoolType.TOKEN not working
        // check if type == TOKEN to avoid two nested IF
        if(_poolType == 1) {
            with_attr error_message("NFTPair::swapTokenForAnyNFTs - Wrong Pool type") {
                assert 1 = 2;
            }
        }

        let (contractAddress) = get_contract_address();
        let (balance) = IERC721.balanceOf(_nftAddress, contractAddress);

        with_attr error_message("NFTPair::swapTokenForAnyNFTs - Contract has not enough balances for trade") {
            assert_not_zero(numNFTs.low);
            assert_not_zero(numNFTs.high);
            let (isLower) = uint256_le(numNFTs, balance); 
            assert isLower = TRUE;
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

        _sendAnyNFTsToRecipient(_nftAddress, nftRecipient, Uint256(low=0, high=0), numNFTs);

        SwpaNFTOutPair.emit();

        ReentrancyGuard._end();
        
        return ();
    }

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

        let (_factory) = factory.read();
        let (_bondingCurve) = bondingCurve.read();
        let (_poolType) = poolType.read();
        let (_nftAddress) = nftAddress.read();

        if(_poolType == 1) {
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

        _sendSpecificNFTsToRecipient(
            _nftAddress,
            nftRecipient,
            0,
            nftIds_len,
            nftIds
        );        

        SwpaNFTOutPair.emit();

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
        let (_factory) = factory.read();
        let (_bondingCurve) = bondingCurve.read();
        let (_poolType) = poolType.read();

        if(_poolType == 1) {
            with_attr error_message("Wrong Pool type") {
                assert 1 = 2;
            }
        }
        with_attr error_message("Must ask for more than 0 NFTs") {
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

        SwapNFTInPair.emit();

        ReentrancyGuard._end();

        return ();
    }

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

    func getSellNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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
            inputAmount=inputAmount,
            protocolFee=protocolFee
        );
    }

    func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
        let (_poolType) = poolType.read();
        if(_poolType == 3) {
            let (contractAddress) = get_contract_address();
            return (recipient=contractAddress);
        }

        let (_assetRecipient) = assetRecipient.read();
        if(_assetRecipient == 0) {
            let (contractAddress) = get_contract_address();
            return (recipient=contractAddress);
        }
        return (recipient=_assetRecipient);
    }

    func getPairVariant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariant: felt) {
        let (_pairVariant) = pairVariant.read();
        return (_pairVariant=_pairVariant);
    }

    func getNFtAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_nftAddress: felt) {
        let (_nftAddress) = nftAddress.read();
        return (_nftAddress=_nftAddress);
    }

    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = ERC1155Holder.supportsInterface(interfaceId);
        return (isSupported=isSupported);
    }

    func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        Ownable.assert_only_owner();
        ERC1155Holder.setInterfacesSupported(interfaceId, isSupported);
        return ();
    }

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

    func _assertCorrectlyInitializedWithPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _poolType: felt,
        _fee: felt,
        _assetRecipient: felt
    ) {
        alloc_locals;
        if(_poolType == 1) {
            with_attr error_message("NFTPair::initializer - Only Trade Pools can have non zero fees") {
                assert _fee = 0;
            }
            assetRecipient.write(_assetRecipient);
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        } else {
            tempvar range_check_ptr = range_check_ptr;
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
        }
        if(_poolType == 2) {
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
        }
        if(_poolType == 3) {
            assert_lt(_fee, MAX_FEE);
            with_attr error_message("NFTPair::initializer - Trade pools can't set asset recipient") {
                assert _assetRecipient = 0;
            }
            fee.write(_fee);
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

        if(error == TRUE) {
            with_attr error_message(
                "NFTPair::_calculateBuyInfoAndUpdatePoolParams - There was an error with the bonding curve"
            ) {
                assert 1 = 2;
            }
        }

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

        // check for error

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

        if(isRouter == TRUE) {
            let (_assetRecipient) = getAssetRecipient();
            let (routerAllowed) = INFTPairFactory.routerStatus(_factory, routerCaller);
            with_attr error_message("Router Not Allowed") {
                assert routerAllowed = 1;
            }

            let (nftIdsLenUint) = FeltUint.feltToUint256(nftIds_len);
            let (moreThanOneNFT) = uint256_lt(Uint256(low=1, high=0), nftIdsLenUint);  
            if(moreThanOneNFT == TRUE) {
                let (beforeBalance) = IERC721.balanceOf(_nftAddress, _assetRecipient);
                if(startIndex == nftIds_len) {
                    return ();
                }
                let (_pairVariant) = pairVariant.read();
                INFTRouter.pairTransferNFTFrom(
                    routerCaller,
                    _nftAddress,
                    routerCaller,
                    _assetRecipient,
                    [nftIds],
                    _pairVariant
                );

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

    func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: Uint256
    ) {
        with_attr error_message("NFTPair::_pullTokenInputAndPayProtocolFee - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt, 
        nftRecipient: felt, 
        startIndex: Uint256, 
        numNFTs: Uint256
    ) {
        with_attr error_message("NFTPair::_sendAnyNFTsToRecipient - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        nftRecipient: felt,
        startIndex: felt,
        nftIds_len: felt,
        nftIds: Uint256*
    ) {
        with_attr error_message("NFTPair::_sendSpecificNFTsToRecipient - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        tokenRecipient: felt, 
        outputAmount: Uint256
    ) {
        with_attr error_message("NFTPair::_sendTokenOutput - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _factory: felt, 
        protocolFee: Uint256
    ) {
        with_attr error_message("NFTPair::_payProtocolFeeFromPair - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    } 
}