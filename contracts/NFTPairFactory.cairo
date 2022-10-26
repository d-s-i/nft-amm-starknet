%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.starknet.common.syscalls import (deploy, get_contract_address, get_caller_address)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.openzeppelin.Ownable import (Ownable)

from contracts.constants.library import (IERC721_ENUMERABLE_ID)
from contracts.interfaces.bonding_curves.ICurve import (ICurve)
from contracts.interfaces.utils.IERC165 import (IERC165)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.pairs.INFTPairEnumerableERC20 import (INFTPairEnumerableERC20)
from contracts.interfaces.pairs.INFTPairMissingEnumerableERC20 import (INFTPairMissingEnumerableERC20)

const MAX_PROTOCOL_FEE = 10**17;

// Define a storage variable for the salt.
@storage_var
func salt() -> (value: felt) {
}

@storage_var
func enumerableERC20Template() -> (address: felt) {
}

@storage_var
func missingEnumerableERC20Template() -> (address: felt) {
}

@storage_var
func bondigCurveAllowed(bondingCurveAddress: felt) -> (isAllowed: felt) {
}


@storage_var
func protocolFeeMultiplier() -> (res: Uint256) {
}

@event
func NewPair(contractAddress: felt) {
}

@event
func BondingCurveStatusUpdate(bondingCurveAddress: felt, isAllowed: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    _enumerableERC20Template: felt,
    _missingEnumerableERC20Template: felt,
    _protocolFeeMultiplier: Uint256,
    owner: felt
) {
    Ownable.initializer(owner);

    enumerableERC20Template.write(_enumerableERC20Template);
    missingEnumerableERC20Template.write(_missingEnumerableERC20Template);
    protocolFeeMultiplier.write(_protocolFeeMultiplier);
    return ();
}

@external
func createPairERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
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

    alloc_locals;
    let (_bondingCurveAllowed) = bondigCurveAllowed.read(_bondingCurve);
    with_attr error_message("NFTPairFactory::createPairERC20 - Bonding curve not whitelisted") {
        assert _bondingCurveAllowed = TRUE;
    }
    
    let (isEnumerable) = IERC165.supportsInterface(_nftAddress, IERC721_ENUMERABLE_ID);
    let (thisAddress) = get_contract_address();
    
    if(isEnumerable == TRUE) {
        let (_pairAddress) = deployPairEnumerableERC20(
            thisAddress,
            _erc20Address,
            _nftAddress,
            _bondingCurve,
            _assetRecipient,
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs_len,
            _initialNFTIDs,
            initialERC20Balance
        );
        return (pairAddress=_pairAddress);
    } else {
        let (_pairAddress) = deployPairMissingEnumerableERC20(
            thisAddress,
            _erc20Address,
            _nftAddress,
            _bondingCurve,
            _assetRecipient,
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs_len,
            _initialNFTIDs,
            initialERC20Balance
        );
        return (pairAddress=_pairAddress);
    }
}

@external
func setBondingCurveAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    bondingCurveAddress: felt,
    isAllowed: felt
) {
    Ownable.assert_only_owner();
    bondigCurveAllowed.write(bondingCurveAddress, isAllowed);
    BondingCurveStatusUpdate.emit(bondingCurveAddress, isAllowed);
    return ();
}

func deployPairEnumerableERC20{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr: felt,
}(
    thisAddress: felt,
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
    alloc_locals;
    
    let (currentSalt) = salt.read();
    let (classHash) = enumerableERC20Template.read();
    let (_pairAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=0,
        constructor_calldata=cast(new (0,), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=currentSalt + 1);

    INFTPairEnumerableERC20.initializer(
        _pairAddress,
        thisAddress,
        _bondingCurve,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        thisAddress,
        _assetRecipient,
        _erc20Address
    );

    _transferInitialLiquidity(
        _pairAddress,
        _erc20Address,
        _nftAddress,
        _initialNFTIds_len,
        _initialNFTIds,
        initialERC20Balance
    );


    NewPair.emit(_pairAddress);

    return (pairAddress=_pairAddress);
}

func deployPairMissingEnumerableERC20{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr: felt,
}(
    thisAddress: felt,
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
    alloc_locals;
    
    let (currentSalt) = salt.read();
    let (classHash) = enumerableERC20Template.read();
    let (_pairAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=0,
        constructor_calldata=cast(new (0,), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=currentSalt + 1);

    INFTPairMissingEnumerableERC20.initializer(
        _pairAddress,
        thisAddress,
        _bondingCurve,
        _poolType,
        _nftAddress,
        _spotPrice,
        _delta,
        _fee,
        thisAddress,
        _assetRecipient,
        _erc20Address
    );

    _transferInitialLiquidity(
        _pairAddress,
        _erc20Address,
        _nftAddress,
        _initialNFTIds_len,
        _initialNFTIds,
        initialERC20Balance
    );

    NewPair.emit(_pairAddress);

    return (pairAddress=_pairAddress);
}

func _transferInitialLiquidity{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    pairAddress: felt,
    erc20Address: felt,
    nftAddress: felt,
    nftIds_len: felt,
    nftIds: Uint256*,
    initialERC20Balance: Uint256
) {
    let (caller) = get_caller_address();
    IERC20.transferFrom(erc20Address, caller, pairAddress, initialERC20Balance);
    _transferInitialNFTs(
        start=0, 
        end=nftIds_len, 
        from_=caller, 
        to=pairAddress, 
        nftAddress=nftAddress, 
        tokenIds=nftIds
    );

    return ();
}

func _transferInitialNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    start: felt,
    end: felt,
    from_: felt,
    to: felt,
    nftAddress: felt,
    tokenIds: Uint256*
) {
    if(start == end) {
        return ();
    }
    IERC721.transferFrom(nftAddress, from_, to, [tokenIds]); 
    return _transferInitialNFTs(start + 1, end, from_, to, nftAddress, tokenIds + 1);
}

@view
func getProtocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (protocolFeeMultiplier: Uint256) {
    let (_protocolFeeMultiplier) = protocolFeeMultiplier.read();
    return (protocolFeeMultiplier=_protocolFeeMultiplier);
}