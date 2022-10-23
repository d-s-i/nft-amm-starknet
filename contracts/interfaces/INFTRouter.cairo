%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace INFTRouter {
    func pairTransferNFTFrom(
        nft: felt,
        _from: felt,
        to: felt,
        id: Uint256,
        variant: felt
    ) {
    }

    func pairTransferERC20From(
        _token: felt,
        routerCaller: felt,
        _assetRecipient: felt,
        amount: Uint256,
        _pairVariant: felt
    ) {
    }
}