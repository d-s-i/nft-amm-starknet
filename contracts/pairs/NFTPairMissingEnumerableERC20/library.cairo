// PROBLEM: If someone do IERC721.transferFrom() to transfer one of his NFT to the pair, the idSet is not updated
// and the pair might not be tradable fully because onERC721Received is not called by `transferFrom`

%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_eq,
    uint256_add
)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.constants.library import (IERC721_RECEIVER_ID)

@storage_var
func idSet_len() -> (res: felt) {
}

@storage_var
func idSet(id: felt) -> (tokenId: Uint256) {
}

@event
func NFTWithdrawal() {
}

namespace NFTPairMissingEnumerableERC20 {
    func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _collectionAddress: felt,
        operator: felt, 
        from_: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ) -> (selector: felt) {
        let (caller) = get_caller_address();

        // with_attr error_message("NFTPairMissingEnumerable::onERC721Received - Can only receive NFTs from pooled collection") {
        //     assert caller = _nftAddress;
        // }
        if(caller == _collectionAddress) {
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
    
    func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _collectionAddress: felt,
        erc721Address: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*
    ) {
        alloc_locals;

        let(thisAddress) = get_contract_address();
        let (caller) = get_caller_address();
        if(erc721Address != _collectionAddress) {
            _withdrawExternalERC721_loop(
                0,
                tokenIds_len,
                erc721Address,
                thisAddress,
                caller,
                tokenIds
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;
        } else {        
            _withdrawERC721_loop(
                0,
                tokenIds_len,
                _collectionAddress,
                thisAddress,
                caller,
                tokenIds
            );
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;              
        }

        return ();
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
            _ids + Uint256.SIZE,
            start + 1,
            end
        );
    }

    func _withdrawExternalERC721_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        start: felt,
        end: felt,
        erc721Address: felt,
        from_: felt,
        to: felt,
        tokenIds: Uint256*
    ) {
        if(start == end) {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;          
            return ();
        } else {
            tempvar syscall_ptr = syscall_ptr;
            tempvar pedersen_ptr = pedersen_ptr;
            tempvar range_check_ptr = range_check_ptr;  
        }

        IERC721.transferFrom(
            contract_address=erc721Address, 
            from_=from_, 
            to=to, 
            tokenId=[tokenIds]
        );
        return _withdrawExternalERC721_loop(
            start + 1,
            end,
            erc721Address,
            from_,
            to,
            tokenIds + Uint256.SIZE
        );
    }

    func _withdrawERC721_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        start: felt,
        end: felt,
        collectionAddress: felt,
        from_: felt,
        to: felt,
        tokenIds: Uint256*
    ) {
        alloc_locals;
        if(start == end) {
            return ();
        }    
         
        IERC721.transferFrom(
            contract_address=collectionAddress, 
            from_=from_, 
            to=to, 
            tokenId=[tokenIds]
        );

        let (maxIndex) = idSet_len.read();
        _removeNFTInEnumeration([tokenIds], 0, maxIndex);
        NFTWithdrawal.emit();
        
        return _withdrawERC721_loop(
            start + 1,
            end,
            collectionAddress,
            from_,
            to,
            tokenIds + Uint256.SIZE
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
            nftIds + Uint256.SIZE
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
}