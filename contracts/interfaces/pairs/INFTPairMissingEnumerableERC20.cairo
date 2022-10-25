%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

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
}