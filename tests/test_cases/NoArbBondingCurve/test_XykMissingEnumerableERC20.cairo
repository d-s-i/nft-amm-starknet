%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.bool import (FALSE, TRUE)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_add,
    uint256_sub,
    uint256_unsigned_div_rem,
    uint256_eq,
    assert_uint256_eq,
    assert_uint256_le
)
from starkware.starknet.common.syscalls import (get_contract_address, get_block_timestamp)

from contracts.mocks.libraries.library_account import (Account)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.IRouter import (IRouter)
from contracts.interfaces.bonding_curves.ICurve import (ICurve)

from contracts.constants.structs import (PoolType)
from contracts.constants.library import (MAX_UINT_128)

from contracts.libraries.felt_uint import (FeltUint)

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
    displayIdsAndOwners
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
from tests.mixins.UsingXykCurve import (Curve)

@storage_var
func spotPrice() -> (res: Uint256) {
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
    let (initialAmount) = FeltUint.feltToUint256(2**252 - 1);
    let (erc20Addr, _, erc1155Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=initialAmount,
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
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);

    return ();
}

@external
func setup_bondingCurveSellBuyNoProfit() {
    %{
        given(
            # uint56
            _spotPrice = strategy.integers(0, 72057594037927935),
            # uint64
            _delta = strategy.integers(0, 18446744073709551615),
            # uint8
            _numItems = strategy.integers(0, 255)
        )
    %}
    return ();
}

@external
func setup_bondingCurveBuySellNoProfit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    %{
        given(
            # uint56
            _spotPrice = strategy.integers(0, 72057594037927935),
            # uint64
            _delta = strategy.integers(0, 18446744073709551615),
            # uint8
            _numItems = strategy.integers(0, 255)
        )
    %}
    return ();
}

@external
func test_bondingCurveSellBuyNoProfit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    local accountAddr;
    local factoryAddr;
    local bondingCurveAddr;
    local erc721Addr;
    local erc20Addr;
    %{
        ids.accountAddr = context.accountAddr
        ids.factoryAddr = context.factoryAddr
        ids.bondingCurveAddr = context.bondingCurveAddr
        ids.erc721Addr = context.erc721Addr
        ids.erc20Addr = context.erc20Addr
    %}

    let (_spotPriceUint) = FeltUint.feltToUint256(_spotPrice);
    let (_deltaUint) = FeltUint.feltToUint256(_delta);
    let (modifiedSpotPrice) = Curve.modifySpotPrice(_spotPriceUint);
    let (delta) = Curve.modifyDelta(_deltaUint);

    let (_, numItems) = uint256_unsigned_div_rem(Uint256(low=_numItems, high=0), Uint256(low=3, high=0));
    let (numItemsEqZero) = uint256_eq(numItems, Uint256(low=0, high=0));

    if(numItemsEqZero == TRUE) {
        return ();
    }
    
    let (emptyNftIds: Uint256*) = alloc();
    let (pairAddr) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=0,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=0,
        initialNFTIds=emptyNftIds,
        initialERC20Balance=Uint256(low=0, high=0),
        spotPrice=modifiedSpotPrice,
        delta=delta
    );
    let (nftIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=0,
        nftIds_len=numItems.low,
        nftIds_ptr=nftIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );
    // %{print(f"erc721Addr: {ids.erc721Addr}")%}
    // displayIdsAndOwners(nftIds, erc721Addr, 0, numItems.low);

    let (
        error,
        newSpotPriceSell,
        newDeltaSell,
        outputAmount,
        protocolFee
    ) = ICurve.getSellInfo(
        contract_address=bondingCurveAddr,
        spotPrice=modifiedSpotPrice,
        delta=delta,
        numItems=numItems,
        feeMultiplier=0,
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0)
    );
    let (minAmount, minAmountCarry) = uint256_add(outputAmount, protocolFee);
    setERC20Allowance(
        erc20Addr=erc20Addr,
        spender=accountAddr,
        operator=accountAddr,
        allowance=Uint256(low=MAX_UINT_128, high=MAX_UINT_128)
    );
    TokenStandard.sendTokens(
        erc20Addr=erc20Addr,
        from_=accountAddr,
        to=pairAddr,
        amount=minAmount
    );
    setERC721Allowance(
        erc721Addr=erc721Addr,
        spender=accountAddr,
        operator=pairAddr
    );
    let (startBalance) = TokenStandard.getBalance(
        erc20Addr=erc20Addr,
        account=accountAddr
    );
    INFTPair.swapNFTsForToken(
        contract_address=pairAddr,
        // assume numItems < 2**128 - 1 (enforced by strategy)
        nftIds_len=numItems.low,
        nftIds=nftIds,
        minExpectedTokenOutput=Uint256(low=0, high=0),
        tokenRecipient=accountAddr,
        isRouter=FALSE,
        routerCaller=0
    );
    spotPrice.write(newSpotPriceSell);

    let (
        error,
        newSpotPriceBuy,
        newDeltaBuy,
        inputAmount,
        protocolFee
    ) = ICurve.getBuyInfo(
        contract_address=bondingCurveAddr,
        spotPrice=newSpotPriceSell,
        delta=newDeltaSell,
        numItems=numItems,
        feeMultiplier=0,
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0)
    );
    setERC20Allowance(
        erc20Addr=erc20Addr,
        spender=accountAddr,
        operator=pairAddr,
        allowance=Uint256(low=MAX_UINT_128, high=MAX_UINT_128)
    );
    INFTPair.swapTokenForAnyNFTs(
        contract_address=pairAddr,
        numNFTs=numItems,
        maxExpectedTokenInput=inputAmount,
        nftRecipient=accountAddr,
        isRouter=FALSE,
        routerCaller=0
    );
    let (endBalance) = TokenStandard.getBalance(
        erc20Addr=erc20Addr,
        account=accountAddr
    );

    assert_uint256_le(endBalance, startBalance);
    return ();
}

@external
func test_bondingCurveBuySellNoProfit{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _spotPrice: felt,
    _delta: felt,
    _numItems: felt
) {
    alloc_locals;

    local accountAddr;
    local factoryAddr;
    local bondingCurveAddr;
    local erc721Addr;
    local erc20Addr;
    %{
        ids.accountAddr = context.accountAddr
        ids.factoryAddr = context.factoryAddr
        ids.bondingCurveAddr = context.bondingCurveAddr
        ids.erc721Addr = context.erc721Addr
        ids.erc20Addr = context.erc20Addr
    %}

    let (_spotPriceUint) = FeltUint.feltToUint256(_spotPrice);
    let (_deltaUint) = FeltUint.feltToUint256(_delta);
    let (modifiedSpotPrice) = Curve.modifySpotPrice(_spotPriceUint);
    let (delta) = Curve.modifyDelta(_deltaUint);

    let (_, numItems) = uint256_unsigned_div_rem(Uint256(low=_numItems, high=0), Uint256(low=3, high=0));
    let (numItemsEqZero) = uint256_eq(numItems, Uint256(low=0, high=0));

    if(numItemsEqZero == TRUE) {
        return ();
    }
    
    let (nftIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=0,
        nftIds_len=numItems.low,
        nftIds_ptr=nftIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );
    let (pairAddr) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=0,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=numItems.low,
        initialNFTIds=nftIds,
        initialERC20Balance=Uint256(low=0, high=0),
        spotPrice=modifiedSpotPrice,
        delta=delta
    );
    setERC721Allowance(
        erc721Addr=erc721Addr,
        spender=accountAddr,
        operator=pairAddr
    );

    let (
        error,
        newSpotPriceBuy,
        newDeltaBuy,
        inputAmount,
        protocolFee
    ) = ICurve.getBuyInfo(
        contract_address=bondingCurveAddr,
        spotPrice=modifiedSpotPrice,
        delta=delta,
        numItems=numItems,
        feeMultiplier=0,
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0)
    );
    setERC20Allowance(
        erc20Addr=erc20Addr,
        spender=accountAddr,
        operator=pairAddr,
        allowance=Uint256(low=MAX_UINT_128, high=MAX_UINT_128)
    );
    let (startBalance) = TokenStandard.getBalance(
        erc20Addr=erc20Addr,
        account=accountAddr
    );
    INFTPair.swapTokenForAnyNFTs(
        contract_address=pairAddr,
        numNFTs=numItems,
        maxExpectedTokenInput=inputAmount,
        nftRecipient=accountAddr,
        isRouter=FALSE,
        routerCaller=0
    );

    let (
        error,
        newSpotPriceSell,
        newDeltaSell,
        outputAmount,
        protocolFee
    ) = ICurve.getSellInfo(
        contract_address=bondingCurveAddr,
        spotPrice=newSpotPriceBuy,
        delta=newDeltaBuy,
        numItems=numItems,
        feeMultiplier=0,
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0)
    );
    INFTPair.swapNFTsForToken(
        contract_address=pairAddr,
        // assume numItems < 2**128 - 1 (enforced by strategy)
        nftIds_len=numItems.low,
        nftIds=nftIds,
        minExpectedTokenOutput=Uint256(low=0, high=0),
        tokenRecipient=accountAddr,
        isRouter=FALSE,
        routerCaller=0
    );

    let (endBalance) = TokenStandard.getBalance(
        erc20Addr=erc20Addr,
        account=accountAddr
    );

    assert_uint256_le(endBalance, startBalance);

    return ();
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return Account.supports_interface(interfaceId);
}