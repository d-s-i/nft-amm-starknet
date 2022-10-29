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
    func getAllHeldIds() -> (tokenIds_len: felt, tokenIds: Uint256*) {
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

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    tempvar accountAddr;
    tempvar factoryAddr;
    tempvar bondingCurveAddr;
    tempvar erc721Addr;
    tempvar erc20Addr;
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
        context.erc20Addr = deploy_contract(
            "./contracts/mocks/ERC20.cairo", 
            [0, 0, 18, 1000000000000000000000, 0, context.accountAddr, context.accountAddr]
        ).contract_address
        ids.erc20Addr = context.erc20Addr
        context.erc721Addr = deploy_contract(
            "./contracts/mocks/ERC721.cairo",
            [0, 0, ids.accountAddr]
        ).contract_address
        ids.erc721Addr = context.erc721Addr

        print(f"factoryAddr: {context.factoryAddr} (hex: {hex(context.factoryAddr)})")
        print(f"bondingCurveAddr: {context.bondingCurveAddr} (hex: {hex(context.bondingCurveAddr)})")
        print(f"erc20Addr: {context.erc20Addr} (hex: {hex(context.erc20Addr)})")
        print(f"erc721Addr: {context.erc721Addr} (hex: {hex(context.erc721Addr)})")
        print(f"accountAddr: {context.accountAddr} (hex: {hex(context.accountAddr)})")

        stop_prank_factory = start_prank(context.accountAddr, context.factoryAddr)
    %}

    NFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
    %{stop_prank_factory()%}

    let (poolTypes) = PoolTypes.value();
    deployPair(
        accountAddr,
        factoryAddr,
        erc20Addr,
        erc721Addr,
        bondingCurveAddr,
        poolTypes.TRADE,
        TOKEN_ID,
        Uint256(low=100, high=0)
    );

    return ();
}

@external
func test_createPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    tempvar pairAddress;
    %{ ids.pairAddress = context.pairAddress %}

    // tempvar factoryAddr;
    // tempvar erc20Addr;
    // tempvar bondingCurveAddr;
    // tempvar erc721Addr;
    // tempvar accountAddr;
    // %{
    //     ids.factoryAddr = context.factoryAddr
    //     ids.erc20Addr = context.erc20Addr
    //     ids.bondingCurveAddr = context.bondingCurveAddr
    //     ids.erc721Addr = context.erc721Addr
    //     ids.accountAddr = context.accountAddr
    // %}

    with_attr error_mesage("NFTPairFactory::createPairERC20 - pairAddress should not be 0 (value: {pairAddress})") {
        assert_not_zero(pairAddress);
    }

    return ();
}

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
        stop_prank_erc721 = start_prank(context.accountAddr, context.erc721Addr)

        # Set allowances    
        store(context.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [context.accountAddr, context.factoryAddr])
        store(context.erc721Addr, "ERC721_operator_approvals", [1], [context.accountAddr, context.factoryAddr])
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

    %{
        print(f"pairAddress: {ids.pairAddress} (hex: {hex(ids.pairAddress)})")
        context.pairAddress = ids.pairAddress
    %}
    return (pairAddress=pairAddress);
}