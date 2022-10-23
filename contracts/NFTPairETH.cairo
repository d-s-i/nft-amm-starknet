%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.math import (assert_lt)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_le, 
    uint256_sub 
)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.NFTPair import (NFTPair)

from contracts.libraries.felt_uint import (FeltUint)

from contracts.interfaces.IERC20 import (IERC20)

from contracts.constants.structs import (PoolType)

let EnumPoolType = PoolType(TOKEN=1, NFT=2, TRADE=3);

@storage_var
func wethAddress() -> (res: felt) {
}

namespace NFTPairETH {
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
        _wethAddress: felt
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
        wethAddress.write(_wethAddress);
        return ();
    }

    func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt} (
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: Uint256
    ) {
        let (_assetRecipient) = NFTPair.getAssetRecipient();
        let (weth) = wethAddress.read();
        let (sender) = get_caller_address();
        let (thisAddress) = get_contract_address();

        let (protocolFeeUint) = FeltUint.feltToUint256(protocolFee);
        let (inputWithoutFee) = uint256_sub(inputAmount, protocolFeeUint);
        IERC20.transferFrom(weth, sender, thisAddress, inputWithoutFee);

        IERC20.transferFrom(weth, sender, _factory, protocolFeeUint);
        
        return ();
    }

    func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        tokenRecipient: felt,
        outputAmount: Uint256
    ) {

        alloc_locals;
        let (outputPositive) = uint256_lt(Uint256(low=0, high=0), outputAmount);
        if(outputPositive == FALSE) {
            return ();
        }
        let (thisAddress) = get_contract_address();
        let (weth) = wethAddress.read();
        IERC20.transferFrom(weth, thisAddress, tokenRecipient, outputAmount);
        return ();

    }

    func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _factory: felt,
        protocolFee: Uint256
    ) {
        alloc_locals;

        // Can't use assert_lt because it revert if not lower
        // Cast to Uint to allow the case where protocolFee == 0
        let (protocolFeeUint) = FeltUint.feltToUint256(protocolFee);
        let (protocolFeePositive) = uint256_le(Uint256(low=0, high=0), protocolFeeUint);
        
        if(protocolFeePositive == FALSE) {
            return ();
        }
        
        let _protocolFee: Uint256 = alloc();

        let (weth) = wethAddress.read();
        let (thisAddress) = get_contract_address();
        let (thisBalance) = IERC20.balanceOf(weth, thisAddress);

        let (balanceHigher) = uint256_le(thisBalance, protocolFeeUint);
        if(balanceHigher == TRUE) {
            assert _protocolFee = thisBalance;
        }

        let (newProtocolFeePositive) = uint256_lt(Uint256(low=0, high=0), _protocolFee);
        if(newProtocolFeePositive == FALSE) {
            return ();
        }
        IERC20.transferFrom(weth, thisAddress, _factory, _protocolFee);

        return ();
    }

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

    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = NFTPair.supportsInterface(interfaceId);
        return (isSupported=isSupported);
    }

    func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt, 
        isSupported: felt
    ) {
        NFTPair.setInterfacesSupported(interfaceId, isSupported);
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