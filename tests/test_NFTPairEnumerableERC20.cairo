%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.NFTPairEnumerableERC20 import (
    initializer,
    getFactory,
    getBondingCurve,
    getPairVariant
)

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    // %{ 
    //     context.nftPairEnumerableERC20 = deploy_contract("./contracts/NFTPairEnumerable.cairo").contract_address 
    // %}

    initializer(
        factoryAddr=0,
        bondingCurveAddr=1,
        _poolType=2,
        _nftAddress=3,
        _spotPrice=Uint256(low=4, high=0),
        _delta=Uint256(low=5, high=0),
        _fee=6,
        owner=7,
        _assetRecipient=0,
        _tokenAddress=9
    );

    return ();
}

@external
func test_storage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {

    let (factoryAddr) = getFactory();
    let (bondingCurveAddr) = getBondingCurve();
    let (_pairVariant) = getPairVariant();

    %{
        print(f"factoryAddr: {ids.factoryAddr}")
        print(f"bondingCurveAddr: {ids.bondingCurveAddr}")
        print(f"pair variant: {ids._pairVariant}")
    %}

    return ();
}