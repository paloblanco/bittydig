pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- lrj 2023
-- palo blanco games
-- rocco panella

-- poke map width
-- needed to easily have y>100
poke(0x5f57,8)
-- poke for resolution
poke(0x5f2c,3)
-- poke to stop btn repeat
poke(0x5f5c,255)

function init_level()
	-- empty lists
	make_level()
	cy=0
	p1_make()
--	air = 100
	air_time = 180
	time_ms = 0
end


function _init()
	start_title()
end

function _update60()
end

function _draw()
end


function update_game()
	time_ms = (time_ms+1)%air_time
	if time_ms==0 then
		air -= 1
	end
	
	p1_update()
	cy = p1.y - 12
	cx = 0
	
	update_air_tanks()
	update_hard_blocks()
	
	collide_p1_items()
	
	if air < 0 then
		start_gameover()
		return
	end
	
	if p1.y > 8*100 then
		--air = min(100,air+30)
		start_level_start()
	end
end

function draw_game()
	camera(cx,cy)
	cls()
	map()
	
	for t in all(air_tanks) do
		spr(6,t.x,t.y)
	end
	
	for h in all(hard_blocks) do
		spr(5+h.dmg*16,h.x,h.y)
	end
	
	spr(0,p1.x,p1.y)
	
	camera()
	color(7)
	print(air)
	color()
end
-->8
-- player

-- # states
-- standing
-- moving left or right
-- moving down
-- recoiling from hitblock
-- moving up (jump)
-- hovering

function p1_make()
	p1 = {}
	
	p1.x = 3*8
	p1.y = -4*8
	
	p1.dx = 0
	p1.dy = 0
	
	p1.read_input = false
	p1.timer = 0
	p1.hang = 0
	
	p1_update = p1_stand
end

function p1_update()
	-- state machine
	-- leaving empty to be
	-- reassigned
end

function p1_stand()
	p1.timer=8
	local e = empty(p1.x,p1.y+8)
	if e then
		p1_update = p1_fall
		p1_update()
		return
	end
	
	if btn(0) then
		local e = empty(p1.x-8,p1.y)
		if e then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		elseif btnp(0) then
			p1_bump_left()
			p1_update=p1_recoil
			p1_update()
			return
		end
	end

	if btn(1) then
		local e = empty(p1.x+8,p1.y)
		if e then
			p1.dx = 1
			p1_update = p1_moveh
			p1_update()
			return
		elseif btnp(1) then
			p1_bump_right()
			p1_update=p1_recoil
			p1_update()
			return
		end
	end	
				
	if btnp(3) then
	 p1_bump_down()			
		p1_update=p1_recoil
		p1_update()
		return
	end
	
	if btn(2) then
		local e = empty(p1.x,p1.y-8)
		if e then
			p1_update = p1_jump
			p1_update()
			return
		elseif btnp(2) then
			p1_bump_up()
			p1_update=p1_recoil
			p1_update()
		end		
	end
end

function p1_moveh()
	p1.x += p1.dx
	if p1.x %8 == 0 then
		p1_update = p1_stand
		p1_update()
		return
	end
end

function p1_fall()
	p1.y += 1
	e = empty(p1.x,p1.y+8)
	if not e then
		p1_update=p1_stand
		p1_update()
		p1.y = 8*(p1.y\8)
		return
	end
end

function p1_recoil()
	p1.timer -= 1
	if p1.timer == 0 then
		p1_update=p1_stand
		return
	end
end

function p1_jump()
	p1.y -= 1
	if p1.y%8 == 0 then
		p1.timer=8
		p1_update = p1_hover
		p1_update()
		return
	end
end

function p1_hover()
	p1.timer-=1
	if p1.timer == 0 then
		p1_update = p1_fall
		p1_update()
		return
	end
	
	if btn(0) then
		local e = empty(p1.x-8,p1.y)
		if e then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		end
	end

	if btn(1) then
		local e = empty(p1.x+8,p1.y)
		if e then
			p1.dx = 1
			p1_update = p1_moveh
			p1_update()
			return
		end
	end	
end

function p1_bump_left()
	air -= 1
	hit_block(p1.x-8,p1.y)
end

function p1_bump_right()
	air -= 1
	hit_block(p1.x+8,p1.y)
end

function p1_bump_down()
	air -= 1
	hit_block(p1.x,p1.y+8)
end

function p1_bump_up()
	air -= 1
	hit_block(p1.x,p1.y-8)
end

function hit_block(x,y)
	x = x\8
	y = y\8
	if (x<0 or x>7) return
	local t = mget(x,y)%16
	if (t==0) return
	if t==5 then
		h = get_block(x,y)
		hurt_block(h)
		return
	end
	mset(x,y,0)
	if (mget(x-1,y)%16==t) hit_block(8*(x-1),8*y)
	if (mget(x+1,y)%16==t) hit_block(8*(x+1),8*y)
	if (mget(x,y-1)%16==t) hit_block(8*x,8*(y-1))
	if (mget(x,y+1)%16==t) hit_block(8*x,8*(y+1))
end

function collide(i1,i2)
	if abs(i1.x-i2.x)<7 and
	abs(i1.y-i2.y)<7 then
		return true
	end
	return false
end


function collide_p1_items()
	
	for t in all(air_tanks) do
		if collide(p1,t) then
			get_air_tank(t)
		end
	end
	
	for h in all(hard_blocks) do
		if collide(p1,h) then
			--sides
			if p1.x < h.x-5 then
				p1.dx = -1
			elseif p1.x > h.x+5 then
				p1.dx = 1
			--smash
			elseif h.y < p1.y-3 then
				kill_block(h)
				air -= 20
				freeze(5)
			end
		end
	end
end




-->8
--items

function add_air_tank(x,y)
	local tank = {}
	tank.x=x
	tank.y=y
	tank.timer=8
	add(air_tanks,tank)
end

function get_air_tank(t)
	air = min(100,air+25)
	mset(t.x\8,t.y\8,0)
	del(air_tanks,t)
end

function update_air_tanks()
	for t in all(air_tanks) do
		local below = m8get(t.x,t.y+8)
		if below==0 then
			mset(t.x\8,t.y\8,0)
			t.timer-= 1
			if t.timer <=0 then
				t.y+=0.5
			end
		else
			t.timer=30
			mset(t.x\8,t.y\8,6)
		end
	end
end

function add_hard_block(x,y)
	local block = {}
	block.x=x
	block.y=y
	block.timer=16
	block.dmg = 0
	add(hard_blocks,block)
end

function update_hard_blocks()
	for h in all(hard_blocks) do
		local below = m8get(h.x,h.y+8)
		if below==0 then
			mset(h.x\8,h.y\8,0)
			h.timer-= 1
			if h.timer <=0 then
				h.y+=0.5
			end
		else
			h.timer=30
			h.y = 8*(h.y\8)
			mset(h.x\8,h.y\8,5+16*h.dmg)
		end
	end
end

function kill_block(h)
	mset(h.x\8,h.y\8,0)
	del(hard_blocks,h)
end

function get_block(x,y)
	for h in all(hard_blocks) do
		if h.x\8==x and h.y\8==y then
			return h
		end
	end
	return nil
end

function hurt_block(h)
	h.dmg += 1
	if h.dmg > 3 then
		kill_block(h)
	end
end
-->8
--utils

function m8get(x,y)
	xx=x\8
	yy=y\8
	if xx<0 or xx>7 then
		return -1
	end
	return mget(xx,yy)
end

function inside(t,v)
	for ti in all(t) do
		if (ti==v) return true
	end
	return false
end

function empty(x,y)
	local v = m8get(x,y)
	return inside({0,6},v)
end

function freeze(n)
	for i=1,n,1 do
		flip()
	end
end
-->8
-- level

blockinfo={}
blockinfo[1] = {1,1}
blockinfo[2] = {2,1}
blockinfo[3] = {4,1}
blockinfo[4] = {6,2}
blockinfo[5] = {10,2}
blockinfo[6] = {15,2}

function make_level()
	-- containers
	air_tanks = {}
	hard_blocks = {}

	-- initial blocking
	for x=0,7,1 do
		for y=0,99,1 do
			mset(x,y,1+flr(rnd(4)))
		end
	end
	
	-- air
	for i=15,95,20 do
		y = -3+flr(rnd(7)) + i
		x = flr(rnd(8))
		mset(x,y,0)
		add_air_tank(x*8,y*8)
		blockcount = 0
		info = blockinfo[min(level,6)]
		amount,radius = info[1],info[2]
		amount = amount-1+flr(rnd(3))
		while blockcount < amount do
			xd = -radius + flr(rnd(2*radius + 1)) + x
			xd = min(max(0,xd),7)
			yd = -radius + flr(rnd(2*radius + 1)) + y
			if mget(xd,yd)>0 then
				add_hard_block(xd*8,yd*8)
				blockcount+=1
				mset(xd,yd,0)
			end
		end
	end
	for x=0,7,1 do
		for y=0,99,1 do
			t = mget(x,y)
			adder = 0
			if mget(x,y-1)%16 != t then
				adder+=16
			end
			if mget(x-1,y)%16 != t then
				adder+=32
			end
			if (t==0) adder = 0
			mset(x,y,t+adder)
		end
	end
end
-->8
-- game flow

function update_title()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
		start_game()
	end
end

function draw_title()
	cls()
	color(7)
	print("bitty dig",10,10)
	print("⬆️⬇️⬅️➡️ to",1,20)
	print("  start",1,27)
end

function start_game()
	fade_out()
	_draw = draw_game
	_update60=update_game
	init_level()
	update_game()
	fade_in()
end

function fade_out()
	for i=0,64,2 do
		--_draw()
		rectfill(0,0,64,i,2)
		flip()
	end
end

function fade_in()
	for i=0,64,2 do
		_draw()
		rectfill(0,0,64,64-i,2)
		flip()
	end
end

function start_title()
	level = 1
	air = 100
	_draw = draw_title
	_update60 = update_title
end

function start_gameover()
	fade_out()

	_draw = draw_gameover
	_update60 = update_gameover
	
	fade_in()
end

function update_gameover()
	if btnp(0) or btnp(1) or btnp(2) or btnp(3) then
		fade_out()
		start_title()
		fade_in()
	end	
end

function draw_gameover()
	cls()
	print("game over", 10,24,7)
end

function start_level_start()
	fade_out()
	level += 1
	st = 0
	_update60 = update_level_start
	_draw = draw_level_start
	fade_in()
end

function update_level_start()
	st+=1
	if (st > 30) start_game()
end

function draw_level_start()
	cls(2)
	print("  level "..level,0,20,7)
end
__gfx__
00000000ccccccccddddddddeeeeeeeeffffffff766666660007a000000000000000000000000000000000000000000070000000000000000000000000000000
00888800ccccccccddddddddeeeeeeeeffffffff65555557007aaa00000000000000000000000000000011000000000007000000000000000000000000000000
08181880ccccccccddddddddeeeeeeeeffffffff655555577aaaaaaa000000000000000000000000011777110000000007000000000000000000000000000000
78181877ccccccccddddddddeeeeeeeeffffffff655555570aaaaaa0000000000000000000000001177000777110000007000000000000000000000000000000
78888877ccccccccddddddddeeeeeeeeffffffff6555555700aaaa00000000000000000000000017700000077777020000700000000000000000000000000000
08888880ccccccccddddddddeeeeeeeeffffffff6555555700aaaa00000000000000000000000070744477770070770000700000000000000000000000000000
07888770ccccccccddddddddeeeeeeeeffffffff6555555707aaaaa0000000000000000000000704407700044788077777770000000000000000000000000000
07700770ccccccccddddddddeeeeeeeeffffffff677777760aa00aa000000000000000000000074887888ddd887787bb70077700000000000000000000000000
00000000111111112222222288888888bbbbbbbb766666660000000000000000000000000000784bb7bbb888874bb870b7770070000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff65555557000000000000000600000000777784b673333887788048777b070007000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000060000077700070087777778788778484701b77000000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff655555570000000000000006000770002227277277778880b887884742177700000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000060070000020777107788888888228888474217770000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff655505570000000000000006007000027b7b873888078887888888887788707b000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6550555700000000000000060070002bb8780738802788888888888888287667000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6770777600000000000000060070002bb8700778772788888888888888487773000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff766666660000000000000000607002b4b87222787277888888888888878774b3000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6555555700000000000000006070020008720b7888b7888888888888887774b3000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff65555557000000000000000000000207b07200778883888888888888887378b3000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6555055700000000000000000607002778728027738888888888888888873743000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff650055570000000000000000006070b2778720273733788888888888888837b7000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff655505570000000000000000000220b027787202777788888888888828883377000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6550555700000000000000000220c20802b787b2033783878888888838788373000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6770777600000000000000000020000007207722003078807888878888887773000000000000000000000000
00000000111111112222222288888888bbbbbbbb7666666600000000000000000220c60000028f77243307888888787382387373000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6505555700000000000000002020c26eb00022277723338b3888888888387077000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6550505700000000000000002020c2c61b88bfb2787733388372b77788887074000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6055055700000000000000002002c2c217bb8f8bb72223337873372777877736000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff6500555700000000000000002002c22cc17cbf888b777777778773772b837322000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff65550557000000000000000020cc2c22217660f781bffb444778888888373226000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff65505057000000000000000c2006622c2c17a0fe788bbfbb7bb777333372be21000000000000000000000000
000000001ccccccc2ddddddd8eeeeeeebfffffff67707776000000000000000c020cc2d22210000f071ff777777bb3777766b212000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000c02ccccad2221760f1711ff7bbbb06b233222222f000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000cc2c2c2addd21160ff77770000266110233330ee000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000c20222aa2ddd111110e111111211116663f333000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000060c220262aaaa670601111111662260fc26eef0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000066666622202226a7f00a0aee7ee0e022eee6e002000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000c222260227f000000000ff0e622222220000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000cc222220c770077a22330f2c63a06000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000006c22222222020cccccc0cf0c60f6000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000006066002222220c0c3aa0a00aff666000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600600002000c0c200c000000c0000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000660000000c222220c0200cc0cc00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000022220000000cc000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc000006000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000060000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000666600000000000000000000000000000000000000
