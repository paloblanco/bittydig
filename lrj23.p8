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
-- get deep red
pal(4,-8,1)

function init_level()
	-- empty lists
	make_level()
	cy=0
	p1_make()
--	air = 100
	air_time = 180
	time_ms = 0
	text_boxes = {}
	explosions = {}
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
	
	if p1.y > 8*101 then
		--air = min(100,air+30)
		start_level_start()
	end
end

function draw_game()
	pal(4,-8,1)
	camera(cx,cy)
	cls()
	map()
	
	for t in all(air_tanks) do
		spr(6,t.x,t.y)
	end
	
	for h in all(hard_blocks) do
		spr(5+h.dmg*16,h.x,h.y)
	end
	
	--player
	spr(p1.ix,p1.x+p1.offx,p1.y+p1.offy,1,1,not p1.faceleft)
	
	draw_text_boxes()
	draw_explosions()
	
	camera()
	color(7)
	print("\#7\fc"..air,1,1)
	color()
end

function make_text_box(s,c,x,y)
	local t = {}
	t.s = s
	t.c = c
	t.x = x
	t.y = y
	t.timer=30
	add(text_boxes,t)
end

function draw_text_boxes()
	for t in all(text_boxes) do
		print("\#7\f"..t.c..t.s,t.x,t.y)
		t.timer -= 1
		if (t.timer < 0) del(text_boxes,t)
	end
end

function make_explosion(x,y)
	local e = {}
	e.x = x
	e.y = y
	e.t = 8
	add(explosions,e)
end

function draw_explosions()
	for e in all(explosions) do
		x = e.x*8
		y = e.y*8
		if e.t > 6 then
			rectfill(x,y,x+7,y+7,7)
		elseif e.t > 4 then
		
		elseif e.t > 2 then
			rectfill(x+1,y+1,x+6,y+6,7)
		else
			del(explosions,e)
		end
		e.t += -1
	end
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
	p1.other = nil --for riding
	p1.faceleft = true
	
	p1.ix = 0
	p1.offx = 0
	p1.offy = 0
	p1.start_t = time()
	
	p1_update = p1_stand
end

function p1_update()
	-- state machine
	-- leaving empty to be
	-- reassigned
end

function p1_stand()
	p1.ix = 0
	p1.offx = 0
	p1.offy = 0

	if (btnp(0) or btnp(1))	p1.start_t = time()

	p1.timer=8
	local e = empty(p1.x,p1.y+8)
	if e then
		p1_update = p1_fall
		p1_update()
		return
	end
	
	if btn(0) then
		p1.faceleft = true
		local e = empty(p1.x-8,p1.y)
		if e then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		elseif btnp(0) then
			p1_bump_left()
			p1.ix = 26
			p1.offx = -1
			p1_update=p1_recoil
			p1_update()
			return
		end
	end

	if btn(1) then
		p1.faceleft = false
		local e = empty(p1.x+8,p1.y)
		if e then
			p1.dx = 1
			p1_update = p1_moveh
			p1_update()
			return
		elseif btnp(1) then
			p1_bump_right()
			p1.ix = 26
			p1.offx = 1
			p1_update=p1_recoil
			p1_update()
			return
		end
	end	
				
	if btnp(3) then
	 p1_bump_down()			
	 p1.ix=28
		p1.offy=1
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
			p1.ix=27
			p1.offy=-1
			p1_update=p1_recoil
			p1_update()
		end		
	end
end

function p1_moveh()
	timed = time() - p1.start_t
	p1.ix = flr((timed*30)%6) + 8
	if (p1.ix>14) p1.ix = 8
	p1.x += p1.dx
	if p1.x %8 == 0 then
		p1_update = p1_stand
		p1.ix=0
		p1_update()
		return
	end
end

function p1_fall()
	p1.ix = max(24,p1.x)
	p1.ix = flr(time()*15%2) + 24
	p1.y += 1
	e = empty(p1.x,p1.y+8)
	if not e then
		p1_update=p1_stand
		p1.ix=0
		p1_update()
		p1.y = 8*(p1.y\8)
		return
	end
end

function p1_recoil()
	p1.timer -= 1
	if (p1.timer < 4) p1.offx, p1.offy = 0,0
	if (p1.timer < 2) p1.ix = 0
	if p1.timer == 0 then
		p1_update=p1_stand
		return
	end
end

function p1_jump()
	p1.ix = max(24,p1.x)
	p1.ix = flr(time()*15%2) + 24
	p1.y -= 1
	if p1.y%8 == 0 then
		p1.timer=8
		p1_update = p1_hover
		p1.ix=0
		p1_update()
		return
	end
end

function p1_ride()
	p1.y = p1.other.y-8
	e = empty(p1.x,p1.y+8)
	if not e then
		p1_update=p1_stand
		p1_update()
		p1.y = 8*(p1.y\8)
		return
	end
	
end

function p1_hover()
	p1.ix = max(24,p1.x)
	p1.ix = flr(time()*15%2) + 24
	p1.timer-=1
	if p1.timer == 0 then
		p1_update = p1_fall
		p1_update()
		return
	end
	
	if btn(0) then
		p1.faceleft = true
		local e = empty(p1.x-8,p1.y)
		if e then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		end
	end

	if btn(1) then
		p1.faceleft = false
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
	sfx(7)
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
	make_explosion(x,y)
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
				for i =1,10,1 do
					p1.ix=24+((i\2)%2)
					make_text_box("-20",8,p1.x+8,p1.y)
					_draw()
					flip()
				end
			--ride
			elseif p1.y < h.y then
				p1.other = h
				p1_update = p1_hover
				p1_update()
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
	make_text_box("+25","c",t.x-1,t.y-8)
end

function update_air_tanks()
	for t in all(air_tanks) do
		local below = m8get(t.x,t.y+8)
		if below==0 then
			mset(t.x\8,t.y\8,0)
			t.timer-= 1
			if t.timer <=0 then
				t.y+=1
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
	block.update = hard_stand
	block.falld = 0 --how far i fell
	add(hard_blocks,block)
end

function update_hard_blocks()
	for h in all(hard_blocks) do
		h:update()
	end
end

function hard_fall(h)
	h.y += 1
	h.falld += 1
	local below = m8get(h.x,h.y+8)
	if below > 0 then
		h.update = hard_stand
		h:update()
		if h.falld > 10 then
			hit_block(h.x,h.y+8)
			h.dmg += 1
			if (h.dmg>3) kill_block(h)
		end
		h.falld=0
		return
	end
end

function hard_hover(h)
	mset(h.x\8,h.y\8,0)
	h.timer-= 1
	if h.timer <=0 then
		h.update = hard_fall
		h:update()
		return
	end
end

function hard_stand(h)
	local below = m8get(h.x,h.y+8)
	h.timer=30
	if below==0 then
		h.update = hard_hover
		h:update()
		return
	else
		h.timer=30
		h.y = 8*(h.y\8)
		mset(h.x\8,h.y\8,5+16*h.dmg)
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

function test_animation()
	poke(0x5f2c,3)
	ix=8
	ixmax=14
	while true do
		poke(0x5f2c,3)
		cls(0)
		spr(ix,10,10)
		flip()
		poke(0x5f2c,3)
		ix+=1
		if (ix>14) ix=8
	end
end

function oprint(s,x,y,c1,c2)
	for xx=x-1,x+1,1 do
	for yy=y-1,y+1,1 do
		print(s,xx,yy,c2)
	end
	end
	print(s,x,y,c1)
end

function cprint(s,y,c1,c2)
	length = #s*4
	startx = 32 - (length\2)
	oprint(s,startx,y,c1,c2)
end
-->8
-- level

blockinfo={}
blockinfo[1] = {1,1}
blockinfo[2] = {2,1}
blockinfo[3] = {4,1}
blockinfo[4] = {6,2}
blockinfo[5] = {10,2}
blockinfo[6] = {12,2}

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
		tries=0
		while blockcount < amount do
			xd = -radius + flr(rnd(2*radius + 1)) + x
			xd = min(max(0,xd),7)
			yd = -radius + flr(rnd(2*radius + 1)) + y
			if mget(xd,yd)>0 then
				add_hard_block(xd*8,yd*8)
				blockcount+=1
				mset(xd,yd,0)
			end
			tries+=1
			if (tries>100) break
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
	for x=0,7,1 do
		mset(x,100,7)
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
	cy+=0.25
	six += 0.25
	if (six >= 14) six=8
	cy = cy%(110*8)
	cls()
	camera(0,cy)
	map()
	camera()
	cprint("bitty dig",12,8,9)
	oprint("⬆️⬇️⬅️➡️ to",10,44,8,0)
	cprint("start",52,8,0)
	
	pal({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
	for x=27,29,1 do
	for y=29,31,1 do
		spr(six,x,y,1,1,true)
	end
	end
	pal()
	spr(six,28,30,1,1,true)
end

function start_game()
	music(-1)
	fade_out()
	_draw = draw_game
	_update60=update_game
	init_level()
	update_game()
	fade_in()
	music(0)
end

function fade_out()
	pal(4,-8,1)
	for i=0,36,1 do
		--_draw()
		rectfill(32-i,32-i,32+i,32+i,4)
		flip()
	end
	pal()
end

function fade_in()
	pal(4,-8,1)
	for i=36,0,-1 do
		_draw()
		rectfill(32-i,32-i,32+i,32+i,4)
		flip()
	end
	pal()
end

function start_title()
	music(4)
	level = 1
	air = 100
	_draw = draw_title
	_update60 = update_title
	make_level()
	cy=0
	six = 8
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
	music(-1)
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
	cls(0)
	cprint("level "..level,28,8,9)
end
__gfx__
09989980ccccccccddddddddeeeeeeeeffffffff766666660007a000222222220998998009989980099899800000000000000000099899800000000000000000
99999998ccccccccddddddddeeeeeeeeffffffff65555557007aaa00288888289999999899999998999999980998998009989980999999980000000000000000
08888940ccccccccddddddddeeeeeeeeffffffff655555577aaaaaaa288882280888894008888940088889409999999899999998088889400000000000000000
78181876ccccccccddddddddeeeeeeeeffffffff655555570aaaaaa0288822287818187678181876018187600888876078888976781818760000000000000000
78181876ccccccccddddddddeeeeeeeeffffffff6555555700aaaa00288222287818187678181876088187600181876078181876781818760000000000000000
08888840ccccccccddddddddeeeeeeeeffffffff6555555700aaaa00282222280888876008888760088876400881884008181840088888400000000000000000
07884760ccccccccddddddddeeeeeeeeffffffff6555555707aaaaa0222222280788476000884760008876000888764008888760078847600000000000000000
07600760ccccccccddddddddeeeeeeeeffffffff677777760aa00aa0288888880760000000760000007600000088760007888760076007600000000000000000
00000000111111112222222288888888bbbbbbbb7666666600000000000000000998998000000000099899800977798009989980000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000069999999809989980999999989966699899999998000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000067888897699999998089888400866884008988840000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000067818187608888760768888400888884008888840000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555555700000000000000060818184008181760766888400888884008888840000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6555055700000000000000067888876008181840766876400888764008866840000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6550555700000000000000067688476078888760008876000088760000666876000000000000000000000000
00000000ccccccccddddddddeeeeeeeeffffffff6770777600000000000000060000000076884760007600000076000000777076000000000000000000000000
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
__sfx__
010e00000f4520f4520040216402134020040200402004020a4520a4521640200402004021b4021b402004020c4520c452184020f4520f4521b4020a4520a45216402164020c4021340200402114021140216402
000e0000114521145200402164020c4520a4020f452004020c4520c4521640200402004021b4021b402004020f4520f4521840211452114521b402114521145216402164020c4021340200402114021140216402
000e0000164521645200402164020c4020a4020f4020040213452134521640200402004021b4021b4020040211452114521840211402114021b4020c4020c4020f4520f4520c4021340200402114021140211402
010e00001145211452114421144211432114321143211432114221142211422114221141211412114121141200000000000000000000000000000000000000000000000000000000000000000000000000000000
900e00001f15300100001032410324153221032215322103221530010300103001032415322103221532210322153001030010300103241532210322153221032215300103001030010300103001030010300103
900e00001f15300100001032410324153221032215322103221530010300103001032415322103221532210322153241532215300103221532415322153221032215300103001030010300103001030010300103
050e0000111530010300103001030f1530c10300103001030c1530010300103001030a153001030010300103111530010300103001030f1530c10300103001030c1530010300103001030a153001030010300103
150400000a731337312473116731137310f7310b73325703007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100701007010070100700
__music__
01 00040644
00 01050644
00 02040644
02 03050644
01 04064344
02 05064344

