%lang starknet

// Changed deadline from uint256 to felt
// Can't pass arrays of struct so have to pass all members separately and merge them into the array of struct

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (
    get_block_timestamp,
    get_caller_address,
    get_contract_address
)
from starkware.cairo.common.bool import (TRUE)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_sub,
    uint256_add,
    uint256_le,
    uint256_lt,
    assert_uint256_le
)
from starkware.cairo.common.math import (assert_le)

from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

from contracts.bonding_curves.CurveErrorCodes import (Error)
from contracts.libraries.felt_uint import (FeltUint)

struct PairSwapAny {
    pair: felt,
    numItems_len: felt,
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

@storage_var
func factory() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(_factory: felt) {
    factory.write(_factory);
    return ();
}

@external
func swapERC20ForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: PairSwapAny*,
    inputAmount: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (remainingValue: Uint256) {

    _checkDeadline(deadline);
    
    let (caller) = get_caller_address();
    let (remainingValue) = _swapERC20ForAnyNFTs(
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );
    return (remainingValue=remainingValue);
}

@external
func swapERC20ForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    // swapList: PairSwapSpecific*,
    // PairSwapSpecific.pairs*
    pairs_len: felt,
    pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,

    inputAmount: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();

    let (swapList: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=swapList_len,
        swapList=swapList,
        index=0,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );

    let (remainingValue) = _swapERC20ForSpecificNFTs(
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );
    
    return (remainingValue=remainingValue);
}

@external
func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    // PairSwapSpecific.pairs*
    pairs_len: felt,
    pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,

    minOutput: Uint256,
    tokenRecipient: felt,
    deadline: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();

    let (swapList: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=swapList_len,
        swapList=swapList,
        index=0,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );

    let (outputAmount) = _swapNFTsForToken(
        swapList_len=swapList_len,
        swapList=swapList,
        outputAmount=Uint256(low=0, high=0),
        minOutput=minOutput,
        tokenRecipient=tokenRecipient,
        index=0,
        caller=caller
    );

    return (outputAmount=outputAmount);
}

@external
func swapNFTsForAnyNFTsThroughERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftToTokenTrades_len: felt,
    // PairSwapSpecific.pairs*
    pairs_len: felt,
    pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,

    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: PairSwapAny*,

    inputAmount: Uint256,
    minOutput: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (swapListSpecific: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=nftToTokenTrades_len,
        swapList=swapListSpecific,
        index=0,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs
    );

    // let trade = NFTsForAnyNFTsTrade(
    //     nftToTokenTrades_len=nftToTokenTrades_len,
    //     nftToTokenTrades=swapListSpecific,
    //     tokenToNFTTrades_len=tokenToNFTTrades_len,
    //     tokenToNFTTrades=tokenToNFTTrades
    // );
    let (thisAddress) = get_contract_address();

    // Swap NFTs for ERC20
    // minOutput of swap set to 0 since we're doing an aggregate slippage check
    // output tokens are sent to caller (msg.sender)
    let (outputAmount_1) = _swapNFTsForToken(
        swapList_len=nftToTokenTrades_len,
        swapList=swapListSpecific,
        outputAmount=Uint256(low=0, high=0),
        minOutput=Uint256(low=0, high=0),
        tokenRecipient=thisAddress,
        index=0,
        caller=caller
    );

    // Add extra value to buy NFTs
    let (outputAmount_2, outputAmount_2Carry) = uint256_add(outputAmount_1, inputAmount);

    let (inputAmountSwapAnyNFTs) = uint256_sub(outputAmount_2, minOutput);
    let (outputAmount_3) = _swapERC20ForAnyNFTs(
        swapList_len=tokenToNFTTrades_len,
        swapList=tokenToNFTTrades,
        inputAmount=inputAmountSwapAnyNFTs,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );

    let (outputAmount, outputAmountCarry) = uint256_add(outputAmount_3, minOutput);

    return (outputAmount=outputAmount);
}

@external
func swapNFTsForSpecificNFTsThroughERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    // trade: NFTsForSpecificNFTsTrade,
    nftToTokenTrades_len: felt,
    // nftToTokenTrades: PairSwapSpecific*,
    // PairSwapSpecific.pairs*
    nftToTokenTrades_pairs_len: felt,
    nftToTokenTrades_pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftToTokenTrades_nftIds_len_len: felt,
    nftToTokenTrades_nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftToTokenTrades_nftIds_ptrs_len: felt,
    nftToTokenTrades_nftIds_ptrs: Uint256*,

    tokenToNFTTrades_len: felt,
    // tokenToNFTTrades: PairSwapSpecific*,
    // PairSwapSpecific.pairs*
    tokenToNFTTrades_pairs_len: felt,
    tokenToNFTTrades_pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    tokenToNFTTrades_nftIds_len_len: felt,
    tokenToNFTTrades_nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    tokenToNFTTrades_nftIds_ptrs_len: felt,
    tokenToNFTTrades_nftIds_ptrs: Uint256*,

    inputAmount: Uint256,
    minOutput: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (nftToTokenTrades_swapList: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=nftToTokenTrades_len,
        swapList=nftToTokenTrades_swapList,
        index=0,
        pairs_len=nftToTokenTrades_pairs_len,
        pairs=nftToTokenTrades_pairs,
        nftIds_len_len=nftToTokenTrades_nftIds_len_len,
        nftIds_len=nftToTokenTrades_nftIds_len,    
        nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
        nftIds_ptrs=nftToTokenTrades_nftIds_ptrs
    );

    let (tokenToNFTTrades_swapList: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=tokenToNFTTrades_len,
        swapList=tokenToNFTTrades_swapList,
        index=0,
        pairs_len=tokenToNFTTrades_pairs_len,
        pairs=tokenToNFTTrades_pairs,
        nftIds_len_len=tokenToNFTTrades_nftIds_len_len,
        nftIds_len=tokenToNFTTrades_nftIds_len,
        nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
        nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs
    );

    // let trade = NFTsForSpecificNFTsTrade(
    //     nftToTokenTrades_len=nftToTokenTrades_len,
    //     nftToTokenTrades=nftToTokenTrades_swapList,

    //     tokenToNFTTrades_len=tokenToNFTTrades_len,
    //     tokenToNFTTrades=tokenToNFTTrades_swapList,
    // );
    
    // Swap NFTs for ERC20
    // minOutput of swap set to 0 since we're doing an aggregate slippage check
    // output tokens are sent to caller (msg.sender)
    let (outputAmount_1) = _swapNFTsForToken(
        swapList_len=nftToTokenTrades_len,
        swapList=nftToTokenTrades_swapList,
        outputAmount=Uint256(low=0, high=0),
        minOutput=minOutput,
        tokenRecipient=caller,
        index=0,
        caller=caller
    );

    // Add extra value to buy NFTs
    let (outputAmount_2, outputAmount_2Carry) = uint256_add(outputAmount_1, inputAmount);

    let (inputAmountSwapSpecificNFTs) = uint256_sub(outputAmount_2, minOutput);
    let (outputAmount_3) = _swapERC20ForSpecificNFTs(
        swapList_len=tokenToNFTTrades_len,
        swapList=tokenToNFTTrades_swapList,
        inputAmount=inputAmountSwapSpecificNFTs,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );

    let (outputAmount, outputAmountCarry) = uint256_add(outputAmount_3, minOutput);

    return (outputAmount=outputAmount);
}

@external
func robustSwapERC20ForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: RobustPairSwapAny*,
    inputAmount: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (remainingValue: Uint256) {

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (remainingValue) = robustSwapERC20ForAnyNFTs_loop(
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );

    return (remainingValue=remainingValue);
}

@external
func robustSwapERC20ForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    // swapList: RobustPairSwapSpecific*,
    // swapInfos: PairSwapSpecific*,
    // PairSwapSpecific.pairs*
    pairs_len: felt,
    pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,
    maxCosts_len: felt,
    maxCosts: Uint256*,

    inputAmount: Uint256,
    nftRecipient: felt,
    deadline: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (swapList: RobustPairSwapSpecific*) = alloc();
    toRobustPairSwapSpecificArr(
        index=0,
        end=swapList_len,
        robustPairSwapArr=swapList,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,
        maxCosts=maxCosts   
    );

    let (remainingValue) = robustSwapERC20ForSpecificNFTs_loop(
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=0,
        caller=caller
    );

    return (remainingValue=remainingValue);
}

@external
func robustSwapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    // swapList: RobustPairSwapSpecificForToken*,
    // swapInfo: PairSwapSpecific,
    // PairSwapSpecific.pairs*
    pairs_len: felt,
    pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftIds_len_len: felt,
    nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftIds_ptrs_len: felt,
    nftIds_ptrs: Uint256*,    
    minOutputs_len: felt,
    minOutputs: Uint256*,

    tokenRecipient: felt,
    deadline: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (swapList: RobustPairSwapSpecificForToken*) = alloc();
    toRobustPairSwapSpecificForTokenArr(
        index=0,
        end=swapList_len,
        robustPairSwapArr=swapList,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,
        minOutputs=minOutputs
    );

    let (outputAmount) = robustSwapNFTsForToken_loop(
        swapList_len=swapList_len,
        swapList=swapList,
        outputAmount=Uint256(low=0, high=0),
        tokenRecipient=tokenRecipient,
        index=0,
        caller=caller
    );

    return (outputAmount=outputAmount);
}

@external
func robustSwapERC20ForSpecificNFTsAndNFTsToToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    // params: RobustPairNFTsForTokenAndTokenForNFTsTrade
    tokenToNFTTrades_len: felt,
    // tokenToNFTTrades: RobustPairSwapSpecific*,
    // PairSwapSpecific.pairs*
    tokenToNFTTrades_pairs_len: felt,
    tokenToNFTTrades_pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    tokenToNFTTrades_nftIds_len_len: felt,
    tokenToNFTTrades_nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    tokenToNFTTrades_nftIds_ptrs_len: felt,
    tokenToNFTTrades_nftIds_ptrs: Uint256*,
    maxCosts_len: felt,
    maxCosts: Uint256*,    

    nftToTokenTrades_len: felt,
    // nftToTokenTrades: RobustPairSwapSpecificForToken*,
    // PairSwapSpecific.pairs*
    nftToTokenTrades_pairs_len: felt,
    nftToTokenTrades_pairs: felt*,
    // PairSwapSpecific.nftIds_len*
    nftToTokenTrades_nftIds_len_len: felt,
    nftToTokenTrades_nftIds_len: felt*,    
    // PairSwapSpecific.nftIds
    nftToTokenTrades_nftIds_ptrs_len: felt,
    nftToTokenTrades_nftIds_ptrs: Uint256*,    
    minOutputs_len: felt,
    minOutputs: Uint256*,    

    inputAmount: Uint256,
    tokenRecipient: felt,
    nftRecipient: felt,
    deadline: felt  
) -> (remainingValue: Uint256, outputAmount: Uint256) {
    alloc_locals;

    _checkDeadline(deadline);

    let (caller) = get_caller_address();
    let (swapListSpecific: RobustPairSwapSpecific*) = alloc();
    toRobustPairSwapSpecificArr(
        index=0,
        end=tokenToNFTTrades_len,
        robustPairSwapArr=swapListSpecific,
        pairs_len=tokenToNFTTrades_pairs_len,
        pairs=tokenToNFTTrades_pairs,
        nftIds_len_len=tokenToNFTTrades_nftIds_len_len,
        nftIds_len=tokenToNFTTrades_nftIds_len,
        nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
        nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs,
        maxCosts=maxCosts   
    );

    let (swapListSpecificForToken: RobustPairSwapSpecificForToken*) = alloc();
    toRobustPairSwapSpecificForTokenArr(
        index=0,
        end=nftToTokenTrades_len,
        robustPairSwapArr=swapListSpecificForToken,
        pairs_len=nftToTokenTrades_pairs_len,
        pairs=nftToTokenTrades_pairs,
        nftIds_len_len=nftToTokenTrades_nftIds_len_len,
        nftIds_len=nftToTokenTrades_nftIds_len,
        nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
        nftIds_ptrs=nftToTokenTrades_nftIds_ptrs,
        minOutputs=minOutputs   
    );
    let params = RobustPairNFTsForTokenAndTokenForNFTsTrade(
        tokenToNFTTrades_len=tokenToNFTTrades_len,
        tokenToNFTTrades=swapListSpecific,

        nftToTokenTrades_len=nftToTokenTrades_len,
        nftToTokenTrades=swapListSpecificForToken,

        inputAmount=inputAmount,
        tokenRecipient=tokenRecipient,
        nftRecipient=nftRecipient,
        deadline=deadline,
    );

    let (remainingValue) = tokenToNFTTrades_loop(
        params=params,
        index=0,
        caller=caller
    );

    let (outputAmount) = nftToTokenTrades_loop(
        params=params,
        outputAmount=Uint256(low=0, high=0),
        index=0,
        caller=caller
    ); 

    return (remainingValue=remainingValue, outputAmount=outputAmount);
}

@external
func pairTransferERC20From{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    tokenAddress: felt,
    from_: felt,
    to: felt,
    amount: Uint256
) {
    let (_factory) = factory.read();
    let (caller) = get_caller_address();
    let (isPair) = INFTPairFactory.isPair(
        contract_address=_factory,
        potentialPair=caller
    );
    with_attr error_mesage("Router::pairTransferERC20From - Not pair") {
        assert isPair = TRUE;
    }

    // No need to check if ERC20 as ONLY ERC20 pair can be deployed from factory

    IERC20.transferFrom(
        contract_address=tokenAddress,
        sender=from_, 
        recipient=to, 
        amount=amount
    );
    
    return ();
}

@external
func pairTransferNFTFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftAddress: felt,
    from_: felt,
    to: felt,
    id: Uint256
) {
    alloc_locals;

    let (_factory) = factory.read();
    let (caller) = get_caller_address();
    let (isPair) = INFTPairFactory.isPair(
        contract_address=_factory,
        potentialPair=caller
    );
    with_attr error_mesage("Router::pairTransferERC20From - Not pair") {
        assert isPair = TRUE;
    }

    IERC721.safeTransferFrom(
        contract_address=nftAddress,
        from_=from_, 
        to=to, 
        tokenId=id, 
        data_len=0, 
        data=cast(new (0,), felt*)
    );
    
    return ();
}

@external
func _checkDeadline{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(deadline: felt) {
    let (timestamp) = get_block_timestamp();
    with_attr error_message("Router::_checkDeadline - Deadline passed") {
        assert_le(timestamp, deadline);
    }
    return ();
}

@external
func _swapERC20ForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: PairSwapAny*,
    inputAmount: Uint256,
    nftRecipient: felt,
    index: felt,
    caller: felt
) -> (remainingValue: Uint256) {
    if(index == swapList_len) {
        return (remainingValue=inputAmount);
    }

    let (inputAmountRequired) = INFTPair.swapTokenForAnyNFTs(
        contract_address=[swapList].pair,
        numNFTs=[swapList].numItems,
        maxExpectedTokenInput=inputAmount,
        nftRecipient=nftRecipient,
        isRouter=TRUE,
        routerCaller=caller
    );
    let (remainingValue) = uint256_sub(inputAmount, inputAmountRequired);

    return _swapERC20ForAnyNFTs(
        swapList_len=swapList_len,
        swapList=swapList + PairSwapAny.SIZE,
        inputAmount=remainingValue,
        nftRecipient=nftRecipient,
        index=index + 1,
        caller=caller
    );
}

func _swapERC20ForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: PairSwapSpecific*,
    inputAmount: Uint256,
    nftRecipient: felt,
    index: felt,
    caller: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    if(index == swapList_len) {
        return (remainingValue=inputAmount);
    }

    let (inputAmountRequired) = INFTPair.swapTokenForSpecificNFTs(
        contract_address=[swapList].pair,
        nftIds_len=[swapList].nftIds_len,
        nftIds=[swapList].nftIds,
        maxExpectedTokenInput=inputAmount,
        nftRecipient=nftRecipient,
        isRouter=TRUE,
        routerCaller=caller
    );
    let (remainingValue) = uint256_sub(inputAmount, inputAmountRequired);
    
    let (swapListSize) = getPairSwapSpecificStructSize([swapList].nftIds_len);
    return _swapERC20ForSpecificNFTs(
        swapList_len=swapList_len,
        swapList=swapList + swapListSize,
        inputAmount=remainingValue,
        nftRecipient=nftRecipient,
        index=index + 1,
        caller=caller
    );
}

// @param outoutAmount - Keep track of outputAmount over swaps. Should be 0 at first call
func _swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: PairSwapSpecific*,
    outputAmount: Uint256,
    minOutput: Uint256,
    tokenRecipient: felt,
    index: felt,
    caller: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    if(index == swapList_len) {
        with_attr error_mesage("Router::_swapNFTsForToken - outputAmount too low") {
            assert_uint256_le(minOutput, outputAmount);
        }
        return (outputAmount=outputAmount);
    }

    // Do the swap for token and then update outputAmount
    // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
    let (outputAmountSwap) = INFTPair.swapNFTsForToken(
        contract_address=[swapList].pair,
        nftIds_len=[swapList].nftIds_len,
        nftIds=[swapList].nftIds,
        minExpectedTokenOutput=Uint256(low=0, high=0),
        tokenRecipient=tokenRecipient,
        isRouter=TRUE,
        routerCaller=caller
    );
    let (newOutputAmount, newOutputAmountCarry) = uint256_add(outputAmount, outputAmountSwap);
    
    let (swapListSize) = getPairSwapSpecificStructSize([swapList].nftIds_len);
    return _swapNFTsForToken(
        swapList_len=swapList_len,
        swapList=swapList + swapListSize,
        outputAmount=newOutputAmount,
        minOutput=minOutput,
        tokenRecipient=tokenRecipient,
        index=index + 1,
        caller=caller
    );
}

func robustSwapERC20ForAnyNFTs_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: RobustPairSwapAny*,
    inputAmount: Uint256,
    nftRecipient: felt,
    index: felt,
    caller: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    if(index == swapList_len) {
        return (remainingValue=inputAmount);
    }

    let (
        error,
        newSpotPrice,
        newDelta,
        pairCost,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=[swapList].swapInfo.pair,
        numNFTs=[swapList].swapInfo.numItems
    );

    let (pairCostOk) = uint256_le(pairCost, [swapList].maxCost);
    if(pairCostOk == TRUE) {
        if(error == Error.OK) {
            let (inputAmountForSwap) = INFTPair.swapTokenForAnyNFTs(
                contract_address=[swapList].swapInfo.pair,
                numNFTs=[swapList].swapInfo.numItems,
                maxExpectedTokenInput=pairCost,
                nftRecipient=nftRecipient,
                isRouter=TRUE,
                routerCaller=caller
            );
            let (remainingValue) = uint256_sub(inputAmount, inputAmountForSwap);

            return robustSwapERC20ForAnyNFTs_loop(
                swapList_len=swapList_len,
                swapList=swapList + RobustPairSwapAny.SIZE,
                inputAmount=remainingValue,
                nftRecipient=nftRecipient,
                index=index + 1,
                caller=caller
            );
        }
    }

    return robustSwapERC20ForAnyNFTs_loop(
        swapList_len=swapList_len,
        swapList=swapList + RobustPairSwapAny.SIZE,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=index + 1,
        caller=caller
    );    
}

func robustSwapERC20ForSpecificNFTs_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: RobustPairSwapSpecific*,
    inputAmount: Uint256,
    nftRecipient: felt,
    index: felt,
    caller: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    if(index == swapList_len ) {
        return (remainingValue=inputAmount);
    }

    let (numNFTs) = FeltUint.feltToUint256([swapList].swapInfo.nftIds_len);
    let (
        error,
        newSpotPrice,
        newDelta,
        pairCost,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=[swapList].swapInfo.pair,
        numNFTs=numNFTs
    );

    let (pairCostOk) = uint256_le(pairCost, [swapList].maxCost);
    if(pairCostOk == TRUE) {
        if(error == Error.OK) {
            let (inputAmountForSwap) = INFTPair.swapTokenForSpecificNFTs(
                contract_address=[swapList].swapInfo.pair,
                nftIds_len=[swapList].swapInfo.nftIds_len,
                nftIds=[swapList].swapInfo.nftIds,
                maxExpectedTokenInput=pairCost,
                nftRecipient=nftRecipient,
                isRouter=TRUE,
                routerCaller=caller
            );
            let (remainingValue) = uint256_sub(inputAmount, inputAmountForSwap);

            let (swapListSize) = getPairSwapSpecificStructSize([swapList].swapInfo.nftIds_len);
            return robustSwapERC20ForSpecificNFTs_loop(
                swapList_len=swapList_len,
                swapList=swapList + swapListSize,
                inputAmount=remainingValue,
                nftRecipient=nftRecipient,
                index=index + 1,
                caller=caller
            );
        }
    } 

    let (swapListSize) = getPairSwapSpecificStructSize([swapList].swapInfo.nftIds_len);
    return robustSwapERC20ForSpecificNFTs_loop(
        swapList_len=swapList_len,
        swapList=swapList + swapListSize,
        inputAmount=inputAmount,
        nftRecipient=nftRecipient,
        index=index + 1,
        caller=caller
    );
}

// @param outoutAmount - Keep track of outputAmount over swaps. Should be 0 at first call
func robustSwapNFTsForToken_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList_len: felt,
    swapList: RobustPairSwapSpecificForToken*,
    outputAmount: Uint256,
    tokenRecipient: felt,
    index: felt,
    caller: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    if(index == swapList_len) {
        return (outputAmount=outputAmount);
    }

    let (numNFTs) = FeltUint.feltToUint256([swapList].swapInfo.nftIds_len);
    let (
        error,
        newSpotPrice,
        newDelta,
        pairOutput,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=[swapList].swapInfo.pair,
        numNFTs=numNFTs
    );

    if(error != Error.OK) {
        let (swapListSize) = getPairSwapSpecificStructSize([swapList].swapInfo.nftIds_len);
        return robustSwapNFTsForToken_loop(
            swapList_len=swapList_len,
            swapList=swapList + swapListSize,
            outputAmount=outputAmount,
            tokenRecipient=tokenRecipient,
            index=index + 1,
            caller=caller
        );
    }

    let (pairOutputOk) = uint256_lt([swapList].minOutput, pairOutput);
    if(pairOutputOk == TRUE) {
        let (outputAmountSwap) = INFTPair.swapNFTsForToken(
            contract_address=[swapList].swapInfo.pair,
            nftIds_len=[swapList].swapInfo.nftIds_len,
            nftIds=[swapList].swapInfo.nftIds,
            minExpectedTokenOutput=Uint256(low=0, high=0),
            tokenRecipient=tokenRecipient,
            isRouter=TRUE,
            routerCaller=caller
        );
        let (newOutputAmount, newOutputAmountCarry) = uint256_add(outputAmountSwap, outputAmount);

        let (swapListSize) = getPairSwapSpecificStructSize([swapList].swapInfo.nftIds_len);
        return robustSwapNFTsForToken_loop(
            swapList_len=swapList_len,
            swapList=swapList + swapListSize,
            outputAmount=newOutputAmount,
            tokenRecipient=tokenRecipient,
            index=index + 1,
            caller=caller
        );
    }

    let (swapListSize) = getPairSwapSpecificStructSize([swapList].swapInfo.nftIds_len);
    return robustSwapNFTsForToken_loop(
        swapList_len=swapList_len,
        swapList=swapList + swapListSize,
        outputAmount=outputAmount,
        tokenRecipient=tokenRecipient,
        index=index + 1,
        caller=caller
    );    
}

func tokenToNFTTrades_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    params: RobustPairNFTsForTokenAndTokenForNFTsTrade,
    index: felt,
    caller: felt
) -> (remainingValue: Uint256) {
    alloc_locals;

    if(index == params.tokenToNFTTrades_len) {
        return (remainingValue=params.inputAmount);
    }
    
    let tokenToNFTTrades_ptr = params.tokenToNFTTrades;
    let (swapListTokenSize) = getRobustPairNFTsForTokenAndTokenForNFTsTradeSize(params);
    let arrIndex = index * swapListTokenSize;
    let currentTokenToNFTTrades = [tokenToNFTTrades_ptr + arrIndex];
    let (numNFTs) = FeltUint.feltToUint256(currentTokenToNFTTrades.swapInfo.nftIds_len);
    let (
        error,
        newSpotPrice,
        newDelta,
        pairCost,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=currentTokenToNFTTrades.swapInfo.pair,
        numNFTs=numNFTs
    );

    let (pairCostOk) = uint256_le(pairCost, currentTokenToNFTTrades.maxCost);
    if(pairCostOk == TRUE) {
        if(error == Error.OK) {
            let (inputAmountSwap) = INFTPair.swapTokenForSpecificNFTs(
                contract_address=currentTokenToNFTTrades.swapInfo.pair,
                nftIds_len=currentTokenToNFTTrades.swapInfo.nftIds_len,
                nftIds=currentTokenToNFTTrades.swapInfo.nftIds,
                maxExpectedTokenInput=pairCost,
                nftRecipient=params.nftRecipient,
                isRouter=TRUE,
                routerCaller=caller
            );
            let (remainingValue) = uint256_sub(params.inputAmount, inputAmountSwap);
            let newParams = RobustPairNFTsForTokenAndTokenForNFTsTrade(
                tokenToNFTTrades_len=params.tokenToNFTTrades_len,
                tokenToNFTTrades=params.tokenToNFTTrades,

                nftToTokenTrades_len=params.nftToTokenTrades_len,
                nftToTokenTrades=params.nftToTokenTrades,

                inputAmount=remainingValue,
                tokenRecipient=params.tokenRecipient,
                nftRecipient=params.nftRecipient,
                deadline=params.deadline
            );
            return tokenToNFTTrades_loop(
                params=newParams,
                index=index + 1,
                caller=caller
            );
        }
    }

    return tokenToNFTTrades_loop(
        params=params,
        index=index + 1,
        caller=caller
    );
}

func nftToTokenTrades_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    params: RobustPairNFTsForTokenAndTokenForNFTsTrade,
    outputAmount: Uint256,
    index: felt,
    caller: felt
) -> (outputAmount: Uint256) {
    alloc_locals;

    if(index == params.nftToTokenTrades_len) {
        return (outputAmount=outputAmount);
    }

    let nftToTokenTrades_ptr = params.nftToTokenTrades;
    // let arrIndex = index * nftToTokenTrades_ptr.SIZE;
    let (swapListSize) = getRobustPairNFTsForTokenAndTokenForNFTsTradeSize(params);
    let currentNftToTokenTrades = [nftToTokenTrades_ptr + swapListSize];
    let (numNFTs) = FeltUint.feltToUint256(currentNftToTokenTrades.swapInfo.nftIds_len);
    let (
        error,
        newSpotPrice,
        newDelta,
        pairOutput,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=currentNftToTokenTrades.swapInfo.pair,
        numNFTs=numNFTs
    );

    if(error != Error.OK) {
        return nftToTokenTrades_loop(
            params=params,
            outputAmount=outputAmount,
            index=index + 1,
            caller=caller
        );
    }

    let (pairOutputOk) = uint256_lt(currentNftToTokenTrades.minOutput, pairOutput);
    if(pairOutputOk == TRUE) {
        let (outputAmountSwap) = INFTPair.swapNFTsForToken(
            contract_address=currentNftToTokenTrades.swapInfo.pair,
            nftIds_len=currentNftToTokenTrades.swapInfo.nftIds_len,
            nftIds=currentNftToTokenTrades.swapInfo.nftIds,
            minExpectedTokenOutput=Uint256(low=0, high=0),
            tokenRecipient=params.tokenRecipient,
            isRouter=TRUE,
            routerCaller=caller            
        );
        let (newOutputAmount, newOutputAmountCarry) = uint256_add(outputAmount, outputAmountSwap);
        return nftToTokenTrades_loop(
            params=params,
            outputAmount=newOutputAmount,
            index=index + 1,
            caller=caller
        );
    }

    return nftToTokenTrades_loop(
        params=params,
        outputAmount=outputAmount,
        index=index + 1,
        caller=caller
    );    
    
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
    toPairSwapSpecificArr(
        swapList_len=pairs_len,
        swapList=swapInfo,
        index=0,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
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

    // let amountsOfNFTIdsForThisSwap = [nftIds_len];
    // let arrSize = amountsOfNFTIdsForThisSwap * Uint256.SIZE;
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
        nftIds_ptrs=nftIds_ptrs + Uint256.SIZE,
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
    minOutputs: Uint256*,
) {
    alloc_locals;

    if(index == end) {
        return ();
    }

    let (swapInfo: PairSwapSpecific*) = alloc();
    toPairSwapSpecificArr(
        swapList_len=pairs_len,
        swapList=swapInfo,
        index=0,
        pairs_len=pairs_len,
        pairs=pairs,
        nftIds_len_len=nftIds_len_len,
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

    // let amountsOfNFTIdsForThisSwap = [nftIds_len];
    // let arrSize = amountsOfNFTIdsForThisSwap * Uint256.SIZE;
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
        nftIds_ptrs=nftIds_ptrs + Uint256.SIZE,
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

func getPairSwapSpecificStructSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    amountsOfNFTIdsInStruct: felt
) -> (size: felt) {
    let arrSize = amountsOfNFTIdsInStruct * Uint256.SIZE;
    // pair.SIZE + nftIds_len.SIZE + nftIds.SIZE
    let size = 1 + 1 + arrSize;
    return (size=size);
}

func getRobustPairNFTsForTokenAndTokenForNFTsTradeSize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    swapList: RobustPairNFTsForTokenAndTokenForNFTsTrade
) -> (size: felt){
    alloc_locals;

    let (tokenToNFTTRadesSize) = getRobustpairSwapSpecificSize_loop(
        swapList=swapList.tokenToNFTTrades,
        start=0,
        end=swapList.tokenToNFTTrades_len,
        sizeCount=0
    );

    let (nftToTokenTradesSize) = getRobustpairSwapSpecificSizeForToken_loop(
        swapList=swapList.nftToTokenTrades,
        start=0,
        end=swapList.nftToTokenTrades_len,
        sizeCount=0
    );    

// tokenToNFTTrades_len + tokenToNFTTrades + nftToTokenTrades_len + nftToTokenTrades
// inputAmount + tokenRecipient + nftRecipient + deadline
   return (size=1 + tokenToNFTTRadesSize + 1 + nftToTokenTradesSize + Uint256.SIZE + 1 + 1 + 1);
}

func getRobustpairSwapSpecificSizeForToken_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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

    return getRobustpairSwapSpecificSizeForToken_loop(
        swapList=swapList + arrSize,
        start=start + 1,
        end=end,
        sizeCount=newSizeCount
    );
}

func getRobustpairSwapSpecificSize_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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

    return getRobustpairSwapSpecificSize_loop(
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