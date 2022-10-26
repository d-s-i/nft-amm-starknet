%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_sub,
    uint256_eq,
    uint256_lt
)
from starkware.cairo.common.math import (assert_not_zero)
from starkware.cairo.common.bool import (TRUE)

from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.INFTRouter import (INFTRouter)

from contracts.NFTPair import (NFTPair)
from contracts.libraries.felt_uint import (FeltUint)

@storage_var
func tokenAddress() -> (res: felt) {
}

namespace NFTPairERC20 {
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
        _tokenAddress: felt
    ) {
        NFTPair.initializer(
            factoryAddr,
            bondingCurveAddr,
            _poolType,
            _nftAddress,
            _spotPrice,
            _delta,
            _fee,
            owner,
            _assetRecipient,
            _pairVariant
        );
        tokenAddress.write(_tokenAddress);
        return ();
    }

    func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: felt
    ) {
        alloc_locals;
    
        let (_token) = tokenAddress.read();
        let (_assetRecipient) = NFTPair.getAssetRecipient();
        let (_pairVariant) = NFTPair.getPairVariant();

        let (protocolFeeUint) = FeltUint.feltToUint256(protocolFee);
        let (amount) = uint256_sub(inputAmount, protocolFeeUint);

        if(isRouter == TRUE) {
            let (routerAllowed) = INFTPairFactory.routerStatus(
                _factory,
                routerCaller
            );
            with_attr error_message("NFTPairERC20::_pullTokenInputAndPayProtocolFee - Router not allowed") {
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
            let (supposedAmount) = uint256_sub(inputAmount, protocolFeeUint);

            with_attr error_message("NFTPairERC20::_pullTokenInputAndPayProtocolFee - ERC20 not transfered in") {
                uint256_eq(transferedAmount, supposedAmount);
            }

            INFTRouter.pairTransferERC20From(
                routerCaller,
                _token,
                routerCaller,
                _factory,
                protocolFeeUint,
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

            let (isPositive) = uint256_lt(Uint256(low=0, high=0), protocolFeeUint);
            if(isPositive == TRUE) {
                IERC20.transferFrom(
                    _token,
                    caller,
                    _factory,
                    protocolFeeUint
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

    // protocolFee paid directly from the this address to the factory
    func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _factory: felt,
        protocolFee: Uint256
    ) {
        let (protocolFeeExist) = uint256_lt(Uint256(low=0, high=0), protocolFee);
        if(protocolFeeExist == TRUE) {
            let (token) = tokenAddress.read();
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

    func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        tokenRecipient: felt,
        outputAmount: Uint256
    ) {
        let (outputExist) = uint256_lt(Uint256(low=0, high=0), outputAmount);
        if(outputExist == TRUE) {
            let (token) = tokenAddress.read();
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

    func _refundTokenToSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(amount: Uint256) {
        return ();
    }

    func withdrawERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        erc20Address: felt,
        amount: Uint256
    ) {
        NFTPair._assertOnlyOwner();
        let (caller) = get_caller_address();
        let (thisAddress) = get_contract_address();
        IERC20.transferFrom(erc20Address, thisAddress, caller, amount);

        let (token) = tokenAddress.read();
        if(erc20Address == token) {
            NFTPair._emitTokenWithdrawal(amount);
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
    // NFTPair

    func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
        NFTPair.swapTokenForAnyNFTs(
            numNFTs,
            maxExpectedTokenInput,
            nftRecipient,
            isRouter,
            routerCaller
        );
        
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
        NFTPair.swapTokenForSpecificNFTs(
            nftIds_len,
            nftIds,
            maxExpectedTokenInput,
            nftRecipient,
            isRouter,
            routerCaller
        );
        return ();

    }

    func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        nftIds_len: felt,
        nftIds: Uint256*,
        minExpectedTokenOutput: Uint256,
        tokenRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
        NFTPair.swapNFTsForToken(
            nftIds_len,
            nftIds,
            minExpectedTokenOutput,
            tokenRecipient,
            isRouter,
            routerCaller
        );
        return ();
    }

    ////////
    // GETTERS

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
        ) = NFTPair.getBuyNFTQuote(numNFTs);
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
        let (
            error,
            newSpotPrice,
            newDelta,
            inputAmount,
            protocolFee
        ) = NFTPair.getSellNFTQuote(numNFTs);
        return (
            error=error,
            newSpotPrice=newSpotPrice,
            newDelta=newDelta,
            inputAmount=inputAmount,
            protocolFee=protocolFee
        );
    }

    func getAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (recipient: felt) {
        let (_assetRecipient) = NFTPair.getAssetRecipient();
        return (recipient=_assetRecipient);
    }

    func getPairVariant{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_pairVariant: felt) {
        let (_pairVariant) = NFTPair.getPairVariant();
        return (_pairVariant=_pairVariant);
    }

    func getPoolType{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_poolType: felt) {
        let (_poolType) = NFTPair.getPoolType();
        return (_poolType=_poolType);
    }

    func getNFTAddress{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_nftAddress: felt) {
        let (_nftAddress) = NFTPair.getNFTAddress();
        return (_nftAddress=_nftAddress);
    }

    func getBondingCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_bondingCurve: felt) {
        let (_bondingCurve) = NFTPair.getBondingCurve();
        return (_bondingCurve=_bondingCurve);
    }

    func getFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (_factory: felt) {
        let (_factory) = NFTPair.getFactory();
        return (_factory=_factory);
    }

    ////////
    // NFTPair - ADMIN

    func changeSpotPrice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        newSpotPrice: Uint256
    ) {
        NFTPair.changeSpotPrice(newSpotPrice);
        return ();
    }

    func changeDelta{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        newDelta: Uint256
    ) {
        NFTPair.changeDelta(newDelta);
        return ();
    }

    func changeFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        newFee: felt
    ) {
        NFTPair.changeFee(newFee);
        return ();
    }

    func changeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        newRecipient: felt
    ) {
        NFTPair.changeAssetRecipient(newRecipient);
        return ();
    }

    func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        NFTPair.setInterfacesSupported(interfaceId, isSupported);
        return ();
    }

    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = NFTPair.supportsInterface(interfaceId);
        return (isSupported=isSupported);
    }

    func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        operator: felt, 
        from_: felt, 
        token_id: Uint256, 
        amount: Uint256,
        data_len: felt, 
        data: felt*
    ) -> (selector: felt) {
        let (selector) = NFTPair.onERC1155Received(
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
        let (selector) = NFTPair.onERC1155BatchReceived(
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
}