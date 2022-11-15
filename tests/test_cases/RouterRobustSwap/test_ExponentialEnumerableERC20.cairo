%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_block_timestamp, get_contract_address)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_sub, 
    uint256_add, 
    uint256_mul,
    assert_uint256_eq
)

from contracts.constants.structs import (PoolType)
from contracts.constants.library import (MAX_UINT_128)

from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.IRouter import (IRouter)
from contracts.interfaces.tokens.IERC721 import (IERC721)

from contracts.router.structs import (
    PairSwapAny,
    PairSwapSpecific,
    NFTsForAnyNFTsTrade,
    NFTsForSpecificNFTsTrade,
    RobustPairSwapAny,
    RobustPairSwapSpecific,
    RobustPairSwapSpecificForToken,
    RobustPairNFTsForTokenAndTokenForNFTsTrade
)

from contracts.mocks.libraries.library_account import (Account)

from tests.utils.library import (
    setBondingCurveAllowed, 
    setRouterAllowed,
    setERC20Allowance,
    setERC721Allowance,
    _mintERC721,
    displayIds
)

from tests.utils.Deployments import (
    CurveId,
    deployAccount,
    deployCurve,
    deployFactory,
    deployTokens,
    deployRouter
)

//
// Setup
// 

from tests.mixins.UsingEnumerable import (TokenImplementation)
from tests.mixins.UsingERC20 import (TokenStandard)
from tests.mixins.UsingExponentialCurve import (Curve)

from tests.test_cases.RouterSinglePool.params import (protocolFeeMultiplier)

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    let (accountAddr) = get_contract_address();
    %{
        context.accountAddr = ids.accountAddr
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}
    let (erc721Addr) = TokenImplementation.setup721(accountAddr);
    %{
        context.erc721Addr = ids.erc721Addr
        print(f"erc721Addr: {ids.erc721Addr} (hex: {hex(ids.erc721Addr)})")
    %}
    let (bondingCurveAddr) = Curve.setupCurve();
    %{
        context.bondingCurveAddr = ids.bondingCurveAddr
        print(f"bondingCurveAddr: {ids.bondingCurveAddr} (hex: {hex(ids.bondingCurveAddr)})")
    %}
    let (factoryAddr) = deployFactory(
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0), 
        ownerAddress=accountAddr
    );
    %{
        context.factoryAddr = ids.factoryAddr
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
    %}
    let (erc20Addr, _, erc1155Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000*10**18, high=0),
        owner=accountAddr
    );
    %{
        context.erc20Addr = ids.erc20Addr
        print(f"erc20Addr: {ids.erc20Addr} (hex: {hex(ids.erc20Addr)})")
        context.erc1155Addr = ids.erc1155Addr
        print(f"erc1155Addr: {ids.erc1155Addr} (hex: {hex(ids.erc1155Addr)})")

    %}
    let (routerAddr) = deployRouter(factoryAddr);
    %{
        context.routerAddr = ids.routerAddr
        print(f"routerAddr {context.routerAddr} (hex: {hex(context.routerAddr)})")
    %}
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);
    setRouterAllowed(
        factoryAddr=factoryAddr,
        factoryOwnerAddr=accountAddr,
        routerAddr=routerAddr
    );
    setERC20Allowance(
        erc20Addr=erc20Addr,
        spender=accountAddr,
        operator=routerAddr,
        allowance=Uint256(low=MAX_UINT_128, high=MAX_UINT_128)
    );
    setERC721Allowance(
        erc721Addr=erc721Addr,
        spender=accountAddr,
        operator=factoryAddr
    );
    setERC721Allowance(
        erc721Addr=erc721Addr,
        spender=accountAddr,
        operator=routerAddr
    );

    // Create 3 pairs with 0 delta and 0 trade fee
    // pair 1 has spot price of 0.1 TOKEN, then pair 2 has 0.2 TOKEN, and pair 3 has 0.3 TOKEN
    // Send 10 NFTs to each pair
    // (0-9), (10-19), (20-29)
    let (nftIds: Uint256*) = alloc();
    let (delta) = Curve.modifyDelta(Uint256(low=0, high=0));
    let (pair1) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,  
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=0,
        initialNFTIds=nftIds,
        initialERC20Balance=Uint256(low=10*10**18, high=0),
        spotPrice=Uint256(low=1*10**17, high=0),
        delta=delta
    );
    %{
        context.pair1 = ids.pair1
        print(f"pair1: {ids.pair1} (hex: {hex(ids.pair1)})")
    %}
    let amountOfNFTPerPair = 10;
    let (lastIndexPair1) = mintAndTransferToPair(
        index=0,
        end=amountOfNFTPerPair,
        erc721Addr=erc721Addr,
        mintTo=accountAddr,
        erc721Owner=accountAddr,
        pairAddr=pair1
    );
    let (pair2) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,  
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=0,
        initialNFTIds=nftIds,
        initialERC20Balance=Uint256(low=10*10**18, high=0),
        spotPrice=Uint256(low=2*10**17, high=0),
        delta=delta
    );
    %{
        context.pair2 = ids.pair2
        print(f"pair2: {ids.pair2} (hex: {hex(ids.pair2)})")
    %}

    let (lastIndexPair2) = mintAndTransferToPair(
        index=lastIndexPair1,
        end=lastIndexPair1 + amountOfNFTPerPair,
        erc721Addr=erc721Addr,
        mintTo=accountAddr,
        erc721Owner=accountAddr,
        pairAddr=pair2
    );

    let (pair3) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,  
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=0,
        initialNFTIds=nftIds,
        initialERC20Balance=Uint256(low=10*10**18, high=0),
        spotPrice=Uint256(low=3*10**17, high=0),
        delta=delta
    );
    %{
        context.pair3 = ids.pair3
        print(f"pair3: {ids.pair3} (hex: {hex(ids.pair3)})")
    %}

    let (lastIndexPair3) = mintAndTransferToPair(
        index=lastIndexPair2,
        end=lastIndexPair2 + amountOfNFTPerPair,
        erc721Addr=erc721Addr,
        mintTo=accountAddr,
        erc721Owner=accountAddr,
        pairAddr=pair3
    );

    let (extraNftIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=lastIndexPair3,
        nftIds_len=lastIndexPair3 + amountOfNFTPerPair,
        nftIds_ptr=extraNftIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );

    // displayIds(extraNftIds, 0, amountOfNFTPerPair);

    return ();
}

@external
func test_robustSwapTokenForAny2NFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
) {
    alloc_locals;

    local pair1;
    local pair2;
    local pair3;
    local routerAddr;
    local accountAddr;
    local erc721Addr;
    %{
        ids.pair1 = context.pair1
        ids.pair2 = context.pair2
        ids.pair3 = context.pair3
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let numItems = Uint256(low=2, high=0);
    let (_,_,_,
        pair1InputAmount, _
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pair1,
        numNFTs=numItems
    );
    let (_,_,_,
        pair2InputAmount, _
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pair2,
        numNFTs=numItems
    );
    
    let swapList_len = 3;
    let (swapList: RobustPairSwapAny*) = alloc();
    assert swapList[0] = RobustPairSwapAny(
        swapInfo=PairSwapAny(
            pair=pair1,
            numItems=numItems
        ),
        maxCost=pair2InputAmount,
    );
    assert swapList[1] = RobustPairSwapAny(
        swapInfo=PairSwapAny(
            pair=pair2,
            numItems=numItems
        ),
        maxCost=pair2InputAmount,
    );
    assert swapList[2] = RobustPairSwapAny(
        swapInfo=PairSwapAny(
            pair=pair3,
            numItems=numItems
        ),
        maxCost=pair2InputAmount,
    );
    
    let (beforeNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    
    let (inputAmount, inputAmountHigh) = uint256_mul(pair2InputAmount, Uint256(low=3, high=0));
    let (timestamp) = get_block_timestamp();
    // Expect to have the first two swapPairs succeed, and the last one silently fail
    // with 10% protocol fee:
    let (remainingValueAfterSwap) = TokenStandard.robustSwapTokenForAnyNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=inputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp
    );

   let (afterNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    with_attr error_mesage("RouterRobustSwap::robustSwapTokenForAny2NFTs - Incorrect NFT amount") {
        let (diff) = uint256_sub(afterNFTBalance, beforeNFTBalance);
        %{print(f"diff before and after balance {ids.diff.low + ids.diff.high}")%}
        assert_uint256_eq(diff, Uint256(low=4, high=0));
    }

    with_attr error_mesage("RouterRobustSwap::robustSwapTokenForAny2NFTs - Incorrect refund") {
        let (pair2InputTime3, pair2InputTime3High) = uint256_mul(pair2InputAmount, Uint256(low=3, high=0));
        let (pair1PlusPair2Input, pair1PlusPair2InputCarry) = uint256_add(pair1InputAmount, pair2InputAmount);
        let (expectedRemainingValue) = uint256_sub(pair2InputTime3, pair1PlusPair2Input);
        %{print(f"remainingValueAfterSwap: {ids.remainingValueAfterSwap.low + ids.remainingValueAfterSwap.high}")%}
        %{print(f"expectedRemainingValue: {ids.expectedRemainingValue.low + ids.expectedRemainingValue.high}")%}
        assert_uint256_eq(remainingValueAfterSwap, expectedRemainingValue);
    }
    
    return ();
}

@external
func test_robustSwapTokenFor2SpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pair1;
    local pair2;
    local pair3;
    local routerAddr;
    local accountAddr;
    local erc721Addr;
    %{
        ids.pair1 = context.pair1
        ids.pair2 = context.pair2
        ids.pair3 = context.pair3
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.erc721Addr = context.erc721Addr
    %}

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

    let (_,_,_,
        pair1InputAmount, _
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pair1,
        numNFTs=numItems
    );
    let (_,_,_,
        pair2InputAmount, _
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pair2,
        numNFTs=numItems
    );
   let (beforeNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    let swapList_len = 3;
    local pairs: felt* = cast(new (pair1, pair2, pair3), felt*);
    local nftIds_len: felt* = cast(new (2, 2, 2), felt*);
    let (maxCosts: Uint256*) = alloc();
    assert maxCosts[0] = pair2InputAmount;
    assert maxCosts[1] = pair2InputAmount;
    assert maxCosts[2] = pair2InputAmount;
    let (inputAmount, inputAmountHigh) = uint256_mul(pair2InputAmount, Uint256(low=3, high=0));
    let (timestamp) = get_block_timestamp();
    let (remainingValue) = TokenStandard.robustSwapTokenForSpecificNFTs(
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        pairs_len=swapList_len,
        pairs=pairs,
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,
        nftIds_ptrs_len=total_nft_ids,
        nftIds_ptrs=nftIds,
        maxCosts_len=swapList_len,
        maxCosts=maxCosts,
        inputAmount=inputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp
    );
   let (afterNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    with_attr error_mesage("RouterRobustSwap::test_robustSwapTokenFor2SpecificNFTs - Incorrect NFT amount") {
        let (diff) = uint256_sub(afterNFTBalance, beforeNFTBalance);
        assert_uint256_eq(diff, Uint256(low=4, high=0));
    }

    with_attr error_mesage("RouterRobustSwap::test_robustSwapTokenFor2SpecificNFTs - Incorrect refund") {
        let (pair2InputTime3, pair2InputTime3High) = uint256_mul(pair2InputAmount, Uint256(low=3, high=0));
        let (pair1PlusPair2Input, pair1PlusPair2InputCarry) = uint256_add(pair1InputAmount, pair2InputAmount);
        let (expectedRemainingValue) = uint256_sub(pair2InputTime3, pair1PlusPair2Input);
        assert_uint256_eq(remainingValue, expectedRemainingValue);
    }
    return ();
}

@external
func test_robustSwap2NFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pair1;
    local pair2;
    local pair3;
    local routerAddr;
    local accountAddr;
    local erc721Addr;
    %{
        ids.pair1 = context.pair1
        ids.pair2 = context.pair2
        ids.pair3 = context.pair3
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let numItems = Uint256(low=2, high=0);
    let total_nft_ids = 6;
    let (nftIds: Uint256*) = alloc();
    // ids for pair1
    assert nftIds[0] = Uint256(low=30, high=0);
    assert nftIds[1] = Uint256(low=31, high=0);
    // ids for pair2
    assert nftIds[2] = Uint256(low=32, high=0);
    assert nftIds[3] = Uint256(low=33, high=0);
    // ids for pair3
    assert nftIds[4] = Uint256(low=34, high=0);
    assert nftIds[5] = Uint256(low=35, high=0);
    let (_,_,_,
        pair2OutputAmount, _
    ) = INFTPair.getSellNFTQuote(
        contract_address=pair2,
        numNFTs=numItems
    );
    let (_,_,_,
        pair3OutputAmount, _
    ) = INFTPair.getSellNFTQuote(
        contract_address=pair3,
        numNFTs=numItems
    );
    let (beforeNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    let swapList_len = 3;
    local pairs: felt* = cast(new (pair1, pair2, pair3), felt*);
    local nftIds_len: felt* = cast(new (2, 2, 2), felt*);
    let (minOutputs: Uint256*) = alloc();
    assert minOutputs[0] = pair2OutputAmount;
    assert minOutputs[1] = pair2OutputAmount;
    assert minOutputs[2] = pair2OutputAmount;
    let (inputAmount, inputAmountHigh) = uint256_mul(pair2OutputAmount, Uint256(low=3, high=0));
    let (timestamp) = get_block_timestamp();
    let (remainingValue) = IRouter.robustSwapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        pairs_len=swapList_len,
        pairs=pairs,
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=total_nft_ids,
        nftIds_ptrs=nftIds,    
        minOutputs_len=swapList_len,
        minOutputs=minOutputs,
        tokenRecipient=accountAddr,
        deadline=timestamp
    );
   let (afterNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    with_attr error_mesage("RouterRobustSwap::test_robustSwapTokenFor2SpecificNFTs - Incorrect NFT amount") {
        let (diff) = uint256_sub(beforeNFTBalance, afterNFTBalance);
        assert_uint256_eq(diff, Uint256(low=4, high=0));
    }

    with_attr error_mesage("RouterRobustSwap::test_robustSwapTokenFor2SpecificNFTs - Incorrect refund") {
        let (expectedRemainingValue, expectedRemainingValueCarry) = uint256_add(pair3OutputAmount, pair2OutputAmount);
        assert_uint256_eq(remainingValue, expectedRemainingValue);
    }
    return ();
}


@external
func test_robustSwapNFTsForTokenWithBondingCurveError{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pair1;
    local pair2;
    local pair3;
    local routerAddr;
    local accountAddr;
    local erc721Addr;
    %{
        ids.pair1 = context.pair1
        ids.pair2 = context.pair2
        ids.pair3 = context.pair3
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let numItems = Uint256(low=2, high=0);
    let (_,_,_,
        pair2OutputAmount, _
    ) = INFTPair.getSellNFTQuote(
        contract_address=pair2,
        numNFTs=numItems
    );

    let total_nft_ids = 4;
    let (nftIds: Uint256*) = alloc();
    // ids for pair1
    assert nftIds[0] = Uint256(low=30, high=0);
    assert nftIds[1] = Uint256(low=31, high=0);
    // ids for pair2
    assert nftIds[2] = Uint256(low=32, high=0);
    assert nftIds[3] = Uint256(low=33, high=0);
    let swapList_len = 3;
    local pairs: felt* = cast(new (pair1, pair2, pair3), felt*);
    local nftIds_len: felt* = cast(new (2, 2, 0), felt*);
    let (minOutputs: Uint256*) = alloc();
    assert minOutputs[0] = pair2OutputAmount;
    assert minOutputs[1] = pair2OutputAmount;
    assert minOutputs[2] = pair2OutputAmount;

    let (beforeNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    let (timestamp) = get_block_timestamp();
    let (remainingValue) = IRouter.robustSwapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        pairs_len=swapList_len,
        pairs=pairs,
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,    
        nftIds_ptrs_len=total_nft_ids,
        nftIds_ptrs=nftIds,    
        minOutputs_len=swapList_len,
        minOutputs=minOutputs,
        tokenRecipient=accountAddr,
        deadline=timestamp
    );

   let (afterNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    with_attr error_mesage("RouterRobustSwap::test_robustSwapNFTsForTokenWithBondingCurveError - Incorrect NFT amount") {
        let (diff) = uint256_sub(beforeNFTBalance, afterNFTBalance);
        assert_uint256_eq(diff, Uint256(low=2, high=0));
    }

    with_attr error_mesage("RouterRobustSwap::test_robustSwapNFTsForTokenWithBondingCurveError - Incorrect refund") {
        assert_uint256_eq(remainingValue, pair2OutputAmount);
    }
    
    return ();
}

@external
func test_robustSwapNFTsForTokenAndTokenForNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pair1;
    local pair2;
    local pair3;
    local routerAddr;
    local accountAddr;
    local erc721Addr;
    %{
        ids.pair1 = context.pair1
        ids.pair2 = context.pair2
        ids.pair3 = context.pair3
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let (owner0) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=0, high=0)
    );
    let (owner1) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=1, high=0)
    );
    let (owner32) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=32, high=0)
    );
    let (owner33) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=33, high=0)
    );
    assert owner0 = pair1;
    assert owner1 = pair1;
    assert owner32 = accountAddr;
    assert owner33 = accountAddr;

    let numItems = Uint256(low=2, high=0);
    let (_,_,_,
        pair1InputAmount, _
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pair1,
        numNFTs=numItems
    );
    %{print(f"pair1InputAmount: {ids.pair1InputAmount.low + ids.pair1InputAmount.high}")%}
    let (_,_,_,
        pair2OutputAmount, _
    ) = INFTPair.getSellNFTQuote(
        contract_address=pair2,
        numNFTs=numItems
    );
    %{print(f"pair2OutputAmount: {ids.pair2OutputAmount.low + ids.pair2OutputAmount.high}")%}

    let tokenToNFTTrades_len = 1;
    local tokenToNFTTrades_pairs: felt* = cast(new (pair1,), felt*);
    local tokenToNFTTrades_nftIds_len: felt* = cast(new (2,), felt*);
    let tokenToNFTTrades_nftIds_ptrs_len = 2;
    let (tokenToNFTTrades_nftIds_ptrs: Uint256*) = alloc();
    assert tokenToNFTTrades_nftIds_ptrs[0] = Uint256(low=0, high=0);
    assert tokenToNFTTrades_nftIds_ptrs[1] = Uint256(low=1, high=0);
    let (maxCosts: Uint256*) = alloc();
    assert maxCosts[0] = pair1InputAmount;

    let nftToTokenTrades_len = 1;
    local nftToTokenTrades_pairs: felt* = cast(new (pair2,), felt*);
    local nftToTokenTrades_nftIds_len: felt* = cast(new (2,), felt*);
    let nftToTokenTrades_nftIds_ptrs_len = 2;
    let (nftToTokenTrades_nftIds_ptrs: Uint256*) = alloc();
    assert nftToTokenTrades_nftIds_ptrs[0] = Uint256(low=32, high=0);
    assert nftToTokenTrades_nftIds_ptrs[1] = Uint256(low=33, high=0);
    let (minOutputs: Uint256*) = alloc();
    assert minOutputs[0] = pair2OutputAmount;

    let (timestamp) = get_block_timestamp();
    TokenStandard.robustSwapTokenForSpecificNFTsAndNFTsForTokens(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        // params: RobustPairNFTsForTokenAndTokenForNFTsTrade
        tokenToNFTTrades_len=tokenToNFTTrades_len,
        // tokenToNFTTrades: RobustPairSwapSpecific*,
        // PairSwapSpecific.pairs*
        tokenToNFTTrades_pairs_len=tokenToNFTTrades_len,
        tokenToNFTTrades_pairs=tokenToNFTTrades_pairs,
        // PairSwapSpecific.nftIds_len*
        tokenToNFTTrades_nftIds_len_len=tokenToNFTTrades_len,
        tokenToNFTTrades_nftIds_len=tokenToNFTTrades_nftIds_len,    
        // PairSwapSpecific.nftIds
        tokenToNFTTrades_nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
        tokenToNFTTrades_nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs,
        maxCosts_len=tokenToNFTTrades_len,
        maxCosts=maxCosts,    

        nftToTokenTrades_len=nftToTokenTrades_len,
        // nftToTokenTrades: RobustPairSwapSpecificForToken*,
        // PairSwapSpecific.pairs*
        nftToTokenTrades_pairs_len=nftToTokenTrades_len,
        nftToTokenTrades_pairs=nftToTokenTrades_pairs,
        // PairSwapSpecific.nftIds_len*
        nftToTokenTrades_nftIds_len_len=nftToTokenTrades_len,
        nftToTokenTrades_nftIds_len=nftToTokenTrades_nftIds_len,    
        // PairSwapSpecific.nftIds
        nftToTokenTrades_nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
        nftToTokenTrades_nftIds_ptrs=nftToTokenTrades_nftIds_ptrs,    
        minOutputs_len=nftToTokenTrades_len,
        minOutputs=minOutputs,    

        inputAmount=pair1InputAmount,
        tokenRecipient=accountAddr,
        nftRecipient=accountAddr,
        deadline=timestamp
    );

    let (owner0) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=0, high=0)
    );
    let (owner1) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=1, high=0)
    );
    let (owner32) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=32, high=0)
    );
    let (owner33) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=Uint256(low=33, high=0)
    );
    assert owner0 = accountAddr;
    assert owner1 = accountAddr;
    assert owner32 = pair2;
    assert owner33 = pair2;

    return ();
}

func mintAndTransferToPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: felt,
    end: felt,
    erc721Addr: felt,
    mintTo: felt,
    erc721Owner: felt,
    pairAddr: felt
) -> (endIndex: felt) {
    alloc_locals;

    if(index == end) {
        return (endIndex=index);
    }

    // mint 1 nft
    %{stop_prank_erc721 = start_prank(ids.erc721Owner, ids.erc721Addr)%}
    let id = Uint256(low=index, high=0);
    IERC721.mint(erc721Addr, mintTo, id);
    %{stop_prank_erc721()%}    

    // transfer to pair
    IERC721.safeTransferFrom(
        contract_address=erc721Addr,
        from_=mintTo,
        to=pairAddr,
        tokenId=id,
        data_len=0,
        data=cast(new (0,), felt*)
    );
    let (idOwner) = IERC721.ownerOf(
        contract_address=erc721Addr,
        tokenId=id
    );
    return mintAndTransferToPair(
        index=index + 1,
        end=end,
        erc721Addr=erc721Addr,
        mintTo=mintTo,
        erc721Owner=erc721Owner,
        pairAddr=pairAddr
    );
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}