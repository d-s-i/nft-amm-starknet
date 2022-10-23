%lang starknet

// from contracts.NFTPair import (
//     swapTokenForAnyNFTs,
//     swapTokenForSpecificNFTs,
//     swapNFTsForToken,
//     getBuyNFTQuote,
//     getSellNFTQuote,
//     getAssetRecipient,
//     getPairVariant,
//     getNFtAddress,
//     supportsInterface,
//     setInterfacesSupported,
//     onERC1155Received,
//     onERC1155BatchReceived,
//     _assertCorrectlyInitializedWithPoolType,
//     _calculateBuyInfoAndUpdatePoolParams,
//     _calculateSellInfoAndUpdatePoolParams,
//     _takeNFTsFromSender,
//     _pullTokenInputAndPayProtocolFee,
//     _sendAnyNFTsToRecipient,
//     _sendSpecificNFTsToRecipient,
//     _sendTokenOutput,
//     _payProtocolFeeFromPair
// )
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.starknet.common.syscalls import (get_contract_address)

from starkware.cairo.common.math import (assert_not_zero)

from contracts.interfaces.INFTPair import (INFTPair)

@external
func __setup__() {
    %{ 
        context.nftPairAddress = deploy_contract("./contracts/NFTPair.cairo", []).contract_address 
        context.erc20Address = deploy_contract("./contracts/tests/ERC20.cairo", [
            0, 0, 0, , ids.thisAddress, ids.thisAddress
        ]).contract_address 
    %}
    return ();
}

@external
func test_deployed_everything{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;

    local nftPairAddress: felt;
    local erc20Address: felt;
    %{ 
        ids.nftPairAddress = context.nftPairAddress
        ids.erc20Address = context.erc20Address
    %}

    assert_not_zero(nftPairAddress);
    assert_not_zero(erc20Address);

    return ();
}

@external

// // @external
// // func test_increase_balance{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}() {
// //     let (result_before) = balance.read();
// //     assert result_before = 0;

// //     increase_balance(42);

// //     let (result_after) = balance.read();
// //     assert result_after = 42;
// //     return ();
// // }

// // @external
// // func test_cannot_increase_balance_with_negative_value{
// //     syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*
// // }() {
// //     let (result_before) = balance.read();
// //     assert result_before = 0;

// //     %{ expect_revert("TRANSACTION_FAILED", "Amount must be positive") %}
// //     increase_balance(-42);

// //     return ();
// // }
