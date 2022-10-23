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

from contracts.interfaces.IERC721 import (IERC721)

from contracts.NFTPair import (NFTPair)
from contracts.libraries.felt_uint import (FeltUint)

@storage_var
func idSet_len() -> (res: felt) {
}

@storage_var
func idSet(id: felt) -> (tokenId: Uint256) {
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
) {
    // PairVariant.MISSING_ENUMERABLE_ETH
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
        2
    );
    return ();
}

@view
func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    tokenId: Uint256, 
    data_len: felt,
    data: felt*
) -> (selector: felt) {
    let (_nftAddress) = NFTPair.getNFtAddress();
    let (caller) = get_caller_address();

    with_attr error_message("NFTPairMissingEnumerable::onERC721Received - Can only receive NFTs from pooled collection") {
        assert caller = _nftAddress;
    }

    _addNFTInEnumeration(tokenId);

    return (selector=IERC721_RECEIVER_ID);
}

@view
func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (ids_len: felt, ids: Uint256*) {
    alloc_locals;
    let (ids: Uint256*) = alloc();
    let (end) = idSet_len.read();

    _getAllHeldIdsLoop(ids, 0, end);
    
    return (ids_len=end, ids=ids);
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

    _removeNFTInEnumeration(lastTokenId, lastIndex, TRUE);

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

func _getAllHeldIdsLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _ids: Uint256*,
    start: felt,
    end: felt
) {
    // let (maxReached) = uint256_eq(start, end);
    // if(maxReached == TRUE) {
    //     return (_ids);
    // }

    if(start == end) {
        return ();
    }

    let (currentId) = idSet.read(start);
    assert [_ids] = currentId;

    return _getAllHeldIdsLoop(
        _ids + 1,
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
    isSearchingForIdToRemove: felt
) {
    alloc_locals;
    let (end) = idSet_len.read();
    let (id) = idSet.read(startIndex);

    let (isCorrectId) = uint256_eq(id, targetId);
    if(isCorrectId == TRUE) {
        let (len) = idSet_len.read();
        let (nextValue) = idSet.read(startIndex + 1);
        idSet.write(startIndex, nextValue);
        idSet_len.write(len - 1);
        return _removeNFTInEnumeration(targetId, startIndex + 1, FALSE);        
        // else: shift all other ids
    } else {
        if(isSearchingForIdToRemove == TRUE) {
            return _removeNFTInEnumeration(targetId, startIndex + 1, TRUE);
        } else {
            if(startIndex == end) {
                return ();
            }
            // If not searching, is organizing
            let (nextValue) = idSet.read(startIndex + 1);
            idSet.write(startIndex, nextValue);        
            return _removeNFTInEnumeration(targetId, startIndex + 1, FALSE);
        }
    }

    // let (currentIdSetLen) = idSet_len.read();
    // idSet.write(currentIdSetLen, tokenId);

    // idSet_len.write(currentIdSetLen - 1);
    // return ();

}