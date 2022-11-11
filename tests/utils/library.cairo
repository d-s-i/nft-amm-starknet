%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)
from starkware.cairo.common.bool import (TRUE)

from contracts.interfaces.INFTPairFactory import (INFTPairFactory)
from contracts.interfaces.tokens.IERC721 import (IERC721)
from contracts.interfaces.tokens.IERC20 import (IERC20)

@external
func setBondingCurveAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    bondingCurveAddr: felt,
    factoryAddr: felt,
    factoryOwnerAddr: felt
) {
    %{stop_prank_factory = start_prank(ids.factoryOwnerAddr, ids.factoryAddr)%}
    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, TRUE);
    %{stop_prank_factory()%}
    return ();
}

@external
func setRouterAllowed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    factoryAddr: felt,
    factoryOwnerAddr: felt,
    routerAddr: felt
) {
    %{stop_prank_factory = start_prank(ids.factoryOwnerAddr, ids.factoryAddr)%}
    INFTPairFactory.setRouterAllowed(factoryAddr, routerAddr, TRUE);
    %{stop_prank_factory()%}
    return ();
}

// @param erc721Addr - The NFT address
// @param start - The first id to be minted
// @param nftIds_len - The amount of NFT to mint from start
// @param nftIds - An empty pointer that will store all minted tokenIds
// @param mintTo
// @param contractOwnner - The NFT contract owner
func _mintERC721{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc721Addr: felt,
    start: felt,
    nftIds_len: felt,
    nftIds_ptr: Uint256*,
    mintTo: felt,
    contractOwner: felt
) {
    alloc_locals;

    if(start == nftIds_len) {
        return ();
    }
    
    local id: Uint256 = Uint256(low=start + 1, high=0);
    assert [nftIds_ptr] = id;

    %{stop_prank_erc721 = start_prank(ids.contractOwner, ids.erc721Addr)%}
    IERC721.mint(erc721Addr, mintTo, id);
    %{stop_prank_erc721()%}
    return _mintERC721(
        erc721Addr=erc721Addr, 
        start=start + 1, 
        nftIds_len=nftIds_len, 
        nftIds_ptr=nftIds_ptr + Uint256.SIZE, 
        mintTo=mintTo, 
        contractOwner=contractOwner
    );
}

func setERC20Allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Addr: felt,
    spender: felt,
    operator: felt,
    allowance: Uint256
) {
    %{
        store(
            ids.erc20Addr, 
            "ERC20_allowances", 
            [ids.allowance.low, ids.allowance.high], 
            [ids.spender, ids.operator]
        )
    %}
    return ();
}

func setERC721Allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc721Addr: felt,
    spender: felt,
    operator: felt
) {
    %{
        store(
            ids.erc721Addr, 
            "ERC721_operator_approvals", 
            [1], 
            [ids.spender, ids.operator]
        )
    %}
    return ();
}

func _mintERC20{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    erc20Addr: felt,
    amount: Uint256,
    to: felt,
    contractOwner: felt
) {
    %{stop_prank_erc20 = start_prank(ids.contractOwner, ids.erc20Addr)%}
    IERC20.mint(erc20Addr, to, amount);
    %{stop_prank_erc20()%}

    return ();
}

func displayIds{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds: Uint256*, 
    start: felt, 
    end: felt
) {
    alloc_locals;

    if(start == end) {
        return ();
    }

    local currentId: Uint256 = [nftIds];
    %{
        print(f"id[{ids.start}]: {ids.currentId.low + ids.currentId.high}")
    %}

    return displayIds(nftIds + Uint256.SIZE, start + 1, end);
}

func displayIdsAndOwners{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
    nftIds: Uint256*,
    nftAddress: felt,
    start: felt, 
    end: felt
) {
    alloc_locals;

    if(start == end) {
        return ();
    }

    local currentId: Uint256 = [nftIds];
    let (idOwner) = IERC721.ownerOf(
        contract_address=nftAddress,
        tokenId=currentId
    );
    %{
        print(f"displayIdsAndOwners - id[{ids.start}]: {ids.currentId.low + ids.currentId.high} (owner: {ids.idOwner})")
    %}

    return displayIdsAndOwners(
        nftIds + Uint256.SIZE, 
        nftAddress, 
        start + 1, 
        end
    );
}
