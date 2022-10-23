import { bnToUint256, UINT_128_MAX } from "starknet/dist/utils/uint256";

const feltToUint = function(felt: BigInt) {
    return (bnToUint256(felt));
}

// uint256 internal constant YAD = 1e8;
// uint256 internal constant WAD = 1e18;
// uint256 internal constant RAY = 1e27;
// uint256 internal constant RAD = 1e45;
// console.log("1e8", feltToUint(BigInt(100000000)));
// console.log("1e18", feltToUint(BigInt(1000000000000000000)));
// console.log("1e27", feltToUint(BigInt(1000000000000000000000000000)));
// console.log("1e45", feltToUint(BigInt(1000000000000000000000000000000000000000000000)));
// console.log(feltToUint(BigInt(340282366920938463463374607431768211456)));

console.log(UINT_128_MAX);