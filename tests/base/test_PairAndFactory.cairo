%lang starknet

// Don't forget to import the correct libraries

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
from contracts.interfaces.tokens.IERC1155 import (IERC1155)

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
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
    %}
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);
    let (erc20Addr, erc721Addr, erc1155Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000*10**18, high=0),
        owner=accountAddr
    );
    %{
        context.erc20Addr = ids.erc20Addr
        print(f"erc20Addr: {ids.erc20Addr} (hex: {hex(ids.erc20Addr)})")
        context.erc721Addr = ids.erc721Addr
        print(f"erc721Addr: {ids.erc721Addr} (hex: {hex(ids.erc721Addr)})")
        context.erc1155Addr = ids.erc1155Addr
        print(f"erc1155Addr: {ids.erc1155Addr} (hex: {hex(ids.erc1155Addr)})")

    %}
    let (pairAddr) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=numItems,
        initialERC20Balance=Uint256(low=tokenAmount, high=0),
        spotPrice=Uint256(low=spotPrice, high=0),
        delta=Uint256(low=delta, high=0)
    );
    %{
        context.pairAddr = ids.pairAddr
        print(f"pairAddr: {ids.pairAddr} (hex: {hex(ids.pairAddr)})")
    %}
    return ();
}

// @external
// func setup_rescueTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local accountAddr;
//     local pairAddr;
//     %{
//         ids.accountAddr = context.accountAddr
//         ids.pairAddr = context.pairAddr
//     %}
//     let (newERC20Addr, newERC721Addr) = deployTokens(18, Uint256(low=1000, high=0), accountAddr);
//     %{
//         context.newERC20Addr = ids.newERC20Addr
//         context.newERC721Addr = ids.newERC721Addr
//     %}
//     local tokenId: Uint256 = Uint256(low=18, high=0);
//     local erc20Amount: Uint256 = Uint256(low=10, high=0);
//     %{
//         context.tokenId = ids.tokenId
//         context.erc20Amount = ids.erc20Amount
//     %}
//     let (nftIds: Uint256*) = alloc();
//     _mintERC721(
//         erc721Addr=newERC721Addr,
//         start=tokenId.low - 1,
//         nftIds_len=tokenId.low,
//         nftIds=nftIds,
//         mintTo=accountAddr,
//         contractOwner=accountAddr
//     );

//     %{
//         stop_prank_erc721 = start_prank(ids.accountAddr, ids.newERC721Addr)
//         stop_prank_erc20 = start_prank(ids.accountAddr, ids.newERC20Addr)
//     %}
//     IERC721.transferFrom(
//         newERC721Addr,
//         accountAddr,
//         pairAddr,
//         tokenId
//     );
//     IERC20.approve(newERC20Addr, accountAddr, Uint256(low=MAX_UINT_128, high=MAX_UINT_128));
//     IERC20.transferFrom(
//         newERC20Addr,
//         accountAddr,
//         pairAddr,
//         erc20Amount
//     );
//     %{
//         stop_prank_erc721()
//         stop_prank_erc20()
//     %}

//     return ();
// }

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

// @external
// func test_rescueTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local pairAddr;
//     local newERC20Addr;
//     local newERC721Addr;
//     local tokenId: Uint256;
//     local erc20Amount: Uint256;
//     %{
//         ids.pairAddr = context.pairAddr
//         ids.newERC20Addr = context.newERC20Addr
//         print(f"newERC20Addr: {context.newERC20Addr}")
//         ids.newERC721Addr = context.newERC721Addr
//         print(f"newERC721Addr: {context.newERC721Addr}")

//         ids.tokenId.low, ids.tokenId.high = [context.tokenId.low, context.tokenId.high]
//         ids.erc20Amount.low, ids.erc20Amount.high = [context.erc20Amount.low, context.erc20Amount.high]
//     %}

//     let (initialERC20Balance) = IERC20.balanceOf(
//         contract_address=newERC20Addr,
//         owner=pairAddr
//     );
//     let (initialERC721Balance) = IERC721.balanceOf(
//         contract_address=newERC721Addr,
//         owner=pairAddr   
//     );
//     let tokenIdsToWithdraw_len = 1;
//     local tokenIdsToWithdraw: Uint256* = cast(new (Uint256(low=tokenId.low, high=tokenId.high),), Uint256*);
//     let erc20AmountToWithraw = initialERC20Balance;

//     %{stop_pair_prank = start_prank(context.accountAddr, context.pairAddr)%}
//     INFTPair.withdrawERC20(
//         contract_address=pairAddr,
//         _erc20Address=newERC20Addr,
//         amount=erc20AmountToWithraw
//     );
//     INFTPair.withdrawERC721(
//         contract_address=pairAddr,
//         _nftAddress=newERC721Addr,
//         tokenIds_len=tokenIdsToWithdraw_len,
//         tokenIds=tokenIdsToWithdraw
//     );
//     %{stop_pair_prank()%}

//     let (finalERC20Balance) = IERC20.balanceOf(
//         contract_address=newERC20Addr,
//         owner=pairAddr
//     );
//     let (finalERC721Balance) = IERC721.balanceOf(
//         contract_address=newERC721Addr,
//         owner=pairAddr
//     );

//     let (expectedERC721Balance) = uint256_sub(initialERC721Balance, Uint256(low=tokenIdsToWithdraw_len, high=0));
//     let (expectedERC20Balance) = uint256_sub(initialERC20Balance, erc20AmountToWithraw);
    
//     with_attr error_mesage("PairAndFactory::test_rescueTokens - Incorrect final ERC20 balance") {
//         assert_uint256_eq(finalERC20Balance, expectedERC20Balance);
//     }

//     with_attr error_mesage("PairAndFactory::test_rescueTokens - Incorrect final ERC721 balance") {
//         assert_uint256_eq(finalERC721Balance, expectedERC721Balance);
//     }

//     return ();
// }

// @external
// func test_tradePoolChangeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;
//     local pairAddr;
//     %{
//         ids.pairAddr = context.pairAddr
//         stop_prank_pair = start_prank(context.accountAddr, context.pairAddr)
//         expect_revert()
//     %}
//     INFTPair.changeAssetRecipient(pairAddr, 55);
//     return ();
// }

// @external
// func test_tradePoolChangeAssetRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;
//     local pairAddr;
//     %{
//         ids.pairAddr = context.pairAddr
//         stop_prank_pair = start_prank(context.accountAddr, context.pairAddr)
//         expect_revert()
//     %}
//     INFTPair.changeFee(pairAddr, 100*10**18);
//     return ();
// }

// @external
// func test_verifyPoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local accountAddr;
//     local pairAddr;
//     local bondingCurveAddr;
//     local erc721Addr;
//     local erc20Addr;
//     %{
//         ids.accountAddr = context.accountAddr
//         ids.pairAddr = context.pairAddr
//         ids.bondingCurveAddr = context.bondingCurveAddr
//         ids.erc721Addr = context.erc721Addr
//         ids.erc20Addr = context.erc20Addr
//     %}

//     let (nftAddress) = INFTPair.getNFTAddress(pairAddr);
//     let (bondingCurve) = INFTPair.getBondingCurve(pairAddr);
//     let (poolType) = INFTPair.getPoolType(pairAddr);
//     let (_delta) = INFTPair.getDelta(pairAddr);
//     let (_spotPrice) = INFTPair.getSpotPrice(pairAddr);
//     let (owner) = INFTPair.owner(pairAddr);
//     let (fee) = INFTPair.getFee(pairAddr);
//     let (_assetRecipient) = INFTPair.getAssetRecipientStorage(pairAddr);
//     let (assetRecipient) = INFTPair.getAssetRecipient(pairAddr);
//     let (erc20Balance) = IERC20.balanceOf(erc20Addr, pairAddr);
//     let (nftOwner) = IERC721.ownerOf(erc721Addr, Uint256(low=1, high=0));

//     assert nftAddress = erc721Addr;
//     assert bondingCurve = bondingCurveAddr;
//     assert poolType = PoolType.TRADE;
//     assert_uint256_eq(_delta, Uint256(low=delta, high=0));
//     assert_uint256_eq(_spotPrice, Uint256(low=spotPrice, high=0));
//     assert owner = accountAddr;
//     assert fee = 0;
//     assert _assetRecipient = 0;
//     assert assetRecipient = pairAddr;
//     assert_uint256_eq(erc20Balance, Uint256(low=tokenAmount, high=0));
//     assert nftOwner = pairAddr;

//     return ();
// }

// @external
// func test_verifyPoolParams{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local accountAddr;
//     local pairAddr;
//     %{
//         ids.accountAddr = context.accountAddr
//         ids.pairAddr = context.pairAddr

//         stop_pair_prank = start_prank(context.accountAddr, context.pairAddr)
//     %}

//     let newSpotPrice = Uint256(low=2*10**18, high=0);
//     INFTPair.changeSpotPrice(pairAddr, newSpotPrice);
//     let (spotPrice) = INFTPair.getSpotPrice(pairAddr);
//     assert_uint256_eq(spotPrice, newSpotPrice);

//     let newDelta = Uint256(low=22*10**17, high=0);
//     INFTPair.changeDelta(pairAddr, newDelta);
//     let (delta) = INFTPair.getDelta(pairAddr);
//     assert_uint256_eq(delta, newDelta);

//     let newFee = 2*10**17;
//     INFTPair.changeFee(pairAddr, newFee);
//     let (fee) = INFTPair.getFee(pairAddr);
//     assert fee = newFee;

//     %{stop_pair_prank()%} 
    
//     return ();
// }

// @external
// func test_withdraw{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local pairAddr;
//     local erc20Addr;
//     %{
//         ids.pairAddr = context.pairAddr
//         ids.erc20Addr = context.erc20Addr
//     %}
//     library.withdrawTokens(pairAddr);
//     let (erc20Balance) = IERC20.balanceOf(erc20Addr, pairAddr);

//     assert_uint256_eq(erc20Balance, 0);

//     return ();
// }

// @external
// func test_withdrawFail{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
//     alloc_locals;

//     local pairAddr;
//     local erc20Addr;
//     %{
//         ids.pairAddr = context.pairAddr
//         ids.erc20Addr = context.erc20Addr
//     %}
//     INFTPair.transferOwnership(101);
//     %{expect_revert()%}
//     library.withdrawTokens(pairAddr);

//     return ();
// }

// @external
// func test_withdrawERC1155{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;

//     local pairAddr;
//     local accountAddr;
//     local erc1155Addr;
//     %{
//         ids.pairAddr = context.pairAddr
//         ids.accountAddr = context.accountAddr
//         ids.erc1155Addr = context.erc1155Addr

//         stop_pair_prank = start_prank(context.accountAddr, context.pairAddr)
//         stop_erc1155_prank = start_prank(context.accountAddr, context.erc1155Addr)
//     %}
//     let erc1155TokenId = Uint256(low=1, high=0);
//     let erc1155Amount = Uint256(low=2, high=0);
//     IERC1155.mint(
//         contract_address=erc1155Addr,
//         to=pairAddr, 
//         id=erc1155TokenId, 
//         amount=erc1155Amount, 
//         data_len=0, 
//         data=cast(new (0,), felt*)
//     );
//     %{stop_erc1155_prank()%}

//     INFTPair.withdrawERC1155(
//         contract_address=pairAddr,
//         erc1155Addr=erc1155Addr,
//         ids_len=1,
//         ids=cast(new (erc1155TokenId,), Uint256*),
//         amounts_len=1,
//         amounts=cast(new (erc1155Amount,), Uint256*),
//     );
//     %{stop_pair_prank()%}

//     let (pairBalance) = IERC1155.balanceOf(
//         contract_address=erc1155Addr,
//         account=pairAddr,
//         id=erc1155TokenId
//     );
//     let (accountBalance) = IERC1155.balanceOf(
//         contract_address=erc1155Addr,
//         account=accountAddr,
//         id=erc1155TokenId
//     );

//     assert_uint256_eq(pairBalance, Uint256(low=0, high=0));
//     assert_uint256_eq(accountBalance, erc1155Amount);

//     return ();
// }

@external
func test_failRescueERC721NotOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc20Addr;
    local erc721Addr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc20Addr = context.erc20Addr
        ids.erc721Addr = context.erc721Addr

        stop_prank_pair = start_prank(context.accountAddr, context.pairAddr)
    %}
    INFTPair.transferOwnership(pairAddr, 1234);
    %{expect_revert()%}
    INFTPair.withdrawERC721(
        contract_address=pairAddr,
        _nftAddress=newERC721Addr,
        tokenIds_len=tokenIdsToWithdraw_len,
        tokenIds=tokenIdsToWithdraw
    );

    return ();
}


@external
func test_failRescueERC20NotOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local pairAddr;
    local erc20Addr;
    local erc721Addr;
    %{
        ids.pairAddr = context.pairAddr
        ids.erc20Addr = context.erc20Addr
        ids.erc721Addr = context.erc721Addr

        stop_prank_pair = start_prank(context.accountAddr, context.pairAddr)
    %}
    INFTPair.transferOwnership(pairAddr, 1234);
    %{expect_revert()%}
    INFTPair.withdrawERC20(
        contract_address=pairAddr,
        _erc20Address=newERC20Addr,
        amount=erc20AmountToWithraw
    );

    return ();
}   

