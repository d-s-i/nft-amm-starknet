%lang starknet

@contract_interface
namespace INFTPairEnumerableETH {
    func initializer(
        factoryAddr:felt,
        bondingCurveAddr: felt,
        _poolType:felt,
        _nftAddress: felt,
        _spotPrice: felt,
        _delta: felt,
        _fee: felt,
        owner: felt,
        _assetRecipient: felt,
        wethAddress: felt
    ) {
    }
}