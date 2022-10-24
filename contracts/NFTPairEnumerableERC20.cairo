%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

from contracts import (
    NFTPairERC20,
    NFTPairEnumerable
)

func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    factoryAddr: felt,
    bondingCurveAddr: felt,
    _poolType: felt,
    _nftAddress: felt,
    _spotPrice: Uint256,
    _delta: Uint256,
    _fee: felt,
    owner: felt,
    _assetRecipient: felt,
    _pairVariant: felt,
    _tokenAddress: felt
) {
    NFTPairERC20.initializer(
        factoryAddr,
        bondingCurveAddr,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        owner,
        _assetRecipient,
        _pairVariant,
        _tokenAddress
    );
    return ();
}