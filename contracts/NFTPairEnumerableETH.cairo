%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_lt, 
    uint256_sub, 
    uint256_add
)
from starkware.starknet.common.syscalls import (get_contract_address)
from starkware.cairo.common.bool import (TRUE)

from contracts.NFTPairETH import (NFTPairETH)
from contracts.NFTPairEnumerable import (NFTPairEnumerable)
from contracts.openzeppelin.Ownable import (Ownable)
from contracts.openzeppelin.ReentrancyGuard import (ReentrancyGuard)

from contracts.interfaces.IERC721 import (IERC721)
from contracts.interfaces.IERC721Enumerable import (IERC721Enumerable)

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt} (
    factoryAddr: felt,
    bondingCurveAddr: felt,
    _poolType: felt,
    _nftAddress: felt,
    _spotPrice: Uint256,
    _delta: Uint256,
    _fee: felt,
    owner: felt,
    _assetRecipient: felt,
    _wethAddress: felt
) {
    // pairVariant == PairVariant.ENUMERABLE_ETH
    NFTPairETH.initializer(
        factoryAddr,
        bondingCurveAddr,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        owner,
        _assetRecipient,
        0,
        _wethAddress
    );
    return ();
}

@external
func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairETH.swapTokenForAnyNFTs(
        numNFTs,
        maxExpectedTokenInput,
        nftRecipient,
        isRouter,
        routerCaller
    );

    return ();
}

@external
func swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    maxExpectedTokenInput: Uint256,
    nftRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairETH.swapTokenForSpecificNFTs(
        nftIds_len,
        nftIds,
        maxExpectedTokenInput,
        nftRecipient,
        isRouter,
        routerCaller
    );
    return ();
}

@external
func swapNFTsForToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds_len: felt,
    nftIds: Uint256*,
    minExpectedTokenOutput: Uint256,
    tokenRecipient: felt,
    isRouter: felt,
    routerCaller: felt
) {
    NFTPairETH.swapNFTsForToken(
        nftIds_len,
        nftIds,
        minExpectedTokenOutput,
        tokenRecipient,
        isRouter,
        routerCaller
    );
    return ();
}

@external
func setInterfacesSupported{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt, 
    isSupported: felt
) {
    NFTPairETH.setInterfacesSupported(interfaceId, isSupported);
    return ();
}

@view
func getBuyNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = NFTPairETH.getBuyNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        inputAmount=inputAmount,
        protocolFee=protocolFee
    );
}

@view
func getSellNFTQuote{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    numNFTs: Uint256
) -> (
    error: felt,
    newSpotPrice: Uint256,
    newDelta: Uint256,
    inputAmount: Uint256,
    protocolFee: Uint256
) {
    let (
        error,
        newSpotPrice,
        newDelta,
        inputAmount,
        protocolFee
    ) = NFTPairETH.getSellNFTQuote(numNFTs);
    return (
        error=error,
        newSpotPrice=newSpotPrice,
        newDelta=newDelta,
        inputAmount=inputAmount,
        protocolFee=protocolFee
    );
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    interfaceId: felt
) -> (isSupported: felt) {
    let (isSupported) = NFTPairETH.supportsInterface(interfaceId);
    return (isSupported=isSupported);
}

@view
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    token_id: Uint256, 
    amount: Uint256,
    data_len: felt, 
    data: felt*
) -> (selector: felt) {
    let (selector) = NFTPairETH.onERC1155Received(
        operator,
        from_,
        token_id,
        amount,
        data_len,
        data
    );
    return (selector=selector);
}

@view
func onERC1155BatchReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    operator: felt, 
    from_: felt, 
    token_ids_len: felt,
    token_ids: Uint256*, 
    amounts_len: felt,
    amounts: Uint256*,
    data_len: felt, 
    data: felt*
) -> (selector: felt) {
    let (selector) = NFTPairETH.onERC1155BatchReceived(
        operator,
        from_,
        token_ids_len,
        token_ids,
        amounts_len,
        amounts,
        data_len,
        data
    );
    return (selector=selector);
}    

func _sendAnyNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    nftRecipient: felt,
    startIndex: Uint256,
    numNFTs: Uint256
) {
    NFTPairEnumerable._sendAnyNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        startIndex,
        numNFTs
    );

    return (); 
}

func _sendSpecificNFTsToRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    nftRecipient: felt,
    startIndex: felt,
    nftIds_len: felt,
    nftIds: Uint256*
) {
    NFTPairEnumerable._sendSpecificNFTsToRecipient(
        _nftAddress,
        nftRecipient,
        startIndex,
        nftIds_len,
        nftIds
    );
    return();
}