# demo only.
addi $fp, $zero, 0x30000
# uses t0, t1
# 'Hello, world!'
prompt:
		addi $t5, $zero, 0x100108
		addi $t6, $zero, 0x01
		sb $t6, ($t5)
		addi $t6, $zero, '>'
		sb $t6, 1($t5)
		# increase cmd_hi
		lbu $t6, -4($t5)
		addiu $t6, $t6, 1
		sw $t6, -4($t5)
		addi $t6, $zero, 0x01
		sb $t6, ($t5)
		addi $t6, $zero, ' '
		sb $t6, 1($t5)
		# increase cmd_hi
		lbu $t6, -4($t5)
		addiu $t6, $t6, 1
		sw $t6, -4($t5)
# end

# enter main function
# t0 ~ t0+9 is address of CMD_HI
addi $t0, $zero, 0x100000
# t1 is 1
addi $t1, $zero, 0x1

# begin loop: initialize to zero
# t2: i
# t3: address of ledr[i]
# t4: for comparison
	addi $t2, $zero, 1
	init_loop:
		add $t3, $t0, $t2
		sb $zero, ($t3)
		addi $t2, $t2, 1
		subi $t4, $t2, 9
		blez $t4, init_loop
		nop
# end loop
sb $t1, ($t0)

# begin loop: main loop
# t2: last value of ledr[0]
# t3: comparison
# t4: first i
# t5: second i
	main:
		lbu  $t2, ($t0)

		# loop 1
		addi $t4, $zero, 0
		loop_shift:
			# t5: ledr[i+1]
			# t6: &ledr[i]
			add  $t6, $t0, $t4
			addi $t5, $t6, 1
			lbu  $t5, ($t5)
			# *t6 = t5
			sb   $t5, ($t6)
			# t7: i - 8
			subi $t7, $t4, 8
			addi $t4, $t4, 1
			blez $t7, loop_shift
			nop

		# t5: &ledr[9]
		addi $t5, $t0, 9
		sb   $t2, ($t5)

		# loop 2
		addi $t5, $zero, -10000
		loop_wait:
			addi $t5, $t5, 1
			blez $t5, loop_wait
			nop

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

		# Read 1 character from keyboard and print it: t5, t6, t7
		# Enable reading
		addi $t5, $zero, 0x100200
		addi $t6, $zero, 0x1
		sb   $t6, ($t5)
		# Wait until ready
		waiting:
			lb   $t6, 1($t5)
			blez $t6, waiting
			nop
		# load the character into t7
		lbu $t7, 16($t5)
		# Disable reading
		sb   $zero, ($t5)
		# Print that character
		addi $t5, $zero, 0x100108
		# print
		addi $t6, $zero, 0x01
		sb   $t6, ($t5)
		# character
		sb   $t7, 1($t5)
		# increase cmd_hi
		addi $t5, $zero, 0x100104
		lbu $t6, ($t5)
		addiu $t6, $t6, 1
		sw $t6, ($t5)

		# loop f. e.
		# t7 - '\r' <= 0
		sub  $t8, $t7, '\r'
		blez $t8, cmp2
		j main
		nop
		cmp2:
		# '\r' - t7 <= 0
		addi $t8, $zero, '\r'
		sub  $t8, $t8, $t7
		blez $t8, prompt
		nop
		j main
		nop
# end loop
