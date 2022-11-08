%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256, uint256_mul)

from contracts.constants.library import (MAX_UINT_128)

from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.IRouter import (IRouter)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

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

from tests.utils.library import (_mintERC721, _mintERC20)

namespace TokenStandard {
    func getBalance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        erc20Addr: felt,
        account: felt
    ) -> (balance: Uint256) {
        let (balance) = IERC20.balanceOf(erc20Addr, account);
        return (balance=balance);
    }

    func sendTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        erc20Addr: felt,
        from_: felt,
        to: felt,
        amount: Uint256
    ) {

        %{
            stop_prank_erc20 = start_prank(ids.from_, ids.erc20Addr)
        %}
        IERC20.transferFrom(erc20Addr, from_, to, amount);
        return ();
    }

    func setupPair{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        accountAddr: felt,
        factoryAddr: felt,
        erc20Addr: felt,
        erc721Addr: felt,
        bondingCurveAddr: felt,
        poolType: felt,
        initialNFTIds_len: felt,
        initialERC20Balance: Uint256,
        spotPrice: Uint256,
        delta: Uint256
    ) -> (pairAddress: felt) {
        alloc_locals;

        tempvar MAX_UINT_256 = Uint256(low=MAX_UINT_128, high=MAX_UINT_128);

        %{
            stop_prank_factory = start_prank(ids.accountAddr, ids.factoryAddr)

            # Set allowances on factory for tokens
            store(ids.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_128, ids.MAX_UINT_128], [ids.accountAddr, ids.factoryAddr])
            store(ids.erc721Addr, "ERC721_operator_approvals", [1], [ids.accountAddr, ids.factoryAddr])
        %}
        let (nftIds: Uint256*) = alloc();
        let (amountToMint, amontToMintHigh) = uint256_mul(initialERC20Balance, Uint256(low=10, high=0));
        _mintERC721(erc721Addr, 0, initialNFTIds_len, nftIds, accountAddr, accountAddr);
        _mintERC20(erc20Addr, amountToMint, accountAddr, accountAddr);
        
        // displayIds(nftIds, 0, initialNFTIds_len);

        %{stop_prank_erc721 = start_prank(ids.accountAddr, ids.erc721Addr)%}
        let (pairAddress) = INFTPairFactory.createPairERC20(
            contract_address=factoryAddr,
            _erc20Address=erc20Addr,
            _nftAddress=erc721Addr,
            _bondingCurve=bondingCurveAddr,
            _assetRecipient=0,
            _poolType=poolType,
            _delta=delta,
            _fee=0,
            _spotPrice=spotPrice,
            _initialNFTIds_len=initialNFTIds_len,
            _initialNFTIds=nftIds,
            initialERC20Balance=initialERC20Balance
        );

        %{
            store(ids.erc20Addr, "ERC20_allowances", [ids.MAX_UINT_128, ids.MAX_UINT_128], [ids.accountAddr, ids.pairAddress])
            store(ids.erc721Addr, "ERC721_operator_approvals", [1], [ids.accountAddr, ids.pairAddress])

            stop_prank_factory()
            stop_prank_erc721()
        %}

        return (pairAddress=pairAddress);
    }

    func withdrawTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        pairAddr: felt,
        erc20Addr: felt,
        owner: felt
    ) {
        let (balance) = IERC20.balanceOf(
            erc20Addr,
            pairAddr
        );
        %{stop_prank_pair = start_prank(ids.owner, ids.pairAddr)%}
        INFTPair.withdrawERC20(pairAddr, erc20Addr, balance);
        %{stop_prank_pair()%}
        return ();
    }

    func withdrawProtocolFees{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        factoryAddr: felt,
        erc20Addr: felt,
        factoryOwner: felt
    ) {
        let (balance) = IERC20.balanceOf(
            erc20Addr,
            factoryAddr
        );
        %{stop_prank_factory = start_prank(ids.factoryOwner, ids.factoryAddr)%}
        INFTPairFactory.withdrawERC20ProtocolFees(
            factoryAddr,
            erc20Addr,
            balance
        );
        %{stop_prank_factory()%}
        return ();
    }

    func swapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
        swapList_len: felt,
        swapList: PairSwapAny*,
        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
        let (remainingValue) = IRouter.swapERC20ForAnyNFTs(
            contract_address=routerAddr,
            swapList_len=swapList_len,
            swapList=swapList,
            inputAmount=inputAmount,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue);
    }

    func swapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
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
        let (remainingValue) = IRouter.swapERC20ForSpecificNFTs(
            contract_address=routerAddr,
            swapList_len=swapList_len,
            // swapList: PairSwapSpecific*,
            // PairSwapSpecific.pairs*
            pairs_len=pairs_len,
            pairs=pairs,
            // PairSwapSpecific.nftIds_len*
            nftIds_len_len=nftIds_len_len,
            nftIds_len=nftIds_len,    
            // PairSwapSpecific.nftIds
            nftIds_ptrs_len=nftIds_ptrs_len,
            nftIds_ptrs=nftIds_ptrs,

            inputAmount=inputAmount,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue); 
    }

    func swapNFTsForAnyNFTsThroughToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
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
    ) -> (remainingValue: Uint256) {
        let (remainingValue) = IRouter.swapNFTsForAnyNFTsThroughERC20(
            contract_address=routerAddr,
            nftToTokenTrades_len=nftToTokenTrades_len,
            // PairSwapSpecific.pairs*
            pairs_len=pairs_len,
            pairs=pairs,
            // PairSwapSpecific.nftIds_len*
            nftIds_len_len=nftIds_len_len,
            nftIds_len=nftIds_len,    
            // PairSwapSpecific.nftIds
            nftIds_ptrs_len=nftIds_ptrs_len,
            nftIds_ptrs=nftIds_ptrs,

            tokenToNFTTrades_len=tokenToNFTTrades_len,
            tokenToNFTTrades=tokenToNFTTrades,

            inputAmount=inputAmount,
            minOutput=minOutput,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue);     
    }

    func swapNFTsForSpecificNFTsThroughToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
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
    ) -> (remainingValue: Uint256) {
        let (remainingValue) = IRouter.swapNFTsForSpecificNFTsThroughERC20(
            contract_address=routerAddr,
            // trade: NFTsForSpecificNFTsTrade,
            nftToTokenTrades_len=nftToTokenTrades_len,
            // nftToTokenTrades: PairSwapSpecific*,
            // PairSwapSpecific.pairs*
            nftToTokenTrades_pairs_len=nftToTokenTrades_pairs_len,
            nftToTokenTrades_pairs=nftToTokenTrades_pairs,
            // PairSwapSpecific.nftIds_len*
            nftToTokenTrades_nftIds_len_len=nftToTokenTrades_nftIds_len_len,
            nftToTokenTrades_nftIds_len=nftToTokenTrades_nftIds_len,    
            // PairSwapSpecific.nftIds
            nftToTokenTrades_nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
            nftToTokenTrades_nftIds_ptrs=nftToTokenTrades_nftIds_ptrs,

            tokenToNFTTrades_len=tokenToNFTTrades_len,
            // tokenToNFTTrades: PairSwapSpecific*,
            // PairSwapSpecific.pairs*
            tokenToNFTTrades_pairs_len=tokenToNFTTrades_pairs_len,
            tokenToNFTTrades_pairs=tokenToNFTTrades_pairs,
            // PairSwapSpecific.nftIds_len*
            tokenToNFTTrades_nftIds_len_len=tokenToNFTTrades_nftIds_len_len,
            tokenToNFTTrades_nftIds_len=tokenToNFTTrades_nftIds_len,    
            // PairSwapSpecific.nftIds
            tokenToNFTTrades_nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
            tokenToNFTTrades_nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs,

            inputAmount=inputAmount,
            minOutput=minOutput,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue);     
    }

    func robustSwapTokenForAnyNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
        swapList_len: felt,
        swapList: RobustPairSwapAny*,
        inputAmount: Uint256,
        nftRecipient: felt,
        deadline: felt
    ) -> (remainingValue: Uint256) {
        let (remainingValue) = IRouter.robustSwapERC20ForAnyNFTs(
            contract_address=routerAddr,
            swapList_len=swapList_len,
            swapList=swapList,
            inputAmount=inputAmount,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue);     
    }

    func robustSwapTokenForSpecificNFTs{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
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
        let (remainingValue) = IRouter.robustSwapERC20ForSpecificNFTs(
            contract_address=routerAddr,
            swapList_len=swapList_len,
            // swapList: RobustPairSwapSpecific*,
            // swapInfos: PairSwapSpecific*,
            // PairSwapSpecific.pairs*
            pairs_len=pairs_len,
            pairs=pairs,
            // PairSwapSpecific.nftIds_len*
            nftIds_len_len=nftIds_len_len,
            nftIds_len=nftIds_len,    
            // PairSwapSpecific.nftIds
            nftIds_ptrs_len=nftIds_ptrs_len,
            nftIds_ptrs=nftIds_ptrs,
            maxCosts_len=maxCosts_len,
            maxCosts=maxCosts,

            inputAmount=inputAmount,
            nftRecipient=nftRecipient,
            deadline=deadline
        );
        return (remainingValue=remainingValue);   
    }

    func robustSwapTokenForSpecificNFTsAndNFTsForTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}(
        callerAddr: felt,
        routerAddr: felt,
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
    ) -> (remainingValue: Uint256) {
        let (remainingValue) = IRouter.robustSwapERC20ForSpecificNFTs(
            contract_address=routerAddr,
            // params: RobustPairNFTsForTokenAndTokenForNFTsTrade
            tokenToNFTTrades_len=tokenToNFTTrades_len,
            // tokenToNFTTrades: RobustPairSwapSpecific*,
            // PairSwapSpecific.pairs*
            tokenToNFTTrades_pairs_len=tokenToNFTTrades_pairs_len,
            tokenToNFTTrades_pairs=tokenToNFTTrades_pairs,
            // PairSwapSpecific.nftIds_len*
            tokenToNFTTrades_nftIds_len_len=tokenToNFTTrades_nftIds_len_len,
            tokenToNFTTrades_nftIds_len=tokenToNFTTrades_nftIds_len,    
            // PairSwapSpecific.nftIds
            tokenToNFTTrades_nftIds_ptrs_len=tokenToNFTTrades_nftIds_ptrs_len,
            tokenToNFTTrades_nftIds_ptrs=tokenToNFTTrades_nftIds_ptrs,
            maxCosts_len=maxCosts_len,
            maxCosts=maxCosts,    

            nftToTokenTrades_len=nftToTokenTrades_len,
            // nftToTokenTrades: RobustPairSwapSpecificForToken*,
            // PairSwapSpecific.pairs*
            nftToTokenTrades_pairs_len=nftToTokenTrades_pairs_len,
            nftToTokenTrades_pairs=nftToTokenTrades_pairs,
            // PairSwapSpecific.nftIds_len*
            nftToTokenTrades_nftIds_len_len=nftToTokenTrades_nftIds_len_len,
            nftToTokenTrades_nftIds_len=nftToTokenTrades_nftIds_len,    
            // PairSwapSpecific.nftIds
            nftToTokenTrades_nftIds_ptrs_len=nftToTokenTrades_nftIds_ptrs_len,
            nftToTokenTrades_nftIds_ptrs=nftToTokenTrades_nftIds_ptrs,    
            minOutputs_len=minOutputs_len,
            minOutputs=minOutputs,    

            inputAmount=inputAmount,
            tokenRecipient=tokenRecipient,
            nftRecipient=nftRecipient,
            deadline=deadline  
        );
        return (remainingValue=remainingValue);     
    }
}