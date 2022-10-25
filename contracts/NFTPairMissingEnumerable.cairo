%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_sub, 
    uint256_add,
    uint256_eq
)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.constants.library import (IERC721_RECEIVER_ID)
from contracts.libraries.felt_uint import (FeltUint)

from contracts.interfaces.tokens.IERC721 import (IERC721)

from contracts.NFTPair import (NFTPair)

@storage_var
func idSet_len() -> (res: felt) {
}

@storage_var
func idSet(id: felt) -> (tokenId: Uint256) {
}

@event
func NFTWithdrawal() {
}

namespace NFTPairMissingEnumerable {
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
        pairVariant: felt
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
            pairVariant
        );
        return ();
    }

    func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*
    ) {
        NFTPair._assertOnlyOwner();

        let (collectionAddress) = NFTPair.getNFTAddress();
        let(thisAddress) = get_contract_address();
        let (caller) = get_caller_address();
        if(_nftAddress != collectionAddress) {
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
        
        return _withdrawExternalERC721_loop(
            start + 1,
            end,
            from_,
            to,
            tokenIds + 1
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

        let (maxReached) = uint256_lt(start, numNFTs);
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

    func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        operator: felt, 
        from_: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ) -> (selector: felt) {
        let (_nftAddress) = NFTPair.getNFTAddress();
        let (caller) = get_caller_address();

        with_attr error_message("NFTPairMissingEnumerable::onERC721Received - Can only receive NFTs from pooled collection") {
            assert caller = _nftAddress;
        }

        _addNFTInEnumeration(tokenId);

        return (selector=IERC721_RECEIVER_ID);
    }

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
            // replace this value by last valule
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