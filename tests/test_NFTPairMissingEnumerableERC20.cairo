%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (TRUE, FALSE)
from starkware.cairo.common.uint256 import (
    Uint256, 
    assert_uint256_eq, 
    uint256_add, 
    uint256_sub
)

from contracts.constants.library import (MAX_UINT_128)
from contracts.constants.structs import (PoolType)

from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)

from tests.utils.Deployments import (
    deployPair, 
    deployFactory,
    deployTokens,
    deployCurve, 
    CurveId
)

const TOKEN_ID = 1;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    %{ 
        print("Starting setup")
        ids.accountAddr = deploy_contract("./contracts/mocks/Account.cairo", [0]).contract_address
        context.accountAddr = ids.accountAddr
    %}

    let erc20InitialSupply = Uint256(low=1000000000000000000000, high=0);
    let erc20Decimals = 18;
    let (erc20AddrForSpecificSwap, erc721AddrForSpecificSwap) = deployTokens(erc20Decimals, erc20InitialSupply, accountAddr);
    let (erc20AddrForAnySwap, erc721AddrForAnySwap) = deployTokens(erc20Decimals, erc20InitialSupply, accountAddr);
    let (erc20AddrForSell, erc721AddrForSell) = deployTokens(erc20Decimals, erc20InitialSupply, accountAddr);
    %{
        context.erc20AddrForSpecificSwap = ids.erc20AddrForSpecificSwap
        context.erc721AddrForSpecificSwap = ids.erc721AddrForSpecificSwap
        context.erc20AddrForAnySwap = ids.erc20AddrForAnySwap
        context.erc721AddrForAnySwap = ids.erc721AddrForAnySwap
        context.erc20AddrForSell = ids.erc20AddrForSell
        context.erc721AddrForSell = ids.erc721AddrForSell
    %}

    let (bondingCurveAddr) = deployCurve(CurveId.Linear);
    let (factoryAddr) = deployFactory(Uint256(low=0, high=0), accountAddr);
    %{
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
        print(f"bondingCurveAddr: {ids.bondingCurveAddr} (hex: {hex(ids.bondingCurveAddr)})")
        print(f"erc20AddrForAnySwap: {ids.erc20AddrForAnySwap} (hex: {hex(ids.erc20AddrForAnySwap)})")
        print(f"erc20AddrForSpecificSwap: {ids.erc20AddrForSpecificSwap} (hex: {hex(ids.erc20AddrForSpecificSwap)})")
        print(f"erc20AddrForSell: {ids.erc20AddrForSell} (hex: {hex(ids.erc20AddrForSell)})")
        print(f"erc721AddrForAnySwap: {ids.erc721AddrForAnySwap} (hex: {hex(ids.erc721AddrForAnySwap)})")
        print(f"erc721AddrForSpecificSwap: {ids.erc721AddrForSpecificSwap} (hex: {hex(ids.erc721AddrForSpecificSwap)})")
        print(f"erc721AddrForSell: {ids.erc721AddrForSell} (hex: {hex(ids.erc721AddrForSell)})")
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")    
    %}    

    %{stop_prank_factory = start_prank(context.accountAddr, ids.factoryAddr)%}
    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
    %{stop_prank_factory()%}

    let (pairAddressForSpecificSwap) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20AddrForSpecificSwap,
        erc721Addr=erc721AddrForSpecificSwap,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTId=1,
        initialERC20Balance=Uint256(low=100, high=0)
    );
    %{
        context.pairAddressForSpecificSwap = ids.pairAddressForSpecificSwap
        print(f"pairAddressForSpecificSwap: {ids.pairAddressForSpecificSwap}")
    %}
    let (pairAddressForAnySwap) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20AddrForAnySwap,
        erc721Addr=erc721AddrForAnySwap,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTId=1,
        initialERC20Balance=Uint256(low=100, high=0)
    );
    %{
        context.pairAddressForAnySwap = ids.pairAddressForAnySwap
        print(f"pairAddressForAnySwap: {ids.pairAddressForAnySwap}")
    %}
    let (pairAddressForSell) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20AddrForSell,
        erc721Addr=erc721AddrForSell,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTId=1,
        initialERC20Balance=Uint256(low=100, high=0)
    );
    %{
        context.pairAddressForSell = ids.pairAddressForSell
        print(f"pairAddressForSell: {ids.pairAddressForSell}")
    %}
    
    return ();
}

@external
func test_swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {

    alloc_locals;

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);

    tempvar pairAddress;
    tempvar erc20Addr;
    tempvar erc721Addr;
    tempvar accountAddr;
    %{
        ids.accountAddr = context.accountAddr
        ids.pairAddress = context.pairAddressForAnySwap
        ids.erc20Addr = context.erc20AddrForAnySwap
        ids.erc721Addr = context.erc721AddrForAnySwap
        stop_prank_erc20 = start_prank(context.accountAddr, ids.erc20Addr)
        stop_prank_pair = start_prank(context.accountAddr, ids.pairAddress)
        store(context.erc20AddrForAnySwap, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [ids.accountAddr, ids.pairAddress])
    %}

    IERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{stop_prank_erc20()%}

    let (initialPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"initialHolderTokenBalance: {ids.initialHolderTokenBalance.low + ids.initialHolderTokenBalance.high}")
        print(f"initialHolderNFTBalance: {ids.initialHolderNFTBalance.low + ids.initialHolderNFTBalance.high}")
    %}

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(pairAddress, Uint256(low=1, high=0));
    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"inputAmount: {ids.inputAmount.low + ids.inputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = INFTPair.getAllHeldIds(pairAddress, erc721Addr);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    let numNFTs = Uint256(low=1, high=0);
    INFTPair.swapTokenForAnyNFTs(
        pairAddress,
        numNFTs,
        Uint256(low=MAX_UINT_128, high=0),
        accountAddr,
        0,
        0
    );

    let (finalPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"finalHolderTokenBalance: {ids.finalHolderTokenBalance.low + ids.finalHolderTokenBalance.high}")
        print(f"finalHolderNFTBalance: {ids.finalHolderNFTBalance.low + ids.finalHolderNFTBalance.high}")
    %}

    let (expetedFinalPairTokenBalance, expetedFinalPairTokenBalanceCarry) = uint256_add(initialPairTokenBalance, inputAmount);
    assert_uint256_eq(finalPairTokenBalance, expetedFinalPairTokenBalance);
    let (expectedFinalHolderTokenBalance) = uint256_sub(initialHolderTokenBalance, inputAmount);
    assert_uint256_eq(finalHolderTokenBalance, expectedFinalHolderTokenBalance);

    let (expectedFinalPairNFTBalance) = uint256_sub(initialPairNFTBalance, numNFTs);
    assert_uint256_eq(expectedFinalPairNFTBalance, finalPairNFTBalance);
    let (expectedFinalHolderNFTBalance, expectedFinalHolderNFTBalanceCarry) = uint256_add(initialHolderNFTBalance, numNFTs);
    assert_uint256_eq(expectedFinalHolderNFTBalance, finalHolderNFTBalance);

    return ();
}

@external
func test_swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddress;
    local erc20Addr;
    local erc721Addr;
    local accountAddr;

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);
    %{
        ids.accountAddr = context.accountAddr
        print(f"(in test) pairAddress: {context.pairAddressForSpecificSwap}")
        ids.pairAddress = context.pairAddressForSpecificSwap
        ids.erc20Addr = context.erc20AddrForSpecificSwap
        ids.erc721Addr = context.erc721AddrForSpecificSwap
        stop_prank_erc20 = start_prank(context.accountAddr, context.erc20AddrForSpecificSwap)
        stop_prank_pair = start_prank(context.accountAddr, context.pairAddressForSpecificSwap)
        store(context.erc20AddrForSpecificSwap, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [context.accountAddr, context.pairAddressForSpecificSwap])
    %}

    IERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{stop_prank_erc20()%}

    let (initialPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"initialHolderTokenBalance: {ids.initialHolderTokenBalance.low + ids.initialHolderTokenBalance.high}")
        print(f"initialHolderNFTBalance: {ids.initialHolderNFTBalance.low + ids.initialHolderNFTBalance.high}")
    %}

    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = INFTPair.getBuyNFTQuote(pairAddress, Uint256(low=1, high=0));
    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"inputAmount: {ids.inputAmount.low + ids.inputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = INFTPair.getAllHeldIds(pairAddress, erc721Addr);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    let nftIds_len = 1;
    INFTPair.swapTokenForSpecificNFTs(
        pairAddress,
        nftIds_len,
        cast(new (Uint256(low=1, high=0),), Uint256*),
        MAX_UINT_256,
        accountAddr,
        0,
        0
    );

    let (finalPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"finalHolderTokenBalance: {ids.finalHolderTokenBalance.low + ids.finalHolderTokenBalance.high}")
        print(f"finalHolderNFTBalance: {ids.finalHolderNFTBalance.low + ids.finalHolderNFTBalance.high}")
    %}

    let (expetedFinalPairTokenBalance, expetedFinalPairTokenBalanceCarry) = uint256_add(initialPairTokenBalance, inputAmount);
    assert_uint256_eq(finalPairTokenBalance, expetedFinalPairTokenBalance);
    let (expectedFinalHolderTokenBalance) = uint256_sub(initialHolderTokenBalance, inputAmount);
    assert_uint256_eq(finalHolderTokenBalance, expectedFinalHolderTokenBalance);

    let (expectedFinalPairNFTBalance) = uint256_sub(initialPairNFTBalance, Uint256(low=nftIds_len, high=0));
    assert_uint256_eq(expectedFinalPairNFTBalance, finalPairNFTBalance);
    let (expectedFinalHolderNFTBalance, expectedFinalHolderNFTBalanceCarry) = uint256_add(initialHolderNFTBalance, Uint256(low=nftIds_len, high=0));
    assert_uint256_eq(expectedFinalHolderNFTBalance, finalHolderNFTBalance);
    return ();
}

@external
func test_swapNFTsForTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddress;
    local erc20Addr;
    local erc721Addr;
    local accountAddr;

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);
    %{
        ids.accountAddr = context.accountAddr
        ids.pairAddress = context.pairAddressForSell
        ids.erc20Addr = context.erc20AddrForSell
        ids.erc721Addr = context.erc721AddrForSell

        stop_prank_erc20 = start_prank(context.accountAddr, ids.erc20Addr)
        stop_prank_erc721 = start_prank(context.accountAddr, ids.erc721Addr)
        stop_prank_pair = start_prank(context.accountAddr, ids.pairAddress)
        store(ids.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [context.accountAddr, ids.pairAddress])
    %}

    let nftIds_len = 1;
    let soldTokenId = Uint256(low=2, high=0);
    IERC721.mint(erc721Addr, accountAddr, soldTokenId);
    IERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{
        stop_prank_erc20()
        stop_prank_erc721()
    %}

    let (initialPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"initialHolderTokenBalance: {ids.initialHolderTokenBalance.low + ids.initialHolderTokenBalance.high}")
        print(f"initialHolderNFTBalance: {ids.initialHolderNFTBalance.low + ids.initialHolderNFTBalance.high}")
    %}

    let (
        error,
        newSpotPrice,
        newDelta,
        outputAmount,
        protocolFee
    ) = INFTPair.getSellNFTQuote(pairAddress, Uint256(low=nftIds_len, high=0));
    %{
        print("\ngetSellNFTQuote")
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"outputAmount: {ids.outputAmount.low + ids.outputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
        print("\n")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = INFTPair.getAllHeldIds(pairAddress, erc721Addr);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    INFTPair.swapNFTsForToken(
        contract_address=pairAddress,
        nftIds_len=nftIds_len,
        nftIds=cast(new (soldTokenId,), Uint256*),
        minExpectedTokenOutput=Uint256(low=5, high=0),
        tokenRecipient=accountAddr,
        isRouter=0,
        routerCaller=0
    );

    let (finalPairTokenBalance) = IERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = IERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = IERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = IERC721.balanceOf(erc721Addr, accountAddr);
    %{
        print(f"finalHolderTokenBalance: {ids.finalHolderTokenBalance.low + ids.finalHolderTokenBalance.high}")
        print(f"finalHolderNFTBalance: {ids.finalHolderNFTBalance.low + ids.finalHolderNFTBalance.high}")
    %}

    let (expectedFinalPairTokenBalance) = uint256_sub(initialPairTokenBalance, outputAmount);
    assert_uint256_eq(finalPairTokenBalance, expectedFinalPairTokenBalance);
    let (expectedFinalHolderTokenBalance, expectedFinalHolderTokenBalanceCarry) = uint256_add(initialHolderTokenBalance, outputAmount);
    assert_uint256_eq(finalHolderTokenBalance, expectedFinalHolderTokenBalance);

    let (expectedFinalPairNFTBalance, expectedFinalPairNFTBalanceCarry) = uint256_add(initialPairNFTBalance, Uint256(low=nftIds_len, high=0));
    assert_uint256_eq(expectedFinalPairNFTBalance, finalPairNFTBalance);
    let (expectedFinalHolderNFTBalance) = uint256_sub(initialHolderNFTBalance, Uint256(low=nftIds_len, high=0));
    assert_uint256_eq(expectedFinalHolderNFTBalance, finalHolderNFTBalance);
    return ();
}