%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.constants.library import (MAX_UINT_128)

@contract_interface
namespace NFTPairFactory {
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

@contract_interface
namespace ERC721 {
    func mint(to: felt, tokenId: Uint256) {
    }
    func balanceOf(owner: felt) -> (balance: Uint256) {
    }
}


func deployPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    accountAddr: felt,
    factoryAddr: felt,
    erc20Addr: felt,
    erc721Addr: felt,
    bondingCurveAddr: felt,
    poolType: felt,
    initialNFTId: felt,
    initialERC20Balance: Uint256
) -> (pairAddress: felt) {

    tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);

    let initialNFTIdUint = Uint256(low=initialNFTId, high=0);
    %{
        stop_prank_factory = start_prank(ids.accountAddr, ids.factoryAddr)
        stop_prank_erc721 = start_prank(context.accountAddr, context.erc721Addr)

        # Set allowances    
        store(context.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_256.low, ids.MAX_UINT_256.high], [context.accountAddr, context.factoryAddr])
        store(context.erc721Addr, "ERC721_operator_approvals", [1], [context.accountAddr, context.factoryAddr])
    %}
    ERC721.mint(erc721Addr, accountAddr, initialNFTIdUint);
    
    let (pairAddress) = NFTPairFactory.createPairERC20(
        contract_address=factoryAddr,
        _erc20Address=erc20Addr,
        _nftAddress=erc721Addr,
        _bondingCurve=bondingCurveAddr,
        _assetRecipient=0,
        _poolType=poolType,
        _delta=Uint256(low=0, high=0),
        _fee=0,
        _spotPrice=Uint256(low=10, high=0),
        _initialNFTIDs_len=1,
        _initialNFTIDs=cast(new (initialNFTIdUint,), Uint256*),
        initialERC20Balance=initialERC20Balance
    );

    %{
        stop_prank_factory()
        stop_prank_erc721()
    %}

    %{
        print(f"pairAddress: {ids.pairAddress} (hex: {hex(ids.pairAddress)})")
        context.pairAddress = ids.pairAddress
    %}
    return (pairAddress=pairAddress);
}