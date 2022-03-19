# Program to encode and decode hamming code

		.data
in_method:	.asciz "Decode [d] or encode [e]: "
		.align 2
method_encode:	.asciz "e"
		.align 2
method_decode:	.asciz "d"
		.align 2
max_len_data:	.word 20
		.align 2
# The data string passed by the user
data:		.space 21
		.align 2
# The data string passed by the user converted to an integer
data_int:	.word 0
		.align 2
encoded_data:	.word 0
		.align 2
zero_str:	.asciz "0"
		.align 2
one_str:	.asciz "1"
		.align 2
# The corr bits combined in an integer. If there was an error, its value is the position of the error, otherwise 0
corr_bits:	.word 0
		.align 2
in_data_rcv:	.asciz "Please enter the recieved data: "
		.align 2
in_data_send:	.asciz "Please enter the data to send: "
		.align 2
zero_errors:	.asciz "There are no one bit errors in your data :)"
		.align 2
bit_error_str:	.asciz "There seems to be a bit error at position "
		.align 2
data_no_cbts:	.asciz "The recieved data without corr bits is: "
		.align 2
data_corr_bits:	.asciz "The corrected data with corr bits is: "
		.align 2
data_corr_nb:	.asciz "The corrected data without corr bits is: "

corr_bits_str:	.asciz "The corr bits are: "
		.align 2
encode_res_str:	.asciz "The encoded data is: "
		.align 2
error_str:	.asciz "An error occured. Please check your input."
		.align 2
nln:		.asciz "\n"

		.text
		.globl main

# Start here, decide whether to decode or to encode		
main:		la a0, in_method
		jal print_string
		jal read_char
		add t2, a0, zero	# Store input in t2
		jal print_nl
		lw t1, method_decode	# Use t1 to store the text it should be
		beq t2, t1, decode
		lw t1, method_encode
		beq t2, t1, encode
		b error

# Decode a given input		
decode:		la a0, in_data_rcv	# Ask for user input
		jal print_string
		jal read_data_str
		jal data_to_int
		
		lw a0, data_int		# Convert user input data to int
		jal calc_corr_bits	# Check if the corr bits are correct
		lw a0, corr_bits
		jal print_dcd_res	# Print the decoding result
		
		j exit

# Print the result of decoding
print_dcd_res:	lw t0, corr_bits
		bne t0, zero, bit_error
			la a0, zero_errors	# No error occured
			jal print_string
			jal print_nl
			
			la a0, data_no_cbts	# Print data without corr bits
			jal print_string
			lw a0, data_int
			jal rem_cbits
			jal print_int_bin
			jal print_nl
			j exit
		bit_error:
			la a0, bit_error_str	# Notify about error
			jal print_string
			lw a0, corr_bits
			jal print_int
			jal print_nl
			
			la a0, data_no_cbts	# Print data without corr bits
			jal print_string
			lw a0, data_int
			jal rem_cbits
			jal print_int_bin
			jal print_nl
			
			la a0, data_corr_bits	# Print corrected data with corr bits
			jal print_string
			jal correct_bit
			jal print_int_bin
			jal print_nl
			
			la a0, data_corr_nb	# Print corrected data without corr bits
			jal print_string
			jal correct_bit
			jal rem_cbits
			jal print_int_bin
			jal print_nl
			
			j exit

# Encode a given input		
encode:		la a0, in_data_send		# Ask for input
		jal print_string
		jal read_data_str
		jal data_to_int
		
		jal space_for_corrbits_encd	# Add 0s where corr bit parity will be
		
		jal add_corrbits_encd		# Set the correct corr bits
		
		la a0, encode_res_str		# Print the result
		jal print_string
		lw a0, encoded_data
		jal print_int_bin
		jal print_nl
		
		j exit

# Calculate the corr bits for an int given in a0
# First loop over all corr bits, inside loop over the parts of data that corr bit represents,
# inside loop over all bits of that part of data
calc_corr_bits:	
		addi sp, sp, -12		# Prolog
		sw ra, 4(sp)
		sw fp, 8(sp)
		addi fp, sp, 8
		
		add t0, a0, zero		# Store the argument (data int) in t0
		add t1, zero, zero		# t1 = Corr_bit now (i) = 0
		all_corr_bits_loop:
			slti t3, t1, 6		
			beq t3, zero, corr_ret	# i >= 6 (corr_bits count) -> return
			li t4, 1		# bitmask t4 (length & start of checking) = 1
			sll t4, t4, t1		# t4 = 2^i as length & start of checking
			add t5, t4, zero	# t5 (j) = t4 as start of checking
			one_corr_bit_loop:
				li t3, 0
				sw t3, 12(sp)		# sp[12] = length of data processed = 0
				part_of_data_loop:
					li t3, 32
					bgt t5, t3, end_one_corr_bit_loop # End corr bit loop if 32th bit is reached
					li t3, 1			# t3 (Bitmask) = 1
					addi t6, t5, -1			# t6 = j - 1
					sll t3, t3, t6			# Bitmask << (j - 1)
					and t6, t0, t3			# Get the j-th bit of data
					sub t3, t5, t1
					addi t3, t3, -1			# t3 (shift amount) = j - i - 1
					srl t6, t6, t3			# Push the bit to the right position in the corr_bit int
					lw t3, corr_bits		# Save the corr_bit int in t3
					xor t3, t3, t6			# XOR the bit to the existing bit (to get the parity)
					sw t3, corr_bits, t6		# Store the corr_bits back into memory
					addi t5, t5, 1			# j++
					lw t3, 12(sp)
					addi t3, t3, 1
					sw t3, 12(sp)			# length of data processed++
					bne t3, t4, part_of_data_loop	# Loop again if (length of data processed != part of data length)
				add t5, t5, t4		# j += part of data length (-> go to next data part)
				j one_corr_bit_loop
			end_one_corr_bit_loop:
				addi t1, t1, 1		# i++
				j all_corr_bits_loop
		
		corr_ret:
			lw ra, 4(sp)		# Epilogue
			lw fp, 8(sp)
			addi sp, sp, 12
			
			jr ra

# Remove the corr bits from data given in a0
# Do this by copying data, but not corr bits, from t0 to t2
rem_cbits:	add t0, a0, zero	# Store argument (data int) in t0
		li t1, 0		# Position in data int (i)
		li t2, 0		# Pure data int
		li t3, 0		# Position in pure_data_int
		li t4, 1		# Corr bit mask now
		rem_loop:
			addi t5, t1, 1
			beq t5, t4, corr_bit	# i+1 == corr bit -> corr bit reached
			blt t5, t4, data_bit	# i + 1 < corr bit -> data bit
			j error
			
			corr_bit:
				li t5, 0x20		# t5 = 32 (6th bit mask)
				beq t4, t5, rem_ret	# 6th bit mask reached? -> return
				
				slli t4, t4, 1		# Corr bit ++ (mask <<)
				j rem_before_next_loop
				
			data_bit:
				andi t5, t0, 1		# Get the current data bit (at the end)
				sll t5, t5, t3		# Shift the bit to the correct position in pure_data_int
				or t2, t2, t5		# Append the current bit to pure_data_int
				
				addi t3, t3, 1		# Position in pure_data_int ++
				j rem_before_next_loop
				
			rem_before_next_loop:
				addi t1, t1, 1		# Position in data int (i) ++
				srli t0, t0, 1		# Shift data to the right (-> next bit at end)
			
				j rem_loop		# Loop again
			
		rem_ret:
			add a0, t2, zero	# Return t2 (pure_data_int)
			jr ra

# Correct a single bit error. The position of the error is parsed from the corr bits int			
correct_bit:	lw t0, data_int
		lw t1, corr_bits
		
		li t2, 1		# Error bitmask
		addi t1, t1, -1		# Shift amount: corr_bits - 1
		sll t2, t2, t1		# Shift the bitmask
		xor t3, t0, t2		# XOR data with bitmask to change only the error bit
		
		add a0, t3, zero	# Return corrected data
		jr ra

# Add 0s where corrbits will later be.
# Copy the data from data_int and store it with additional 0s in between in encoded_data		
space_for_corrbits_encd:
		# Code similar to rem_cbits
		# Copy data to t2 and add 0s as place holders for corr bits
		lw t0, data_int		# t0 = data int without corr bits
		li t2, 0		# Data int with added corr bits
		li t3, 0		# Position in corrbit_data_int
		li t4, 1		# Corr bit mask now
		space_loop:
			addi t5, t3, 1
			beq t5, t4, space_corr_bit	# Position in corrbit_data_int + 1 == corr bit -> corr bit reached
			blt t5, t4, space_data_bit	# Position in corrbit_data_int + 1 < corr bit -> data bit
			j error
			
			space_corr_bit:
				li t5, 0x20		# t5 = 32 (6th bit mask)
				beq t4, t5, space_ret	# 6th bit mask reached? -> return
				
				slli t4, t4, 1		# Corr bit ++ (mask <<)
				j space_before_next_loop
				
			space_data_bit:
				andi t5, t0, 1		# Get the current data bit (at the end)
				sll t5, t5, t3		# Shift the bit to the correct position in corrbit_data_int
				or t2, t2, t5		# Append the current bit to corrbit_data_int
				
				srli t0, t0, 1		# Shift data to the right (-> next bit at end)
				j space_before_next_loop
				
			space_before_next_loop:
				addi t3, t3, 1		# Position in corrbit_data_int ++
			
				j space_loop		# Loop again
			
		space_ret:
			sw t2, encoded_data, t3	# Save result in encoded_data
			add a0, t2, zero	# Return t2 (corrbit_data_int)
			jr ra

# Replace the 0s in encoded_data with the real parity bits in place			
add_corrbits_encd:
		addi sp, sp, -8		# Prolog
		sw ra, 4(sp)
		sw fp, 8(sp)
		addi fp, sp, 8

		lw a0, encoded_data
		jal calc_corr_bits	# Calculate what the corr bits should be
		lw t0, encoded_data	# t0 = corrbit_data_int (with corrbits = 0)
		la a0, corr_bits_str
		jal print_string
		lw t1, corr_bits	# Save the corr bits in t1
		add a0, t1, zero
		jal print_int_bin
		jal print_nl
		
		li t2, 0		# i = 0
		add_corrbits_loop:
			li t3, 6
			beq t2, t3, add_ret 	# i == 6 (corr bit count) -> return
			addi t4, zero, 1	# Current corr bit bitmask
			sll t4, t4, t2		# Bitmask << i
			add t5, t4, zero	# t5 = Shift amount
			addi t5, t5, -1
			and t4, t4, t1		# Get the value the corr bit should have from the corr bit int
			srl t4, t4, t2		# Bit >> i
			sll t4, t4, t5		# Bit << 2^i
			or t0, t0, t4		# Add corr bit to data
			
			addi t2, t2, 1		# i++
			j add_corrbits_loop
		add_ret:
			lw ra, 4(sp)		# Epilogue
			lw fp, 8(sp)
			addi sp, sp, 8
		
			sw t0, encoded_data, t3	# Save result in encoded_data
			add a0, t0, zero	# Return data with corr bits
			jr ra

# Convert a string given in a0 to an integer, store the result in a0 and in data_int
# ASCII 30 -> 0, 31 -> 1, stop when newline (\n) is reached		
data_to_int:	
		addi sp, sp, -8		# Prolog
		sw ra, 4(sp)
		sw fp, 8(sp)
		addi fp, sp, 8

		jal get_data_bitlen
		addi t4, a0, -1		# t4 (i) = data_bitlen - 1
		add t6, zero, zero	# t6 (result int) = 0
		la t0, data		# t0 = Address of data
		lb t1, nln		# t1 = \n (end of data)
		string_loop_int:
			lb t3, (t0)		# t3 = Current byte
			beq t1, t3, ret_int	# Newline (end of data) reached?
			lb t5, zero_str
			beq t5, t3, skipmask	# if current byte == "0" skip bitmasking int
			lb t5, one_str
			bne t5, t3, error	# current byte != "0" and != "1" -> error
				addi t5, zero, 1	# bitmask in t5
				sll t5, t5, t4		# bitmask << i
				or t6, t6, t5		# result int OR bitmask
			skipmask:
			addi t0, t0, 1		# Go to next byte
			addi t4, t4, -1		# i--
			j string_loop_int
		ret_int:
			lw ra, 4(sp)		# Epilogue
			lw fp, 8(sp)
			addi sp, sp, 8
			
			sw t6, data_int, t0	# Store the data int in memory
			add a0, t6, zero	# Return result int
			jr ra

# Get the length of a string given in a0 before a newline character (\n), store it in a0.
get_data_bitlen:	la t0, data	# t0 = Address of data
			lb t1, nln	# t1 = \n (end of data)
			li a0, 0	# a0 (cnt) = 0
			string_loop_len:	
				lb t3, (t0)		# t3 = Current bit
				beq t1, t3, ret_len	# Newline (end of data) reached?
				addi a0, a0, 1		# cnt++
				addi t0, t0, 1		# Go to next byte
				j string_loop_len
			ret_len:
				jr ra			# Return a0 (cnt)
		

print_string:	li a7, 4		# PrintString
		ecall
		jr ra
		
print_char:	li a7, 11		# PrintChar
		ecall
		jr ra

# Print a new line		
print_nl:	la a0, nln
		li a7, 4		# PrintString
		ecall
		jr ra
		
print_int:	li a7, 1		# PrintInt
		ecall
		jr ra

# Print int as binary with trailing 0s		
print_int_0bin:	li a7, 35		# PrintIntBinary
		ecall
		jr ra

# Print int as binary without trailing 0s
print_int_bin:	addi sp, sp, -20	# Prolog
		sw ra, 4(sp)
		sw fp, 8(sp)
		addi fp, sp, 8
		
		sw a0, 12(sp)		# sp[12] = arg
		li a1, 0x80000000
		sw a1, 16(sp)		# sp[16] = bitmask
		li a1, 0
		sw a1, 20(sp)		# sp[20] = first_one_passed (boolean, true if a set bit (1) was already read
		int_bin_loop:
			lw a1, 16(sp)			# Get the bitmask
			beqz a1, int_bin_end		# End if bitmask was pushed out on the right (== 0)
			lw a0, 12(sp)
			and a0, a0, a1			# Apply bitmask to arg
			beqz a0, int_bin_print_zero 	# Is the bit 1 or 0?
				# 1 was read
				li a0, 1
				sw a0, 20(sp)		# first_one_passed = true = 1
				jal print_int
				j int_bin_before_loop
			int_bin_print_zero:
				# 0 was read
				lw a0, 20(sp)
				beqz a0, int_bin_before_loop # first_one_passed == false -> don't print 0
				li a0, 0
				jal print_int
			int_bin_before_loop:
				lw a0, 16(sp)
				srli a0, a0, 1
				sw a0, 16(sp)	# bitmask >> 1
				j int_bin_loop
		int_bin_end:
			lw a0, 20(sp)
			bnez a0, skip_print_zero # Loop is finished but first_one_passed == false -> print 0
				li a0, 0
				jal print_int
			skip_print_zero:
			lw a0, 12(sp)		# Restore initial arg
		
			lw ra, 4(sp)		# Epilogue
			lw fp, 8(sp)
			addi sp, sp, 20
			
			jr ra

read_char:	li a7, 12		# ReadChar
		ecall
		jr ra
		
read_data_str:	la a0, data
		lw a1, max_len_data
		li a7, 8		# ReadString
		ecall
		jr ra
		
error:		la a0, error_str
		jal print_string
		jal print_nl
		j exit
		
exit:		li a7, 10		# Exit
		ecall
