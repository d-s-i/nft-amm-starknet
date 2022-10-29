%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace INFTPairFactory {
    func getProtocolFeeMultiplier() -> (res: Uint256) {
    }
    func routerStatus(routerAddress: felt) -> (success: felt) {
    }
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