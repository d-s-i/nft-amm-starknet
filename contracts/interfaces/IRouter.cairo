%lang starknet

from starkware.cairo.common.uint256 import (Uint256)

from contracts.router.structs import (
    PairSwapAny,
    PairSwapSpecific,
    NFTsForAnyNFTsTrade,
    NFTsForSpecificNFTsTrade,
    RobustPairSwapAny,
    RobustPairSwapSpecific,
    RobustPairSwapSpecificForToken,
    RobustPairNFTsForTokenAndTokenForNFTsTrade
)

@contract_interface
namespace IRouter {
    func swapERC20ForAnyNFTs(
        swapList_len: felt,
        swapList: PairSwapAny*,
        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
    }
    func swapERC20ForSpecificNFTs(
        swapList_len: felt,
        // swapList: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len: felt,
        pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len: felt,
        nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len: felt,
        nftIds_ptrs: Uint256*,

        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
    }
    func swapNFTsForToken(
        swapList_len: felt,
        // PairSwapSpecific.pairs*
        pairs_len: felt,
        pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len: felt,
        nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len: felt,
        nftIds_ptrs: Uint256*,

        minOutput: Uint256,
        tokenRecipient: felt,
        deadline: felt
    ) -> (outputAmount: Uint256) {
    }
    func swapNFTsForAnyNFTsThroughERC20(
        nftToTokenTrades_len: felt,
        // PairSwapSpecific.pairs*
        pairs_len: felt,
        pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len: felt,
        nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len: felt,
        nftIds_ptrs: Uint256*,

        tokenToNFTTrades_len: felt,
        tokenToNFTTrades: PairSwapAny*,

        inputAmount: Uint256,
        minOutput: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (outputAmount: Uint256) {
    }
    func swapNFTsForSpecificNFTsThroughERC20(
        // trade: NFTsForSpecificNFTsTrade,
        nftToTokenTrades_len: felt,
        // nftToTokenTrades: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        nftToTokenTrades_pairs_len: felt,
        nftToTokenTrades_pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftToTokenTrades_nftIds_len_len: felt,
        nftToTokenTrades_nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftToTokenTrades_nftIds_ptrs_len: felt,
        nftToTokenTrades_nftIds_ptrs: Uint256*,

        tokenToNFTTrades_len: felt,
        // tokenToNFTTrades: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        tokenToNFTTrades_pairs_len: felt,
        tokenToNFTTrades_pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        tokenToNFTTrades_nftIds_len_len: felt,
        tokenToNFTTrades_nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        tokenToNFTTrades_nftIds_ptrs_len: felt,
        tokenToNFTTrades_nftIds_ptrs: Uint256*,

        inputAmount: Uint256,
        minOutput: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (outputAmount: Uint256) {
    }
    func robustSwapERC20ForAnyNFTs(
        swapList_len: felt,
        swapList: RobustPairSwapAny*,
        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
    }
    func robustSwapERC20ForSpecificNFTs(
        swapList_len: felt,
        // swapList: RobustPairSwapSpecific*,
        // swapInfos: PairSwapSpecific*,
        // PairSwapSpecific.pairs*
        pairs_len: felt,
        pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len: felt,
        nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len: felt,
        nftIds_ptrs: Uint256*,
        maxCosts_len: felt,
        maxCosts: Uint256*,

        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
    }
    func robustSwapNFTsForToken(
        swapList_len: felt,
        // swapList: RobustPairSwapSpecificForToken*,
        // swapInfo: PairSwapSpecific,
        // PairSwapSpecific.pairs*
        pairs_len: felt,
        pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftIds_len_len: felt,
        nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftIds_ptrs_len: felt,
        nftIds_ptrs: Uint256*,    
        minOutputs_len: felt,
        minOutputs: Uint256*,

        tokenRecipient: felt,
        deadline: felt
    ) -> (outputAmount: Uint256) {
    }
    func robustSwapERC20ForSpecificNFTsAndNFTsToToken(
        // params: RobustPairNFTsForTokenAndTokenForNFTsTrade
        tokenToNFTTrades_len: felt,
        // tokenToNFTTrades: RobustPairSwapSpecific*,
        // PairSwapSpecific.pairs*
        tokenToNFTTrades_pairs_len: felt,
        tokenToNFTTrades_pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        tokenToNFTTrades_nftIds_len_len: felt,
        tokenToNFTTrades_nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        tokenToNFTTrades_nftIds_ptrs_len: felt,
        tokenToNFTTrades_nftIds_ptrs: Uint256*,
        maxCosts_len: felt,
        maxCosts: Uint256*,    

        nftToTokenTrades_len: felt,
        // nftToTokenTrades: RobustPairSwapSpecificForToken*,
        // PairSwapSpecific.pairs*
        nftToTokenTrades_pairs_len: felt,
        nftToTokenTrades_pairs: felt*,
        // PairSwapSpecific.nftIds_len*
        nftToTokenTrades_nftIds_len_len: felt,
        nftToTokenTrades_nftIds_len: felt*,    
        // PairSwapSpecific.nftIds
        nftToTokenTrades_nftIds_ptrs_len: felt,
        nftToTokenTrades_nftIds_ptrs: Uint256*,    
        minOutputs_len: felt,
        minOutputs: Uint256*,    

        inputAmount: Uint256,
        tokenRecipient: felt,
        nftRecipient: felt,
        deadline: felt  
    ) -> (remainingValue: Uint256, outputAmount: Uint256) {
    }

    func pairTransferNFTFrom(
        nftAddress: felt,
        _from: felt,
        to: felt,
        id: Uint256
    ) {
    }

    func pairTransferERC20From(
        tokenAddress: felt,
        from_: felt,
        to: felt,
        amount: Uint256
    ) {
    }
}