# Daniel Goldman
# 8/29/2012
############################
#	Reverse Polish Notation Calculator
#	Input: collects user input and converts to usable form
#	$a0 - used to add/remove contents on the stack
#	$sp - stack pointer.  Used a lot!
#	$s0 - used as a pointer to the bottom of the stack
#	$s2 - briefly used in main for hex output
#	$t0,$t1,$t2,$t6,$t7 - used for various tests in functions
#		Input, Perform & print_hex
############################

		.data
ask:	.asciiz	"Please enter operand, operator, or '=' below\n"
newLn:	.asciiz	"\n"
		.align	2
buffer:	.space	8
addr_buffer:	.space	36
		.globl	main
		.code
main:
		move	$s0,$sp			# $s0 points to the bottom of the stack
		la		$a0,ask			# prompt user for input
		syscall	$print_string
m_rpt:
		jal		Input
		beqz	$v0,m_rpt		# on exit of this branch, input is complete

		jal		Perform			# works with data provided by Fetch

		lw		$a0,($sp)
		move	$s2,$a0
		syscall	$print_int
		la		$a0,newLn
		syscall	$print_string
		syscall	$print_string

		move	$v0,$s2
		move	$a0,$v0

		la		$a1,buffer
		addi	$t0,$0,8
		move	$t1,$v0		# load $t1 with user input from $v0
		lw		$t2,($sp)
		jal		print_hex	# jump to print_hex function

		la		$a0,buffer
		syscall	$print_string

		addi	$sp,$sp,4	# returns stack space to the stack

		move	$t0,$0		# clear the registers
		move	$t1,$0
		move	$t2,$0
		move	$t4,$0
		move	$t5,$0
		move	$t6,$0

#		b		main

		syscall	$exit

##################################################################
Input:
		la		$a0,addr_buffer	# preparing for read_string
		li		$a1,36			# preparing for read_string
		syscall	$read_string	# reads string into addr_buffer

		la		$a0,addr_buffer	# creates pointer to addr_buffer
		li		$t2,1			# boolean, does the operator get its own line?
		addi	$sp,$sp,-4		# allocates space on the stackd
		move	$v0,$0			# clears $v0
		lb		$t3,($a0)		# prepares to test if '='
		addi	$t3,$t3,-61
		beqz	$t3,i_equals
i_loop:
		lb		$t7,($a0)		# prepares for test if NULL below
		beqz	$t7,input_end	# NULL?  branch to end of input
		addi	$t7,$t7,-37		# prepares for test if operator
		li		$t6,11
i_opTest:
		beqz	$t7,i_opTrue
		addi	$t7,$t7,-1
		addi	$t6,$t6,-1
		beqz	$t6,i_opSkp
		b		i_opTest
i_opTrue:
		lb		$v1,($a0)		# returns operator to main in $v1
		lb		$t1,($a0)
		bnez	$t2,i_opTrue_whole_line
		addi	$sp,$sp,-4
i_opTrue_whole_line:
		li		$t2,0
		sw		$t1,($sp)
		b		input_end		# branches to end of function
i_opSkp:
		li		$t2,0
		lb		$t7,($a0)
		sll		$t0,$t0,4
		addi	$t7,$t7,-65
		bltz	$t7,i_0thru9	# 0-9?  If so, branch to i_0thru9
		move	$t6,$0			# reset counter $t6 to zero
		addi	$t6,$t6,10
i_rpt:
		beqz	$t7,i_skp
		addi	$t7,$t7,-1
		addi	$t6,$t6,1
		b		i_rpt			# re-do i_rpt: until correct hex
i_skp:
		or		$t0,$t0,$t6
		sw		$t0,($sp)
		li		$t2,0
		addi	$a0,$a0,1
		b		i_loop
i_0thru9:
		lb		$t7,($a0)
		addi	$t7,$t7,-48
		move	$t6,$0
i_rpt2:
		beqz	$t7,i_skp2
		addi	$t6,$t6,1
		addi	$t7,$t7,-1
		b		i_rpt2
i_skp2:
		or		$t0,$t0,$t6
		sw		$t0,($sp)
		li		$t2,0			# boolean to FALSE
		addi	$a0,$a0,1		# increment the pointer by 1
		b		i_loop
i_equals:
		li		$v0,1			# sets boolean '=' to TRUE
		addi	$sp,$sp,4
input_end:
		move	$t0,$0			# clears register upon exit
		move	$t1,$0			# clears register upon exit
		move	$t2,$0			# clears register upon exit
		move	$t6,$0			# clears register upon exit
		jr		$ra				# return from subroutine

##################################################################
Perform:
		move	$a0,$s0			# $a0 traverses the stack, starting at bottom
		lw		$t0,-4($a0)
		lw		$t1,-8($a0)

		# check to see if end of stack
		# if not, move contents of -4 into current
		# advance -4
		# repeat until end of stack

		addi	$a0,$a0,-8
p_rpt:
		slt		$t7,$sp,$a0
		beqz	$t7,p_next
		lw		$t6,-4($a0)
		sw		$t6,($a0)
		addi	$a0,$a0,-4
		b		p_rpt
p_next:
		addi	$sp,$sp,4

		# successfully shifted the stack over by one word

		move	$a0,$s0			# $a0 traverses the stack, starting at bottom
		addi	$a0,$a0,-4		# starts $a0 at the bottom item of the stack
p_rpt2:
		lw		$t5,($a0)
		li		$t4,37			# modulus
		sub		$t7,$t5,$t4
		beqz	$t7,p_modulus
		
		li		$t4,42			# multiply
		sub		$t7,$t5,$t4
		beqz	$t7,p_multiply
		
		li		$t4,43			# add
		sub		$t7,$t5,$t4
		beqz	$t7,p_add
		
		li		$t4,45			# subtract
		sub		$t7,$t5,$t4
		beqz	$t7,p_sub

		li		$t4,47			# divide
		sub		$t7,$t5,$t4
		beqz	$t7,p_divide

		addi	$a0,$a0,-4
		b		p_rpt2
p_modulus:
		div		$t0,$t1
		mfhi	$t2
		b		p_result
p_multiply:
		mult	$t0,$t1
		mflo	$t2
		b		p_result
p_add:
		add		$t2,$t0,$t1
		b		p_result
p_sub:
		sub		$t2,$t0,$t1
		b		p_result
p_divide:
		div		$t0,$t1
		mflo	$t2
		b		p_result
p_result:
		sw		$t2,-4($s0)

		# $a0 is now the location to be overwritten
		# check to see if end of stack
		# if not, move contents of -4 into current
		# advance -4
		# repeat until end of stack
p_rpt3:
		slt		$t7,$sp,$a0
		beqz	$t7,p_next3
		lw		$t6,-4($a0)
		sw		$t6,($a0)
		addi	$a0,$a0,-4
		b		p_rpt3
p_next3:
		addi	$sp,$sp,4

		# successfully shifted the stack over by one word

		move	$a1,$sp
		addi	$a1,$a1,4
		slt		$t7,$a1,$s0
		bnez	$t7,Perform
p_end:
		jr		$ra

##################################################################
print_hex:
hex_start:
		addi	$t2,$0,15	# prepares $t2 for 'and' comparison
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big0	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small0	# otherwise 0-9, branch to small0
big0:	addi	$t1,$t1,55
small0:	sb		$t1,7($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big1	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small1	# otherwise 0-9, branch to small0
big1:	addi	$t1,$t1,55
small1:	sb		$t1,6($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big2	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small2	# otherwise 0-9, branch to small0
big2:	addi	$t1,$t1,55
small2:	sb		$t1,5($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big3	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small3	# otherwise 0-9, branch to small0
big3:	addi	$t1,$t1,55
small3:	sb		$t1,4($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big4	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small4	# otherwise 0-9, branch to small0
big4:	addi	$t1,$t1,55
small4:	sb		$t1,3($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big5	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small5	# otherwise 0-9, branch to small0
big5:	addi	$t1,$t1,55
small5:	sb		$t1,2($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big6	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small6	# otherwise 0-9, branch to small0
big6:	addi	$t1,$t1,55
small6:	sb		$t1,1($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		move	$t1,$v0
		and		$t1,$t1,$t2	# brings $t1 down to 4 bits
		addi	$t3,$0,-10
		add		$t3,$t3,$t1
		bgez	$t3,big7	# A-F? branch to big0
		addi	$t1,$t1,48
		bltz	$t3,small7	# otherwise 0-9, branch to small0
big7:	addi	$t1,$t1,55
small7:	sb		$t1,0($a1)	# place in ASCII buffer 'buffer'
		srl		$v0,$v0,4	# shift right logical

		jr		$ra		# return to main
