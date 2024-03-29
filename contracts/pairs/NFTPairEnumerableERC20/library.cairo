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
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.constants.library import (IERC721_RECEIVER_ID)
from contracts.libraries.felt_uint import (FeltUint) 

from contracts.interfaces.tokens.IERC721Enumerable import (IERC721Enumerable)

namespace NFTPairEnumerableERC20 {
   func onERC721Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _collectionAddress: felt,
        operator: felt, 
        from_: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
   ) -> (interfaceId: felt) {
        return (interfaceId=IERC721_RECEIVER_ID);
    }
    
    func withdrawERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        collectionAddress: felt,
        erc721Address: felt,
        tokenIds_len: felt,
        tokenIds: Uint256*
    ) {
        alloc_locals;
        let (thisAddress) = get_contract_address();
        let (caller) = get_caller_address();

        withdrawERC721_loop(
            _nftAddress=erc721Address, 
            from_=thisAddress, 
            to=caller,
            tokenIds_len=tokenIds_len,
            tokenIds=tokenIds,
            start=0
        );
        
        return ();
    }

    func getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(collectionAddress: felt) -> (tokenIds_len: felt, tokenIds: Uint256*) {
        alloc_locals;

        let (thisAddress) = get_contract_address();
        let (balance) = IERC721Enumerable.balanceOf(collectionAddress, thisAddress);
        
        let (tokenIds_len) = FeltUint.uint256ToFelt(balance);
        let (tokenIds: Uint256*) = alloc();

        _getAllIdsLoop(Uint256(low=0, high=0), balance, collectionAddress, thisAddress, tokenIds);

        return (tokenIds_len, tokenIds);
    }

    func _getAllIdsLoop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        index: Uint256,
        end: Uint256,
        collectionAddress: felt,
        ownerAddress: felt,
        tokenIds: Uint256*
    ) {

        let (endReached) = uint256_eq(index, end);
        if(endReached == TRUE) {
            return ();
        }

        let (id) = IERC721Enumerable.tokenOfOwnerByIndex(collectionAddress, ownerAddress, index);
        assert [tokenIds] = id;

        let (newIndex, newIndexCarry) = uint256_add(index, Uint256(low=1, high=0));
        return _getAllIdsLoop(
            newIndex,
            end,
            collectionAddress,
            ownerAddress,
            tokenIds + Uint256.SIZE
        );
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

        IERC721Enumerable.transferFrom(
            contract_address=_nftAddress, 
            from_=from_, 
            to=to, 
            tokenId=[tokenIds]
        );

        return withdrawERC721_loop(
            _nftAddress,
            from_,
            to,
            tokenIds_len,
            tokenIds + Uint256.SIZE,
            start + 1
        );
    }

    func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        _nftAddress: felt,
        nftRecipient: felt,
        startIndex: Uint256,
        lastIndex: Uint256,
        numNFTs: Uint256
    ) {
       let (isLower) = uint256_lt(startIndex, numNFTs);
        if(isLower == FALSE) {
            return (); 
        } 

        let (thisAddress) = get_contract_address();
        let (nftId) = IERC721Enumerable.tokenOfOwnerByIndex(_nftAddress, thisAddress, lastIndex);
        IERC721Enumerable.transferFrom(_nftAddress, thisAddress, nftRecipient, nftId);

        let (newStartIndex, carry) = uint256_add(startIndex, Uint256(low=1, high=0));
        let (newlastIndex) = uint256_sub(lastIndex, Uint256(low=1, high=0));
        return _sendAnyNFTsToRecipient(_nftAddress, nftRecipient, newStartIndex, newlastIndex, numNFTs);

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
            nftIds + Uint256.SIZE
        );
    }
}