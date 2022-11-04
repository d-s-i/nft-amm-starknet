%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256,
    assert_uint256_eq
)
from contracts.pairs.NFTPairMissingEnumerableERC20.library import (
    NFTPairMissingEnumerableERC20,
    idSet_len,
    idSet
)
from tests.utils.library import (displayIds)

@external
func setup_removeEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    tempvar NFT_AMOUNT = 10;
    %{ context.NFT_AMOUNT = ids.NFT_AMOUNT %}
    addNFTsToEnum(1, NFT_AMOUNT);
    return ();
}

@external
func setup_getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    tempvar NFT_AMOUNT = 5;
    %{ context.NFT_AMOUNT = ids.NFT_AMOUNT %}
    addNFTsToEnum(1, NFT_AMOUNT);
    return ();
}

@external
func test_addEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    const AMOUNT = 10;
    let (initialLen) = idSet_len.read();
    let (firstId) = idSet.read(0);
    %{
        print(f"initialLen: {ids.initialLen}")
        print(f"firstId: {ids.firstId.low + ids.firstId.high}")
    %}

    with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Initial length should be 0") {
        assert initialLen = 0;
    }
    with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - first id should be 0") {
        assert_uint256_eq(firstId, Uint256(low=0, high=0));
    }

    addNFTsToEnum(1, AMOUNT);
    
    let (finalLen) = idSet_len.read();
    let (lastId) = idSet.read(finalLen - 1);

    %{
        print(f"finalLen: {ids.finalLen}")
        print(f"lastId: {ids.lastId.low + ids.lastId.high}")
    %}

    with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Unexpected length (found: {finalLen}, expected: {AMOUNT})") {
        assert finalLen = AMOUNT;
    }
    with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Unexpected last id (found: {lastId}, expected: {AMOUNT})") {
        assert_uint256_eq(lastId, Uint256(low=AMOUNT, high=0));
    }

    return ();
}

@external
func test_removeEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local NFT_AMOUNT;
    %{ids.NFT_AMOUNT = context.NFT_AMOUNT%}

    let (initial_len) = idSet_len.read();
    let initialLastIndex = initial_len - 1;
    let (initialLastTokenId) = idSet.read(initialLastIndex);
    let targetTokenIdToRemove = NFT_AMOUNT;

    let (initialAllIds_len, initialAllIds) = NFTPairMissingEnumerableERC20.getAllHeldIds(0);
    %{
        print(f"Removing tokenId {ids.targetTokenIdToRemove}")
    %}

    %{print("\ninitial tokenIds:")%}
    displayIds(initialAllIds, 0, initialAllIds_len);
    
    // Should be initial_len - 1 because one tokenId has been removed
    let expectedFinalLen = initial_len - 1;
    // Should now be AMOUNT - 1 as the last id (AMOUNT) has been moved somewhere else (or removed)
    let expectedLastTokenId = Uint256(low=NFT_AMOUNT - 1, high=0);
    // assuming tokenId have been added from 1 to max (<=> index === tokenId - 1)
    let expectedReplacedIndex = targetTokenIdToRemove - 1;
    let (expectedReplacedValue) = getValueAtRemovedIndex(targetTokenIdToRemove, NFT_AMOUNT);

    NFTPairMissingEnumerableERC20._removeNFTInEnumeration(Uint256(low=targetTokenIdToRemove, high=0), 0, initial_len);

    let (finalLen) = idSet_len.read();
    let (finalLastTokenId) = idSet.read(finalLen - 1);
    // Should be 0 bc value has been moved to previous index
    let (valueAtInitialMaxIndex) = idSet.read(initialLastIndex);
    // Value at removed value should now be the previously last value (AMOUNT)
    let (removedTokenIdIdUpdatedValue) = idSet.read(expectedReplacedIndex);

    %{print("\ntokenIds after update:")%}
    let (finalAllIds_len, finalAllIds) = NFTPairMissingEnumerableERC20.getAllHeldIds(0);
    displayIds(finalAllIds, 0, finalAllIds_len);

    with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected final len (found: {finalLen}, expected {expectedFinalLen}") {
        assert finalLen = expectedFinalLen;
    }
    with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected last id (found: {ids.finalLastId.low + ids.finalLastId.high}, expected {ids.expectedLastId.low + ids.expectedLastId.high}") {
        assert_uint256_eq(finalLastTokenId, expectedLastTokenId);
    }
    with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected replaced id (found: {ids.removedTokenIdIdUpdatedValue.low + ids.removedTokenIdIdUpdatedValue.high}, expected {expectedFinalLen}") {
        assert_uint256_eq(removedTokenIdIdUpdatedValue, expectedReplacedValue);
    }

    return ();
}

@external
func test_getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    // param is useless for NFTPairMissingEnumerableERC20 (but required for NFTPairEnumerableERC20)
    let (allIds_len, _allIds) = NFTPairMissingEnumerableERC20.getAllHeldIds(213546846546);

    assert_uint256_eq(_allIds[0], Uint256(low=1, high=0));
    assert_uint256_eq(_allIds[1], Uint256(low=2, high=0));
    assert_uint256_eq(_allIds[2], Uint256(low=3, high=0));
    assert_uint256_eq(_allIds[3], Uint256(low=4, high=0));
    assert_uint256_eq(_allIds[4], Uint256(low=5, high=0));

    displayIds(_allIds, 0, allIds_len);

    return ();
}

///////////
// HELPERS
// @notice set index = tokenId for all index starting from startId to maxId
func addNFTsToEnum{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(startId: felt, maxId: felt) {
    alloc_locals;
    if(startId == maxId + 1) {
        return ();
    }

    NFTPairMissingEnumerableERC20._addNFTInEnumeration(Uint256(low=startId, high=0));

    return addNFTsToEnum(startId + 1, maxId);
}

func getValueAtRemovedIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    targetIdRemoved: felt,
    NFT_AMOUNT: felt
) -> (val: Uint256) {
    if(targetIdRemoved == NFT_AMOUNT) {
        // If removed id is the id that have been replaced (=delteted in this case) is now 0
        return (val=Uint256(low=0, high=0));
    } else {
        // if the removed id is in the midle then this value should be the previous last one
        return (val=Uint256(low=NFT_AMOUNT, high=0));
    }
}