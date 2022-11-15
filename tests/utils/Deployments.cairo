%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_le, assert_lt)

from contracts.constants.library import (MAX_UINT_128)

from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

from tests.utils.library import (_mintERC721, _mintERC20)

namespace CurveId {
    const Linear = 1;
    const Exponential = 2;
    const Xyk = 3;
}

func deployAccount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    privateKey: felt
) -> (accountAddr: felt) {
    tempvar accountAddr;
    %{ 
        ids.accountAddr = deploy_contract("./contracts/mocks/Account.cairo", [ids.privateKey]).contract_address
    %}
    return (accountAddr=accountAddr);
}

func deployCurve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    curveId: felt
) -> (bondingCurveAddr: felt) {

    with_attr error_mesage("deployCurve - curveId should be between 1 and 3 (value: {curveId}") {
        assert_le(0, curveId);
        assert_le(curveId, 3);
    }

    tempvar bondingCurveAddr;
    %{
        # Deploy curve
        curveName = "LinearCurve"
        if ids.curveId == ids.CurveId.Exponential:
            curveName = "ExponentialCurve"
        if ids.curveId == ids.CurveId.Xyk:
            curveName = "XykCurve"
        
        ids.bondingCurveAddr = deploy_contract(f"./contracts/bonding_curves/{curveName}.cairo").contract_address
    %}
    return (bondingCurveAddr=bondingCurveAddr);    
}

func deployFactory{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    protocolFeeMultiplier: Uint256,
    ownerAddress: felt
) -> (factoryAddr: felt) {
    alloc_locals;

    local factoryAddr;
    %{ 
        NFTPairEnumerableERC20ClassHash = declare("./contracts/pairs/NFTPairEnumerableERC20.cairo").class_hash
        NFTPairMissingEnumerableERC20ClassHash = declare("./contracts/pairs/NFTPairMissingEnumerableERC20.cairo").class_hash

        ids.factoryAddr = deploy_contract(
            "./contracts/factory/NFTPairFactory.cairo", 
            [
                NFTPairEnumerableERC20ClassHash,
                NFTPairMissingEnumerableERC20ClassHash, 
                ids.protocolFeeMultiplier.low, 
                ids.protocolFeeMultiplier.high,
                ids.ownerAddress
            ]
        ).contract_address
    %}
    
    return (factoryAddr=factoryAddr);
}

func deployRouter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    factoryAddr: felt
) -> (routerAddr: felt) {
    tempvar routerAddr;
    %{
        ids.routerAddr = deploy_contract(
            "./contracts/router/Router.cairo", 
            [ids.factoryAddr]
        ).contract_address
    %}
    return (routerAddr=routerAddr);
}

func deployTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Decimals: felt,
    erc20InitialSupply: Uint256,
    owner: felt
) -> (erc20Addr: felt, erc721Addr: felt, erc1155Addr: felt) {
    tempvar erc20Addr;
    tempvar erc721Addr;
    tempvar erc1155Addr;
    %{
        ids.erc20Addr = deploy_contract(
            "./contracts/mocks/ERC20.cairo", 
            [0, 0, ids.erc20Decimals, ids.erc20InitialSupply.low, ids.erc20InitialSupply.high, ids.owner, ids.owner]
        ).contract_address
        ids.erc721Addr = deploy_contract(
            "./contracts/mocks/ERC721.cairo",
            [0, 0, ids.owner]
        ).contract_address
        ids.erc1155Addr = deploy_contract(
            "./contracts/mocks/ERC1155.cairo",
            [0, ids.owner]
        ).contract_address        
    %}

    return (erc20Addr=erc20Addr, erc721Addr=erc721Addr, erc1155Addr=erc1155Addr);
}