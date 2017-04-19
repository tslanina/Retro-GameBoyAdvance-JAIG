@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    Just Another Invaders Game
@ 
@  	     24 h compo entry 
@
@       (c) Tomasz 'dox' Slanina
@        tomasz@slanina.pl
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ vars (EWRAM)
@ 00 score digits
@ 04 -
@ 08 -
@ 0c -
@ 10 score value
@ 14 hiscore digits
@ 18 - 
@ 1c -
@ 20 -
@ 24 hiscore value
@ 28 dir
@ 2c maxy 
@ 30 speed cnt
@ 34 ufo cnt
@ 38 shot cnt
@ 3c main cnt
@ 40 cnt sfx
@ 44 cnt sfx2
@ 48 sfx busy
@ 4c address of data
@ 50 game over flag
@ 54 level over flag

b  start
.org 0xc0

start:
  	mov r11,#0x02000000   @ external working ram
      	add r12,r11,#0x20000  @ r12 - vars (base)
      	mov r0,#0x04000000 @ registers base
      	mov r1,#0x8b       @ sound init
      	strh r1,[r0,#0x84]
      	ldr r1,=0xff17
	strh r1,[r0,#0x80]
	add r9,r0,#6   @ r9 = pointer to line counter
      	mov r1,#0x1140 @ obj on,  obj 1D map , no bg
      	str r1,[r0]
      	mov r1,#0x84   @ 256 colors, map base #0, tile base #1
      	str r1,[r0,#8] 
      	bl clear_sprites
      	mov r0,#0x06000000 @ vram 
      	add r1,r0,#0x10000 
      	mov r2,#0
vclear:	
      	str r2,[r0],#4
      	cmp r0,r1
      	bne vclear
      	bl wait_vbl @vbl+copy sprites
	@tiles decoding (1bpp -> 8bpp)
      	adr r0,data @ tiles
      	str r0,[r12,#0x4c]
      	mov r1,#0x06000000
      	add r1,r1,#0x10000 @ obj vram
     	mov r6,#10*2        
      	mov r7,#6					  
      	mov r8,#0x600       
      	bl decode
      	mov r6,#33*2        
      	mov r7,#1					  
      	mov r8,#0x100       
      	bl decode
      	mov r6,#2*2        
      	mov r7,#5					  
      	mov r8,#0x500       
      	bl decode
	mov r6,#4*2        @ alien 1
      	mov r7,#2					  
      	mov r8,#0x200       
      	bl decode
      	mov r6,#4*2        @ alien 2
      	mov r7,#3					  
      	mov r8,#0x300       
      	bl decode
      	mov r6,#4*2        @ alien 3
      	mov r7,#4					  
      	mov r8,#0x400       
      	bl decode
      	mov r6,#2*2        @ hero
      	mov r7,#1					  
      	mov r8,#0x100       
      	bl decode
      	mov r6,#3*2        @ shot + explosion
      	mov r7,#5					  
      	mov r8,#0x500       
      	bl decode
	@colors
	mov r0,#0x05000000 	@ palette base
	add r0,r0,#0x200 	@ obj palette offset
	ldr r1,=0xffff0000
	str r1,[r0],#4
	ldr r1,=0x001f03e0
	str r1,[r0],#4
	ldr r1,=0x03ff7c00
	str r1,[r0],#4
	ldr r1,=0xd7e4edb8
	str r1,[r0],#4
	bl make_title
	mov r0,#0   @hiscore clear
	str r0,[r12,#0x14]
	str r0,[r12,#0x18]
	str r0,[r12,#0x1c]
	str r0,[r12,#0x20]
	str r0,[r12,#0x24] 

restart:			
	bl title 
	mov r0,#0
	str r0,[r12,#0x50] @gameover flag
			
	mov r0,#0   @score clear
	str r0,[r12]
	str r0,[r12,#4]
	str r0,[r12,#8]
	str r0,[r12,#12]
	str r0,[r12,#16] 
			
levelstart:			
	bl clear_sprites
	bl wait_vbl 
	mov r0,#0x04000000 @ registers base
      	mov r1,#0x1040 @ obj on,  obj 1D map , no bg
      	str r1,[r0]
	bl default_invaders      
      	mov r1,#1
      	str r1,[r12,#0x54]		
mainloop:
	ldr r0,[r12,#0x54] @is level completed ?
	cmp r0,#0
	beq levelstart
	bl wait_vbl			
      	ldr r0,[r12,#0x48] @sound busy counter
      	cmp r0,#0
      	subne r0,r0,#1
	str r0,[r12,#0x48]
      	ldr r0,[r12,#0x34] @ufo counter
      	add r0,r0,#1
      	cmp r0,#0x400
      	movgt r0,#0
      	str r0,[r12,#0x34]
      	cmp r0,#0
      	bne skipufo
	@ufo on
      	mov r3,#14
	orr r3,r3,#0x6000
	strh r3,[r11,#3*4*2]
	mov r3,#239-16
	strh r3,[r11,#3*4*2+2]
	mov r3,#43*2
	strh r3,[r11,#3*4*2+4]
skipufo:      
      	ldr r0,[r12,#0x38] @alien shot counter
      	add r0,r0,#1
      	cmp r0,#0x13
	movgt r0,#0
      	str r0,[r12,#0x38]
      	cmp r0,#0
      	bleq add_shot
      	ldr r0,[r12,#0x3c]
      	add r0,r0,#1
      	str r0,[r12,#0x3c]
      	bl hero_move
	ldr r1,[r12,#0x30] 
	add r1,r1,#1
      	ldr r0,[r12,#0x2c] @maxy
      	cmp r0,#13
      	movgt r0,#13 @max 10
      	rsb r0,r0,#14
      	cmp r1,r0
      	movgt r1,#0
      	str r1,[r12,#0x30]
      	blgt enemy_move
     	bl bullets_move
	bl checkdead
	ldr r0,[r12,#0x50]
	cmp r0,#1
	bne mainloop
@@@@sfx shot2
	mov r2,#0x04000000 @ register base
      	mov r1,#0x1d
      	strh r1,[r2,#0x60]
      	ldr r1,=0xf2c4
      	strh r1,[r2,#0x62]
      	ldr r1,=0x8e93
      	strh r1,[r2,#0x64] @ play sfx
	mov r0,#6
	str r0,[r12,#0x48] @sfx busy
	mov r7,#60*3
	ldrh r5,[r11]
dead:		
	bl wait_vbl			
	subs r7,r7,#1
	beq restart2
	mov r0,r5
	tst r7,#16
	moveq r0,#0x200
	strh r0,[r11]
	b dead
restart2:
	ldr r0,[r12,#0x10]
	ldr r1,[r12,#0x24]
	cmp r0,r1
	ble restart
	str r0,[r12,#0x24]
	ldr r0,[r12,#0x0]
	str r0,[r12,#0x14]
	ldr r0,[r12,#0x4]
	str r0,[r12,#0x18]
	ldr r0,[r12,#0x8]
	str r0,[r12,#0x1c]
	ldr r0,[r12,#0xc]
	str r0,[r12,#0x20]
	b restart
.pool			      
      
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@	
data: 
  	.word 0x00384cc6
 	.word 0xc6c66438
  	.word 0x00307030
  	.word 0x303030fc
  	.word 0x007cc60e
  	.word 0x3c78e0fe
  	.word 0x007e0c18
  	.word 0x3c06c67c
  	.word 0x001c3c6c
  	.word 0xccfe0c0c
  	.word 0x00fcc0fc
  	.word 0x0606c67c
  	.word 0x003c60c0
  	.word 0xfcc6c67c
  	.word 0x00fec60c
  	.word 0x18303030
  	.word 0x0078c4e4
  	.word 0x789e867c
  	.word 0x007cc6c6
  	.word 0x7e060c78
  	.word 0x00001818
  	.word 0x00181800
  	.word 0x38383030
  	.word 0x00003030
  	.word 0x00000000
  	.word 0x00181800
  	.word 0x00001818
  	.word 0x18181800
  	.word 0x00060c18
  	.word 0x3060c000
  	.word 0x6030180c
  	.word 0x0c183060
  	.word 0x3c66c296
  	.word 0xbcd8633e
  	.word 0x00386cc6
  	.word 0xc6fec6c6
  	.word 0x00fcc6c6
  	.word 0xfcc6c6fc
  	.word 0x003c66c0
  	.word 0xc0c0663c
  	.word 0x00f8ccc6
  	.word 0xc6c6ccf8
  	.word 0x00fcc0c0
  	.word 0xf8c0c0fe
  	.word 0x00fec0c0
  	.word 0xfcc0c0c0
  	.word 0x003e60c0
	.word 0xcec6663e
	.word 0x00c6c6c6
	.word 0xfec6c6c6
  	.word 0x00fc3030
  	.word 0x303030fc
  	.word 0x00060606
  	.word 0x0606c67c
  	.word 0x00c6ccd8
  	.word 0xf0f8dcce
  	.word 0x00c0c0c0
  	.word 0xc0c0c0fe
  	.word 0x00c6eefe
  	.word 0xfed6c6c6
 	.word 0x00c6e6f6
  	.word 0xfedecec6
  	.word 0x007cc6c6
  	.word 0xc6c6c67c
 	.word 0x00fcc6c6
  	.word 0xc6fcc0c0
  	.word 0x007cc6c6
  	.word 0xc6decc7a
  	.word 0x00fcc6c6
  	.word 0xcef8dcce
  	.word 0x0078ccc0
  	.word 0x7c06c67c
  	.word 0x00fc3030
  	.word 0x30303030
  	.word 0x00c6c6c6
  	.word 0xc6c6c67c
  	.word 0x00c6c6c6
  	.word 0xee7c3810
  	.word 0x00c6c6d6
  	.word 0xfefeeec6
  	.word 0x00c6ee7c
  	.word 0x387ceec6
  	.word 0x00cccccc
  	.word 0x78303030
  	.word 0x00fe0e1c
	.word 0x3870e0fe
  	.word 0x00071f3f
  	.word 0x6dff3910
  	.word 0x00e0f8fc
  	.word 0xb6ff9c08
  	.word 0x04020f1b
  	.word 0x3b2f2804
  	.word 0x2040f0d8
  	.word 0xdcf41420
	.word 0x04222f3b
  	.word 0x3b1f0810
  	.word 0x2044f4dc
  	.word 0xdcf81008
  	.word 0x0103050d
  	.word 0x0f050804
  	.word 0x80c0a0b0
  	.word 0xf0a01020
  	.word 0x0103050d
  	.word 0x0f02050a
  	.word 0x80c0a0b0
  	.word 0xf040a050
  	.word 0x031f3f39
  	.word 0x3f0e1960
  	.word 0xc0f8fc9c
  	.word 0xfc709806
  	.word 0x031f3f39
  	.word 0x3f0e190c
  	.word 0xc0f8fc9c
  	.word 0xfc709830
  	.word 0x0103033f
  	.word 0x7f7f7f7f
  	.word 0x008080f8
  	.word 0xfcfcfcfc
  	.word 0x02110804
  	.word 0x30040912
  	.word 0x20440810
  	.word 0x06104824
  	.word 0x00100804
  	.word 0x08100804
  	.word 0xffffffff
  	.word 0xffffffff


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

default_invaders: 
			
	mov r5,lr
	bl clear_sprites
			
	add r0,r11,#0x200 
	adr r1,str01
	mov r2,#14*2
lo3:
	ldr r3,[r1],#4
	str r3,[r0],#4
	subs r2,r2,#1
	bne lo3 		  
@score
	bl update_score
@hiscore
	add r0,r11,#0x320+32
	mov r4,#0x48+114 @x
	add r7,r12,#5*4 @score
	bl score_inside
			
	mov r0,#1
	str r0,[r12,#0x28] @dir
	str r0,[r12,#0x2c] @maxy						
	mov r2,r11
		
@hero 112,144,45*2
	mov r3,#144
	orr r3,r3,#0x6000
	strh r3,[r2],#2
	mov r3,#112
	strh r3,[r2],#2
	mov r3,#57*2
	strh r3,[r2],#2
	add r2,r2,#2
@hero shot 13*2
	mov r3,#0x200
	strh r3,[r2],#2
	mov r3,#112+3
	strh r3,[r2],#2
	mov r3,#13*2
	strh r3,[r2],#2
	add r2,r2,#2	
			
@enemy shot 61*2
	mov r3,#44
	orr r3,r3,#0x200
	strh r3,[r2],#2
	mov r3,#200
	strh r3,[r2],#2
	mov r3,#61*2
	strh r3,[r2],#2
	add r2,r2,#2		
			
@enemy ship 43*2
	mov r3,#0x200
	strh r3,[r2],#2
	mov r3,#239-16
	strh r3,[r2],#2
	mov r3,#43*2
	strh r3,[r2],#2
	add r2,r2,#2		
						
	mov r6,#30
pi1:
	bl wait_vbl
	subs r6,r6,#1
	bne pi1		  
		  
	mov r0,#51*2 
	mov r1,#24
	bl enemy_row
	  
	mov r6,#30
pi2:
	bl wait_vbl
	subs r6,r6,#1
	bne pi2		  		  
	mov r0,#47*2 
	mov r1,#33
	bl enemy_row
		  
	mov r6,#30
pi3:
	bl wait_vbl
	subs r6,r6,#1
	bne pi3		  
		  
	mov r0,#45*2 
	mov r1,#43
	bl enemy_row
		  
	mov r6,#30
pi4:
	bl wait_vbl
	subs r6,r6,#1
	bne pi4		  
		  
	mov r0,#55*2 
	mov r1,#53
	bl enemy_row
	  
	mov r6,#30
pi5:
	bl wait_vbl
	subs r6,r6,#1
	bne pi5		  
		  
	mov r0,#53*2 
	mov r1,#63
  	bl enemy_row
	mov pc,r5
			
@@@@@@@@@@@@@@@@@@@@@@@@@@			
			
update_score:
@score  (100) , hiscore (104)
	add r0,r11,#0x320 
	mov r4,#0x48 
	mov r7,r12 

score_inside:			
	ldr r3,=0x2002
	mov r6,#4
lo4:			
	strh r3,[r0],#2
	strh r4,[r0],#2
	ldr r2,[r7],#4
	mov r2,r2,lsl #1
	strh r2,[r0],#4
	add r4,r4,#8 @ x
			
	subs r6,r6,#1
	bne lo4
	mov pc,lr
@@@@@@@@@@@@@@@@@@@

str01:
	.word 0x00142002 @S
	.word 0x00000046
	.word 0x001c2002 @C
	.word 0x00000026
	.word 0x00242002 @O
	.word 0x0000003e
	.word 0x002c2002 @R
	.word 0x00000044
	.word 0x00342002 @E
	.word 0x0000002a
	.word 0x003c2002 @:
	.word 0x00000014
		
	.word 0x00742002 @H
	.word 0x00000030
	.word 0x007c2002 @I
	.word 0x00000032
	.word 0x00842002 @S
	.word 0x00000046
	.word 0x008c2002 @C
	.word 0x00000026
	.word 0x00942002 @O
	.word 0x0000003e
	.word 0x009c2002 @R
	.word 0x00000044
	.word 0x00a42002 @E
	.word 0x0000002a
	.word 0x00ac2002 @:
	.word 0x00000014

		
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

enemy_row: 

	mov r3,#0x04000000 @ register base
      	mov r4,#0x2d
      	strh r4,[r3,#0x60]
      	ldr r4,=0xf180
      	strh r4,[r3,#0x62]
      	ldr r4,=0x80e1
      	strh r4,[r3,#0x64] @ play sfx
				
	mov r3,#10 @counter
	mov r4,#30 @x	
lo1:			
	orr r1,r1,#0x6000
	strh r1,[r2],#2 @y
			
	strh r4,[r2],#2 @x
	strh r0,[r2],#2 @tile
	add r2,r2,#2 @skip
	add r4,r4,#18
	subs r3,r3,#1
	bne lo1
	mov pc,lr 			
 			
@@@@@@@@@@@@@@@@@@@@@@@
 			
clear_sprites:
	mov r0,r11
	mov r1,#128
	mov r2,#0x200
lo2:			
 	strh r2,[r0],#8
 	subs r1,r1,#1
 	bne lo2
 	mov pc,lr

@@@@@@@@@@@@@@@@@@@@@@@@
 			
decode:
      	ldr r2,[r0],#4     @ 1bpp data
      	mov r3,#0x80000000 @ initial bit mask
decode1:
      	mov r4,#0
      	tst r2,r3           @ test bit
      	movne r4,r7         @ set pixel
      	mov r3,r3,lsr #1    @ shift mask
      	tst r2,r3
      	orrne r4,r4,r8
      	movs r3,r3,lsr #1
      	strh r4,[r1],#2
      	bne decode1         @ branch if  bit mask != 0
      	subs r6,r6,#1
      	bne decode
	mov pc,lr
 			
@@@@@@@@@@@@@@@@@@@@@@@@@

hero_move:
      	mov r0,#0x04000000 @ registers base
      	add r0,r0,#0x130   @ key input offset
      	ldrh r0,[r0]       @ left
      	ldr r1,=0xffffff
      	eor r0,r0,r1
      	tst r0,#0x220
      	beq noleft
	 @left
      	ldrh r3,[r11,#2]
      	cmp r3,#8
      	subgt r3,r3,#1     @ sub if != 0
      	strh r3,[r11,#2]
	b skipkey
noleft:
	tst r0,#0x110       @ right
      	beq skipkey
	ldrh r3,[r11,#2]
      	cmp r3,#240-8-16
      	addle r3,r3,#1
      	strh r3,[r11,#2]
skipkey:			
	tst r0,#0x3       @ shot
	moveq pc,lr
	ldr r0,[r12,#0x34]
      	add r0,r0,#16
	str r0,[r12,#0x34]
	add r0,r11,#1*4*2
	ldrh r1,[r0]
	ands r1,r1,#0x200
	moveq pc,lr @on
	mov r1,#144-8
	orr r1,r1,#0x2000
	strh r1,[r0],#2
	ldrh r1,[r0,#-4*2]
	add r1,r1,#4
	strh r1,[r0]
	@@@@sfx shot 
	mov r2,#0x04000000 @ register base
      	mov r1,#0x3e
      	strh r1,[r2,#0x60]
      	ldr r1,=0xf627
      	strh r1,[r2,#0x62]
      	ldr r1,=0x8421
      	strh r1,[r2,#0x64] @ play sfx
	mov r0,#6
	str r0,[r12,#0x48] @busy sfx
	mov pc,lr			
 			
@@@@@@@@@@@@@@@@@@@@@@@@@@

enemy_move:
		
	ldr r0,[r12,#0x48] @busy audio
	cmp r0,#0
	bne zasfx
	ldr r0,[r12,#0x40]
      	add r0,r0,#1
      	str r0,[r12,#0x40]
	tst r0,#1      
	bne sfx2
	mov r2,#0x04000000 @ register base
      	mov r1,#0x2d
      	strh r1,[r2,#0x60]
      	ldr r1,=0xf180
      	strh r1,[r2,#0x62]
      	ldr r1,=0x80e1
    	strh r1,[r2,#0x64] @ play sfx
	b zasfx
sfx2:
	mov r2,#0x04000000 @ register base
      	mov r1,#0x1d
      	strh r1,[r2,#0x60]
      	ldr r1,=0xf180
      	strh r1,[r2,#0x62]
      	ldr r1,=0x80d1
	strh r1,[r2,#0x64] @ play sfx
zasfx:	
				
	ldr r1,[r12,#0x28] @direction
	mov r2,#2 @speed
	cmp r1,#-1
	subeq r2,r2,r2,lsl #1 
	add r0,r11,#4*4*2
	mov r8,#0 
	mov r6,#0 @max y
	mov r4,#0
	str r6,[r12,#0x54]		
	mov r4,#50
slop:
	ldrh r3,[r0]
	ands r3,r3,#0x200
	bne soff
	mov r3,#1
	str r3,[r12,#0x54]		
	ldrh r3,[r0],#2
	and r3,r3,#0xff
	cmp r3,r6
	movgt r6,r3
	ldrh r3,[r0]
	add r3,r3,r2
	cmp r3,#240-16-4
	movgt r8,#1
	cmp r3,#4
	movlt r8,#1
	and r3,r3,#0xff
	strh r3,[r0],#2
	ldrh r3,[r0]
	cmp r3,#59*2
	eorne r3,r3,#4 @ only shots (explosions not)
	strh r3,[r0],#4
	b sdal
			
soff:
	add r0,r0,#8
sdal:			
	subs r4,r4,#1
	bne slop
	cmp r8,#0
	moveq pc,lr
	ldr r1,[r12,#0x28] @dir
	sub r1,r1,r1,lsl #1 
	str r1,[r12,#0x28]
	cmp r6,#140
	movgt pc,lr
	@inc y
	ldr r1,[r12,#0x2c]
	add r1,r1,#1
	str r1,[r12,#0x2c] @maxy 
			
	add r0,r11,#4*4*2
	mov r4,#50			
	ldr r3,=0xffffff00
zmax:
	ldrh r1,[r0]
	mov r2,r1
	and r2,r2,r3
	and r1,r1,#0xff
	add r1,r1,#6
	orr r1,r1,r2
	strh r1,[r0],#8		
	subs r4,r4,#1
	bne zmax
	mov pc,lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@


bullets_move:
			
	add r0,r11,#1*4*2
	ldrh r1,[r0]
	ands r1,r1,#0x200
	movne pc,lr @empty
	ldrh r1,[r0]
	ldr r3,=0xffffff00
	and r2,r1,r3
	and r1,r1,#0xff
	cmp r1,#12
	movlt r1,#0x200
	strh r1,[r0]
	movlt pc,lr
	sub r1,r1,#1
	orr r1,r1,r2
	strh r1,[r0]
			
	@collisions 

	add r0,r11,#1*4*2
	ldrh r1,[r0],#2
	and r8,r1,#0xff @Y
	add r8,r8,#2
	ldrh r1,[r0]
	and r7,r1,#0xff @X
	add r7,r7,#3
	add r0,r11,#4*4*2
	mov r4,#50
klp:
	ldrh r3,[r0]
	ands r3,r3,#0x200
	bne nocol
			
	ldrh r3,[r0,#4]
	cmp r3,#59*2  @no coll with explosion
	beq nocol
			
	ldrh r1,[r0]
	and r1,r1,#0xff @y
	add r1,r1,#2 @y0
	add r6,r8,#4 @height
	cmp r6,r1
	ble nocol
	add r1,r1,#4 @y1
	cmp r8,r1
	bgt nocol
	ldrh r1,[r0,#2] @x
	add r1,r1,#3 @x0
	add r6,r7,#2
	cmp r6,r1
	ble nocol
	add r1,r1,#10 @x1
	cmp r7,r1
	bgt nocol
	mov r1,#59*2
	strh r1,[r0,#2*2] @alien off
	mov r1,#6
	strh r1,[r0,#3*2]
	mov r1,#0x200
	add r0,r11,#1*4*2
	strh r1,[r0] @shot off
	b score_add
coltot:		
	mov r1,#0x200
	strh r1,[r0] @alien off
	mov r1,#0x200
	add r0,r11,#1*4*2
	strh r1,[r0] @shot off
	b score_add	
nocol:			
	add r0,r0,#4*2
	subs r4,r4,#1
	bne klp					
	@ufo
	add r0,r11,#3*4*2
	ldrh r3,[r0]
	ands r3,r3,#0x200
	bne nocol2
	ldrh r1,[r0]
	and r1,r1,#0xff @y
	add r6,r8,#4 @height
	cmp r6,r1
	ble nocol2
	add r1,r1,#7 @y1
	cmp r8,r1
	bgt nocol2
	ldrh r1,[r0,#2] @x
	add r6,r7,#2
	cmp r6,r1
	ble nocol2
	add r1,r1,#15 @x1
	cmp r7,r1
	ble coltot
nocol2:
	@shotem 3 1 5 7
	add r0,r11,#2*4*2
	ldrh r3,[r0]
	ands r3,r3,#0x200
	movne pc,lr
	ldrh r1,[r0]
	and r1,r1,#0xff @y
	add r1,r1,#1
	add r6,r8,#4 @height
	cmp r6,r1
	movle pc,lr
	add r1,r1,#4 @y1
	cmp r8,r1
	movgt pc,lr
	ldrh r1,[r0,#2] @x
	add r1,r1,#3
	add r6,r7,#2
	cmp r6,r1
	movle pc,lr
	add r1,r1,#4 @x1
	cmp r7,r1
	ble coltot
	mov pc,lr
@@@@@@@@@@@@@@@@@@@@@@@@
score_add:
	@@@@sfx shot2
	mov r2,#0x04000000 @ register base
      	mov r1,#0x1d
      	strh r1,[r2,#0x60]
      	ldr r1,=0xf2c4
      	strh r1,[r2,#0x62]
      	ldr r1,=0x8e93
	strh r1,[r2,#0x64] @ play sfx

	mov r0,#6
	str r0,[r12,#0x48]
			
	ldr r1,[r12,#0x10]
	add r1,r1,#1
	str r1,[r12,#0x10] @real
			
	ldr r1,[r12,#12]
	cmp r1,#9
	moveq r1,#0
	addne r1,r1,#1
	str r1,[r12,#12]
	bne update_score
@10			
	ldr r1,[r12,#8]
	cmp r1,#9
	moveq r1,#0
	addne r1,r1,#1
	str r1,[r12,#8]
	bne update_score
@100		
	ldr r1,[r12,#4]
	cmp r1,#9
	moveq r1,#0
	addne r1,r1,#1
	str r1,[r12,#4]
	bne update_score
			
	ldr r1,[r12]
	add r1,r1,#1
	str r1,[r12]
	b update_score

@@@@@@@@@@@@@@@@@@@@@@@@@@


checkdead:

@ ufo	
	add r0,r11,#3*4*2
	ldrh r3,[r0],#2
	ands r3,r3,#0x200
	bne noufo
			
      	mov r1,#0
      	str r1,[r12,#0x34] @ufo cnt
			
	ldrh r3,[r0]
	sub r3,r3,#1
	strh r3,[r0]
	cmp r3,#4
	bgt noufo2
	mov r3,#0x200
	strh r3,[r11,#3*4*2] @ufo-border
			
noufo2:			
			
	ldr r0,[r12,#0x44]
      	add r0,r0,#1
	str r0,[r12,#0x44]
	ands r0,r0,#0x1f      
	bne noufo
			
			
	@@@@sfx ufo
	mov r2,#0x04000000 @ register base
      	mov r1,#0xdd
      	strh r1,[r2,#0x60]
      	ldr r1,=0xfc80
      	strh r1,[r2,#0x62]
      	ldr r1,=0x8fe1
	strh r1,[r2,#0x64] @ play sfx
      
	mov r0,#8
	str r0,[r12,#0x48]
	
noufo:			
	@enemy bullet
	add r0,r11,#2*4*2
	ldrh r3,[r0]
	ands r3,r3,#0x200
	bne nobul
			
	mov r1,#0
	str r1,[r12,#0x38] 
		
	ldrh r3,[r0,#2]
	eor r3,r3,#0x1000
	strh r3,[r0,#2]
			
	ldrh r3,[r0]
	add r3,r3,#2 @speed  alien bullet
	strh r3,[r0]
	and r3,r3,#0xff
	cmp r3,#160
	blt nobul
	mov r3,#0x200
	strh r3,[r11,#2*4*2] @bullet-border
nobul:

	ldrh r8,[r11]
	and r8,r8,#0xff
	add r8,r8,#3
	ldrh r7,[r11,#2]
	add r7,r7,#1
	add r0,r11,#4*4*2
	mov r4,#50
dlp:
	ldrh r3,[r0]
	ands r3,r3,#0x200
	bne skip2
	@hero coll
	ldrh r3,[r0,#4]
	cmp r3,#59*2
	bne skip_1  @ explosion
	ldrh r3,[r0,#6]
	cmp r3,#0
	bne no0
	mov r3,#0x200
	strh r3,[r0]
	b skip2
no0:
	sub r3,r3,#1
	strh r3,[r0,#6]
	b skip2		
			
skip_1:			
	@hcol
	add r6,r8,#7  @y1
	ldrh r1,[r0]
	and r1,r1,#0xff
	add r1,r1,#2 @?
	cmp r6,r1
	ble skip2
	add r1,r1,#12
	cmp r8,r1
	bgt skip2
	ldrh r1,[r0,#2] @x
	add r1,r1,#2
			
	add r6,r7,#12
	cmp r6,r1
	ble skip2

	add r1,r1,#12 @x1
	cmp r7,r1
	ble game_over
skip2:
	add r0,r0,#8
	subs r4,r4,#1
	bne dlp
@enemy bullet coll 3 1 5 7
	add r0,r11,#4*2*2
	ldrh r3,[r0]
	ands r3,r3,#0x200
	movne pc,lr
	add r6,r8,#7  @y1
	ldrh r1,[r0]
	and r1,r1,#0xff
	add r1,r1,#1 @?
	cmp r6,r1
	movle pc,lr
	add r1,r1,#7
	cmp r8,r1
	movgt pc,lr
	ldrh r1,[r0,#2] @x
	add r1,r1,#3
	add r6,r7,#12
	cmp r6,r1
	movle pc,lr
	add r1,r1,#2 @x1
	cmp r7,r1
	movgt pc,lr
game_over:
	mov r0,#1
	str r0,[r12,#0x50]
	mov pc,lr
@@@@@@@@@@@@			
add_shot:	 @ a bit buggy

	ldr r3,[r12,#0x3c] @cnt
	ldr r2,[r12,#0x34] @ufo cnt
	eor r2,r2,r3
	and r2,r2,#0xf
	cmp r2,#9
	subgt r2,r2,#8
	mov r2,r2,lsl #3 @pseudo random column ;)
	add r0,r11,#40*4*2
	add r0,r0,r2
	ldrh r3,[r0]
	ands r3,r3,#0x200 @ active ?
	beq shotset
	sub r0,r0,#80
	ldrh r3,[r0]
	ands r3,r3,#0x200
	beq shotset
	sub r0,r0,#80
	ldrh r3,[r0]
	ands r3,r3,#0x200
	beq shotset
	sub r0,r0,#80
	ldrh r3,[r0]
	ands r3,r3,#0x200
	beq shotset
	sub r0,r0,#80
	ldrh r3,[r0]
	ands r3,r3,#0x200
	movne pc,lr
shotset:		
	ldrh r1,[r0]
	and r1,r1,#0xff @y
	add r1,r1,#10
	cmp r1,#160-32
	movge pc,lr
	orr r1,r1,#0x2000 @on
	strh r1,[r11,#2*4*2] @y
	ldrh r1,[r0,#2]
	add r1,r1,#3
	strh r1,[r11,#2*4*2+2] @x
	mov r1,#61*2
	strh r1,[r11,#2*4*2+4] @tile
	mov pc,lr

@@@@@@@@@@@@@@@@@

wait_vbl:
      	ldrh r8,[r9]
      	cmp r8,#159
      	bne wait_vbl  @ wait for rasterline 159
w2:      
      	ldrh r8,[r9]
      	cmp r8,#160
      	bne w2  @ wait for rasterline 160
	mov r0,#0
	mov r1,#0x07000000 @ OAM
copyOAM:
	ldrh r3,[r11,r0]
	strh r3,[r1,r0]    @ Shadow OAM -> OAM
	add r0,r0,#2
	cmp r0,#512*2
	bne copyOAM
	mov pc,lr

@@@@@@@@@@@@@@@@@@@@@      
title:
	mov r0,#0x04000000 @ reg base
	mov r1,#0x0100 @  bg on , obj off
	str r1,[r0]
	mov r1,#0x84   @ 256 colors, map base #0, tile base #1
	str r1,[r0,#8] 
	mov r1,#0
	str r1,[r0,#0x10] 
	mov r5,#0 		
wait:		
	mov r7,lr
	bl wait_vbl
	mov lr,r7
	mov r0,#0x05000000 	@ palette base
	add r5,r5,#1
	and r5,r5,#63
	mov r4,r5
	mov r3,#63
	cmp r5,#31
	subgt r4,r3,r4
	mov r4,r4,lsl #5
	ldr r3,=0xc2cf0000
	orr r3,r3,r4
	str r3,[r0,#4]
	mov r0,#0x04000000 @ registers base
	add r0,r0,#0x130   @ key input offset
	ldrh r0,[r0]       @ 
	ands r0,r0,#15	
	eors r0,r0,#15
	beq wait
	mov pc,lr
@@@@@@@@@@@@@@@@@@@@@
make_title:
  
	mov r5,lr	
	ldr r0,[r12,#0x4c] @ tiles
	mov r1,#0x06000000
	add r1,r1,#0x4000  @ vram - tiles block #1
	add r1,r1,#64
	mov r6,#43*2         @ 12 tiles (10 digits+transparent+spike)
	mov r7,#3
	mov r8,#0x300      @ 1 = color 1
	bl decode
	mov r6,#20*2         @ 12 tiles (10 digits+transparent+spike)
	mov r7,#2
	mov r8,#0x200      @ 1 = color 1
	bl decode
	ldr r0,[r12,#0x4c]   @ tiles
	mov r6,#43*2         @ 12 tiles (10 digits+transparent+spike)
	mov r7,#1
	mov r8,#0x100        @ 1 = color 1
	bl decode
	mov lr,r5 
	mov r0,#0x05000000 	@ palette base
	ldr r1,=0xffff0000
	str r1,[r0],#4
	ldr r1,=0xc2cf03e0
	str r1,[r0],#4
	mov r2,#0x06000000
	adr r0,str2
wloop:
	ldr r1,[r0],#4
	cmp r1,r2
	moveq pc,lr
	mov r3,r1,lsr #8	
	mov r3,r3,lsl #1
	and r4,r1,#0xff
	strh r4,[r2,r3]
	b wloop
str2:   
	.word 0x0000025a @j
	.word 0x00000326 @u
	.word 0x00000424 @s
	.word 0x00000525 @t

	.word 0x00000751 @a
	.word 0x0000081f @n
	.word 0x00000920 @o
	.word 0x00000a25 @t
	.word 0x00000b19 @h
	.word 0x00000c16 @e
	.word 0x00000d23 @r
		
	.word 0x00000f59 @i
	.word 0x0000101f @n
	.word 0x00001127 @v
	.word 0x00001212 @a
	.word 0x00001315 @d
	.word 0x00001416 @e
	.word 0x00001523 @r
	.word 0x00001624 @s
		
	.word 0x00001857 @g
	.word 0x00001912 @a
	.word 0x00001a1e @m
	.word 0x00001b16 @e
		 
	.word 0x00004c3f @*
	.word 0x0000513f @*
	.word 0x00006d3f @*
	.word 0x0000703f @*
		 
	.word 0x00008b3f @*
	.word 0x00008c3f @*
	.word 0x00008d3f @*
	.word 0x00008e3f @*
	.word 0x00008f3f @*
	.word 0x0000903f @*
	.word 0x0000913f @*
	.word 0x0000923f @*
		 
	.word 0x0000aa3f @*
	.word 0x0000ab3f @*
	.word 0x0000ad3f @*
	.word 0x0000ae3f @*
	.word 0x0000af3f @*
	.word 0x0000b03f @*
	.word 0x0000b23f @*
	.word 0x0000b33f @*
		 
	.word 0x0000c93f @*
	.word 0x0000ca3f @*
	.word 0x0000cb3f @*
	.word 0x0000cd3f @*
	.word 0x0000ce3f @*
	.word 0x0000cf3f @*
	.word 0x0000d03f @*
	.word 0x0000d23f @*
	.word 0x0000d33f @*
	.word 0x0000d43f @*
		 
		 
	.word 0x0000e93f @*
	.word 0x0000eb3f @*
	.word 0x0000ec3f @*
	.word 0x0000ed3f @*
	.word 0x0000ee3f @*
	.word 0x0000ef3f @*
	.word 0x0000f03f @*
	.word 0x0000f13f @*
	.word 0x0000f23f @*
	.word 0x0000f43f @*
		 
	.word 0x0001093f @*
	.word 0x00010b3f @*
	.word 0x0001123f @*
	.word 0x0001143f @*
		 
	.word 0x00012c3f @*
	.word 0x0001313f @*
		
	.word 0x00016a42 @2
	.word 0x00016b44 @4
	.word 0x00016c58 @h
		
	.word 0x00016f53 @c
	.word 0x0001705f @o
	.word 0x0001715d @m
	.word 0x00017260 @p
	.word 0x0001735f @o 
	 
	.word 0x0001a721 @p 
	.word 0x0001a826 @u 
	.word 0x0001a923 @r 
 	.word 0x0001aa16 @e 
 
	.word 0x0001ac12 @a 
	.word 0x0001ad24 @s 
	.word 0x0001ae1e @m 
 
	.word 0x0001b014 @c 
	.word 0x0001b120 @o 
	.word 0x0001b215 @d 
 	.word 0x0001b316 @e 
		 
	.word 0x0001b513 @b 
	.word 0x0001b62a @y 
		 
	.word 0x0001e954 @d 
	.word 0x0001ea5f @o 
	.word 0x0001eb68 @x 
	.word 0x0001ec50 @@ 
	.word 0x0001ed63 @s 
	.word 0x0001ee60 @p 
	.word 0x0001ef51 @a 
	.word 0x0001f053 @c 
	.word 0x0001f155 @e 
	.word 0x0001f24c @. 
	.word 0x0001f360 @p 
	.word 0x0001f45c @l 
		  
	.word 0x00020319 @h 
	.word 0x00020425 @t 
	.word 0x00020525 @t 
	.word 0x00020621 @p 
	.word 0x0002070b @: 
	.word 0x0002080f @/ 
	.word 0x0002090f @/ 
	.word 0x00020a15 @d 
	.word 0x00020b20 @o 
	.word 0x00020c29 @x 
	.word 0x00020d0d @. 
	.word 0x00020e1f @n 
	.word 0x00020f20 @o 
	.word 0x00021024 @s 
	.word 0x00021125 @t 
	.word 0x00021212 @a 
	.word 0x0002131d @l 
	.word 0x00021418 @g 
	.word 0x0002151a @i 
	.word 0x00021612 @a 
	.word 0x0002170d @. 
	.word 0x00021821 @p 
	.word 0x0002191d @l 
		  
	.word 0x00024960 @p 
	.word 0x00024a62 @r 
	.word 0x00024b55 @e 
	.word 0x00024c63 @s 
	.word 0x00024d63 @s 
		  
	.word 0x00025063 @s 
	.word 0x00025164 @t 
	.word 0x00025251 @a 
	.word 0x00025362 @r 
	.word 0x00025464 @t 
	 
	.word 0x06000000






