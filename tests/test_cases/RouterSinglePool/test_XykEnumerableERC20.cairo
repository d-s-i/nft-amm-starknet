%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_block_timestamp, get_contract_address)
from starkware.cairo.common.uint256 import (Uint256, uint256_sub)

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

from contracts.mocks.libraries.library_account import (Account, AccountCallArray)

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
from tests.mixins.UsingXykCurve import (Curve)

from tests.test_cases.RouterSinglePool.params import (
    feeRecipient,
    protocolFeeMultiplier,
    numInitialNFTs
)

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    // let (accountAddr) = deployAccount(0);
    let (accountAddr) = get_contract_address();
    %{
        context.accountAddr = ids.accountAddr
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}
    let (bondingCurveAddr) = Curve.setupCurve();
    %{context.bondingCurveAddr = ids.bondingCurveAddr%}
    let (factoryAddr) = deployFactory(
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0), 
        ownerAddress=accountAddr
    );
    %{
        context.factoryAddr = ids.factoryAddr
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
    %}
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);
    let (erc20Addr, _, erc1155Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000*10**18, high=0),
        owner=accountAddr
    );
    let (erc721Addr) = TokenImplementation.setup721(accountAddr);
    %{
        context.erc20Addr = ids.erc20Addr
        print(f"erc20Addr: {ids.erc20Addr} (hex: {hex(ids.erc20Addr)})")
        context.erc721Addr = ids.erc721Addr
        print(f"erc721Addr: {ids.erc721Addr} (hex: {hex(ids.erc721Addr)})")
        context.erc1155Addr = ids.erc1155Addr
        print(f"erc1155Addr: {ids.erc1155Addr} (hex: {hex(ids.erc1155Addr)})")

    %}
    let (routerAddr) = deployRouter(factoryAddr);
    %{
        context.routerAddr = ids.routerAddr
        print(f"routerAddr {context.routerAddr} (hex: {hex(context.routerAddr)})")
    %}
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
        operator=routerAddr
    );

    let (delta) = Curve.modifyDelta(Uint256(low=0, high=0));
    let (pairAddr) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=numInitialNFTs,
        initialERC20Balance=Uint256(low=10*10**18, high=0),
        spotPrice=Uint256(low=10**18, high=0),
        delta=delta
    );
    %{
        context.pairAddr = ids.pairAddr
        print(f"pairAddr: {ids.pairAddr} (hex: {hex(ids.pairAddr)})")
    %}

    let (extraNFTIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=numInitialNFTs,
        nftIds_len=2 * numInitialNFTs,
        nftIds_ptr=extraNFTIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );

    return ();
}

@external
func test_swapTokenForSingleAnyNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
) {
    alloc_locals;

    local routerAddr;
    local accountAddr;
    local pairAddr;
    %{
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
        ids.pairAddr = context.pairAddr
    %}
    
    let numNFTs = Uint256(low=1, high=0);
    let swapList_len = 1;
    let swapList = PairSwapAny(
        pair=pairAddr,
        numItems=numNFTs
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=numNFTs
    );

    let (timestamp) = get_block_timestamp();
    TokenStandard.swapTokenForAnyNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        swapList=cast(new (swapList,), PairSwapAny*),
        inputAmount=inputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );

    return ();
}

@external
func test_swapTokenForSingleSpecificNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pair = pairAddr;
    let nftIds_len = 1;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=1, high=0);
    // swapList struct not used as is (bc can't pass struct as arg) but
    // but useful to picture what's happening
    let swapList = PairSwapSpecific(
        pair=pair,
        nftIds_len=nftIds_len,
        nftIds=nftIds
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    TokenStandard.swapTokenForSpecificNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        // swapList: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=cast(new (pair,), felt*),
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=cast(new (nftIds_len,), felt*),    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_len,
        nftIds_ptrs=nftIds,

        inputAmount=inputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );    

    return ();    
}

@external
func test_swapSingleNFTForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pair = pairAddr;
    let nftIds_len = 1;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=numInitialNFTs + 1, high=0);
    // swapList struct not used as is (bc can't pass struct* as calldata) but
    // but useful to picture what's happening
    let swapList = PairSwapSpecific(
        pair=pair,
        nftIds_len=nftIds_len,
        nftIds=nftIds
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    IRouter.swapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=cast(new (pair,), felt*),
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=cast(new (nftIds_len,), felt*),    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_len,
        nftIds_ptrs=nftIds,

        minOutput=outputAmount,
        tokenRecipient=accountAddr,
        deadline=timestamp * 2    
    );

    return ();
}

@external
func test_swapSingleNFTForAnyNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let nftToTokenTrades_len = 1;
    let pairs_len = nftToTokenTrades_len;
    local pairs: felt* = cast(new (pairAddr,), felt*);
    let nftIds_len_len = nftToTokenTrades_len;
    local nftIds_len: felt* = cast(new (1,), felt*);
    let nftIds_ptrs_len = 1;
    local nftIds_ptrs: Uint256* = cast(new (Uint256(low=numInitialNFTs + 1, high=0),), Uint256*);

    let tokenToNFTTrades_len = 1;
    let (tokenToNFTSwapList: PairSwapAny*) = alloc();
    assert [tokenToNFTSwapList] = PairSwapAny(
        pair=pairAddr,
        numItems=Uint256(low=1, high=0)
    );

    // 0.01 ether
    let inputAmount = Uint256(low=10**16, high=0);
    let (timestamp) = get_block_timestamp();
    TokenStandard.swapNFTsForAnyNFTsThroughToken(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        nftToTokenTrades_len=nftToTokenTrades_len,
        // PairSwapSpecific.pairs*
        pairs_len=pairs_len,
        pairs=pairs,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,

        tokenToNFTTrades_len=tokenToNFTTrades_len,
        tokenToNFTTrades=tokenToNFTSwapList,

        inputAmount=inputAmount,
        minOutput=Uint256(low=0, high=0),
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );
    return ();
}

@external
func test_swapSingleNFTForSpecificNFT{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let nftToTokenTrades_len = 1;
    let nftToTokenTrades_pairs_len = nftToTokenTrades_len;
    local nftToTokenTrades_pairs: felt* = cast(new (pairAddr,), felt*);
    let nftToTokenTrades_nftIds_len_len = nftToTokenTrades_len;
    local nftToTokenTrades_nftIds_len: felt* = cast(new (1,), felt*);
    let nftToTokenTrades_nftIds_ptrs_len = 1;
    local nftToTokenTrades_nftIds_ptrs: Uint256* = cast(new (Uint256(low=numInitialNFTs + 1, high=0),), Uint256*);

    let tokenToNFTTrades_len = 1;
    let tokenToNFTTrades_pairs_len = 1;
    local tokenToNFTTrades_pairs: felt* = cast(new (pairAddr,), felt*);
    let tokenToNFTTrades_nftIds_len_len = tokenToNFTTrades_len;
    local tokenToNFTTrades_nftIds_len: felt* = cast(new (1,), felt*);
    let tokenToNFTTrades_nftIds_ptrs_len = 1;
    local tokenToNFTTrades_nftIds_ptrs: Uint256* = cast(new (Uint256(low=1, high=0),), Uint256*);

    // 0.01 ether
    let inputAmount = Uint256(low=10**16, high=0);
    let (timestamp) = get_block_timestamp();
    TokenStandard.swapNFTsForSpecificNFTsThroughToken(
        callerAddr=accountAddr,
        routerAddr=routerAddr,

        nftToTokenTrades_len=nftToTokenTrades_len,
        nftToTokenTrades_pairs_len=nftToTokenTrades_pairs_len,
        nftToTokenTrades_pairs=nftToTokenTrades_pairs,
        nftToTokenTrades_nftIds_len_len=nftToTokenTrades_nftIds_len_len,
        nftToTokenTrades_nftIds_len=nftToTokenTrades_nftIds_len,    
        nftToTokenTrades_nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
        nftToTokenTrades_nftIds_ptrs=nftToTokenTrades_nftIds_ptrs,

        tokenToNFTTrades_len=tokenToNFTTrades_len,
        tokenToNFTTrades_pairs_len=tokenToNFTTrades_pairs_len,
        tokenToNFTTrades_pairs=tokenToNFTTrades_pairs,
        tokenToNFTTrades_nftIds_len_len=tokenToNFTTrades_nftIds_len_len,
        tokenToNFTTrades_nftIds_len=tokenToNFTTrades_nftIds_len,    
        tokenToNFTTrades_nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
        tokenToNFTTrades_nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs,

        inputAmount=inputAmount,
        minOutput=Uint256(low=0, high=0),
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );
    return ();
}

@external
func test_swapTokenForSpecific5NFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc721Addr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc721Addr = context.erc721Addr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pairs_len = swapList_len;
    local pairs: felt* = cast(new (pairAddr,), felt*);
    let nftIds_len_len = swapList_len;
    local nftIds_len: felt* = cast(new (5,), felt*);
    let nftIds_ptrs_len = 5;
    local nftIds_ptrs: Uint256* = cast(new (
        Uint256(low=1, high=0),
        Uint256(low=2, high=0),
        Uint256(low=3, high=0),
        Uint256(low=4, high=0),
        Uint256(low=5, high=0),
    ), Uint256*);

    let (startBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_ptrs_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    TokenStandard.swapTokenForSpecificNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        // swapList: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=pairs,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,

        inputAmount=inputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );

    let (endBalance) = IERC721.balanceOf(erc721Addr, accountAddr);

    with_attr error_mesage("swapTokenForSpecific5NFTs - Too few NFTs acquired") {
        let (diff) = uint256_sub(endBalance, startBalance);
        let _diff = diff.low + diff.high;
        assert _diff = 5;
    }

    return ();
}

@external
func test_swap5NFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc721Addr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc721Addr = context.erc721Addr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pairs_len = swapList_len;
    local pairs: felt* = cast(new (pairAddr,), felt*);
    let nftIds_len_len = swapList_len;
    local nftIds_len: felt* = cast(new (5,), felt*);
    let nftIds_ptrs_len = 5;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=numInitialNFTs + 1, high=0);
    assert nftIds[1] = Uint256(low=numInitialNFTs + 2, high=0);
    assert nftIds[2] = Uint256(low=numInitialNFTs + 3, high=0);
    assert nftIds[3] = Uint256(low=numInitialNFTs + 4, high=0);
    assert nftIds[4] = Uint256(low=numInitialNFTs + 5, high=0);

    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_ptrs_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    IRouter.swapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        // PairSwapSpecific.pairs*
        pairs_len=pairs_len,
        pairs=pairs,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=nftIds_len_len,
        nftIds_len=nftIds_len,
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds,

        minOutput=outputAmount,
        tokenRecipient=accountAddr,
        deadline=timestamp * 2    
    );

    return ();
}

@external
func test_swapTokenForSingleAnyNFTSlippage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc721Addr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc721Addr = context.erc721Addr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %} 

    let numNFTs = Uint256(low=1, high=0);
    let swapList_len = 1;
    let swapList = PairSwapAny(
        pair=pairAddr,
        numItems=numNFTs
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=numNFTs
    );

    let (timestamp) = get_block_timestamp();
    %{ expect_revert() %}
    TokenStandard.swapTokenForAnyNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        swapList=cast(new (swapList,), PairSwapAny*),
        inputAmount=Uint256(low=inputAmount.low - 1, high=inputAmount.high),
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );    

    return ();
}

@external
func test_swapTokenForSingleSpecificNFTSlippage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pair = pairAddr;
    let nftIds_len = 1;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=1, high=0);
    // swapList struct not used as is (bc can't pass struct as arg) but
    // but useful to picture what's happening
    let swapList = PairSwapSpecific(
        pair=pair,
        nftIds_len=nftIds_len,
        nftIds=nftIds
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    %{ expect_revert() %}
    TokenStandard.swapTokenForSpecificNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        // swapList: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=cast(new (pair,), felt*),
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=cast(new (nftIds_len,), felt*),    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_len,
        nftIds_ptrs=nftIds,

        inputAmount=Uint256(low=inputAmount.low - 1, high=inputAmount.high),
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );    

    return ();    
}

@external
func test_swapSingleNFTForNonExistentToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let pair = pairAddr;
    let nftIds_len = 1;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=numInitialNFTs + 1, high=0);
    // swapList struct not used as is (bc can't pass struct* as calldata) but
    // but useful to picture what's happening
    let swapList = PairSwapSpecific(
        pair=pair,
        nftIds_len=nftIds_len,
        nftIds=nftIds
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=nftIds_len, high=0)
    );

    let (timestamp) = get_block_timestamp();
    %{expect_revert()%}
    IRouter.swapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=cast(new (pair,), felt*),
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=cast(new (nftIds_len,), felt*),    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_len,
        nftIds_ptrs=nftIds,

        minOutput=Uint256(low=outputAmount.low + 1, high=outputAmount.high),
        tokenRecipient=accountAddr,
        deadline=timestamp * 2    
    );

    return ();    
}

@external
func test_swapTokenForAnyNFTsPastBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc721Addr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc721Addr = context.erc721Addr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let swapList_len = 1;
    let (nftIds: Uint256*) = alloc();
    assert nftIds[0] = Uint256(low=numInitialNFTs + 1, high=0);
    let (pairBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=pairAddr
    );
    let overPairBalance = Uint256(low=pairBalance.low + 1, high=pairBalance.high);
    let swapList = PairSwapAny(
        pair=pairAddr,
        numItems=overPairBalance
    );

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=overPairBalance
    );

    let (timestamp) = get_block_timestamp();
    %{expect_revert()%}
    TokenStandard.swapTokenForAnyNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        swapList=cast(new (swapList,), PairSwapAny*),
        inputAmount=Uint256(low=inputAmount.low + 1, high=inputAmount.high),
        nftRecipient=accountAddr,
        deadline=timestamp * 2
    );    

    return ();
}

@external
func test_swapSingleNFTForTokenWithEmptyList{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc721Addr;
    local routerAddr;
    local accountAddr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc721Addr = context.erc721Addr
        ids.routerAddr = context.routerAddr
        ids.accountAddr = context.accountAddr
    %}

    let (nftIds: Uint256*) = alloc();
    let swapList_len = 1;
    let pair = pairAddr;
    let nftIds_len = 0;
    // swapList struct not used as is (bc can't pass struct as arg) but
    // but useful to picture what's happening
    let swapList = PairSwapSpecific(
        pair=pair,
        nftIds_len=nftIds_len,
        nftIds=nftIds
    );    

    let (
        error,
        newSpotPrice,
        newDelta,
        sellAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=pairAddr,
        numNFTs=Uint256(low=1, high=0)
    );

    let (timestamp) = get_block_timestamp();
    %{expect_revert()%}
    IRouter.swapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=cast(new (pair,), felt*),
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=cast(new (nftIds_len,), felt*),    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_len,
        nftIds_ptrs=nftIds,

        minOutput=sellAmount,
        tokenRecipient=accountAddr,
        deadline=timestamp * 2    
    );    

    return ();    
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}
