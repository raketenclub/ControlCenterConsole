#rem
for picaxe 18x

 b1  b0 b3  b2 b5  b4 b7  b6 b9  b8 b11 b10 b13 b12
 --w0-- --w1-- --w2-- --w3-- --w4-- --w5--- --w6---

b0 = bit7  : bit6  : bit5  : bit4  : bit3  : bit2  : bit1 : bit0
b1 = bit15 : bit14 : bit13 : bit12 : bit11 : bit10 : bit9 : bit8

inputs:
	pin0: encoder button mode (prg/run), white
	pin1: encoder inc / button yes/ok, right, 
	pin2: encoder dec / button no, left
	pin6: run/enter, green
	pin7: fire button, red

outputs:
	pin1: fire button enabled led
	pin0: launch signal to optpcoupler cny17, shorten, launch, fire!
	pin2: operate/run led, ready
	pin3: program mode led
	pin4: counter clock
	pin5: counter reset
	pin6: counter display enable
	pin7: speaker
#endrem

'	sertxd("R",0,13,10)


'set up symbols

'outputs
symbol led_fire =1
symbol signal_fire = 0
symbol led_operate = 2
symbol led_mode = 3
symbol signal_counter_clock = 4
symbol signal_counter_reset = 5
symbol signal_display_enable = 6
symbol speaker = 7

'inputs
symbol button_mode = pin0
symbol rot_inc = pin1
symbol button_yes = rot_inc
symbol rot_dec = pin2
symbol button_no = rot_dec
symbol button_run = pin6
symbol button_fire = pin7

symbol button_mode_val = 0
symbol button_yes_val = 1
symbol button_no_val = 2
symbol button_run_val = 6
symbol button_fire_val = 7

'variables
symbol rot_getbits = b0 'b0 = bit7 : bit6 : bit5 : bit4 : bit3 : bit2 : bit1 : bit0
symbol mode = b1 '0: run, 1:prg, 2: wait input prg set value
symbol program = b2 'current running program
symbol tone = b3
symbol display_counter   = b4 'counter to show at display 7 seg
symbol rot_dir       = b5
symbol rot_counter   = b6
symbol state = b7
symbol program_selected = b8 'selected prg when choosing program to run
symbol value_selected = b9
symbol countdown = b10
symbol engine = b11
symbol tmp = b12
symbol tmp2 = b13

'prg
symbol program_default = 1
symbol program_init = 9
symbol program_displayval = 10
symbol program_autorun = 20
symbol program_engine = 30
symbol program_checklist = 40
symbol program_checklist_1 = 41
symbol program_checklist_2 = 42
symbol program_checklist_3 = 43
symbol program_checklist_4 = 44
symbol program_checklist_5 = 45
symbol program_checklist_6 = 46
symbol program_checklist_7 = 47
symbol program_checklist_8 = 48
symbol program_checklist_9 = 49
symbol program_countdown = 60
symbol program_waitpressfire = 98
symbol program_sendlaunchsignal = 99

'sound speaker,(70,25)

'initialize box, reset values, set to default
goto init

'initialize variables, set to default, reset values
init:

	' set interrupt on rotary encoder , pin1 and 2 high only
	setint %00000010,%00000010

	'all outputs low
	let pins = %00000000

	low signal_fire
	low signal_display_enable
	low led_fire
	low led_operate
	low led_mode
	low signal_counter_clock
	low signal_counter_reset

	let mode = 0	'mode: 0: run, 1:prg, 2: enter value prg
	let program = 0	'00: startup
	let program_selected = 0	'00: startup
	let tone = 0
	let state = 0 'state: 0: init, unset, standby. 3: motor selected, 4: checklist ok, 6: running countdown, ..... 9: ready to launch, press fire! number according to program ... :)
	let countdown = 0
	let display_counter = 0
	let rot_dir = 1	'rotary encoder rotation direction: 0 left dec, 2 right inc
	let rot_counter = 0
	let value_selected = 0
	let tmp = 0
	let tmp2 = 0

	sertxd("I",0,13,10)

	'call startup gimmicks
	gosub box_startup
	gosub proc_program_displayval
	gosub play_ok_sound
	'start main program
	goto main
end

'start main program
main:
	do 
		'show program number by default
		high signal_display_enable
		if mode = 0 and display_counter <> program then
			let display_counter = program
			gosub set_counter
		endif

		'check mode button
		if mode = 0 or mode = 1 then
			let tmp=0
			button button_mode_val,0,100,100,tmp,0,proc_button_mode
		endif

		'if in prg select mode, select program and display it, wait for press mode button
		if mode = 1 then
			low signal_display_enable
			pause 100
			'let program_selected = rot_counter
			'only change display if value changed
			'if display_counter <>  program_selected then
			if display_counter <>  rot_counter then
				'let display_counter = program_selected
				let display_counter = rot_counter
				gosub set_counter
				let program_selected = display_counter
			endif
			high signal_display_enable
			pause 100
		endif

		#rem
		'if in mode 2, select value in program, then display value
		if mode = 2 then
			let value_selected = rot_counter
			'only change display if value changed
			if display_counter <>  value_selected then
				let display_counter = value_selected
				gosub set_counter
			endif
		endif
		#endrem
	
		'if in run mode, check for programs and wait for press run button to start program
		if mode = 0 then
			high led_operate
			if program = program_default then goto proc_program_default
			if program = program_init then goto init
	
			#rem
			if program = program_autorun then
				let tmp=0 
				button button_run_val,0,100,100,tmp,0,proc_program_autorun
			endif
			#endrem

			if program = program_engine then 
				let tmp=0
				button button_run_val,0,100,100,tmp,0,proc_program_engine
			endif

			if program = program_checklist then
				let tmp=0
				button button_run_val,0,100,100,tmp,0,proc_program_checklist
			endif

			if program = program_displayval then 
				let tmp=0
				button button_run_val,0,100,100,tmp,0,proc_program_displayval
			endif

			if program = program_countdown then 
				let tmp=0
				button button_run_val,0,100,100,tmp,0,proc_program_countdown
			endif
			low led_operate
			pause 250
		endif
	loop
end


#rem
#	sub procedures for buttons pressed...
#endrem

'toggle mode
proc_button_mode:
	high led_operate
	if mode = 0 then
		high led_mode
		sound speaker,(80,10)
		let mode = 1
		sertxd("M",#mode,13,10)
		low led_operate
		pause 200
		return
	endif
	if mode = 1 then
		low led_mode
		sound speaker,(90,10)
		let mode = 0
		sertxd("M",#mode,13,10)
		'if mode button pressed while in mode 1, select new program!
		let program = program_selected
		sertxd("P",#program,13,10)
		low led_operate
		pause 200
		return
	endif
	if mode = 2 then
		high led_mode
		sound speaker,(100,10)
		let mode = 0
		let engine = value_selected
'		sertxd("M",#mode,13,10)
'		sertxd("E",#engine,13,10)
		gosub proc_program_displayval

		low led_operate
		pause 200
		return
	endif
	low led_operate
return
end

#rem
#	now the startbox programs!
#endrem

proc_program_default:
	#rem
	if mode = 0 then
		high led_operate
		pause 500
		low led_operate
		pause 500
	endif
	#endrem
'return
	goto main
end

'autorun all prg, engine-checklist-displayval-countdown-init

proc_program_autorun:
#rem
	'gosub proc_program_engine
	'gosub proc_program_checklist
	'gosub proc_program_countdown
	'goto init
#endrem
'return
end

'select engine
proc_program_engine:
	'select engine type, then set state
	'2do
	let state = program_engine
	gosub proc_program_displayval
	gosub play_ok_sound
	goto main
'return
end

'run checklist
proc_program_checklist:
	' disable interrupt
	setint %00000000,%00000000

	if state => program_engine then
		let state=program_checklist
		'do checklist
		'let program = program_checklist
		let display_counter = program_checklist
		gosub set_counter
		'sound speaker,(110,50)
		gosub proc_program_displayval
		gosub play_ok_sound
		goto proc_program_checklist_1
	else
		gosub play_cancel_sound
	endif
	goto main
'return
end

proc_program_checklist_1:
	if state => program_checklist then
		let display_counter = program '_checklist_1
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_1
			let program = program_checklist_2
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_2
		endif
		if  rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_2:
	if state => program_checklist_1 then
		let display_counter = program_checklist_2
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_2
			let program = program_checklist_3
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_3
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_3:
	if state => program_checklist_2 then
		let display_counter = program_checklist_3
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_3
			let program = program_checklist_4
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_4
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_4:
	if state => program_checklist_3 then
		let display_counter = program_checklist_4
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_4
			let program = program_checklist_5
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_5
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_5:
	if state => program_checklist_4 then
		let display_counter = program_checklist_5
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_5
			let program = program_checklist_6
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_6
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_6:
	if state => program_checklist_5 then
		let display_counter = program_checklist_6
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_6
			let program = program_checklist_7
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_7
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_7:
	if state => program_checklist_6 then
		let display_counter = program_checklist_7
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_7
			let program = program_checklist_8
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_8
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_8:
	if state => program_checklist_7 then
		let display_counter = program_checklist_8
		gosub set_counter
		sound speaker,(110,50)
		'check yes no
		let rot_dir = 1
		do
		high led_operate
		pause 100
		high led_mode
		if rot_dir =2 or button_yes=1 then
			'ok
			let state = program_checklist_8
			let program = program_checklist_9
			gosub play_ok_sound
			gosub proc_program_displayval
			goto proc_program_checklist_9
		endif
		if rot_dir=0 or button_no=1 then
			let state = program_checklist
			let program = program_checklist
			gosub play_cancel_sound
			goto main
		endif
		low led_operate
		pause 100
		low led_mode
		loop while rot_dir=1
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

proc_program_checklist_9:
	if state => program_checklist_8 then
		'if all ok, finally set state
		let state = program_checklist_9
		let program = program_countdown
		gosub play_ok_sound
		gosub proc_program_displayval
		goto main
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto main
end

'serial out, send data to host
proc_program_send_data:
	'sertxd("OK",1,13,10)
	sertxd("M",#mode,13,10)
	sertxd("P",#program,13,10)
	sertxd("S",#state,13,10)
	sertxd("E",#engine,13,10)
return

'display paras program nr and state
proc_program_displayval:
	gosub proc_program_send_data
	let display_counter = program
	gosub set_counter
	sound speaker,(70,25)
	let display_counter = state
	gosub set_counter
	sound speaker,(70,25)
	pause 50
return
'end

'countdown:
proc_program_countdown:
	if state >= program_checklist_9 then
		gosub play_ok_sound
		pause 1000
		for countdown = 9 to 1 step -1
		
			sertxd("C",#countdown,13,10)

			let tmp=0
			button button_fire_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_run_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_mode_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_yes_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_no_val,0,200,100,tmp,0,proc_cancel
			pause 50
			let tone = 110 - countdown
			let display_counter = countdown
			gosub set_counter
			if countdown > 5 then
				sound speaker, (tone,50)
			else
				sound speaker, (tone,25)
				sound speaker, (tone,25)
			endif
			pause 950
		next countdown
		sound speaker, (118,100)
		gosub rst_counter
		let state=program_countdown
		sertxd("C",#countdown,13,10)
		goto proc_program_waitpressfire
	else
		gosub play_cancel_sound
	endif
	gosub play_cancel_sound
	goto proc_cancel
'return
end

proc_program_waitpressfire: 
	if state=program_countdown then
		'wait for fire button to press within 3 seconds!
		high led_fire
		for tmp2 = 0 to 30

			sertxd("l",#tmp2,13,10)

			let tmp=0 
			button button_fire_val,0,200,100,tmp,0,proc_program_sendlaunchsignal
			let tmp=0
			button button_run_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_mode_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_yes_val,0,200,100,tmp,0,proc_cancel
			let tmp=0
			button button_no_val,0,200,100,tmp,0,proc_cancel
			pause 100

		next tmp2
		low led_fire
		goto proc_cancel
	else
		goto proc_cancel
	endif
	goto proc_cancel
'return
end

'send launch signal!
proc_program_sendlaunchsignal:
	let state = program_waitpressfire
	let tmp = 1
	sertxd("S",#state,13,10)
	sertxd("L",#tmp,13,10)
	high signal_fire
	sound speaker,(117,1000)
	low signal_fire
	low led_fire
	let tmp = 0
	sertxd("L",#tmp,13,10)
	let state = program_sendlaunchsignal
	sertxd("S",#state,13,10)
	let display_counter = state
	gosub set_counter
	pause 50
	gosub play_launch_sound
	gosub proc_program_displayval
	pause 5000
	'goto init
	goto liftoff_loop
'return
end

liftoff_loop:
	do
		pause 250
		low signal_display_enable
		pause 250
		high signal_display_enable
	loop
end

'play some startup sounds and animation for cool looking, not necessary at all but a gimmick
box_startup:

	sertxd("OK",0,13,10)

	'servo 3,85
	'pause 500
	'servopos 3,85
	'pause 1000
	'servopos 3,250
	'pause 1000
	high signal_display_enable
	high led_operate
	high led_mode

pause 1000

	let display_counter = 88
	gosub set_counter
	gosub play_startup_sound
	pause 250
	low signal_display_enable
	low led_operate
	low led_mode
	pause 250
	high signal_display_enable
	high led_operate
	for display_counter = 0 to 10
		let tone = display_counter + 100
		gosub set_counter
		sound speaker,(tone,5)
		pause 10
	next display_counter
	low led_operate
	pause 500
	'display current program number
	high led_operate
	let display_counter = program
	gosub set_counter
	low led_operate
return
'end

play_ok_sound:
	sound speaker,(90,5)
	sound speaker,(100,5)
	sound speaker,(110,5)
return

'play the raketenclub.de theme! hell, yeah... it's rocket science
play_startup_sound:	
	sound speaker,(105,2)
	sound speaker,(115,2)
	sound speaker,(110,2)
	sound speaker,(105,2)
	sound speaker,(105,2)
return
'end

'play sounds to simulate rocket engine... and duration etc, peaks, depending on motor selected
play_launch_sound:
		high led_operate
		sound speaker,(200,250)
		sound speaker,(180,750)
		sound speaker,(160,750)
		'sound speaker,(140,3000)
		low led_operate
return
'end

play_cancel_sound:
	high led_operate
	gosub proc_program_displayval
	sound speaker,(60,100)
	low led_operate
return
'end

'set counter, disable display, reset counter, count, enable display and return
set_counter:
	high led_operate
	low signal_display_enable
	gosub rst_counter
	if display_counter = 0 then
		high signal_display_enable
		low led_operate
		return
	endif
	for tmp = 1 to display_counter
		pulsout signal_counter_clock,3
	next tmp
	high signal_display_enable
	low led_operate
return
'end

'reset counter, set reset pin to led driver ic to high for about 5ms
rst_counter:
	high led_operate
	pulsout signal_counter_reset,5
	low led_operate
return
'end

proc_cancel:
	sertxd("Cancel",0,13,10)
	gosub play_cancel_sound
	goto init
'return
end


interrupt:
	'mode 0, 1 or mode 2, 0: run program, 1:program, 2:enter values in program
	bit2 = pin2: bit1 = pin1       'save rotary encoder pins status
	rot_getBits = rot_getBits & %000000110 'isolate rotary encoder pins
	if rot_getBits <> 0 then           'if both pins are low, the direction is undetermined: discard
		'always get rotate direction
		rot_dir = bit2 * 2                'direction: if bit2=low then dir=0; if bit2=high then dir=2
		'only count when in prg or enter val mode
		if mode = 1 or mode = 2 then
			'count
			rot_counter = rot_counter - 1 + rot_dir   'change counter variable accordingly
			'if counter gets higher than 99 set to 1
			if rot_counter > 99 then 
				let rot_counter = 1
				sound speaker,(118,1)
			endif
			'if counter gets lower than 1 then set counter to 99
			if rot_counter < 1 then 
				let rot_counter = 99
				sound speaker,(105,1)
			endif
		endif
		do while rot_getBits <> 0         'wait for the encoder to go to the next "detent" position
			rot_getBits = pins & %000000110
		loop
	endif
	'beeps on rotate button
	if mode = 0 and rot_dir = 0 then
		sound speaker,(80,1)
	endif
	if mode = 0 and rot_dir > 0 then
		sound speaker,(82,1)
	endif
	if mode = 1 and rot_dir = 0 then
		sound speaker,(110,1)
	endif
	if mode = 1 and rot_dir > 0 then
		sound speaker,(112,1)
	endif
	if mode = 2 and rot_dir = 0 then
		sound speaker,(115,1)
	endif
	if mode = 2 and rot_dir > 0 then
		sound speaker,(117,1)
	endif

	'restore interrupt
	setint %00000010,%00000010
return