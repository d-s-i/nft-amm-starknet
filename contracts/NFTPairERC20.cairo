%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_caller_address)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_sub,
    uint256_eq,
    uint256_lt
)
from starkware.cairo.common.math import (assert_not_zero)
from starkware.cairo.common.bool import (TRUE)

from contracts.interfaces.IERC20 import (IERC20)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.INFTRouter import (INFTRouter)

from contracts.NFTPair import (NFTPair)
from contracts.libraries.felt_uint import (FeltUint)


@storage_var
func tokenAddress() -> (res: felt) {
}

namespace NFTPairERC20 {
    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        factoryAddr: felt,
        bondingCurveAddr: felt,
        _poolType: felt,
        _nftAddress: felt,
        _spotPrice: felt,
        _delta: felt,
        _fee: felt,
        owner: felt,
        _assetRecipient: felt,
        _pairVariant: felt,
        _tokenAddress: felt
    ) {
        NFTPair.initializer(
            factoryAddr,
            bondingCurveAddr,
            _poolType,
            _nftAddress,
            _spotPrice,
            _delta,
            _fee,
            owner,
            _assetRecipient,
            _pairVariant
        );
        tokenAddress.write(_tokenAddress);
        return ();
    }

    func _pullTokenInputAndPayProtocolFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        inputAmount: Uint256,
        isRouter: felt,
        routerCaller: felt,
        _factory: felt,
        protocolFee: felt
    ) {
        let (_token) = tokenAddress.read();
        let (_assetRecipient) = NFTPair.getAssetRecipient();
        let (_pairVariant) = NFTPair.getPairVariant();

        let (protocolFeeUint) = FeltUint.feltToUint256(protocolFee);
        let (amount) = uint256_sub(inputAmount, protocolFeeUint);

        if(isRouter == TRUE) {
            let (routerAllowed) = INFTPairFactory.routerStatus(
                _factory,
                routerCaller
            );
            with_attr error_message("NFTPairERC20::_pullTokenInputAndPayProtocolFee - Router not allowed") {
                assert_not_zero(routerCaller);
            }
            let (beforeBalance) = IERC20.balanceOf(
                _token,
                _assetRecipient
            );
            INFTRouter.pairTransferERC20From(
                routerCaller,
                _token,
                routerCaller,
                _assetRecipient,
                amount,
                _pairVariant
            );

            let (currentBalance) = IERC20.balanceOf(
                _token,
                _assetRecipient
            );
            let (transferedAmount) = uint256_sub(currentBalance, beforeBalance);
            let (supposedAmount) = uint256_sub(inputAmount, protocolFeeUint);

            with_attr error_message("NFTPairERC20::_pullTokenInputAndPayProtocolFee - ERC20 not transfered in") {
                uint256_eq(transferedAmount, supposedAmount);
            }

            INFTRouter.pairTransferERC20From(
                routerCaller,
                _token,
                routerCaller,
                _factory,
                protocolFeeUint,
                _pairVariant
            );

        } else {
            let (caller) = get_caller_address();
            IERC20.transferFrom(
                _token,
                caller,
                _assetRecipient,
                amount
            );

            let (isPositive) = uint256_lt(Uint256(low=0, high=0), protocolFeeUint);
            if(isPositive == TRUE) {
                IERC20.transferFrom(
                    _token,
                    caller,
                    _factory,
                    protocolFeeUint
                );
            }
        }

        return ();
    }
}