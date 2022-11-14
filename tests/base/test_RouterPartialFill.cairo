// Seem to be ununsed by the sudoswap team, skipping tests for now
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

from tests.test_cases.RouterPartialFill.params import (
    feeRecipient,
    protocolFeeMultiplier,
    numInitialNFTs
)

//
// Setup
// 

from tests.mixins.UsingEnumerable import (TokenImplementation)
from tests.mixins.UsingERC20 import (TokenStandard)
from tests.mixins.UsingLinearCurve import (Curve)

@storage_var
func SPOT_PRICE() -> (res: Uint256) {
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    let (
        accountAddr,
        bondingCurveAddr,
        erc721Addr,
        factoryAddr,
        routerAddr,
        pairAddr
    ) = setupTest();

    return ();
}

@external
func test_defaultFullFill{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    return ();
}

func defaultFullFill_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt
) {
    if(start == end + 1) {
        return ();
    }
    let (
        accountAddr,
        bondingCurveAddr,
        erc721Addr,
        factoryAddr,
        routerAddr,
        pairAddr
    ) = setupTest();

    let NUM_NFTS = start;
    let (startNFTBalance) = IERC721.balanceOf(
        contract_address=erc721Addr,
        owner=accountAddr
    );
}

func setupTest{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (
    accountAddr: felt,
    bondingCurveAddr: felt,
    erc721Addr: felt,
    factoryAddr: felt,
    routerAddr: felt,
    pairAddr: felt
) {
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

    let (emptyNFTIds: Uint256*) = alloc();
    let (spotPrice, delta) = Curve.getParamsForPartialFillTest();
    SPOT_PRICE.write(spotPrice);
    let (pairAddr) = TokenStandard.setupPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        routerAddr=routerAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=0,
        initialNFTIds=emptyNFTIds,
        initialERC20Balance=Uint256(low=10*10**18, high=0),
        spotPrice=spotPrice,
        delta=delta
    );

    let (nftIdsToPair: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=erc721Addr,
        start=10,
        nftIds_len=20,
        nftIds_ptr=nftIdsToPair,
        mintTo=pairAddr,
        contractOwner=accountAddr
    );
    return (
        accountAddr=accountAddr
        bondingCurveAddr=bondingCurveAddr
        erc721Addr=erc721Addr
        factoryAddr=factoryAddr
        routerAddr=routerAddr
        pairAddr=pairAddr
    );
}