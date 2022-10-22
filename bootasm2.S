# When the PC starts, the processor is essentially emulating an 8086 processor, i.e. 
# a 16-bit processor.  So our initial boot loader code is 16-bit code that will 
# eventually switch the processor into 32-bit mode.

# This code is linked to assume a starting address of 0x7C00 which is where the BIOS
# will load a boot segment.

.code16                         # Assemble for 16-bit mode
.globl start
start:
    jmp     real_start

# Write to the console using BIOS.
# 
# Input: SI contains the address of the null-terminated string to be displayed

cons_write:
    movb    $0x0e, %ah           # 0x0e is the INT 10h BIOS call to output the value contained in AL to screen

cons_write_rpt:
    movb    (%si), %al          # Load the byte at the location contained in the SI register into AL   
    inc     %si                 # Add 1 to the value in SI
    cmp     $0, %al             # Compare the value in AL with 0
    jz      cons_write_done     # If it is zero, then we are done
    int     $0x10               # Output the character in AL to the screen
    jmp     cons_write_rpt      # and continue

cons_write_done:                # Something that is called will never return 
    ret                         # until a 'ret' instruction is encountered.  Labels do 
                                # not give a program any structure.  They just give a 
                                # memory location a name that we can use in our code. 

cons_write_crlf:
    movb    $0x0e, %ah          # Output CR
    movb    $0x0d, %al
    int     $0x10
    movb    $0x0a, %al          # Output LF
    int     $0x10
    ret

cons_writeline:
    call    cons_write
    call    cons_write_crlf
    ret    

# Output the 16-bit value in BX to the screen has a 4 digit hex value	
#
# Input:  BX = Value to output	

HexChars:	.ascii "0123456789ABCDEF"

# Output the value passed on the stack to the screen using the specified base
#

#define     number      6
#define     base        4

#define     endofstring -2

cons_write_number:
    pushw   %bp                 # Save existing frame pointer
    movw    %sp, %bp            # Setup our frame pointer
    subw    $18, %sp            # Reserve space for our string buffer
    pushw   %ax                 # Save the registers we will trash
    pushw   %bx
    pushw   %cx
    pushw   %dx
    pushw   %si
    pushw   %di

    movw    %bp, %si
    subw    $3, %si
    movb    $0, endofstring(%bp)    # Insert end of string indicator (0)    
    movw    number(%bp), %ax
	
getdigit:
	xor		%dx, %dx                # Divide number by base
	movw	base(%bp), %cx
	div		%cx
    movw    %dx, %di                # Convert remainder to hex character
    movb    HexChars(%di), %dl      # and stpre in buffer
	movb	%dl, (%si)
	dec		%si
	cmpw	$0, %ax                 # Have we extracted all digits?
	jne		getdigit
	inc		%si
	call	cons_write              # Output the string

    popw    %di                     # Restore the registers
    popw    %si
    popw    %dx
    popw    %cx
    popw    %bx
    popw    %ax
    movw    %bp, %sp                # Delete the local variables
    popw    %bp
    ret     $4                      # Return, removing paramters from stack


	ret
	
IntBuffer:   .string "     "

real_start:
    movb    %dl, (boot_device) # Boot device number is passed in DL from BIOS. Save it hear since DL might get trashed

    movw    $boot_message, %si  # Display our boot message
    call    cons_writeline

    # Test cons_write_number

    pushw   $65535
    pushw   $10
    call    cons_write_number
    call    cons_write_crlf

    pushw   $0x1234
    pushw   $16
    call    cons_write_number
    call    cons_write_crlf

    pushw   $0xABCD
    pushw   $16
    call    cons_write_number
    call    cons_write_crlf

    pushw   $0x1234
    pushw   $2
    call    cons_write_number
    call    cons_write_crlf

    pushw   $0xABEF
    pushw   $2
    call    cons_write_number
    call    cons_write_crlf

endless_loop:                   # Loop forever more
    jmp     endless_loop    

# Program data

boot_device:
    .byte   0

boot_message:     
    .string "Boot Loader Stage 2 loaded"             

