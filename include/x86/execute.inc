
.ifndef _X86_EXECUTE_
    _X86_EXECUTE_ = 1

    .scope Execute

        .import execute

        .import get_carry_flag
        .import set_carry_flag
        .import clear_carry_flag

        .import get_parity_flag
        .import set_parity_flag
        .import clear_parity_flag

        .import get_auxiliary_flag
        .import set_auxiliary_flag
        .import clear_auxiliary_flag

        .import get_zero_flag
        .import set_zero_flag
        .import clear_zero_flag

        .import get_sign_flag
        .import set_sign_flag
        .import clear_sign_flag

        .import get_trap_flag
        .import set_trap_flag
        .import clear_trap_flag

        .import get_interrupt_flag
        .import set_interrupt_flag
        .import clear_interrupt_flag

        .import get_direction_flag
        .import set_direction_flag
        .import clear_direction_flag

        .import get_overflow_flag
        .import set_overflow_flag
        .import clear_overflow_flag

    .endscope

.endif
