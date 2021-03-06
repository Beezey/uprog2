;################################################################################
;#										#
;# UPROG2 universal programmer for linux					#
;#										#
;# copyright (c) 2012-2017 Joerg Wolfram (joerg@jcwolfram.de)			#
;#										#
;#										#
;# This program is free software; you can redistribute it and/or		#
;# modify it under the terms of the GNU General Public License			#
;# as published by the Free Software Foundation; either version 2		#
;# of the License, or (at your option) any later version.			#
;#										#
;# This program is distributed in the hope that it will be useful,		#
;# but WITHOUT ANY WARRANTY; without even the implied warranty of		#
;# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the GNU		#
;# General Public License for more details.					#
;#										#
;# You should have received a copy of the GNU General Public			#
;# License along with this library; if not, write to the			#
;# Free Software Foundation, Inc., 59 Temple Place - Suite 330,			#
;# Boston, MA 02111-1307, USA.							#
;#										#
;################################################################################

;------------------------------------------------------------------------------
; logic analyzer, 1M
; PAR1/2	trigger count 
; PAR3		trigger mask
; PAR4		trigger polarity
; mem[0]	input config
;------------------------------------------------------------------------------
la1m_start:		ldi	XL,0x00			;OK
			call	host_put
			ldi	XL,0x98
			sts	UCSR0B,XL		;enable INT
			ldi	ZL,0x00			;trigger sample memory starts at 0x200
			ldi	ZH,0x02
la1m_start1:		st	Z+,const_0
			cpi	ZH,0x10
			brne	la1m_start1			
			ldi	XL,0xC0
			out	CTRLDDR,XL
			lds	XL,0x100		;internal pull-up on deselected signals
			sts	parbuffer,XL
			com	XL
			out	CTRLPORT,XL
			ldi	XL,0x55
			sts	0x100,XL
			ldi	XL,0xAA
			sts	0x101,XL
			sei
	
la1m_prepare:		movw	XL,r16			;trigger count
			ldi	YL,0x00			;main sample memory starts at 0x200
			ldi	YH,0x02
			ldi	ZL,0x00			;pre trigger sample memory starts at 0xF00
			ldi	ZH,0x0F
			
			in	r21,CTRLPIN		;1 get data
			st	Z+,const_1		;2 store delay
			st	Z+,r21			;2 store value
			mov	r20,r21			;1 this is our next "old" value
			ldi	r24,1			;1 set delay to init
			rjmp	la1m_ptrigger_loop11	;2
			
la1m_ptrigger_loop13:	nop
la1m_ptrigger_loop12:	nop
la1m_ptrigger_loop11:	nop
la1m_ptrigger_loop10:	nop
la1m_ptrigger_loop9:	nop
la1m_ptrigger_loop8:	nop
la1m_ptrigger_loop7:	nop
la1m_ptrigger_loop6:	nop
la1m_ptrigger_loop5:	nop
la1m_ptrigger_loop4:	nop
la1m_ptrigger_loop3:	nop
la1m_ptrigger_loop2:	nop
la1m_ptrigger_loop1:	nop
la1m_ptrigger_loop:	in	r21,CTRLPIN		;1 get data
			mov	r6,r21			;1 copy for edge detection
			eor	r6,r20			;1 1=changed
			mov	r20,r21			;1 this is our next "old" value
			brne	la1m_ptrigger_changed	;1/2
			
			inc	r24			;1 increment step counter
			brne	la1m_ptrigger_loop12	;1/2
			
			st	Z+,r24			;2 store step counter
			st	Z+,r21			;2 store new value
			ldi	r24,1			;1 reset step counter
			ldi	ZH,0x0F			;1 limit pretrigger area
			rjmp	la1m_ptrigger_loop5	;2
			
la1m_ptrigger_changed:	;(+6)
			st	Z+,r24			;2 store step counter
			st	Z+,r21			;2 store new value
			ldi	r24,1			;1 reset step counter
			ldi	ZH,0x0F			;1 limit pretrigger area
			
			eor	r21,r18			;1 polarity
			and	r6,r21			;1 only positive edges
			and	r6,r19			;1 signal select
			brne	la1m_ptrigger_loop3	;2
			
			sbiw	XL,1			;2 trigger counter
			brne	la1m_ptrigger_loop	;1/2
			
			cli				;disable interrupts
			
la1m_trigger_loop:	in	r21,CTRLPIN		;1 get data
			mov	r6,r21			;1 copy for edge detection
			eor	r6,r20			;1 1=changed
			mov	r20,r21			;1 this is our next "old" value
			brne	la1m_trigger_changed	;1/2
			
			inc	r24			;1 increment step counter
			brne	la1m_trigger_loop12	;1/2
			
			st	Y+,r24			;2 store step counter
			st	Y+,r21			;2 store new value
			ldi	r24,1			;1 reset step counter
			cpi	YH,0x0F			;1 limit trigger area
			brne	la1m_trigger_loop5	;2
			rjmp	la_trigger_end
			
la1m_trigger_changed:	;(+6)
			st	Y+,r24			;2 store step counter
			st	Y+,r21			;2 store new value
			ldi	r24,1			;1 reset step counter
			cpi	YH,0x0F			;1 limit trigger area
			brne	la1m_trigger_loop6	;2
			rjmp	la_trigger_end

la1m_trigger_loop12:	nop	
la1m_trigger_loop11:	nop
la1m_trigger_loop10:	nop
la1m_trigger_loop9:	nop
la1m_trigger_loop8:	nop
la1m_trigger_loop7:	nop
la1m_trigger_loop6:	nop
la1m_trigger_loop5:	nop
la1m_trigger_loop4:	nop
la1m_trigger_loop3:	nop
la1m_trigger_loop2:	rjmp	la1m_trigger_loop			
			

la_trigger_end:		cbi	LEDPORT,BUSY_LED	;busy LED off
			
			lds	r24,parbuffer		;mask
			andi	r24,0x3f		;only signals
			
			;re-sort the pretrigger values
			ldi	YL,0x00
			ldi	YH,0x01
			ldi	ZH,0x0F
					
la_sort1:		ld	XL,Z+			;get time
			ldi	ZH,0x0F
			st	Y+,XL			;store
			ld	XL,Z+			;get value
			ldi	ZH,0x0F
			st	Y+,XL			;store value
			cpi	YH,0x02
			brne	la_sort1
		
						
la_sort2:		ldi	YL,0x00
			ldi	YH,0x01
la_sort2_1:		ldd	XL,Y+1			;value
			ldi	XH,0xff
			cpi	XL,0x00			;unused
			breq	la_sort2_2
			and	XL,r24			;only active signals
			mov	XH,XL
la_sort2_2:		std	Y+1,XH
			adiw	YL,2
			cpi	YH,0x0F
			brne	la_sort2_1

			sei				;re-enable interrupts
			ldi	XL,'+'
			call	api_host_put		;send done

la_wait:		rjmp	la_wait			;wait until break


la_stop:		out	CTRLDDR,const_0
			out	CTRLPORT,const_0
			jmp	main_loop_ok


			