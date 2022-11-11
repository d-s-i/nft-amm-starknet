%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.router.structs import (
    PairSwapSpecific,
    RobustPairSwapSpecific
)

from contracts.router.router import (
    toPairSwapSpecificArr,
    toRobustPairSwapSpecificArr
)

from tests.utils.library import (displayIds)

// @external
// func test_toStruct{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     let swapList_len = 5;
//     let (swapList: PairSwapSpecific*) = alloc();

//     let (pairs: felt*) = alloc();
//     // pair addresses:
//     // [ 1, 2, 3, 4, 5 ]
//     assert pairs[0] = 1;
//     assert pairs[1] = 2;
//     assert pairs[2] = 3;
//     assert pairs[3] = 4;
//     assert pairs[4] = 5;

//     let (nftIds_len: felt*) = alloc();
//     // amount of ids to trade for each pair
//     assert nftIds_len[0] = 3;
//     assert nftIds_len[1] = 2;
//     assert nftIds_len[2] = 3;
//     assert nftIds_len[3] = 4;
//     assert nftIds_len[4] = 1;

//     let nftIds_ptrs_len = 13;
//     let (nftIds_ptrs: Uint256*) = alloc();
//     // all ids for all pairs together
//     // [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12]
//     assert nftIds_ptrs[0] = Uint256(low=0, high=0);
//     assert nftIds_ptrs[1] = Uint256(low=1, high=0);
//     assert nftIds_ptrs[2] = Uint256(low=2, high=0);
//     assert nftIds_ptrs[3] = Uint256(low=3, high=0);
//     assert nftIds_ptrs[4] = Uint256(low=4, high=0);
//     assert nftIds_ptrs[5] = Uint256(low=5, high=0);
//     assert nftIds_ptrs[6] = Uint256(low=6, high=0);
//     assert nftIds_ptrs[7] = Uint256(low=7, high=0);
//     assert nftIds_ptrs[8] = Uint256(low=8, high=0);
//     assert nftIds_ptrs[9] = Uint256(low=9, high=0);
//     assert nftIds_ptrs[10] = Uint256(low=10, high=0);
//     assert nftIds_ptrs[11] = Uint256(low=11, high=0);
//     assert nftIds_ptrs[12] = Uint256(low=12, high=0);

//     //           ||
//     //           ||
//     //           ||
//     //           \/

//     // [
//     //     PairSwapSpecific(
//     //         pair=1,
//     //         nftIds_len=3,
//     //         nftIds=[ 0, 1, 2 ]
//     //     ),
//     //     PairSwapSpecific(
//     //         pair=2,
//     //         nftIds_len=2,
//     //         nftIds=[ 3, 4 ]
//     //     ),
//     //     PairSwapSpecific(
//     //         pair=3,
//     //         nftIds_len=3,
//     //         nftIds=[ 5, 6, 7 ]
//     //     ),
//     //     PairSwapSpecific(
//     //         pair=4,
//     //         nftIds_len=4,
//     //         nftIds=[ 8, 9, 10, 11 ]
//     //     ),
//     //     PairSwapSpecific(
//     //         pair=5,
//     //         nftIds_len=1,
//     //         nftIds=[ 12 ]
//     //     ),                
//     // ]

//     assert nftIds_len[0] + nftIds_len[1] + nftIds_len[2] + nftIds_len[3] + nftIds_len[4] = nftIds_ptrs_len;

//     toPairSwapSpecificArr(
//         swapList_len=swapList_len,
//         swapList=swapList,
//         index=0,
//         pairs_len=swapList_len,
//         pairs=pairs,
//         nftIds_len_len=swapList_len,
//         nftIds_len=nftIds_len,
//         nftIds_ptrs_len=nftIds_ptrs_len,
//         nftIds_ptrs=nftIds_ptrs
//     );

//     local _swapList: PairSwapSpecific* = swapList;
//     displaySwapListSpecific(0, swapList_len, _swapList);

//     return ();
// }

@external
func test_toRobustPairSwapSpecificArr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt} () {
    alloc_locals;

    let numItems = Uint256(low=2, high=0);
    let total_nft_ids = 6;
    let (nftIds: Uint256*) = alloc();
    // ids for pair1
    assert nftIds[0] = Uint256(low=0, high=0);
    assert nftIds[1] = Uint256(low=1, high=0);
    // ids for pair2
    assert nftIds[2] = Uint256(low=10, high=0);
    assert nftIds[3] = Uint256(low=11, high=0);
    // ids for pair3
    assert nftIds[4] = Uint256(low=20, high=0);
    assert nftIds[5] = Uint256(low=21, high=0);

    let pair2InputAmount = Uint256(low=2, high=0);

    let swapList_len = 3;
    let (swapList: RobustPairSwapSpecific*) = alloc();
    local pairs: felt* = cast(new (1, 2, 3), felt*);
    local nftIds_len: felt* = cast(new (2, 2, 2), felt*);
    let (maxCosts: Uint256*) = alloc();
    assert maxCosts[0] = pair2InputAmount;
    assert maxCosts[1] = pair2InputAmount;
    assert maxCosts[2] = pair2InputAmount;

    toRobustPairSwapSpecificArr(
        index=0,
        end=swapList_len,
        robustPairSwapArr=swapList,
        pairs_len=swapList_len,
        pairs=pairs,
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,
        nftIds_ptrs_len=total_nft_ids,
        nftIds_ptrs=nftIds,
        maxCosts=maxCosts   
    );
    %{print("Done casting to struct \n")%}

    displaySwapListRobustPairSwapSpecific(
        index=0,
        swapList_len=swapList_len,
        swapList=swapList
    );

    return ();
}

func displaySwapListRobustPairSwapSpecific{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    swapList_len: felt,
    swapList: RobustPairSwapSpecific*
) {
    alloc_locals;
    
    if(index == swapList_len) {
        return ();
    }
    let test = PairSwapSpecific(
        pair=swapList.swapInfo.pair,
        nftIds_len=swapList.swapInfo.nftIds_len,
        nftIds=swapList.swapInfo.nftIds
    );
    // Only 1 PairSwapSpecific per RobustPairSwapSpecific value
    displaySwapListSpecific(
        index=0,
        swapList_len=1,
        swapList=cast(new (test,), PairSwapSpecific*)
    );
    local maxCost: Uint256 = [swapList].maxCost;
    %{print(f"maxCost: {ids.maxCost.low + ids.maxCost.high}")%}

    let arrSize = [swapList].swapInfo.nftIds_len * Uint256.SIZE;
    return displaySwapListRobustPairSwapSpecific(
        index=index + 1,
        swapList_len=swapList_len,
        swapList=swapList + (1 + 1 + arrSize + Uint256.SIZE)
    );
}

func displaySwapListSpecific{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    swapList_len: felt,
    swapList: PairSwapSpecific*
) {
    if(index == swapList_len) {
        return ();
    }
    %{print(f"\n --- swapListSpecific[{ids.index}] --- ")%}

    let pair = [swapList].pair;
    let nftIds_len = [swapList].nftIds_len;
    %{
        print(f"pair = {ids.pair}")
        print(f"nftIds_len = {ids.nftIds_len}")
    %}
    displayIds(
        nftIds=[swapList].nftIds, 
        start=0, 
        end=nftIds_len
    );
    
    let arrSize = nftIds_len * Uint256.SIZE;

    return displaySwapListSpecific(
        index=index + 1,
        swapList_len=swapList_len,
        swapList=swapList + (1 + 1 + arrSize)
    );
}