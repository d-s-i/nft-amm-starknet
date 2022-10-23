%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin)

@storage_var
func test() -> (res: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr: felt}() {
    test.write(1);
    return ();
}
