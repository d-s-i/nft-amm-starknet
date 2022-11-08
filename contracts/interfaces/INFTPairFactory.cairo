%lang starknet

from starkware.cairo.common.uint256 import (Uint256)
from contracts.factory.structs import (RouterStatus)

@contract_interface
namespace INFTPairFactory {
    func createPairERC20(
        _erc20Address: felt,
        _nftAddress: felt,
        _bondingCurve: felt,
        _assetRecipient: felt,
        _poolType: felt,
        _delta: Uint256,
        _fee: felt,
        _spotPrice: Uint256,
        _initialNFTIds_len: felt,
        _initialNFTIds: Uint256*,
        initialERC20Balance: Uint256
    ) -> (pairAddress: felt) {
    }
    func setBondingCurveAllowed(
        bondingCurveAddress: felt,
        isAllowed: felt
    ) {
    }
    func setRouterAllowed(
        routerAddr: felt,
        isAllowed: felt
    ) {
    }
    func changeProtocolFeeRecipient(newProtocolFeeRecipient: felt) {
    }
    func changeProtocolFeeMultiplier(newProtocolFeeMultiplier: Uint256) {
    }
    func withdrawERC20ProtocolFees(
        erc20Addr: felt,
        amount: Uint256
    ) {
    }    
    func getProtocolFeeRecipient() -> (protocolFeeRecipient: felt) {
    }
    func getProtocolFeeMultiplier() -> (res: Uint256) {
    }
    func getRouterStatus(
        routerAddress: felt
    ) -> (routerStatus: RouterStatus) {
    }   
    func isPair(potentialPair: felt) -> (_isPair: felt) {
    }
}