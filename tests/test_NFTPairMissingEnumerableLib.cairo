%lang starknet

// from contracts.NFTPairMissingEnumerableERC20 import (
//     _removeNFTInEnumeration,
//     _addNFTInEnumeration,
//     getAllHeldIds,
//     idSet_len, 
//     idSet
// )


// @external
// func test_addEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     const AMOUNT = 10;
//     let (initialLen) = idSet_len.read();
//     let (firstId) = idSet.read(0);
//     // %{
//     //     print(f"initialLen: {ids.initialLen}")
//     //     print(f"firstId: {ids.firstId.low + ids.firstId.high}")
//     // %}

//     with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Initial length should be 0") {
//         assert initialLen = 0;
//     }
//     with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - first id should be 0") {
//         assert_uint256_eq(firstId, Uint256(low=0, high=0));
//     }

//     addNFTsToEnum(1, AMOUNT + 1);
    
//     let (finalLen) = idSet_len.read();
//     let (lastId) = idSet.read(finalLen - 1);

//     // %{
//     //     print(f"finalLen: {ids.finalLen}")
//     //     print(f"lastId: {ids.lastId.low + ids.lastId.high}")
//     // %}

//     with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Unexpected length (found: {finalLen}, expected: {AMOUNT})") {
//         assert finalLen = AMOUNT;
//     }
//     with_attr error_message("NFTPairMissingEnumerableERC20::_addNFTInEnumeration - Unexpected last it (found: {lastId}, expected: {AMOUNT})") {
//         assert_uint256_eq(lastId, Uint256(low=AMOUNT, high=0));
//     }

//     return ();
// }

// @external
// func test_removeEnumeration{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     %{
//         if ids.testEnumeration == 0:
//             skip("Skipping Enumeration")
//     %}

//     tempvar NFT_AMOUNT;
//     %{ ids.NFT_AMOUNT = context.NFT_AMOUNT %}

//     let (initial_len) = idSet_len.read();
//     let initialLastIndex = initial_len - 1;
//     let (initialLastId) = idSet.read(initialLastIndex);
//     let targetId = 11;

//     // Should be initial_len - 1 because one tokenId has been removed
//     let expectedFinalLen = initial_len - 1;
//     // Should now be AMOUNT - 1 as the last id (AMOUNT) has been moved 
//     let expectedLastId = Uint256(low=NFT_AMOUNT - 1, high=0);
//     let expectedReplacedId = Uint256(low=NFT_AMOUNT, high=0);

//     %{
//         print(f"initialIdAtMax: {ids.initialLastId.low + ids.initialLastId.high}")
//     %}

//     _removeNFTInEnumeration(Uint256(low=targetId, high=0), 0, initial_len);

//     let (finalLen) = idSet_len.read();
//     let (finalLastId) = idSet.read(finalLen - 1);
//     // Should be 0 bc value has been moved to previous index
//     let (previousLastId) = idSet.read(initialLastIndex);
//     // Value at removed value should now be the previously last value (AMOUNT)
//     let (removedIdUpdatedValue) = idSet.read(targetId - 1);

//     %{
//         print("\n")
//         print(f"finalLen: {ids.finalLen}")
//         print(f"finalLastId: {ids.finalLastId.low + ids.finalLastId.high}")
//         print(f"tokenId at the previous max index is now {ids.previousLastId.low + ids.previousLastId.high}")
//         print(f"tokenId at the removed index is now {ids.removedIdUpdatedValue.low + ids.removedIdUpdatedValue.high}")
//     %}

//     with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected final len (found: {finalLen}, expected {expectedFinalLen}") {
//         assert finalLen = expectedFinalLen;
//     }
//     with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected last id (found: {ids.finalLastId.low + ids.finalLastId.high}, expected {ids.expectedLastId.low + ids.expectedLastId.high}") {
//         assert_uint256_eq(finalLastId, expectedLastId);
//     }
//     with_attr error_message("NFTPairMissingEnumerableERC20::_removeNFTInEnumeration - Unexpected replaced id (found: {ids.removedIdUpdatedValue.low + ids.removedIdUpdatedValue.high}, expected {expectedFinalLen}") {
//         assert_uint256_eq(removedIdUpdatedValue, expectedReplacedId);
//     }

//     return ();
// }

// @external
// func test_getAllHeldIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;
//     %{
//         if ids.testGetAllIds == 0:
//             skip("Skipping getAllIds")    
//     %}

//     let (allIds_len, _allIds) = getAllHeldIds();
//     local allIds: Uint256* = _allIds;

//     assert_uint256_eq(_allIds[0], Uint256(low=1, high=0));
//     assert_uint256_eq(_allIds[1], Uint256(low=2, high=0));
//     assert_uint256_eq(_allIds[2], Uint256(low=3, high=0));
//     assert_uint256_eq(_allIds[3], Uint256(low=4, high=0));
//     assert_uint256_eq(_allIds[4], Uint256(low=5, high=0));
//     // assert_uint256_eq(_allIds[5], Uint256(low=0, high=0));
//     // assert _allIds[5] = 0;
//     // local sixthValue: Uint256 = _allIds[5];

//     %{
//         allIds = ids._allIds[5]
//         allIds_len = ids.allIds_len
//         #print(f"allIds_len: {allIds_len}")
//         #print(f"sixthValue: {reflect.sixthValue.get().low + reflect.sixthValue.get().high}")
//         ## _ids = reflect.allIds.get()
//         #print(f"ids: {_ids}")

//         #for i in range(0, allIds_len):
//             #print(f"idHeld: {_ids[i].low + _ids[i].high}")
//     %}
//     return ();
// }

///////////
// HELPERS
// // @notice set index = tokenId for all index starting from startId to maxId
// func addNFTsToEnum{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(startId: felt, maxId: felt) {
//     alloc_locals;
//     if(startId == maxId + 1) {
//         return ();
//     }

//     _addNFTInEnumeration(Uint256(low=startId, high=0));

//     return addNFTsToEnum(startId + 1, maxId);
// }