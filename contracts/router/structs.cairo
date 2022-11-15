%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.uint256 import (Uint256)

struct PairSwapAny {
    pair: felt,
    numItems: Uint256,
}

struct PairSwapSpecific {
    pair: felt,
    nftIds_len: felt,
    nftIds: Uint256*,
}

struct NFTsForAnyNFTsTrade {
    nftToTokenTrades_len: felt,
    nftToTokenTrades: PairSwapSpecific*,

    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: PairSwapAny*,
}

struct NFTsForSpecificNFTsTrade {
    nftToTokenTrades_len: felt,
    nftToTokenTrades: PairSwapSpecific*,

    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: PairSwapSpecific*,
}

struct RobustPairSwapAny {
    swapInfo: PairSwapAny,
    maxCost: Uint256,
}

struct RobustPairSwapSpecific {
    swapInfo: PairSwapSpecific,
    maxCost: Uint256,
}

struct RobustPairSwapSpecificForToken {
    swapInfo: PairSwapSpecific,
    minOutput: Uint256,
}

struct RobustPairNFTsForTokenAndTokenForNFTsTrade {
    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: RobustPairSwapSpecific*,

    nftToTokenTrades_len: felt,
    nftToTokenTrades: RobustPairSwapSpecificForToken*,

    inputAmount: Uint256,
    tokenRecipient: felt,
    nftRecipient: felt,
    deadline: felt,
}

// Struct manipulation

// pair addresses:
// [ 1, 2, 3, 4, 5 ]
// each array length
// [3, 2, 3, 4, 1]
// all ids for all pairs together
// [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ,11, 12]

//            |
//            v

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
    let (swapListSize) = getPairSwapSpecificStructSize(amountsOfNFTIdsForThisSwap);
    return toPairSwapSpecificArr(
        swapList_len=swapList_len,
        swapList=swapList + swapListSize,
        index=index + 1,
        pairs_len=pairs_len,
        pairs=pairs + 1,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len + 1,
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs + arrSize
    );
}

func toRobustPairSwapSpecificArr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    end: felt,
    robustPairSwapArr: RobustPairSwapSpecific*,
    pairs_len: felt,
    pairs: felt*,
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,
    maxCosts: Uint256*
) {
    alloc_locals;

    if(index == end) {
        return ();
    }

    let (swapInfo: PairSwapSpecific*) = alloc();
    // There is only 1 swapList.PairSwapSpecific per RobustPairSwapSpecific struct
    toPairSwapSpecificArr(
        swapList_len=1,
        swapList=swapInfo,
        index=0,
        pairs_len=1,
        pairs=pairs,
        nftIds_len_len=1,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );
    // creating a PairSwapSpecific* pointer but RobustPairSwapSpecific asks a simpler pointer
    // so asserting it to only the first pointer value 
    assert [robustPairSwapArr] = RobustPairSwapSpecific(
        swapInfo=[swapInfo],
        maxCost=[maxCosts]
    );

    let (swapListSize) = getPairSwapSpecificStructSize([nftIds_len]);
    return toRobustPairSwapSpecificArr(
        index=index + 1,
        end=end,
        robustPairSwapArr=robustPairSwapArr + swapListSize + Uint256.SIZE,
        pairs_len=pairs_len,
        pairs=pairs + 1,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len + 1,
        nftIds_ptrs_len=nftIds_ptrs_len,
        // increment ptr to the next array of nftIds
        nftIds_ptrs=nftIds_ptrs + [nftIds_len] * Uint256.SIZE,
        maxCosts=maxCosts + Uint256.SIZE
    );
}

func toRobustPairSwapSpecificForTokenArr{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    end: felt,
    robustPairSwapArr: RobustPairSwapSpecificForToken*,
    pairs_len: felt,
    pairs: felt*,
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,
    minOutputs: Uint256*
) {
    alloc_locals;

    if(index == end) {
        return ();
    }

    let (swapInfo: PairSwapSpecific*) = alloc();
    // There is only 1 swapList.PairSwapSpecific per RobustPairSwapSpecific struct
    toPairSwapSpecificArr(
        swapList_len=1,
        swapList=swapInfo,
        index=0,
        pairs_len=1,
        pairs=pairs,
        nftIds_len_len=1,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );
    // creating a PairSwapSpecific* pointer but RobustPairSwapSpecific asks a simpler pointer
    // so asserting it to only the first pointer value 
    assert [robustPairSwapArr] = RobustPairSwapSpecificForToken(
        swapInfo=[swapInfo],
        minOutput=[minOutputs]
    );

    let (swapListSize) = getPairSwapSpecificStructSize([nftIds_len]);
    return toRobustPairSwapSpecificForTokenArr(
        index=index + 1,
        end=end,
        robustPairSwapArr=robustPairSwapArr + swapListSize + Uint256.SIZE,
        pairs_len=pairs_len,
        pairs=pairs + 1,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len + 1,
        nftIds_ptrs_len=nftIds_ptrs_len,
        // increment ptr to the next array of nftIds
        nftIds_ptrs=nftIds_ptrs + [nftIds_len] * Uint256.SIZE,
        minOutputs=minOutputs + Uint256.SIZE
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

// @notice - Goal basically is to slice a sub array from the NFTIds.
// Start at a given index and stop at the length of the array and fill it with all the ids in between
func packNFTIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIdsForPair_len: felt,
    nftIdsForPair: Uint256*,
    allNFTIds: Uint256*,
    start: felt
) {
    if(start == nftIdsForPair_len) {
        return ();
    }

    assert [nftIdsForPair] = [allNFTIds];

    return packNFTIds(
        nftIdsForPair_len=nftIdsForPair_len,
        nftIdsForPair=nftIdsForPair + Uint256.SIZE,
        allNFTIds=allNFTIds + Uint256.SIZE,
        start=start + 1
    );

}

func getPairSwapSpecificStructSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    amountsOfNFTIdsInStruct: felt
) -> (size: felt) {
    let arrSize = amountsOfNFTIdsInStruct * Uint256.SIZE;
    // pair.SIZE + nftIds_len.SIZE + nftIdsArr.SIZE
    return (size=1 + 1 + arrSize);
}

func getRobustPairNFTsForTokenAndTokenForNFTsTradeSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairNFTsForTokenAndTokenForNFTsTrade
) -> (size: felt){
    alloc_locals;

    let (tokenToNFTTRadesSize) = getRobustPairSwapSpecificSize_loop(
        swapList=swapList.tokenToNFTTrades,
        start=0,
        end=swapList.tokenToNFTTrades_len,
        sizeCount=0
    );

    let (nftToTokenTradesSize) = getRobustPairSwapSpecificSizeForToken_loop(
        swapList=swapList.nftToTokenTrades,
        start=0,
        end=swapList.nftToTokenTrades_len,
        sizeCount=0
    );    

// tokenToNFTTrades_len + tokenToNFTTrades + nftToTokenTrades_len + nftToTokenTrades
// inputAmount + tokenRecipient + nftRecipient + deadline
   return (size=1 + tokenToNFTTRadesSize + 1 + nftToTokenTradesSize + Uint256.SIZE + 1 + 1 + 1);
}

func getRobustPairSwapSpecificSizeForToken_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairSwapSpecificForToken*,
    start: felt,
    end: felt,
    sizeCount: felt
) -> (size: felt) {
    if(start == end) {
        return (size=sizeCount);
    }

    let (arrSize) = getRobustpairSwapSpecificForTokenSize([swapList]);
    let newSizeCount = sizeCount + arrSize;

    return getRobustPairSwapSpecificSizeForToken_loop(
        swapList=swapList + arrSize,
        start=start + 1,
        end=end,
        sizeCount=newSizeCount
    );
}

func getRobustPairSwapSpecificSize_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairSwapSpecific*,
    start: felt,
    end: felt,
    sizeCount: felt
) -> (size: felt) {
    if(start == end) {
        return (size=sizeCount);
    }

    let (arrSize) = getRobustpairSwapSpecificSize([swapList]);
    let newSizeCount = sizeCount + arrSize;

    return getRobustPairSwapSpecificSize_loop(
        swapList=swapList + arrSize,
        start=start + 1,
        end=end,
        sizeCount=newSizeCount
    );
}

func getRobustpairSwapSpecificForTokenSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairSwapSpecificForToken
) -> (size: felt) {
    let (swapInfoSize) = getPairSwapSpecificStructSize(swapList.swapInfo.nftIds_len);
    return (size=swapInfoSize + Uint256.SIZE);
}

func getRobustpairSwapSpecificSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairSwapSpecific
) -> (size: felt) {
    let (swapInfoSize) = getPairSwapSpecificStructSize(swapList.swapInfo.nftIds_len);
    return (size=swapInfoSize + Uint256.SIZE);
}