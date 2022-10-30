%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256)

from contracts.constants.structs import (PoolType)

from contracts.interfaces.pairs.INFTPair import (INFTPair)

from tests.utils.library import (setBondingCurveAllowed)
from tests.utils.Deployments import (
    CurveId,
    deployAccount,
    deployCurve,
    deployFactory,
    deployTokens,
    deployPair
)

// 1.1 ether
const delta = 11*10**17;
// 1 ether
const spotPrice = 10**18;
// 10 ether
const tokenAmount = 10*10**18;
const numItems = 2;
const protocolFeeMultiplier = 3*10**15;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    let (accountAddr) = deployAccount(0);
    %{
        context.accountAddr = ids.accountAddr
        print(f"accountAddr: {ids.accountAddr} (hex: {hex(ids.accountAddr)})")
    %}
    let (bondingCurveAddr) = deployCurve(CurveId.Linear);
    %{context.bondingCurveAddr = ids.bondingCurveAddr%}
    let (factoryAddr) = deployFactory(
        protocolFeeMultiplier=Uint256(low=protocolFeeMultiplier, high=0), 
        ownerAddress=accountAddr
    );
    %{
        context.factoryAddr = ids.factoryAddr
        print(f"factoryAddr: {ids.factoryAddr}")
    %}
    setBondingCurveAllowed(bondingCurveAddr, factoryAddr, accountAddr);
    let (erc20Addr, erc721Addr) = deployTokens(
        erc20Decimals=18,
        erc20InitialSupply=Uint256(low=1000*10**18, high=0),
        owner=accountAddr
    );
    %{
        context.erc20Addr = ids.erc20Addr
        print(f"erc20Addr: {ids.erc20Addr}")
        context.erc721Addr = ids.erc721Addr
        print(f"erc721Addr: {ids.erc721Addr}")
    %}
    let (pairAddr) = deployPair(
        accountAddr=accountAddr,
        factoryAddr=factoryAddr,
        erc20Addr=erc20Addr,
        erc721Addr=erc721Addr,
        bondingCurveAddr=bondingCurveAddr,
        poolType=PoolType.TRADE,
        initialNFTIds_len=numItems,
        initialERC20Balance=Uint256(low=100, high=0),
        spotPrice=Uint256(low=spotPrice, high=0),
        delta=Uint256(low=delta, high=0)
    );
    %{context.pairAddr = ids.pairAddr%}
    return ();
}

@external
func test_transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    alloc_locals;
    
    tempvar pairAddress;
    %{ids.pairAddress = context.pairAddress%}
    let (initialOwner) = INFTPair.owner(pairAddress);
    let newOwner = 58;

    INFTPair.transferOwnership(pairAddress, newOwner);

    let (finalOwner) = INFTPair.owner(pairAddress);
    if(newOwner != finalOwner) {
        with_attr error_mesage("PairAndFactory::transferOwnership - Owner not set correctly") {
            assert 1 = 2;
        }
    }

    return ();
}