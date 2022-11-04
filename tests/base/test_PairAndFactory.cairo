%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address)
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    assert_uint256_eq
)

from contracts.constants.structs import (PoolType)
from contracts.constants.library import (MAX_UINT_128)

from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)

from tests.utils.library import (setBondingCurveAllowed, _mintERC721)
from tests.utils.Deployments import (
    CurveId,
    deployAccount,
    deployCurve,
    deployFactory,
    deployTokens,
    deployPair
)

// 1.1 ether
const delta = 11*10**17;
// 1 ether
const spotPrice = 10**18;
// 10 ether
const tokenAmount = 10*10**18;
const numItems = 2;
const protocolFeeMultiplier = 3*10**15;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    let (accountAddr) = deployAccount(0);
    %{
        context.accountAddr = ids.accountAddr
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}
    let (bondingCurveAddr) = deployCurve(CurveId.Linear);
    %{context.bondingCurveAddr = ids.bondingCurveAddr%}
    let (factoryAddr) = deployFactory(
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0), 
        ownerAddress=accountAddr
    );
    %{
        context.factoryAddr = ids.factoryAddr
        print(f"factoryAddr: {ids.factoryAddr}")
    %}
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);
    let (erc20Addr, erc721Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000*10**18, high=0),
        owner=accountAddr
    );
    %{
        context.erc20Addr = ids.erc20Addr
        print(f"erc20Addr: {ids.erc20Addr}")
        context.erc721Addr = ids.erc721Addr
        print(f"erc721Addr: {ids.erc721Addr}")
    %}
    let (pairAddr) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=numItems,
        initialERC20Balance=Uint256(low=100, high=0),
        spotPrice=Uint256(low=spotPrice, high=0),
        delta=Uint256(low=delta, high=0)
    );
    %{
        context.pairAddr = ids.pairAddr
        print(f"pairAddr: {ids.pairAddr}")
    %}
    return ();
}

@external
func setup_rescueTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local accountAddr;
    local pairAddr;
    %{
        ids.accountAddr = context.accountAddr
        ids.pairAddr = context.pairAddr
    %}
    let (newERC20Addr, newERC721Addr) = deployTokens(18, Uint256(low=1000, high=0), accountAddr);
    %{
        context.newERC20Addr = ids.newERC20Addr
        context.newERC721Addr = ids.newERC721Addr
    %}
    local tokenId: Uint256 = Uint256(low=18, high=0);
    local erc20Amount: Uint256 = Uint256(low=10, high=0);
    %{
        context.tokenId = ids.tokenId
        context.erc20Amount = ids.erc20Amount
    %}
    let (nftIds: Uint256*) = alloc();
    _mintERC721(
        erc721Addr=newERC721Addr,
        start=tokenId.low - 1,
        nftIds_len=tokenId.low,
        nftIds=nftIds,
        mintTo=accountAddr,
        contractOwner=accountAddr
    );

    %{
        stop_prank_erc721 = start_prank(ids.accountAddr, ids.newERC721Addr)
        stop_prank_erc20 = start_prank(ids.accountAddr, ids.newERC20Addr)
    %}
    IERC721.transferFrom(
        newERC721Addr,
        accountAddr,
        pairAddr,
        tokenId
    );
    IERC20.approve(newERC20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=MAX_UINT_128));
    IERC20.transferFrom(
        newERC20Addr,
        accountAddr,
        pairAddr,
        erc20Amount
    );
    %{
        stop_prank_erc721()
        stop_prank_erc20()
    %}

    return ();
}

// @external
// func test_transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;
    
//     tempvar pairAddr;
//     %{ids.pairAddr = context.pairAddr%}
//     let (initialOwner) = INFTPair.owner(pairAddr);
//     let newOwner = 58;

//     %{stop_pair_prank = start_prank(context.accountAddr, context.pairAddr)%}
//     INFTPair.transferOwnership(pairAddr, newOwner);

//     let (finalOwner) = INFTPair.owner(pairAddr);
//     with_attr error_mesage("PairAndFactory::transferOwnership - Owner not set correctly") {
//         assert finalOwner = newOwner;
//     }

//     return ();
// }

@external
func test_rescueTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local newERC20Addr;
    local newERC721Addr;
    local tokenId: Uint256;
    local erc20Amount: Uint256;
    %{
        ids.pairAddr = context.pairAddr
        ids.newERC20Addr = context.newERC20Addr
        print(f"newERC20Addr: {context.newERC20Addr}")
        ids.newERC721Addr = context.newERC721Addr
        print(f"newERC721Addr: {context.newERC721Addr}")

        ids.tokenId.low, ids.tokenId.high = [context.tokenId.low, context.tokenId.high]
        ids.erc20Amount.low, ids.erc20Amount.high = [context.erc20Amount.low, context.erc20Amount.high]
    %}

    let (initialERC20Balance) = IERC20.balanceOf(
        contract_address=newERC20Addr,
        owner=pairAddr
    );
    let (initialERC721Balance) = IERC721.balanceOf(
        contract_address=newERC721Addr,
        owner=pairAddr   
    );
    let tokenIdsToWithdraw_len = 1;
    local tokenIdsToWithdraw: Uint256* = cast(new (Uint256(low=tokenId.low, high=tokenId.high),), Uint256*);
    let erc20AmountToWithraw = initialERC20Balance;

    %{stop_pair_prank = start_prank(context.accountAddr, context.pairAddr)%}
    INFTPair.withdrawERC20(
        contract_address=pairAddr,
        _erc20Address=newERC20Addr,
        amount=erc20AmountToWithraw
    );
    INFTPair.withdrawERC721(
        contract_address=pairAddr,
        _nftAddress=newERC721Addr,
        tokenIds_len=tokenIdsToWithdraw_len,
        tokenIds=tokenIdsToWithdraw
    );
    %{stop_pair_prank()%}

    let (finalERC20Balance) = IERC20.balanceOf(
        contract_address=newERC20Addr,
        owner=pairAddr
    );
    let (finalERC721Balance) = IERC721.balanceOf(
        contract_address=newERC721Addr,
        owner=pairAddr
    );

    let (expectedERC721Balance) = uint256_sub(initialERC721Balance, Uint256(low=tokenIdsToWithdraw_len, high=0));
    let (expectedERC20Balance) = uint256_sub(initialERC20Balance, erc20AmountToWithraw);
    
    with_attr error_mesage("PairAndFactory::test_rescueTokens - Incorrect final ERC20 balance") {
        assert_uint256_eq(finalERC20Balance, expectedERC20Balance);
    }

    with_attr error_mesage("PairAndFactory::test_rescueTokens - Incorrect final ERC721 balance") {
        assert_uint256_eq(finalERC721Balance, expectedERC721Balance);
    }

    return ();
}

// @external
// func test_tradePoolChangeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;
//     local pairAddr;
//     %{ids.pairAddr = context.pairAddr%}
//     %{expect_revert()%}
//     return ();
// }