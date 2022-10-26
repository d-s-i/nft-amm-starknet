%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_eq,
    uint256_sub, 
    uint256_add
)
from starkware.cairo.common.alloc import (alloc)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.bool import (TRUE)

from contracts.constants.library import (IERC721_RECEIVER_ID)
from contracts.libraries.felt_uint import (FeltUint) 

from contracts.interfaces.tokens.IERC721Enumerable import (IERC721Enumerable)

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
        let (balance) = IERC721Enumerable.balanceOf(_nftAddress, contractAddress);
        let (lastIndex) = uint256_sub(balance, Uint256(low=1, high=0));

        let (isLower) = uint256_lt(startIndex, numNFTs);
        if(isLower == TRUE) {
            let (nftId) = IERC721Enumerable.tokenOfOwnerByIndex(_nftAddress, contractAddress, startIndex);
            IERC721Enumerable.transferFrom(_nftAddress, contractAddress, nftRecipient, nftId);
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
        IERC721Enumerable.transferFrom(_nftAddress, contractAddress, nftRecipient, [nftIds]);

        return _sendSpecificNFTsToRecipient(
            _nftAddress,
            nftRecipient,
            startIndex + 1,
            nftIds_len,
            nftIds + 1
        );
    }

    func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (tokenIds_len: felt, tokenIds: Uint256*) {
        alloc_locals;

        let (_nftAddress) = NFTPair.getNFTAddress();
        let (thisAddress) = get_contract_address();
        let (balance) = IERC721Enumerable.balanceOf(_nftAddress, thisAddress);
        
        let (tokenIds_len) = FeltUint.uint256ToFelt(balance);
        let (tokenIds: Uint256*) = alloc();

        _getAllIdsLoop(Uint256(low=0, high=0), balance, _nftAddress, thisAddress, tokenIds);

        return (tokenIds_len, tokenIds);
    }

    func _getAllIdsLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        index: Uint256,
        end: Uint256,
        nftAddress: felt,
        ownerAddress: felt,
        tokenIds: Uint256*
    ) {

        let (endReached) = uint256_eq(index, end);
        if(endReached == TRUE) {
            return ();
        }

        let (id) = IERC721Enumerable.tokenOfOwnerByIndex(nftAddress, ownerAddress, index);
        assert [tokenIds] = id;

        let (newIndex, newIndexCarry) = uint256_add(index, Uint256(low=1, high=0));
        return _getAllIdsLoop(
            newIndex,
            end,
            nftAddress,
            ownerAddress,
            tokenIds + 1
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
        outputAmount: Uint256,
        protocolFee: Uint256
    ) {
        let (
            error,
            newSpotPrice,
            newDelta,
            outputAmount,
            protocolFee
        ) = NFTPair.getSellNFTQuote(numNFTs);
        return (
            error=error,
            newSpotPrice=newSpotPrice,
            newDelta=newDelta,
            outputAmount=outputAmount,
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

    func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        interfaceId: felt
    ) -> (isSupported: felt) {
        let (isSupported) = NFTPair.supportsInterface(interfaceId);
        return (isSupported=isSupported);
    }

    func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (interfaceId: felt) {
        return (IERC721_RECEIVER_ID);
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

    func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        tokenIds_len,
        tokenIds: Uint256*
    ) {
        let (thisAddress) = get_contract_address();
        let (caller) = get_caller_address();

        withdrawERC721_loop(
            _nftAddress, 
            thisAddress, 
            caller,
            tokenIds_len,
            tokenIds,
            0
        );
        
        return ();
    }

    func withdrawERC721_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        from_: felt,
        to: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*,
        start: felt
    ) {
        if(start == tokenIds_len) {
            return ();
        }

        IERC721Enumerable.transferFrom(_nftAddress, from_, to, [tokenIds]);

        return withdrawERC721_loop(
            _nftAddress,
            from_,
            to,
            tokenIds_len,
            tokenIds + 1,
            start + 1
        );
    
    }

    func withdrawERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        sender: felt, 
        recipient: felt, 
        amount: Uint256
    ) {
        with_attr error_message("NFTPairEnumerable::withdrawERC20 - Function must be implemented in parent") {
            assert 1 = 2;
        }
        return ();
    }

    func withdrawERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*,
    ) {
        with_attr error_message("NFTPairEnumerable::withdrawERC1155 - Function must be implemented in parent") {
            assert 1 = 2;
        }
        return ();
    }

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

    ////////
    // INTERNAL

    func _takeNFTsFromSender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        startIndex: felt,
        nftIds_len: felt,
        nftIds: Uint256*,
        _factory: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
        NFTPair._takeNFTsFromSender(
            _nftAddress,
            startIndex,
            nftIds_len,
            nftIds,
            _factory,
            isRouter,
            routerCaller
        );
        return ();
    }

    func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: Uint256
    ) {
        with_attr error_message("NFTPairEnumerable::_pullTokenInputAndPayProtocolFee - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _sendTokenOutput{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        tokenRecipient: felt, 
        outputAmount: Uint256
    ) {
        with_attr error_message("NFTPairEnumerable::_sendTokenOutput - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    }

    func _payProtocolFeeFromPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _factory: felt, 
        protocolFee: Uint256
    ) {
        with_attr error_message("NFTPairEnumerable::_payProtocolFeeFromPair - Function must be implemented in parent contract") {
            assert 1 = 2;
        }
        return ();
    } 

    func _revertIfError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(error: felt) {
        NFTPair._revertIfError(error);
        return ();
    }

    func _assertOnlyOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
        NFTPair._assertOnlyOwner();
        return ();
    }

    func _emitTokenWithdrawal{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        amount: Uint256
    ) {
        NFTPair._emitTokenWithdrawal(amount);
        return ();
    }
}