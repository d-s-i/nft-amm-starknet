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

const TOKEN_ID = 1;

@contract_interface
namespace NFTPairFactory {
    func createPairERC20(
        _erc20Address: felt,
        _nftAddress: felt,
        _bondingCurve: felt,
        _assetRecipient: felt,
        _poolType: felt,
        _delta: Uint256,
        _fee: felt,
        _spotPrice: Uint256,
        _initialNFTIDs_len: felt,
        _initialNFTIDs: Uint256*,
        initialERC20Balance: Uint256
    ) -> (pairAddress: felt) {
    }
    func setBondingCurveAllowed(
        bondingCurveAddress: felt,
        isAllowed: felt
    ) {
    }
    func getProtocolFeeMultiplier() -> (res: Uint256) {
    }
}

@contract_interface
namespace NFTPairERC20 {
    func getSellNFTQuote(
        numNFTs: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        outputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
}

@contract_interface
namespace NFTPairMissingEnumerableERC20 {
    func swapTokenForAnyNFTs(
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }

    func swapTokenForSpecificNFTs(
        nftIds_len: felt,
        nftIds: Uint256*,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }

    func swapNFTsForToken(
        nftIds_len: felt,
        nftIds: Uint256*,
        minExpectedTokenOutput: Uint256,
        tokenRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
    }
    func getBuyNFTQuote(numNFTs: Uint256) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        inputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
    func getSellNFTQuote(numNFTs: Uint256) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        outputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
    func getAllHeldIds() -> (tokenIds_len: felt, tokenIds: Uint256*) {
    }
    func getBondingCurve() -> (res: felt) {
    }
    func getFactory() -> (res: felt) {
    }
    func getSpotPrice() -> (res: Uint256) {
    }
    func getDelta() -> (res: Uint256) {
    }
    func getFee() -> (res: felt) {
    }
}

@contract_interface
namespace ERC20 {
    func allowance(
        owner: felt, spender: felt
    ) -> (remaining: Uint256) {
    }
    func mint(to: felt, amount: Uint256) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
    func test() -> (caller: felt) {
    }
}

@contract_interface
namespace ERC721 {
    func mint(to: felt, tokenId: Uint256) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}

@contract_interface
namespace ICurve {
    func getSellInfo(
        spotPrice: Uint256,
        delta: Uint256,
        numItems: Uint256,
        feeMultiplier: felt,
        protocolFeeMultiplier: Uint256
    ) -> (
        error: felt,
        newSpotPrice: Uint256,
        newDelta: Uint256,
        outputAmount: Uint256,
        protocolFee: Uint256
    ) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    local factoryAddr;
    local bondingCurveAddr;
    local erc721AddrForSpecificSwap;
    local erc721AddrForAnySwap;
    local erc721AddrForSell;
    local erc20AddrForSpecificSwap;
    local erc20AddrForAnySwap;
    local erc20AddrForSell;
    %{ 
        print("Starting setup")
        # context.accountAddr = ids.accountAddr
        ids.accountAddr = deploy_contract("./contracts/mocks/Account.cairo", [0]).contract_address
        context.accountAddr = ids.accountAddr
        
        # Deploy factory
        # NFTPairEnumerableERC20ClassHash = declare("./contracts/NFTPairEnumerableERC20.cairo").class_hash
        NFTPairMissingEnumerableERC20ClassHash = declare("./contracts/NFTPairMissingEnumerableERC20.cairo").class_hash
        context.factoryAddr = deploy_contract(
            "./contracts/NFTPairFactory.cairo", 
            [
                NFTPairMissingEnumerableERC20ClassHash, # Need to change for NFTPairEnumerableERC20ClassHash once prepared 
                NFTPairMissingEnumerableERC20ClassHash, 
                0, 
                0,
                ids.accountAddr
            ]
        ).contract_address
        ids.factoryAddr = context.factoryAddr

        # Deploy curve
        context.bondingCurveAddr = deploy_contract("./contracts/bonding_curves/LinearCurve.cairo").contract_address
        ids.bondingCurveAddr = context.bondingCurveAddr

        # Deploy tokens
        context.erc20AddrForSpecificSwap = deploy_contract(
            "./contracts/mocks/ERC20.cairo", 
            [0, 0, 18, 1000000000000000000000, 0, context.accountAddr, context.accountAddr]
        ).contract_address
        ids.erc20AddrForSpecificSwap = context.erc20AddrForSpecificSwap
        context.erc20AddrForAnySwap = deploy_contract(
            "./contracts/mocks/ERC20.cairo", 
            [0, 0, 18, 1000000000000000000000, 0, context.accountAddr, context.accountAddr]
        ).contract_address
        ids.erc20AddrForAnySwap = context.erc20AddrForAnySwap
        context.erc20AddrForSell = deploy_contract(
            "./contracts/mocks/ERC20.cairo", 
            [0, 0, 18, 1000000000000000000000, 0, context.accountAddr, context.accountAddr]
        ).contract_address
        ids.erc20AddrForSell = context.erc20AddrForSell

        context.erc721AddrForSpecificSwap = deploy_contract(
            "./contracts/mocks/ERC721.cairo",
            [0, 0, ids.accountAddr]
        ).contract_address
        ids.erc721AddrForSpecificSwap = context.erc721AddrForSpecificSwap
        context.erc721AddrForAnySwap = deploy_contract(
            "./contracts/mocks/ERC721.cairo",
            [0, 0, ids.accountAddr]
        ).contract_address
        ids.erc721AddrForAnySwap = context.erc721AddrForAnySwap
        context.erc721AddrForSell = deploy_contract(
            "./contracts/mocks/ERC721.cairo",
            [0, 0, ids.accountAddr]
        ).contract_address
        ids.erc721AddrForSell = context.erc721AddrForSell

        print(f"factoryAddr: {context.factoryAddr} (hex: {hex(context.factoryAddr)})")
        print(f"bondingCurveAddr: {context.bondingCurveAddr} (hex: {hex(context.bondingCurveAddr)})")
        print(f"erc20AddrForAnySwap: {context.erc20AddrForAnySwap} (hex: {hex(context.erc20AddrForAnySwap)})")
        print(f"erc20AddrForSpecificSwap: {context.erc20AddrForSpecificSwap} (hex: {hex(context.erc20AddrForSpecificSwap)})")
        print(f"erc20AddrForSell: {context.erc20AddrForSell} (hex: {hex(context.erc20AddrForSell)})")
        print(f"erc721AddrForAnySwap: {context.erc721AddrForAnySwap} (hex: {hex(context.erc721AddrForAnySwap)})")
        print(f"erc721AddrForSpecificSwap: {context.erc721AddrForSpecificSwap} (hex: {hex(context.erc721AddrForSpecificSwap)})")
        print(f"erc721AddrForSell: {context.erc721AddrForSell} (hex: {hex(context.erc721AddrForSell)})")
        print(f"accountAddr: {context.accountAddr} (hex: {hex(context.accountAddr)})")
    %}

    %{stop_prank_factory = start_prank(context.accountAddr, context.factoryAddr)%}
    NFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
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

    ERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{stop_prank_erc20()%}

    let (initialPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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
    ) = NFTPairMissingEnumerableERC20.getBuyNFTQuote(pairAddress, Uint256(low=1, high=0));
    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"inputAmount: {ids.inputAmount.low + ids.inputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = NFTPairMissingEnumerableERC20.getAllHeldIds(pairAddress);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    let numNFTs = Uint256(low=1, high=0);
    NFTPairMissingEnumerableERC20.swapTokenForAnyNFTs(
        pairAddress,
        numNFTs,
        Uint256(low=MAX_UINT_128, high=0),
        accountAddr,
        0,
        0
    );

    let (finalPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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

    ERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{stop_prank_erc20()%}

    let (initialPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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
    ) = NFTPairMissingEnumerableERC20.getBuyNFTQuote(pairAddress, Uint256(low=1, high=0));
    %{
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"inputAmount: {ids.inputAmount.low + ids.inputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = NFTPairMissingEnumerableERC20.getAllHeldIds(pairAddress);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    let nftIds_len = 1;
    NFTPairMissingEnumerableERC20.swapTokenForSpecificNFTs(
        pairAddress,
        nftIds_len,
        cast(new (Uint256(low=1, high=0),), Uint256*),
        MAX_UINT_256,
        accountAddr,
        0,
        0
    );

    let (finalPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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
    ERC721.mint(erc721Addr, accountAddr, soldTokenId);
    ERC20.mint(erc20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=0));
    %{
        stop_prank_erc20()
        stop_prank_erc721()
    %}

    let (initialPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    let (initialHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (initialHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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
    ) = NFTPairMissingEnumerableERC20.getSellNFTQuote(pairAddress, Uint256(low=nftIds_len, high=0));
    %{
        print("\ngetSellNFTQuote")
        print(f"error: {ids.error}")
        print(f"newSpotPrice: {ids.newSpotPrice.low + ids.newSpotPrice.high}")
        print(f"newDelta: {ids.newDelta.low + ids.newDelta.high}")
        print(f"outputAmount: {ids.outputAmount.low + ids.outputAmount.high}")
        print(f"protocolFee: {ids.protocolFee.low + ids.protocolFee.high}")
        print("\n")
    %}

    let (tokenIdsPair_len, tokenIdsPair) = NFTPairMissingEnumerableERC20.getAllHeldIds(pairAddress);
    %{
        tokenIdsPairLen = ids.tokenIdsPair_len
        print(f"tokenIdsPairLen: {tokenIdsPairLen}")
    %}

    NFTPairMissingEnumerableERC20.swapNFTsForToken(
        contract_address=pairAddress,
        nftIds_len=nftIds_len,
        nftIds=cast(new (soldTokenId,), Uint256*),
        minExpectedTokenOutput=Uint256(low=5, high=0),
        tokenRecipient=accountAddr,
        isRouter=0,
        routerCaller=0
    );

    let (finalPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (finalPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
        print(f"finialPairNFTBalance: {ids.finalPairNFTBalance.low + ids.finalPairNFTBalance.high}")
    %}

    let (finalHolderTokenBalance) = ERC20.balanceOf(erc20Addr, accountAddr);
    let (finalHolderNFTBalance) = ERC721.balanceOf(erc721Addr, accountAddr);
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


////////////////
/// Helpers 

func deployPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    accountAddr: felt,
    factoryAddr: felt,
    erc20Addr: felt,
    erc721Addr: felt,
    bondingCurveAddr: felt,
    poolType: felt,
    initialNFTId: felt,
    initialERC20Balance: Uint256
) -> (pairAddress: felt) {

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);

    let initialNFTIdUint = Uint256(low=initialNFTId, high=0);
    %{
        stop_prank_factory = start_prank(ids.accountAddr, ids.factoryAddr)
        stop_prank_erc721 = start_prank(context.accountAddr, ids.erc721Addr)

        # Set allowances    
        store(ids.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [ids.accountAddr, ids.factoryAddr])
        store(ids.erc721Addr, "ERC721_operator_approvals", [1], [ids.accountAddr, ids.factoryAddr])
    %}
    ERC721.mint(erc721Addr, accountAddr, initialNFTIdUint);
    
    let (pairAddress) = NFTPairFactory.createPairERC20(
        contract_address=factoryAddr,
        _erc20Address=erc20Addr,
        _nftAddress=erc721Addr,
        _bondingCurve=bondingCurveAddr,
        _assetRecipient=0,
        _poolType=poolType,
        _delta=Uint256(low=0, high=0),
        _fee=0,
        _spotPrice=Uint256(low=10, high=0),
        _initialNFTIDs_len=1,
        _initialNFTIDs=cast(new (initialNFTIdUint,), Uint256*),
        initialERC20Balance=initialERC20Balance
    );

    %{
        stop_prank_factory()
        stop_prank_erc721()
    %}

    return (pairAddress=pairAddress);
}