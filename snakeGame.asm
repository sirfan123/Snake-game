# Samih Irfan
# sai48

# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Game grid dimensions.
.eqv GRID_CELL_SIZE 4 # pixels
.eqv GRID_WIDTH  16 # cells
.eqv GRID_HEIGHT 14 # cells
.eqv GRID_CELLS 224 #= GRID_WIDTH * GRID_HEIGHT

# How long the snake can possibly be.
.eqv SNAKE_MAX_LEN GRID_CELLS # segments

# How many frames (1/60th of a second) between snake movements.
.eqv SNAKE_MOVE_DELAY 12 # frames

# How many apples the snake needs to eat to win the game.
.eqv APPLES_NEEDED 20

# ------------------------------------------------------------------------------------------------
.data

# set to 1 when the player loses the game (running into the walls/other part of the snake).
lost_game: .word 0

# the direction the snake is facing (one of the DIR_ constants).
snake_dir: .word DIR_N

# how long the snake is (how many segments).
snake_len: .word 2

# parallel arrays of segment coordinates. index 0 is the head.
snake_x: .byte 0:SNAKE_MAX_LEN
snake_y: .byte 0:SNAKE_MAX_LEN

# used to keep track of time until the next time the snake can move.
snake_move_timer: .word 0

# 1 if the snake changed direction since the last time it moved.
snake_dir_changed: .word 0

# how many apples have been eaten.
apples_eaten: .word 0

# coordinates of the (one) apple in the world.
apple_x: .word 3
apple_y: .word 2

# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2211_0822.asm"
.include "textures.asm"

# ------------------------------------------------------------------------------------------------

.text
.globl main
main:
	jal setup_snake
	jal wait_for_game_start

	# main game loop
	_loop:
		jal check_input
		jal update_snake
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------

# waits for the user to press a key to start the game (so the snake doesn't go barreling
# into the wall while the user ineffectually flails attempting to click the display (ask
# me how I know that that happens))
wait_for_game_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
leave

# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	li v0, 0

	# if they've eaten enough apples, the game is over.
	lw t0, apples_eaten
	blt t0, APPLES_NEEDED, _endif
		li v0, 1
		j _return
	_endif:

	# if they lost the game, the game is over.
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
_return:
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# then show different things depending on if they won or lost
	lw t0, lost_game
	bne t0, 0, _lost
		# they finished successfully!
		li   a0, 7
		li   a1, 25
		lstr a2, "yay! you"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		li   a0, 12
		li   a1, 31
		lstr a2, "did it!"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text
	j _endif
	_lost:
		# they... didn't...
		li   a0, 5
		li   a1, 30
		lstr a2, "oh no :("
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	_endif:

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------
# Snake
# ------------------------------------------------------------------------------------------------

# sets up the snake so the first two segments are in the middle of the screen.
setup_snake:
enter
	# snake head in the middle, tail below it
	li  t0, GRID_WIDTH
	div t0, t0, 2
	sb  t0, snake_x
	sb  t0, snake_x + 1

	li  t0, GRID_HEIGHT
	div t0, t0, 2
	sb  t0, snake_y
	add t0, t0, 1
	sb  t0, snake_y + 1
leave

# ------------------------------------------------------------------------------------------------

# checks for the arrow keys to change the snake's direction.
check_input:
enter
	# TODO
	lw t0, snake_dir_changed
	bne t0, 0, _break
		
	jal input_get_keys_held
	#switch(input_get_keys_held){
	
	beq v0, KEY_U, _north
	beq v0, KEY_D, _south
	beq v0, KEY_R, _east
	beq v0, KEY_L, _west
	
	j _break
#-----------------------------------
	_west:
	#{
		lw t0, snake_dir
		li t2, DIR_E
		li t1, DIR_W
	#if-else if- else
	bne t0, t1, _else_if_W
    		j _break
    	j _endif_W # note!!!
_else_if_W:
    	bne t0, t2, _else_W
    		j _break
    		j _endif_W # note!!!
_else_W:
    	sw t1, snake_dir
    	li t3, 1
    	sw t3, snake_dir_changed
_endif_W:

	j _break
	#}
#------------------------------------------	
	_east:
	#{
	lw t0, snake_dir
	li t1, DIR_E
	li t2, DIR_W
	#if-else if- else
	bne t0, t1, _else_if_E
    		j _break
    	j _endif_E # note!!!
_else_if_E:
    	bne t0, t2, _else_E
    		j _break
    	j _endif_E # note!!!
_else_E:
    	sw t1, snake_dir
    	li t3, 1
    	sw t3, snake_dir_changed
_endif_E:

	j _break
	#}
#------------------------------------------------	
	_north:
	#{
	lw t0, snake_dir
	li t1, DIR_N
	li t2, DIR_S
	#if-else if- else
	bne t0, t1, _else_if_N
    		j _break
    	j _endif_N # note!!!
_else_if_N:
    	bne t0, t2, _else_N
    		j _break
    	j _endif_N # note!!!
_else_N:
    	sw t1, snake_dir
    	li t3, 1
    	sw t3, snake_dir_changed
_endif_N:

	j _break
	#}
#----------------------------------------------	
_south:
	#{
	lw t0, snake_dir
	li t2, DIR_N
	li t1, DIR_S
	#if-else if- else
	bne t0, t1, _else_if_S
    		j _break
    	j _endif_S # note!!!
_else_if_S:
    	bne t0, t2, _else_S
    		j _break
    	j _endif_S # note!!!
_else_S:
    	sw t1, snake_dir
    	li t3, 1
    	sw t3, snake_dir_changed
_endif_S:

	j _break
	#}
#--------------------------------------------------
_break:
	#}
		
leave

# ------------------------------------------------------------------------------------------------

# update the snake.
update_snake:
enter
	# TODO
	li t2, SNAKE_MOVE_DELAY
	lw t1, snake_move_timer
	beq t1, 0, _else
    		#sub t1, t1, 1
    		dec t1
    		sw t1, snake_move_timer
    		j _endif # note!!!
_else:
    		
    		#lw t2, SNAKE_MOVE_DELAY
    		sw t2, snake_move_timer
    		li t3, 0
    		sw t3, snake_dir_changed
    		jal move_snake
_endif:
leave

# ------------------------------------------------------------------------------------------------

move_snake:
enter s0, s1
	# TODO
	#jal shift_snake_segments
	#jal compute_next_snake_pos
	#sb v0, snake_x
	#sb v1, snake_y
	jal compute_next_snake_pos
	move s0, v0
	move s1, v1
	li t0, GRID_WIDTH
	li t1, GRID_HEIGHT
	
	lw t2, apple_x
	lw t3, apple_y
	
	#switch(s0,s1){
	blt s0, 0, _game_over
	bge s0, t0, _game_over 
	blt s1, 0, _game_over
	bge s1, t1, _game_over
	
	#check if snake touches itself
	move a0, s0
	move a1, s1
	jal is_point_on_snake
	beq v0, 1, _game_over
	
	bne s0, t2, _move_forward
    	bne s1, t3, _move_forward
    	
    	j _eat_apple

	
	_eat_apple:
	#apples_eaten++
	lw t1, apples_eaten
	inc t1
	sw t1, apples_eaten
	
	#snake_len++
	lw t1, snake_len
	inc t1
	sw t1, snake_len
	
	jal shift_snake_segments
	
	sb s0, snake_x
	sb s1, snake_y
    	
	jal move_apple
	
	j _break
	
	_move_forward:
	jal shift_snake_segments
	sb s0, snake_x
	sb s1, snake_y
	j _break
	
	_game_over:
	lw t1, lost_game
	inc t1
	sw t1, lost_game
	j _break
	
_break:
	
	#}
	
	
	
leave s0, s1

# ------------------------------------------------------------------------------------------------

shift_snake_segments:
enter
	# TODO
	lw t0, snake_len
	dec t0
	
	#int i = snake_len - 1;  
	move t5, t0
	
_loop:
    	# code
    	#snake_x[i] = snake_x[i - 1];	
    	dec t5
    	lb t2, snake_x(t5)
    	sb t2, snake_x(t0)
    	
    	#snake_y[i] = snake_y[i - 1]
    	lb t3, snake_y(t5)
    	sb t3, snake_y(t0)
    	
	#i--
    	dec t0
    	#i >= 1;
    	bge t0, 1, _loop

leave

# ------------------------------------------------------------------------------------------------

move_apple:
enter s0,s1
	# TODO
	#do-while loop
	_loop_top:
		li a0, 0 # first argument is always, always 0. it's not the lower end of the range.
    		li a1, GRID_WIDTH # second argument is the upper end of the range, non-inclusive.
    		li v0, 42
    		syscall
    		# now v0 contains a random integer in the range [0, SOME_CONSTANT - 1].
    		move s0, v0
		
		li a0, 0 # first argument is always, always 0. it's not the lower end of the range.
    		li a1, GRID_HEIGHT # second argument is the upper end of the range, non-inclusive.
    		li v0, 42
    		syscall
    		# now v0 contains a random integer in the range [0, SOME_CONSTANT - 1].
    		move s1, v0
    		
    		move a0, s0
    		move a1, s1
    		jal is_point_on_snake
    	
    	beq v0, 1, _loop_top
    	
    	sw s0, apple_x
    	sw s1, apple_y
    	
leave s0,s1

# ------------------------------------------------------------------------------------------------

compute_next_snake_pos:
enter
	# t9 = direction
	lw t9, snake_dir

	# v0 = direction_delta_x[snake_dir]
	lb v0, snake_x
	lb t0, direction_delta_x(t9)
	add v0, v0, t0

	# v1 = direction_delta_y[snake_dir]
	lb v1, snake_y
	lb t0, direction_delta_y(t9)
	add v1, v1, t0 
leave

# ------------------------------------------------------------------------------------------------

# takes a coordinate (x, y) in a0, a1.
# returns a boolean (1/0) saying whether that coordinate is part of the snake or not.
is_point_on_snake:
enter
	# for i = 0 to snake_len
	li t9, 0
	_loop:
		lb t0, snake_x(t9)
		bne t0, a0, _differ
		lb t0, snake_y(t9)
		bne t0, a1, _differ

			li v0, 1
			j _return

		_differ:
	add t9, t9, 1
	lw  t0, snake_len
	blt t9, t0, _loop

	li v0, 0

_return:
leave

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

draw_all:
enter
	# if we haven't lost...
	lw t0, lost_game
	bne t0, 0, _return

		# draw everything.
		jal draw_snake
		jal draw_apple
		jal draw_hud
_return:
leave

# ------------------------------------------------------------------------------------------------

draw_snake:
enter s0 
	# TODO
	li s0, 0
	lw t2, snake_len
_loop:
    	# code
    	lb t0, snake_x(s0)
    	mul a0, t0, GRID_CELL_SIZE
    	
    	lb t1, snake_y(s0)
    	mul a1, t1, GRID_CELL_SIZE
    	#la a2, tex_snake_segment
    	
    	bne s0, 0, _else
    		lw t4, snake_dir
    		mul t3, t4, 4
    		lw a2, tex_snake_head(t3)
    		j _endif # note!!!
_else:
    	la a2, tex_snake_segment
_endif:
    	
    	
    	jal display_blit_5x5_trans
 

    	add s0, s0, 1
    	blt s0, t2, _loop
	
leave s0
# ------------------------------------------------------------------------------------------------

draw_apple:
enter 
	# TODO
	lw t1, apple_x
	lw t2, apple_y
	mul a0, t1, GRID_CELL_SIZE
	mul a1, t2, GRID_CELL_SIZE
	la a2, tex_apple
	jal display_blit_5x5_trans
leave 

# ------------------------------------------------------------------------------------------------

draw_hud:
enter
	# draw a horizontal line above the HUD showing the lower boundary of the playfield
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw apples collected out of remaining
	li a0, 1
	li a1, 58
	lw a2, apples_eaten
	jal display_draw_int

	li a0, 13
	li a1, 58
	li a2, '/'
	jal display_draw_char

	li a0, 19
	li a2, 58
	li a2, APPLES_NEEDED
	jal display_draw_int
leave
