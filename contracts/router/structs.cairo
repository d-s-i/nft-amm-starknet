%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

struct PairSwapAny {
    pair: felt,
    numItems: Uint256,
}

struct PairSwapSpecific {
    pair: felt,
    nftIds_len: felt,
    nftIds: Uint256*,
}

struct NFTsForAnyNFTsTrade {
    nftToTokenTrades_len: felt,
    nftToTokenTrades: PairSwapSpecific*,

    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: PairSwapAny*,
}

struct NFTsForSpecificNFTsTrade {
    nftToTokenTrades_len: felt,
    nftToTokenTrades: PairSwapSpecific*,

    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: PairSwapSpecific*,
}

struct RobustPairSwapAny {
    swapInfo: PairSwapAny,
    maxCost: Uint256,
}

struct RobustPairSwapSpecific {
    swapInfo: PairSwapSpecific,
    maxCost: Uint256,
}

struct RobustPairSwapSpecificForToken {
    swapInfo: PairSwapSpecific,
    minOutput: Uint256,
}

struct RobustPairNFTsForTokenAndTokenForNFTsTrade {
    tokenToNFTTrades_len: felt,
    tokenToNFTTrades: RobustPairSwapSpecific*,

    nftToTokenTrades_len: felt,
    nftToTokenTrades: RobustPairSwapSpecificForToken*,

    inputAmount: Uint256,
    tokenRecipient: felt,
    nftRecipient: felt,
    deadline: felt,
}