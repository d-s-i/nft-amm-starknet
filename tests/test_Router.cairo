%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.Router import (
    PairSwapSpecific
)

from tests.utils.library import (displayIds)


// struct PairSwapSpecific {
//     pair: felt,
//     nftIds_len: felt,
//     nftIds: Uint256*,
// }


@external
func test_toStruct{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    let swapList_len = 5;
    let (swapList: PairSwapSpecific*) = alloc();

    let (pairs: felt*) = alloc();
    // pair addresses:
    // [ 1, 2, 3, 4, 5 ]
    assert pairs[0] = 1;
    assert pairs[1] = 2;
    assert pairs[2] = 3;
    assert pairs[3] = 4;
    assert pairs[4] = 5;

    let (nftIds_len: felt*) = alloc();
    // amount of ids to trade for each pair
    assert nftIds_len[0] = 3;
    assert nftIds_len[1] = 2;
    assert nftIds_len[2] = 3;
    assert nftIds_len[3] = 4;
    assert nftIds_len[4] = 1;

    let nftIds_ptrs_len = 13;
    let (nftIds_ptrs: Uint256*) = alloc();
    // all ids for all pairs together
    // [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12]
    assert nftIds_ptrs[0] = Uint256(low=0, high=0);
    assert nftIds_ptrs[1] = Uint256(low=1, high=0);
    assert nftIds_ptrs[2] = Uint256(low=2, high=0);
    assert nftIds_ptrs[3] = Uint256(low=3, high=0);
    assert nftIds_ptrs[4] = Uint256(low=4, high=0);
    assert nftIds_ptrs[5] = Uint256(low=5, high=0);
    assert nftIds_ptrs[6] = Uint256(low=6, high=0);
    assert nftIds_ptrs[7] = Uint256(low=7, high=0);
    assert nftIds_ptrs[8] = Uint256(low=8, high=0);
    assert nftIds_ptrs[9] = Uint256(low=9, high=0);
    assert nftIds_ptrs[10] = Uint256(low=10, high=0);
    assert nftIds_ptrs[11] = Uint256(low=11, high=0);
    assert nftIds_ptrs[12] = Uint256(low=12, high=0);

    //           ||
    //           ||
    //           ||
    //           \/

    // [
    //     PairSwapSpecific(
    //         pair=1,
    //         nftIds_len=3,
    //         nftIds=[ 0, 1, 2 ]
    //     ),
    //     PairSwapSpecific(
    //         pair=2,
    //         nftIds_len=2,
    //         nftIds=[ 3, 4 ]
    //     ),
    //     PairSwapSpecific(
    //         pair=3,
    //         nftIds_len=3,
    //         nftIds=[ 5, 6, 7 ]
    //     ),
    //     PairSwapSpecific(
    //         pair=4,
    //         nftIds_len=4,
    //         nftIds=[ 8, 9, 10, 11 ]
    //     ),
    //     PairSwapSpecific(
    //         pair=5,
    //         nftIds_len=1,
    //         nftIds=[ 12 ]
    //     ),                
    // ]

    assert nftIds_len[0] + nftIds_len[1] + nftIds_len[2] + nftIds_len[3] + nftIds_len[4] = nftIds_ptrs_len;

    toPairSwapSpecificArr(
        swapList_len=swapList_len,
        swapList=swapList,
        index=0,
        pairs_len=swapList_len,
        pairs=pairs,
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );

    local _swapList: PairSwapSpecific* = swapList;
    displaySwapList(0, swapList_len, _swapList);

    return ();
}

func displaySwapList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    swapList_len: felt,
    swapList: PairSwapSpecific*
) {
    if(index == swapList_len) {
        return ();
    }
    %{print(f"\n --- swapList[{ids.index}] --- ")%}

    let pair = swapList.pair;
    let nftIds_len = swapList.nftIds_len;
    %{
        print(f"pair = {ids.pair}")
        print(f"nftIds_len = {ids.nftIds_len}")
    %}
    displayIds(swapList.nftIds, 0, nftIds_len);
    
    let arrSize = nftIds_len * Uint256.SIZE;

    return displaySwapList(
        index=index + 1,
        swapList_len=swapList_len,
        swapList=swapList + (1 + 1 + arrSize)
    );
}

func toPairSwapSpecificArr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: PairSwapSpecific*,
    index: felt,
    pairs_len: felt,
    pairs: felt*,
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*
) {
    alloc_locals;

    if(index == swapList_len) {
        return ();
    }

    let (nftIds: Uint256*) = alloc();
    // have to remove index to nftIds_len because I increase nftIds_len after each call
    let (start) = getStartIndex(
        start=0,
        end=index,
        allLength=nftIds_len - index,
        count=0
    );
    let amountsOfNFTIdsForThisSwap = [nftIds_len];
    
    packNFTIds(
        nftIdsForPair_len=start + amountsOfNFTIdsForThisSwap,
        nftIdsForPair=nftIds,
        allNFTIds=nftIds_ptrs,
        start=start
    );

    assert [swapList] = PairSwapSpecific(
        pair=[pairs],
        nftIds_len=amountsOfNFTIdsForThisSwap,
        nftIds=nftIds
    );

    let arrSize = amountsOfNFTIdsForThisSwap * Uint256.SIZE;
    return toPairSwapSpecificArr(
        swapList_len=swapList_len,
        // pair.SIZE + nftIds_len.SIZE + nftIds.SIZE
        swapList=swapList + (1 + 1 + arrSize),
        index=index + 1,
        pairs_len=pairs_len,
        pairs=pairs + 1,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len + 1,
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs + arrSize
    );
}

func getStartIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt,
    allLength: felt*,
    count: felt
) -> (startIndex: felt) {
    if(start == end) {
        if(end == 0) {
            return (startIndex=0);
        }
        return (startIndex=count);
    }

    let currLen = [allLength];
    let currCount = count + currLen;

    return getStartIndex(
        start=start + 1,
        end=end,
        allLength=allLength + 1,
        count=currCount
    );
    
}
func packNFTIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIdsForPair_len: felt,
    nftIdsForPair: Uint256*,
    allNFTIds: Uint256*,
    start: felt
) {
    if(start == nftIdsForPair_len) {
        return ();
    }

    return packNFTIds_loop(
        start=start,
        max=nftIdsForPair_len,
        nftIdsArr=nftIdsForPair,
        allNFTIds=allNFTIds
    );

}

func packNFTIds_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    max: felt,
    nftIdsArr: Uint256*,
    allNFTIds: Uint256*
) {
    if(start == max) {
        return ();
    }

    assert [nftIdsArr] = [allNFTIds];

    return packNFTIds_loop(
        start=start + 1,
        max=max,
        nftIdsArr=nftIdsArr + Uint256.SIZE,
        allNFTIds=allNFTIds + Uint256.SIZE
    );
}