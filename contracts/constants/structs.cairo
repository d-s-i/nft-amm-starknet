%lang starknet

struct PoolType {
    TOKEN: felt,
    NFT: felt,
    TRADE: felt,
}

struct PairVariant {
    ENUMERABLE_ETH: felt,
    MISSING_ENUMERABLE_ETH: felt,
    ENUMERABLE_ERC20: felt,
    MISSING_ENUMERABLE_ERC20: felt,
}