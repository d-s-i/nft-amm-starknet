%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_sub, 
    uint256_add
)
from starkware.starknet.common.syscalls import (get_contract_address)
from starkware.cairo.common.bool import (TRUE)

from contracts.interfaces.IERC721 import (IERC721)
from contracts.interfaces.IERC721Enumerable import (IERC721Enumerable)

from contracts.NFTPair import (NFTPair)

namespace NFTPairEnumerable {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        factoryAddr: felt,
        bondingCurveAddr: felt,
        _poolType: felt,
        _nftAddress: felt,
        _spotPrice: felt,
        _delta: felt,
        _fee: felt,
        owner: felt,
        _assetRecipient: felt,
        _pairVariant: felt
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
        return ();
    }

    func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        nftRecipient: felt,
        startIndex: Uint256,
        numNFTs: Uint256
    ) {
        let (contractAddress) = get_contract_address();
        let (balance) = IERC721.balanceOf(_nftAddress, contractAddress);
        let (lastIndex) = uint256_sub(balance, Uint256(low=1, high=0));

        let (isLower) = uint256_lt(startIndex, numNFTs);
        if(isLower == TRUE) {
            let (nftId) = IERC721Enumerable.tokenOfOwnerByIndex(_nftAddress, contractAddress, startIndex);
            IERC721.transferFrom(_nftAddress, contractAddress, nftRecipient, nftId);
            let (newStartIndex, carry) = uint256_add(startIndex, Uint256(low=1, high=0));
            return _sendAnyNFTsToRecipient(_nftAddress, nftRecipient, newStartIndex, numNFTs);
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
        if(startIndex == nftIds_len) {
            return ();
        }

        let (contractAddress) = get_contract_address();
        IERC721.transferFrom(_nftAddress, contractAddress, nftRecipient, [nftIds]);

        return _sendSpecificNFTsToRecipient(
            _nftAddress,
            nftRecipient,
            startIndex + 1,
            nftIds_len,
            nftIds + 1
        );
    }

    ///////////
    // NFTPair.cairo

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
        protocolFee: felt
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
        protocolFee: felt
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
        let (selector) = NFTPair.onERC1155Received(
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