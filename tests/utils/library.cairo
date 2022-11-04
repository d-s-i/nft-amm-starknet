%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

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
    INFTPairFactory.setBondingCurveAllowed(factoryAddr, bondingCurveAddr, 1);
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
    nftIds: Uint256*,
    mintTo: felt,
    contractOwner: felt
) {
    if(start == nftIds_len) {
        return ();
    }
    
    let id = Uint256(low=start + 1, high=0);
    assert [nftIds] = id;

    %{stop_prank_erc721 = start_prank(ids.contractOwner, ids.erc721Addr)%}
    IERC721.mint(erc721Addr, mintTo, id);
    %{stop_prank_erc721()%}
    return _mintERC721(erc721Addr, start + 1, nftIds_len, nftIds + 2, mintTo, contractOwner);
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