%lang starknet

from starkware.starknet.common.syscalls import (get_caller_address)

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)

// from contracts.tests.libraries.library_erc20 import (ERC20_allowances)

from contracts.constants.library import (MAX_UINT_128)
from contracts.constants.PoolType import (PoolTypes)

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
}

@contract_interface
namespace INFTPairMissingEnumerableERC20 {
    func initializer(
        factoryAddr: felt,
        bondingCurveAddr: felt,
        _poolType: felt,
        _nftAddress: felt,
        _spotPrice: Uint256,
        _delta: Uint256,
        _fee: felt,
        owner: felt,
        _assetRecipient: felt,
        _tokenAddress: felt
    ) {
    }

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
}

@contract_interface
namespace ERC721 {
    func mint(to: felt, tokenId: Uint256) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);

    let holderAddr = 2971377087062275847644889140048409281862029281453332545390872066700573941323;
    
    tempvar factoryAddr;
    tempvar bondingCurveAddr;
    tempvar erc721Addr;
    tempvar erc20Addr;
    %{ 
        print("Starting setup")
        context.holderAddr = ids.holderAddr
        
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
                ids.holderAddr
            ]
        ).contract_address
        ids.factoryAddr = context.factoryAddr

        # Deploy curve
        context.bondingCurveAddr = deploy_contract("./contracts/bonding_curves/LinearCurve.cairo").contract_address
        ids.bondingCurveAddr = context.bondingCurveAddr

        # Deploy tokens
        context.erc20Addr = deploy_contract(
            "./contracts/tests/ERC20.cairo", 
            [0, 0, 18, 1000000000000000000000, 0, context.holderAddr, context.holderAddr]
        ).contract_address
        ids.erc20Addr = context.erc20Addr
        context.erc721Addr = deploy_contract(
            "./contracts/tests/ERC721.cairo",
            [0, 0, ids.holderAddr]
        ).contract_address
        ids.erc721Addr = context.erc721Addr

        # Set allowances
        store(context.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [context.holderAddr, context.factoryAddr])
        store(context.erc721Addr, "ERC721_operator_approvals", [1], [context.holderAddr, context.factoryAddr])

        print(f"factoryAddr: {context.factoryAddr} (hex: {hex(context.factoryAddr)})")
        print(f"bondingCurveAddr: {context.bondingCurveAddr} (hex: {hex(context.bondingCurveAddr)})")
        print(f"erc20Addr: {context.erc20Addr} (hex: {hex(context.erc20Addr)})")
        print(f"erc721Addr: {context.erc721Addr} (hex: {hex(context.erc721Addr)})")
        print(f"holderAddr: {context.holderAddr} (hex: {hex(context.holderAddr)})")

        stop_prank_factory = start_prank(context.holderAddr, context.factoryAddr)
        stop_prank_erc721 = start_prank(context.holderAddr, context.erc721Addr)

    %}

    NFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);

    let tokenId = Uint256(low=TOKEN_ID, high=0);
    ERC721.mint(erc721Addr, holderAddr, tokenId);

    let (poolTypes) = PoolTypes.value();
    let (pairAddress) = NFTPairFactory.createPairERC20(
        contract_address=factoryAddr,
        _erc20Address=erc20Addr,
        _nftAddress=erc721Addr,
        _bondingCurve=bondingCurveAddr,
        _assetRecipient=0,
        _poolType=poolTypes.TRADE,
        _delta=Uint256(low=0, high=0),
        _fee=0,
        _spotPrice=Uint256(low=10, high=0),
        _initialNFTIDs_len=1,
        _initialNFTIDs=cast(new (tokenId,), Uint256*),
        initialERC20Balance=Uint256(low=100, high=0)
    );

    %{
        print(f"pairAddress: {ids.pairAddress} (hex: {hex(ids.pairAddress)})")
        context.pairAddress = ids.pairAddress
    %}

    return ();
}

@external
func test_createPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    tempvar pairAddress;
    %{ ids.pairAddress = context.pairAddress %}

    with_attr error_mesage("NFTPairFactory::createPairERC20 - pairAddress should not be 0 (value: {pairAddress})") {
        assert_not_zero(pairAddress);
    }

    return ();
}

@external
func test_swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {

    tempvar pairAddress;
    tempvar erc20Addr;
    tempvar erc721Addr;
    tempvar holderAddr;
    %{
        stop_prank_erc20 = start_prank(context.holderAddr, context.erc20Addr)
        ids.holderAddr = context.holderAddr
        ids.pairAddress = context.pairAddress
        ids.erc20Addr = context.erc20Addr
        ids.erc721Addr = context.erc721Addr
    %}

    ERC20.mint(erc20Addr, holderAddr, Uint256(low=MAX_UINT_128, high=0));

    let (initialPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    let (initialPairNFTBalance) = ERC721.balanceOf(erc721Addr, pairAddress);
    %{
        print(f"initialPairTokenBalance: {ids.initialPairTokenBalance.low + ids.initialPairTokenBalance.high}")
        print(f"initialPairNFTBalance: {ids.initialPairNFTBalance.low + ids.initialPairNFTBalance.high}")
    %}

    INFTPairMissingEnumerableERC20.swapTokenForAnyNFTs(
        pairAddress,
        Uint256(low=1, high=0),
        Uint256(low=MAX_UINT_128, high=0),
        holderAddr,
        0,
        0
    );

    let (finalPairTokenBalance) = ERC20.balanceOf(erc20Addr, pairAddress);
    %{
        print(f"finalPairTokenBalance: {ids.finalPairTokenBalance.low + ids.finalPairTokenBalance.high}")
    %}
    return ();
}