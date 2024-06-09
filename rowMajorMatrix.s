.data
read_row_matrix_prompt_p:   .asciiz "Enter an integer: "
###########################################################

.text
read_row_matrix:
    li $t3, 0               # initialize outer-loop counter to 0

read_row_matrix_loop_outer:
    bge $t3, $t1, read_row_matrix_loop_outer_end

    li $t4, 0               # initialize inner-loop counter to 0

read_row_matrix_loop_inner:
    bge $t4, $t2, read_row_matrix_loop_inner_end

    mul $t5, $t3, $t2       # $t5 <-- width * i
    add $t5, $t5, $t4       # $t5 <-- width * i + j
    sll $t5, $t5, 2         # $t5 <-- 2^2 * (width * i + j)
    add $t5, $t0, $t5       # $t5 <-- base address + (2^2 * (width * i + j))

    li $v0, 4               # prompt for number
    la $a0, read_row_matrix_prompt_p
    syscall

    li $v0, 5               # read a integer number
    syscall

    sw $v0, 0($t5)          # store input number into array

    addiu $t4, $t4, 1       # increment inner-loop counter

    b read_row_matrix_loop_inner    # branch unconditionally back to beginning of the inner loop

read_row_matrix_loop_inner_end:
    addiu $t3, $t3, 1       # increment outer-loop counter

    b read_row_matrix_loop_outer    # branch unconditionally back to beginning of the outer loop

read_row_matrix_loop_outer_end:
