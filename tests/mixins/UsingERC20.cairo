%lang starknet

from starkware.cairo.common.alloc import (alloc)
from starkware.cairo.common.cairo_builtins import (HashBuiltin)
from starkware.cairo.common.uint256 import (Uint256, uint256_mul)

from contracts.constants.library import (MAX_UINT_128)

from contracts.interfaces.tokens.IERC20 import (IERC20)
from contracts.interfaces.pairs.INFTPair import (INFTPair)
from contracts.interfaces.INFTPairFactory import (INFTPairFactory)

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
        senderAddr: felt,
        pairAddr: felt,
        numNFTs: Uint256,
        maxExpectedTokenInput: Uint256,
        nftRecipient: felt,
        isRouter: felt,
        routerCaller: felt
    ) {
        %{stop_pair_prank = start_prank(ids.senderAddr, ids.pairAddr)%}
        INFTPair.swapTokenForAnyNFTs(
            contract_address=pairAddr,
            numNFTs=numNFTs,
            maxExpectedTokenInput=maxExpectedTokenInput,
            nftRecipient=senderAddr,
            isRouter=isRouter,
            routerCaller=routerCaller
        );
        %{stop_pair_prank()%}
        return ();
    }
}

    // function swapTokenForAnyNFTs(
    //     LSSVMRouter router,
    //     LSSVMRouter.PairSwapAny[] calldata swapList,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.swapERC20ForAnyNFTs(
    //             swapList,
    //             inputAmount,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function swapTokenForSpecificNFTs(
    //     LSSVMRouter router,
    //     LSSVMRouter.PairSwapSpecific[] calldata swapList,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.swapERC20ForSpecificNFTs(
    //             swapList,
    //             inputAmount,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function swapNFTsForAnyNFTsThroughToken(
    //     LSSVMRouter router,
    //     LSSVMRouter.NFTsForAnyNFTsTrade calldata trade,
    //     uint256 minOutput,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.swapNFTsForAnyNFTsThroughERC20(
    //             trade,
    //             inputAmount,
    //             minOutput,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function swapNFTsForSpecificNFTsThroughToken(
    //     LSSVMRouter router,
    //     LSSVMRouter.NFTsForSpecificNFTsTrade calldata trade,
    //     uint256 minOutput,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.swapNFTsForSpecificNFTsThroughERC20(
    //             trade,
    //             inputAmount,
    //             minOutput,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function robustSwapTokenForAnyNFTs(
    //     LSSVMRouter router,
    //     LSSVMRouter.RobustPairSwapAny[] calldata swapList,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.robustSwapERC20ForAnyNFTs(
    //             swapList,
    //             inputAmount,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function robustSwapTokenForSpecificNFTs(
    //     LSSVMRouter router,
    //     LSSVMRouter.RobustPairSwapSpecific[] calldata swapList,
    //     address payable,
    //     address nftRecipient,
    //     uint256 deadline,
    //     uint256 inputAmount
    // ) public payable override returns (uint256) {
    //     return
    //         router.robustSwapERC20ForSpecificNFTs(
    //             swapList,
    //             inputAmount,
    //             nftRecipient,
    //             deadline
    //         );
    // }

    // function robustSwapTokenForSpecificNFTsAndNFTsForTokens(
    //     LSSVMRouter router,
    //     LSSVMRouter.RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    // ) public payable override returns (uint256, uint256) {
    //     return router.robustSwapERC20ForSpecificNFTsAndNFTsToToken(params);
    // }