########################################################################
#
# 1521 spim -f cellular.s
# 1521 autotest cellular
# give cs1521 ass1_cellular cellular.s

# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE  =    1
MAX_WORLD_SIZE  =  128
MIN_GENERATIONS = -256
MAX_GENERATIONS =  256
MIN_RULE        =    0
MAX_RULE        =  255

# Characters used to print alive/dead cells.

ALIVE_CHAR      = '#'
DEAD_CHAR       = '.'

# Maximum number of bytes needs to store all generations of cells.
# static int8_t cells[MAX_GENERATIONS + 1][MAX_WORLD_SIZE];
MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

    .data

# `cells' is used to store successive generations.
# Each byte will be 1 if the cell is alive in that generation, 0 otherwise.

cells:                  .space MAX_CELLS_BYTES

# Some strings you'll need to use:

prompt_world_size:      .asciiz "Enter world size: "
error_world_size:       .asciiz "Invalid world size\n"
prompt_rule:            .asciiz "Enter rule: "
error_rule:             .asciiz "Invalid rule\n"
prompt_n_generations:   .asciiz "Enter how many generations: "
error_n_generations:    .asciiz "Invalid number of generations\n"

########################################################################
# .TEXT <main>
    .text

# Frame:        $ra
# Uses:         $a0, $v0, $s0, $s1, $s2, $s3, $s4
# Clobbers:     $a0, $a1, $a2

# Locals:
#       - `world_size' in $s0
#       - `rule' in $s1
#       - `n_generations' in $s2
#       - `reverse' in $s3
#       - `g' in $s4

# Structure:
#       main
#       -> main_pro
#       -> main_body
#       -> invalid_size
#         -> return_1
#       -> invalid_rule
#         -> return_1
#       -> invalid_generation
#         -> return_1
#       -> reverse
#       -> next
#       -> loop_run
#          -> run_generation !!
#       -> then
#          -> loop_print_neg
#          	  -> print_generation !!
#          -> loop_print_pos
#          	  -> print_generation !!
#       -> main_epi

main:                               # int main(int argc, char *argv[]) {

main_pro:                           # Main's prologue
    addi    $sp, $sp, -4            # move stack pointer down to make room
    sw      $ra, 0($sp)             # save $ra on $stack

main_body:
    # read world size from stdin
    la      $a0, prompt_world_size
    li      $v0, 4                  # printf("Enter world size: ");
    syscall

    li      $v0, 5                  # scanf("%d", &world_size);
    syscall
    move    $s0, $v0                # s0 = world_size

    # if (world_size < MIN_WORLD_SIZE) {
    blt     $s0, MIN_WORLD_SIZE, invalid_size

    # if (world_size > MAX_WORLD_SIZE) {
    bgt     $s0, MAX_WORLD_SIZE, invalid_size

    # read rule from stdin
    la      $a0, prompt_rule
    li      $v0, 4                  # printf("Enter rule: ");
    syscall

    li      $v0, 5                  # scanf("%d", &rule);
    syscall
    move    $s1, $v0                # s1 = rule

    # if (rule < MIN_RULE) {
    blt     $s1, MIN_RULE, invalid_rule

    # if (rule > MAX_RULE) {
    bgt     $s1, MAX_RULE, invalid_rule

    # read world size from stdin
    la      $a0, prompt_n_generations
    li      $v0, 4                  # printf("Enter how many generations: ");
    syscall

    li      $v0, 5                  # scanf("%d", &n_generations);
    syscall
    move    $t0, $v0                # t0 = n_generation

    # if (n_generations < MIN_GENERATIONS) {
    blt     $t0, MIN_GENERATIONS, invalid_generation

    # if (n_generations > MAX_GENERATIONS) {
    bgt     $t0, MAX_GENERATIONS, invalid_generation

    li      $a0, '\n'               # putchar('\n');
    li      $v0, 11
    syscall

    # negative generations means show the generations in reverse
    li      $t1, 0                  # int reverse = 0; t1 -> reverse

    blt     $t0, 0, if_reverse      # if (n_generations < 0) {

    b next

if_reverse:
    addi    $t1, $t1, 1             # reverse = 1; t1 -> reverse

    neg     $t0, $t0                # t0 -> n_generations = -n_generations;

    b next                          # }

next:
    # // the first generation always has a only single cell which is alive
    # // this cell is in the middle of the world
    move    $s2, $t0                #  s2 -> +/- n_generations
    move    $s3, $t1                #  s3 -> reverse

    # cells[0][world_size / 2] = 1;
    div     $t5, $s0, 2             # $t5 = world_size / 2
    addi    $t6, $t5, 0             # $t6 = $t5 + $t7
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $t5 -> cells[g][x]

    li      $t0, 1                  # $t0 = 1

    sb      $t0, 0($t5)             # cells[0][world_size / 2] = 1;

    li      $s4, 1                  # g = 0; t0 -> g

loop_run:
    # for (int g = 1; g <= n_generations; g++) {
    bgt     $s4, $s2, then          # if (g > n_generations) {then}

    move    $a1, $s0                # a0 -> world_size
    move    $a2, $s4                # a1 -> g
    move    $a3, $s1                # a2 -> rule

    jal     run_generation          # run_generation(world_size, g, rule);

    add     $s4, $s4, 1             # g++

    b       loop_run                # }
then:
    # n_generation is negative
    addi    $s4, $s2, 0	            # g = n_generations

    bne     $s3, 0, loop_print_neg  # if (reverse != 0) {

    # n_generation is positive
    li      $s4, 0                  # g = 0

    beq     $s3, 0, loop_print_pos  # else {

loop_print_neg:
    # for (int g = n_generations; g >= 0; g--) {
    blt     $s4, 0, main_epi        # if (g < 0) {return_0}

    move    $a1, $s0                # a0 -> world_size
    move    $a2, $s4                # a1 -> g

    jal     print_generation        # print_generation(world_size, g);

    sub     $s4, $s4, 1             # g--

    b       loop_print_neg          # }

loop_print_pos:
    # for (int g = 0; g <= n_generations; g++) {
    bgt     $s4, $s2, main_epi      # if (g > n_generations) {return_0}

    move    $a1, $s0                # a0 -> world_size
    move    $a2, $s4                # a1 -> g

    jal     print_generation        # print_generation(world_size, g);

    add     $s4, $s4, 1             # g++

    b       loop_print_pos          # }

invalid_size:
    la      $a0, error_world_size
    li      $v0, 4                  # printf("Invalid world size\n");
    syscall

    b       return_1                # }

invalid_rule:
    la      $a0, error_rule
    li      $v0, 4                  # printf("Invalid rule\n");
    syscall

    b       return_1                # }

invalid_generation:
    la      $a0, error_n_generations
    li      $v0, 4                  # printf("Invalid number of generations\n");
    syscall

    b       return_1                # }

return_1:
    li      $v0, 1                  # return 1;
    jr      $ra

main_epi:                           # Main's epilogue
    lw      $ra, 0($sp)             # recover $ra from $stack
    addi    $sp, $sp, 4
    # move stack pointer back up to what it was when main called

    li      $v0, 10                 # exit
    syscall


#######################################################################
# Frame:        $ra
# Uses:         $v0, $t0, $t1, $t2, $t3, $t4, $t5, $t6, $t7
# Clobbers:     $a0, $a1, $a2, $a3

# Locals:
#       - `world_size' in $a1
#       - `rule' in $a3
#       - `g' in $a2

# Structure:
#       run_generation
#       -> run_generation_pro
#       -> run_generation_body
#       -> run_for_loop
#         -> if_left
#         -> left_done
#         -> if_right
#         -> right_done
#         -> if_set
#         -> if_not_set
#       -> run_generation_epi

# Given `world_size', `which_generation', and `rule', calculate
# a new generation according to `rule' and store it in `cells'.

run_generation:
# static void run_generation(int world_size, int which_generation, int rule) {
run_generation_pro:                 # run_generation's prologue
    addi	$sp, $sp, -24

    sw      $s0,  0($sp)            # s0 -> world_size
    sw      $s1,  4($sp)            # s1 -> rule
    sw      $s2,  8($sp)            # s2 -> n_generations
    sw      $s3, 12($sp)            # s3 -> reverse
    sw      $s4, 16($sp)            # s4 -> g
    sw      $ra, 20($sp)            # ra

run_generation_body:
    li      $t1, 0                  # int x = 0; t1 -> x

run_for_loop:
    # // Get the values in the left and right neighbour cells.
    # // This requires some care, otherwise we could read beyond the
    # // bounds of the array.  In the cases we are at the limits of
    # // the function, we consider those out-of-bounds cells zero.

    # for (int x = 0; x < world_size; x++) {
    bge     $t1, $a1, run_generation_epi    # if(x >= world_size) return

    # left
    li      $t2, 0                  # int left = 0; t2 -> left

    bgt     $t1, 0, if_left         # if (x > 0) {

left_done:
    # centre
    # int centre = cells[which_generation - 1][x];
    sub     $t0, $a2, 1             # $t0 = g - 1

    mul     $t5, $t0, $a1           # $s0 = $t0 * world_size
    add     $t6, $t5, $t1           # $s1 = $s0 + $t0
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $s3 -> cells[g-1][x]

    lb      $t3, 0($t5)             # $t3 -> centre

    # right
    li      $t4, 0                  # int right = 0; t4 -> right

    sub     $t5, $a1, 1             # t5 -> world_size - 1

    blt     $t1, $t5, if_right      # if (x < world_size - 1) {

right_done:
    # // Convert the left, centre, and right states into one value.
    # int state = left << 2 | centre << 1 | right << 0;

    sll     $t2, $t2, 2             # left = left << 2
    sll     $t3, $t3, 1             # centre = centre << 1
    sll     $t4, $t4, 0             # right = right << 0
    or      $t5, $t2, $t3           # t5 -> state = left | centre
    or      $t5, $t5, $t4           # t5 -> state = state | right

    # // And check whether that bit is set or not in the rule.
    # // by testing the corresponding bit of the rule number.
    # int bit = 1 << state;
    li      $t7, 1                  # int t7 = 1

    sllv    $t6, $t7, $t5           # t6 -> bit = 1 << state

    # int set = rule & bit;
    and     $t7, $a3, $t6           # t7 -> set = rule & bit

    bne     $t7, 0, if_set          # if (set != 0) {
    b       if_not_set              # } else {

if_left:
    # left = cells[which_generation - 1][x - 1];
    sub     $t0, $a2, 1             # $t0 = g - 1
    sub     $t7, $t1, 1             # $t7 = x - 1

    mul     $t5, $t0, $a1           # $t5 = $t0 * world_size
    add     $t6, $t5, $t7           # $t6 = $t5 + $t7
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $t5 -> cells[g - 1][x - 1]

    lb      $t2, 0($t5)             # $t2 -> left

    b       left_done               # }

if_right:
    # right = cells[which_generation - 1][x + 1];
    sub     $t0, $a2, 1             # $t0 = g - 1
    addi    $t7, $t1, 1             # $t7 = x + 1

    mul     $t5, $t0, $a1           # $t5 = $t0 * world_size
    add     $t6, $t5, $t7           # $t6 = $t5 + $t7
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $t5 -> cells[g - 1][x + 1]

    lb      $t4, 0($t5)             # $t4 -> right

    b       right_done              # }

if_not_set:
    # cells[which_generation][x] = 1;
    mul     $t5, $a2, $a1           # $t5 = $t0 * world_size
    add     $t6, $t5, $t1           # $t6 = $t5 + $t7
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $t5 -> cells[g][x]

    li      $t0, 0                  # $t0 = 0

    sb      $t0, 0($t5)             # cells[g][x] = 0;

    addi    $t1, $t1, 1             # x++;

    b       run_for_loop            # }

if_set:
    # cells[which_generation][x] = 0;
    mul     $t5, $a2, $a1           # $t5 = $t0 * world_size
    add     $t6, $t5, $t1           # $t6 = $t5 + $t7
    la      $t7, cells              # get address of cells array
    add     $t5, $t7, $t6           # $t5 -> cells[g][x]

    li      $t0, 1                  # $t0 = 1

    sb      $t0, 0($t5)             # cells[g][x] = 1;

    addi    $t1, $t1, 1             # x++;

    b       run_for_loop            # }

run_generation_epi:                 # run_generation's epilogue
    lw      $s0,  0($sp)            # s0 -> world_size
    lw      $s1,  4($sp)            # s1 -> rule
    lw      $s2,  8($sp)            # s2 -> n_generations
    lw      $s3, 12($sp)            # s3 -> reverse
    lw      $s4, 16($sp)            # s4 -> g
    lw      $ra, 20($sp)            # ra

    addi    $sp, $sp, 24

    jr      $ra                     # return to caller (main)

#######################################################################
# Frame:        $ra
# Uses:         $v0, $t0, $t1, $t2, $t3, $t4, $t5
# Clobbers:     $a0, $a1, $a2

# Locals:
#       - `world_size' in $a1
#       - `g' in $a2

# Structure:
#       print_generation
#       -> print_generation_pro
#       -> print_generation_body
#       -> print
#         -> print_else
#         -> print_if
#       -> print_end
#       -> print_generation_epi

# Given `world_size', and `which_generation', print out the
# specified generation.
#

print_generation:
# static void print_generation(int world_size, int which_generation) {

print_generation_pro:               # print_generation's prologue
    addi    $sp, $sp, -24

    sw      $s0,  0($sp)            # s0 -> world_size
    sw      $s1,  4($sp)            # s1 -> rule
    sw      $s2,  8($sp)            # s2 -> n_generations
    sw      $s3, 12($sp)            # s3 -> reverse
    sw      $s4, 16($sp)            # s4 -> g
    sw      $ra, 20($sp)            # ra

print_generation_body:
    # a2 -> which_generation = g
    move    $a0, $a2                # printf("%d", which_generation);
    li      $v0, 1
    syscall

    li      $a0, '\t'               # putchar('\t');
    li      $v0, 11
    syscall

    li      $t1, 0                  # int x = 0; $t1 -> x

print:
    # for (int x = 0; x < world_size; x++) {
    bge     $t1, $a1, print_end     # if (x >= world_size) return

    mul     $t2, $a2, $a1           # $t2 = g * world_size
    add     $t3, $t2, $t1           # $t3 = $t2 + x
    la      $t4, cells              # get address of cells array
    add     $t5, $t4, $t3           # $t5 -> cells[g][x]

    lb      $t5, 0($t5)             # load byte of cells[g][x]

    bne     $t5, 0, print_if        # if (cells[which_generation][x] != 0) {

print_else:
    # else {
    li      $a0, DEAD_CHAR          # putchar(DEAD_CHAR);
    li      $v0, 11
    syscall

    addi    $t1, $t1, 1             # x++;

    b       print                   # }

print_if:
    li      $a0, ALIVE_CHAR         # putchar(DEAD_CHAR);
    li      $v0, 11
    syscall

    addi    $t1, $t1, 1             # x++;

    b       print

print_end:
    li      $a0, '\n'               # putchar('\n');
    li      $v0, 11
    syscall

    b print_generation_epi

print_generation_epi:               # print_generation's epilogue
    lw      $s0,  0($sp)            # s0 -> world_size
    lw      $s1,  4($sp)            # s1 -> rule
    lw      $s2,  8($sp)            # s2 -> n_generations
    lw      $s3, 12($sp)            # s3 -> reverse
    lw      $s4, 16($sp)            # s4 -> g
    lw      $ra, 20($sp)            # ra

    addi    $sp, $sp, 24

    jr      $ra                     # return to caller (main)
