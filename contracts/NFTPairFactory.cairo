%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.starknet.common.syscalls import (deploy, get_contract_address)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.constants.library import (IERC721_ENUMERABLE_ID)
from contracts.interfaces.bonding_curves.ICurve import (ICurve)
from contracts.interfaces.utils.IERC165 import (IERC165)
from contracts.interfaces.pairs.INFTPairEnumerableETH import (INFTPairEnumerableETH)

const MAX_PROTOCOL_FEE = 10**18;

// Define a storage variable for the salt.
@storage_var
func salt() -> (value: felt) {
}

@storage_var
func enumerableETHTemplate() -> (address: felt) {
}

@storage_var
func missingEnumerableETHTemplate() -> (address: felt) {
}

@storage_var
func protocolFeeMultiplier() -> (res: Uint256) {
}

@event
func NewPair(contractAddress: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _enumerableETHTemplate: felt,
    _missingEnumerableETHTemplate: felt,
    _protocolFeeMultiplier: Uint256
) {
    enumerableETHTemplate.write(_enumerableETHTemplate);
    missingEnumerableETHTemplate.write(_missingEnumerableETHTemplate);
    protocolFeeMultiplier.write(_protocolFeeMultiplier);
    return ();
}

// @notice Creates a pair contract using EIP-1167.
// @param _nft The NFT contract of the collection the pair trades
// @param _bondingCurve The bonding curve address for the pair to price NFTs, must be whitelisted
// @param _assetRecipient The address that will receive the assets traders give during trades.
                    //   If set to address(0), assets will be sent to the pool address.
                    //   Not available to TRADE pools. 
// @param _poolType TOKEN, NFT, or TRADE
// @param _delta The delta value used by the bonding curve. The meaning of delta depends
// on the specific curve.
// @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
// @param _spotPrice The initial selling spot price
// @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
// @return pair The new pair
@external
func createPairETH{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _nftAddress: felt,
    _bondingCurve: felt,
    _assetRecipient: felt,
    _poolType: felt,
    _delta: felt,
    _fee: felt,
    _spotPrice: felt,
    _initialNFTIDs_len: felt,
    _initialNFTIDs: Uint256*,
    _wethAddress: felt
) -> (pairAddress: felt) {

    alloc_locals;
    let (isEnumerable) = IERC165.supportsInterface(_nftAddress, IERC721_ENUMERABLE_ID);
    let (thisAddress) = get_contract_address();
    
    let (pairAddress: felt) = alloc();
    if(isEnumerable == TRUE) {
        let (templateAddress) = enumerableETHTemplate.read();
        let (_pairAddress) = deployPairEnumerableETH();
        pairAddress = _pairAddress;

        INFTPairEnumerableETH.initializer(
            pairAddress,
            factoryAddr=thisAddress,
            bondingCurveAddr=_bondingCurve,
            _poolType=_poolType,
            _nftAddress=_nftAddress,
            _spotPrice=_spotPrice,
            _delta=_delta,
            _fee=_fee,
            owner=thisAddress,
            _assetRecipient=_assetRecipient,
            wethAddress=_wethAddress
        );
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        let (templateAddress) = missingEnumerableETHTemplate.read();
        let (_pairAddress) = deployPairMissingEnumerableETH();
        pairAddress = _pairAddress;
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }



    with_attr error_message("Token need to be an NFT (ERC721 or ERC1155, i.e. implement either interface)") {
        assert_not_zero(pairAddress);
    }

    return (pairAddress=pairAddress);
}

func deployPairEnumerableETH{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr: felt,
}(
    // ADD ARGS
) -> (pairAddress: felt) {
    let (currentSalt) = salt.read();
    let (classHash) = enumerableETHTemplate.read();
    let (contractAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=0,
        constructor_calldata=cast(0, felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=currentSalt + 1);

    NewPair.emit(contractAddress);

    return (pairAddress=contractAddress);
}

func deployPairMissingEnumerableETH{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr: felt,
}(
    // ADD ARGS
) -> (pairAddress: felt) {
    let (currentSalt) = salt.read();
    let (classHash) = missingEnumerableETHTemplate.read();
    let (contractAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=0,
        constructor_calldata=cast(new (0,), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=currentSalt + 1);

    NewPair.emit(contractAddress);

    return (pairAddress=contractAddress);
}

@view
func getProtocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (protocolFeeMultiplier: Uint256) {
    let (_protocolFeeMultiplier) = protocolFeeMultiplier.read();
    return (protocolFeeMultiplier=_protocolFeeMultiplier);
}