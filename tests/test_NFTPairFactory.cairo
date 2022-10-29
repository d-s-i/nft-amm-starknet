%lang starknet

from starkware.starknet.common.syscalls import (get_caller_address)

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.pairs.INFTPairMissingEnumerableERC20 import (INFTPairMissingEnumerableERC20)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

from contracts.constants.library import (MAX_UINT_128)
from contracts.constants.structs import (PoolType)

from tests.utils.DeployPair import (deployPair)

const TOKEN_ID = 1;

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
        NFTPairEnumerableERC20ClassHash = declare("./contracts/NFTPairEnumerableERC20.cairo").class_hash
        NFTPairMissingEnumerableERC20ClassHash = declare("./contracts/NFTPairMissingEnumerableERC20.cairo").class_hash
        context.factoryAddr = deploy_contract(
            "./contracts/NFTPairFactory.cairo", 
            [
                NFTPairEnumerableERC20ClassHash,
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

    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
    %{stop_prank_factory()%}

    deployPair(
        accountAddr,
        factoryAddr,
        erc20Addr,
        erc721Addr,
        bondingCurveAddr,
        PoolType.TRADE,
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

    with_attr error_mesage("NFTPairFactory::createPairERC20 - pairAddress should not be 0 (value: {pairAddress})") {
        assert_not_zero(pairAddress);
    }

    return ();
}