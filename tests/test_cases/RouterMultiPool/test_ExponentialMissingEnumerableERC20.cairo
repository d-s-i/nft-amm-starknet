%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    assert_uint256_eq
)
from starkware.starknet.common.syscalls import (get_contract_address, get_block_timestamp)

from contracts.mocks.libraries.library_account import (Account)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.IRouter import (IRouter)

from contracts.constants.structs import (PoolType)
from contracts.constants.library import (MAX_UINT_128)

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

from tests.test_cases.RouterMultiPool.params import (
    feeRecipient,
    protocolFeeMultiplier,
    numInitialNFTs
)

//
// Setup
// 

from tests.mixins.UsingMissingEnumerable import (TokenImplementation)
from tests.mixins.UsingERC20 import (TokenStandard)
from tests.mixins.UsingExponentialCurve import (Curve)

@storage_var
func pairs(index: felt) -> (pairAddr: felt) {
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    let (accountAddr) = get_contract_address();
    %{
        context.accountAddr = ids.accountAddr
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}
    let (bondingCurveAddr) = Curve.setupCurve();
    %{context.bondingCurveAddr = ids.bondingCurveAddr%}
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
    let (factoryAddr) = deployFactory(
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0), 
        ownerAddress=accountAddr
    );
    %{
        context.factoryAddr = ids.factoryAddr
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
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
    let (nftIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=0,
        nftIds_len=numInitialNFTs,
        nftIds_ptr=nftIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );

    deployPairs_loop(
        start=0,
        end=5,
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        initialNFTIds=nftIds
    );

    return ();
}

@external
func test_swapTokenForAny5NFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    local routerAddr;
    local erc721Addr;
    %{
        ids.accountAddr = context.accountAddr
        ids.routerAddr = context.routerAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let swapList_len = 5;
    let (swapList: PairSwapAny*) = alloc();
    let (totalInputAmount) = getBuySwapListAny(
        index=0,
        swapList_len=swapList_len,
        swapList=swapList,
        totalInputAmount= Uint256(low=0, high=0)
    );

    let (startBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    let (timestamp) = get_block_timestamp();
    TokenStandard.swapTokenForAnyNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        swapList=swapList,
        inputAmount=totalInputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp
    );
    let (endBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    let (diff) = uint256_sub(endBalance, startBalance);
    with_attr error_mesage ("swapTokenForAny5NFTs - Incorrect amount of NFT acquired") {
        assert_uint256_eq(diff, Uint256(low=5, high=0));
    } 
    return ();    
}

@external
func test_swapTokenForSpecific5NFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    local routerAddr;
    local erc721Addr;
    %{
        ids.accountAddr = context.accountAddr
        ids.routerAddr = context.routerAddr
        ids.erc721Addr = context.erc721Addr
    %}
    let swapList_len = 5;
    let (pair_0) = pairs.read(1);
    let (pair_1) = pairs.read(2);
    let (pair_2) = pairs.read(3);
    let (pair_3) = pairs.read(4);
    let (pair_4) = pairs.read(5);
    local pairs_ptr: felt* = cast(new (
        pair_0,
        pair_1,
        pair_2,
        pair_3,
        pair_4
    ), felt*);
    local nftIds_len: felt* = cast(new (
        1,
        1,
        1,
        1,
        1
    ), felt*);
    let nftIds_ptrs_len = 5;
    local nftIds_ptrs: Uint256* = cast(new (
        Uint256(low=1, high=0),
        Uint256(low=2, high=0),
        Uint256(low=3, high=0),
        Uint256(low=4, high=0),
        Uint256(low=5, high=0)
    ), Uint256*);
    let (totalInputAmount) = getBuySwapListSpecificInputAmount(
        index=0,
        end=swapList_len,
        totalInputAmount= Uint256(low=0, high=0)
    );

    let (startBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    let (timestamp) = get_block_timestamp();
    TokenStandard.swapTokenForSpecificNFTs(
        callerAddr=accountAddr,
        routerAddr=routerAddr,
        swapList_len=swapList_len,
        // swapList: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=pairs_ptr,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,

        inputAmount=totalInputAmount,
        nftRecipient=accountAddr,
        deadline=timestamp
    );
    let (endBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    let (diff) = uint256_sub(endBalance, startBalance);
    with_attr error_mesage ("swapTokenForSpecific5NFTs - Incorrect amount of NFT acquired") {
        assert_uint256_eq(diff, Uint256(low=5, high=0));
    } 
    return ();      
}

@external
func test_swap5NFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    local routerAddr;
    local erc721Addr;
    %{
        ids.accountAddr = context.accountAddr
        ids.routerAddr = context.routerAddr
        ids.erc721Addr = context.erc721Addr
    %}

    let swapList_len = 5;
    let (pair_0) = pairs.read(1);
    let (pair_1) = pairs.read(2);
    let (pair_2) = pairs.read(3);
    let (pair_3) = pairs.read(4);
    let (pair_4) = pairs.read(5);
    local pairs_ptr: felt* = cast(new (
        pair_0,
        pair_1,
        pair_2,
        pair_3,
        pair_4
    ), felt*);
    local nftIds_len: felt* = cast(new (
        1,
        1,
        1,
        1,
        1
    ), felt*);
    let nftIds_ptrs_len = 5;
    local nftIds_ptrs: Uint256* = cast(new (
        Uint256(low=6, high=0),
        Uint256(low=7, high=0),
        Uint256(low=8, high=0),
        Uint256(low=9, high=0),
        Uint256(low=10, high=0)
    ), Uint256*);
    
    let (totalOutputAmount) = getSellSwapListSpecificOutputAmount(
        index=0,
        end=swapList_len,
        totalOutputAmount= Uint256(low=0, high=0)
    );

    let (startBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
    let (timestamp) = get_block_timestamp();
    IRouter.swapNFTsForToken(
        contract_address=routerAddr,
        swapList_len=swapList_len,
        // PairSwapSpecific.pairs*
        pairs_len=swapList_len,
        pairs=pairs_ptr,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len=swapList_len,
        nftIds_len=nftIds_len,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len=nftIds_ptrs_len,
        nftIds_ptrs=nftIds_ptrs,

        minOutput=totalOutputAmount,
        tokenRecipient=accountAddr,
        deadline=timestamp * 2    
    );
    let (endBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );

    let (diff) = uint256_sub(startBalance, endBalance);
    with_attr error_mesage ("swapTokenForAny5NFTs - Incorrect amount of NFT acquired") {
        assert_uint256_eq(diff, Uint256(low=5, high=0));
    } 
    return ();    
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}

func getBuySwapListSpecificInputAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    end: felt,
    totalInputAmount: Uint256
) -> (totalInputAmount: Uint256) {
    if(index == end) {
        return (totalInputAmount=totalInputAmount);
    }
    let (pairAddr) = pairs.read(index + 1);
    let numItems = Uint256(low=1, high=0);
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=numItems
    );
    let (newInputAmount, newInputAmountCarry) = uint256_add(totalInputAmount, inputAmount);

    return getBuySwapListSpecificInputAmount(
        index=index + 1,
        end=end,
        totalInputAmount=newInputAmount
    );
}

func getSellSwapListSpecificOutputAmount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    end: felt,
    totalOutputAmount: Uint256
) -> (totalOutputAmount: Uint256) {
    if(index == end) {
        return (totalOutputAmount=totalOutputAmount);
    }
    let (pairAddr) = pairs.read(index + 1);
    let numItems = Uint256(low=1, high=0);
    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(
        contract_address=pairAddr,
        numNFTs=numItems
    );
    let (newOutputAmount, newOutputAmountCarry) = uint256_add(totalOutputAmount, outputAmount);

    return getSellSwapListSpecificOutputAmount(
        index=index + 1,
        end=end,
        totalOutputAmount=newOutputAmount
    );
}

func getBuySwapListAny{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    index: felt,
    swapList_len: felt,
    swapList: PairSwapAny*,
    totalInputAmount: Uint256
) -> (totalInputAmount: Uint256) {

    if(index == swapList_len) {
        return (totalInputAmount=totalInputAmount);
    }
    let (pairAddr) = pairs.read(index + 1);
    let numItems = Uint256(low=1, high=0);
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(
        contract_address=pairAddr,
        numNFTs=numItems
    );
    let (newInputAmount, newInputAmountCarry) = uint256_add(totalInputAmount, inputAmount);
    assert [swapList] = PairSwapAny(
        pair=pairAddr,
        numItems=numItems
    );

    return getBuySwapListAny(
        index=index + 1,
        swapList_len=swapList_len,
        swapList=swapList + PairSwapAny.SIZE,
        totalInputAmount=newInputAmount
    );
}

func deployPairs_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt,
    accountAddr: felt,
    factoryAddr: felt,
    routerAddr: felt,
    erc20Addr: felt,
    erc721Addr: felt,
    bondingCurveAddr: felt,
    initialNFTIds: Uint256*
) {
    alloc_locals;
    
    if(start == end) {
        return ();
    }

    let (delta) = Curve.modifyDelta(Uint256(low=0, high=0));
    local nftId: Uint256 = [initialNFTIds];
    let (pairAddr) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=1,
        initialNFTIds=initialNFTIds,
        initialERC20Balance=Uint256(low=(start + 1)*10**18, high=0),
        spotPrice=Uint256(low=(start + 1)*10**18, high=0),
        delta=delta
    );
    pairs.write(start + 1, pairAddr);

    return deployPairs_loop(
        start=start + 1,
        end=end,
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        initialNFTIds=initialNFTIds + Uint256.SIZE
    );    
}