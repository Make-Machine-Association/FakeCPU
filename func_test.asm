main:
	addi $sp, $zero, 0x7ffff
	addi $fp, $sp,   0x0
	# enable ledr[0]
	addi $a0, $zero, 0
	addi $a1, $zero, 1
	jal set_led
	nop
	#### test MUL/DIV
	addi $s0, $zero, 177623
	addi $s1, $zero, 4227
	mult $s0, $s1
	addi $s1, $zero, 10
	mflo $s0
	decomp:
		div $s0, $s1
		mfhi $a0
		mflo $s0
		addi $a0, $a0, '0'
		jal putc
		nop
		bne $s0, $zero, decomp
		nop
	addi $a0, $zero, '\r'
	jal putc
	nop
	####
	__main_loop:
		jal prompt
		nop
		addi $a0, $zero, 10000
		jal sleep
		nop
		jal shift_led
		nop
		# read a string
		subi $sp, $sp, 64
		addi $a0, $sp, 0
		addi $a1, $zero, 63
		jal readstr
		nop
		addi $a0, $sp, 0
		jal putsl
		nop
		j __main_loop
		nop

putc:
	# arguments:
	# 	$a0: the character to print
	addi  $t0, $zero, 0x100108
	addi  $t1, $zero, 0x1	
	sb    $t1, ($t0)
	sb    $a0, 1($t0)
	lbu   $t1, -4($t0)
	addiu $t1, $t1, 1
	sw    $t1, -4($t0)
	jr    $ra

prompt:
	# save return address
	subi $sp, $sp, 4
	sw   $ra, ($sp)
	addi $a0, $zero, '='
	jal  putc
	nop
	addi $a0, $zero, '>'
	jal  putc
	nop
	addi $a0, $zero, ' '
	jal  putc
	nop
	# restore return address
	lw   $ra, ($sp)
	addi $sp, $sp, 4
	jr   $ra
	nop

sleep:
	# arguments:
	# 	$a0: number of "cycles" to sleep for
	__sleep_loop:
		subi  $a0, $a0, 1
		bgtz  $a0, __sleep_loop
		nop
	jr $ra
	nop

get_led:
	# arguments:
	# 	$a0: led to get (0 ~ 9)
	# return value(s):
	#   $v0: 0 if success, 1 if failed
	# 	$v1: value of LED
	# $a0 >= 0
	bltz $a0, __get_led_fail
	nop
	# $a0 <= 9
	subi $t0, $a0, 9
	bgtz $t0, __get_led_fail
	nop
	addi $t0, $zero, 0x100000
	add  $t0, $t0, $a0
	lbu  $v1, ($t0)
	addi $v0, $zero, 0
	jr   $ra
	nop
	__get_led_fail:
		addi $v0, $zero, 1
		jr $ra
		nop

set_led:
	# arguments:
	# 	$a0: led to set (0 ~ 9)
	# 	$a1: new value
	# return value(s):
	#   $v0: 0 if success, 1 if failed
	# $a0 >= 0
	bltz $a0, __set_led_fail
	nop
	# $a0 <= 9
	subi $t0, $a0, 9
	bgtz $t0, __set_led_fail
	nop
	addi $t0, $zero, 0x100000
	add  $t0, $t0, $a0
	sb   $a1, ($t0)
	addi $v0, $zero, 0
	jr   $ra
	nop
	__set_led_fail:
		addi $v0, $zero, 1
		jr $ra
		nop

shift_led:
	# $s0: previous ledr[0]
	# $s1: i
	# $s2: temp
	# save registers
	subi $sp, $sp, 4
	sw   $ra, ($sp)
	subi $sp, $sp, 4
	sw   $s2, ($sp)
	subi $sp, $sp, 4
	sw   $s1, ($sp)
	subi $sp, $sp, 4
	sw   $s0, ($sp)
	#
	addi $a0, $zero, 0
	jal  get_led
	nop
	addi $s0, $v1, 0
	addi $s1, $zero, 0
	__shift_led_loop_shift:
		addi $a0, $s1, 1
		jal  get_led
		nop
		addi $a0, $s1, 0
		add  $a1, $zero, $v1
		jal set_led
		nop
		# $s2 <= 7
		subi $s2, $s1, 7
		addi $s1, $s1, 1
		blez $s2, __shift_led_loop_shift
		nop
	# set_led(9, $s0)
	addi $a0, $s1, 0
	add  $a1, $zero, $s0
	jal  set_led
	nop
	# restore registers
	lw   $s2, ($sp)
	addi $sp, $sp, 4
	lw   $s1, ($sp)
	addi $sp, $sp, 4
	lw   $s0, ($sp)
	addi $sp, $sp, 4
	lw   $ra, ($sp)
	addi $sp, $sp, 4
	#
	jr $ra
	nop

getc:
	# return value:
	# 	$v0: the character
	addi $t0, $zero, 0x100200
	addi $t1, $zero, 0x1
	sb   $t1, ($t0)
	# Wait until ready
	__getc_waiting:
		lb   $t1, 1($t0)
		blez $t1, __getc_waiting
		nop
	lbu $v0, 16($t0)
	# Disable reading
	sb  $zero, ($t0)
	jr  $ra

readstr:
	# arguments:
	# 	$a0: the address of returned string
	# 	$a1: length limit (before appending '\0')
	# variables:
	# 	$s0: current append pointer
	# 	$s1: return value
	# 	$s2: temp
	# return value:
	# 	$v0: length of string (w/o terminal '\0')
	# 	requested string stored at ($a0)
	#	 (the final '\r' is removed and the a '\0' is appended)
	# save registers
	subi $sp, $sp, 4
	sw   $ra, ($sp)
	subi $sp, $sp, 4
	sw   $s3, ($sp)
	subi $sp, $sp, 4
	sw   $s2, ($sp)
	subi $sp, $sp, 4
	sw   $s1, ($sp)
	subi $sp, $sp, 4
	sw   $s0, ($sp)
	#
	addi $s0, $a0, 0
	addi $s1, $zero, 0
	__readstr_next:
		# $a1 <= $s1 -> finish
		sub $s2, $a1, $s1
		blez $s2, __readstr_finish
		nop
		jal getc
		nop
		addi $s3, $v0, 0
		addi $a0, $s3, 0
		addi $s2, $zero, '\r'
		beq $s2, $s3, __readstr_newline
		addi $s2, $zero, 0x08
		beq $s2, $s3, __readstr_bksp
		jal putc
		nop
		sb $s3, ($s0)
		addi $s0, $s0, 1
		addi $s1, $s1, 1
		j __readstr_next
		nop
		__readstr_newline:
			jal putc
			nop
			j __readstr_finish
			nop
		__readstr_bksp:
			blez $s1, __readstr_next
			nop
			jal putc
			nop
			subi $s0, $s0, 1
			subi $s1, $s1, 1
			j __readstr_next
			nop
	__readstr_finish:
		sb $zero, ($s0)
		addi $v0, $s1, 0
	# restore registers
	lw   $s3, ($sp)
	addi $sp, $sp, 4
	lw   $s2, ($sp)
	addi $sp, $sp, 4
	lw   $s1, ($sp)
	addi $sp, $sp, 4
	lw   $s0, ($sp)
	addi $sp, $sp, 4
	lw   $ra, ($sp)
	addi $sp, $sp, 4
	#
	jr $ra
	nop

putsl:
	# arguments:
	# 	$a0: the address of the null-terminated string
	# save registers
	subi $sp, $sp, 4
	sw   $ra, ($sp)
	subi $sp, $sp, 4
	sw   $s0, ($sp)
	#
	addi $s0, $a0, 0
	__putsl_loop:
		lb $a0, ($s0)
		beq $zero, $a0, __putsl_end
		jal putc
		nop
		addi $s0, $s0, 1
		j __putsl_loop
		nop
	__putsl_end:
	addi $a0, $zero, '\r'
	jal putc
	nop
	# restore registers
	lw   $s0, ($sp)
	addi $sp, $sp, 4
	lw   $ra, ($sp)
	addi $sp, $sp, 4
	#
	jr $ra
	nop

############## Incomplete yet

setbg:
	# arguments:
	# 	$a0: background color

		# Set bg: t5, t6
		addi $t5, $zero, 0x100108
		# bg
		addi $t6, $zero, 0x06
		sb $t6, ($t5)
		# b, g, r
		lb $t6, ($fp)
		addi $t6, $t6, 23
		sb $t6, ($fp)
		# write
		sb $t6, 1($t5)
		sb $t6, 2($t5)
		sb $t6, 3($t5)
		# increase cmd_hi
		addi $t5, $zero, 0x100104
		lbu $t6, ($t5)
		addiu $t6, $t6, 1
		sw $t6, ($t5)

setfg:
	# arguments:
	# 	$a0: foreground color
		# Set fg: t5, t6
		addi $t5, $zero, 0x100108
		# bg
		addi $t6, $zero, 0x05
		sb $t6, ($t5)
		# b, g, r
		lbu $t6, 1($fp)
		addiu $t6, $t6, 16
		sw $t6, 1($fp)
		# write
		sb $t6, 1($t5)
		sb $zero, 2($t5)
		sb $t6, 3($t5)
		# increase cmd_hi
		addi $t5, $zero, 0x100104
		lbu $t6, ($t5)
		addiu $t6, $t6, 1
		sw $t6, ($t5)
