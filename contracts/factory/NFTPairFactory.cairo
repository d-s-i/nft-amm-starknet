%lang starknet

// Changed createPairERC20 to keep track of all deployed pairs in storage (inneficient)
// Changed isPair to read deployedPairStorage instead of checking contract_address or class_hash
// Didn't implement yet setCallAllowed as arbitrary calls are not implemented on pairs and routers

from starkware.cairo.common.alloc import (alloc)
from starkware.starknet.common.syscalls import (deploy, get_contract_address, get_caller_address)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.math import (assert_not_zero)
from starkware.cairo.common.bool import (TRUE, FALSE)

from contracts.openzeppelin.Ownable import (Ownable)

from contracts.constants.structs import (PairVariant)
from contracts.constants.library import (MAX_UINT_128)

from contracts.constants.library import (IERC721_ENUMERABLE_ID)
from contracts.interfaces.bonding_curves.ICurve import (ICurve)
from contracts.interfaces.utils.IERC165 import (IERC165)
from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.pairs.INFTPair import (INFTPair)

from contracts.factory.structs import (RouterStatus)

const MAX_PROTOCOL_FEE = 10**17;

// Storage

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

@storage_var
func protocolFeeRecipient() -> (res: felt) {
}

@storage_var
func pairDeployed(address: felt) -> (isPair: felt) {
}

@storage_var
func routerStatus(routerAddr: felt) -> (status: RouterStatus) {
}

// Events

@event
func NewPair(contractAddress: felt) {
}

@event
func BondingCurveStatusUpdate(bondingCurveAddress: felt, isAllowed: felt) {
}

@event
func ProtocolFeeRecipientUpdate(newProtocolFeeRecipientUpdate: felt) {
}

@event
func ProtocolFeeMultiplierUpdate(newProtocolFeeMultiplierUpdate: Uint256) {
}

@event
func RouterStatusUpdate(routerAddr: felt, isAllowed: felt) {
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
    _initialNFTIds_len: felt,
    _initialNFTIds: Uint256*,
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
            _initialNFTIds_len,
            _initialNFTIds,
            initialERC20Balance
        );
        pairDeployed.write(_pairAddress, TRUE);
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
            _initialNFTIds_len,
            _initialNFTIds,
            initialERC20Balance
        );
        pairDeployed.write(_pairAddress, TRUE);
        return (pairAddress=_pairAddress);
    }
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

    let (caller) = get_caller_address();
    INFTPair.initializer(
        contract_address=_pairAddress,
        factoryAddr=thisAddress,
        bondingCurveAddr=_bondingCurve,
        _poolType=_poolType,
        _nftAddress=_nftAddress,
        _spotPrice=_spotPrice,
        _delta=_delta,
        _fee=_fee,
        owner=caller,
        _assetRecipient=_assetRecipient,
        _pairVariant=PairVariant.ENUMERABLE_ERC20,
        _erc20Address=_erc20Address
    );

    _transferInitialLiquidity(
        pairAddress=_pairAddress,
        erc20Address=_erc20Address,
        nftAddress=_nftAddress,
        nftIds_len=_initialNFTIds_len,
        nftIds=_initialNFTIds,
        initialERC20Balance=initialERC20Balance
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
    let (classHash) = missingEnumerableERC20Template.read();
    let (_pairAddress) = deploy(
        class_hash=classHash,
        contract_address_salt=currentSalt,
        constructor_calldata_size=0,
        constructor_calldata=cast(new (0,), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=currentSalt + 1);

    let (caller) = get_caller_address();
    INFTPair.initializer(
        contract_address=_pairAddress,
        factoryAddr=thisAddress,
        bondingCurveAddr=_bondingCurve,
        _poolType=_poolType,
        _nftAddress=_nftAddress,
        _spotPrice=_spotPrice,
        _delta=_delta,
        _fee=_fee,
        owner=caller,
        _assetRecipient=_assetRecipient,
        _pairVariant=PairVariant.MISSING_ENUMERABLE_ERC20,
        _erc20Address=_erc20Address
    );

    _transferInitialLiquidity(
        pairAddress=_pairAddress,
        erc20Address=_erc20Address,
        nftAddress=_nftAddress,
        nftIds_len=_initialNFTIds_len,
        nftIds=_initialNFTIds,
        initialERC20Balance=initialERC20Balance
    );

    NewPair.emit(_pairAddress);

    return (pairAddress=_pairAddress);
}

// ADMIN

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

@external
func setRouterAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    routerAddr: felt,
    isAllowed: felt
) {
    Ownable.assert_only_owner();

    let status = RouterStatus(
        allowed=isAllowed,
        wasEverAllowed=TRUE
    );

    routerStatus.write(routerAddr, status);

    RouterStatusUpdate.emit(routerAddr, isAllowed);
    return ();
}

@external
func changeProtocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newProtocolFeeRecipient: felt
) {
    Ownable.assert_only_owner();
    protocolFeeRecipient.write(newProtocolFeeRecipient);
    ProtocolFeeRecipientUpdate.emit(newProtocolFeeRecipient);
    return ();
}

@external
func changeProtocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    newProtocolFeeMultiplier: Uint256
) {
    Ownable.assert_only_owner();
    protocolFeeMultiplier.write(newProtocolFeeMultiplier);
    ProtocolFeeMultiplierUpdate.emit(newProtocolFeeMultiplier);
    return ();
}

@external
func withdrawERC20ProtocolFees{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Addr: felt,
    amount: Uint256
) {
    Ownable.assert_only_owner();

    let (thisAddress) = get_contract_address();
    let (_protocolFeeRecipient) = protocolFeeRecipient.read();
    IERC20.approve(erc20Addr, thisAddress, Uint256(low=MAX_UINT_128, high=MAX_UINT_128));
    IERC20.transferFrom(erc20Addr, thisAddress, _protocolFeeRecipient, amount);
    return ();
}

// VIEW

@view
func getProtocolFeeMultiplier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (protocolFeeMultiplier: Uint256) {
    let (_protocolFeeMultiplier) = protocolFeeMultiplier.read();
    return (protocolFeeMultiplier=_protocolFeeMultiplier);
}

@view
func getProtocolFeeRecipient{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() -> (protocolFeeRecipient: felt) {
    let (_protocolFeeRecipient) = protocolFeeRecipient.read();
    return (protocolFeeRecipient=_protocolFeeRecipient);
}

// Instead of checking the generated address like in LSSVM contracts
// checking if the class hash match
// Since checking the class hash match isn't possible, storing all
// deployed addresses directly
@view
func isPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    potentialPair: felt
) -> (_isPair: felt) {

    // if(variant == PairVariant.ENUMERABLE_ERC20) {
    //     // get class hash of potential pair
    //     // if is equal return true else return faldr
    // }  

    // if(variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
    //     // get class hash of potential pair
    //     // if is equal return true else return faldr
    // }

    // return (FALSE);

    let (isPair_) = pairDeployed.read(potentialPair);
    return (_isPair=isPair_);
}

@view
func getRouterStatus{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    routerAddress: felt
) -> (routerStatus: RouterStatus) {
    let (_routerStatus) = routerStatus.read(routerAddress);
    return (routerStatus=_routerStatus);
}

// INTERNAL

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
    IERC721.safeTransferFrom(nftAddress, from_, to, [tokenIds], 0, cast(new (0,), felt*)); 
    return _transferInitialNFTs(start + 1, end, from_, to, nftAddress, tokenIds + 2);
}