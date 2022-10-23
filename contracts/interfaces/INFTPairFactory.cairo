%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

@contract_interface
namespace INFTPairFactory {
    func getProtocolFeeMultiplier() -> (res: Uint256) {
    }
    func routerStatus(routerAddress: felt) -> (success: felt) {
    }
}