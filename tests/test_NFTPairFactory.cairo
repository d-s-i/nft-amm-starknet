%lang starknet

from starkware.starknet.common.syscalls import (get_caller_address)

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

from contracts.constants.library import (MAX_UINT_128)
from contracts.constants.structs import (PoolType)

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

    tempvar accountAddr;
    %{ 
        ids.accountAddr = deploy_contract("./contracts/mocks/Account.cairo", [0]).contract_address
    %}
    let (erc20Addr, erc721Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000000000000000000000, high=0),
        owner=accountAddr
    );

    let (bondingCurveAddr) = deployCurve(CurveId.Linear);
    
    let (factoryAddr) = deployFactory(Uint256(low=0, high=0), accountAddr);
    %{stop_prank_factory = start_prank(ids.accountAddr, ids.factoryAddr)%}
    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
    %{stop_prank_factory()%}

    %{
        print(f"factoryAddr: {ids.factoryAddr} (hex: {hex(ids.factoryAddr)})")
        print(f"bondingCurveAddr: {ids.bondingCurveAddr} (hex: {hex(ids.bondingCurveAddr)})")
        print(f"erc20Addr: {ids.erc20Addr} (hex: {hex(ids.erc20Addr)})")
        print(f"erc721Addr: {ids.erc721Addr} (hex: {hex(ids.erc721Addr)})")
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}

    let (pairAddress) = deployPair(
        accountAddr,
        factoryAddr,
        erc20Addr,
        erc721Addr,
        bondingCurveAddr,
        PoolType.TRADE,
        1,
        Uint256(low=100, high=0),
        Uint256(low=10, high=0),
        Uint256(low=0, high=0)
    );

    %{context.pairAddress = ids.pairAddress%}

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