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



function _init()
	for x=0,7,1 do
		for y=0,99,1 do
			mset(x,y,1+flr(rnd(4)))
		end
	end
	
	cy=0
	p1_make()
	
end

function _update60()
	
	p1_update()

	cy = p1.y - 12
	cx = 0
	camera(cx,cy)
end

function _draw()
	cls()
	map()
	spr(0,p1.x,p1.y)
	camera()
	color(7)
	print(p1.hang)
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

function p1_stand()
	p1.timer=8
	if m8get(p1.x,p1.y+8)==0 then
		p1_update = p1_fall
		p1_update()
		return
	end
	
	if btn(0) then
		local t = m8get(p1.x-8,p1.y)
		if t==0 then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		else
			p1_bump_left()
			p1_update=p1_recoil
			p1_update()
			return
		end
	end

	if btn(1) then
		local t = m8get(p1.x+8,p1.y)
		if t==0 then
			p1.dx = 1
			p1_update = p1_moveh
			p1_update()
			return
		else
			p1_bump_right()
			p1_update=p1_recoil
			p1_update()
			return
		end
	end	
				
	if btn(3) then
	 p1_bump_down()			
		p1_update=p1_recoil
		p1_update()
		return
	end
	
	if btn(2) then
		local t = m8get(p1.x,p1.y-8)
		if t==0 then
			p1_update = p1_jump
			p1_update()
			return
		else
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
	t = m8get(p1.x,p1.y+8)
	if t>0 then
		p1_update=p1_stand
		p1_update()
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
		local t = m8get(p1.x-8,p1.y)
		if t==0 then
			p1.dx = -1
			p1_update = p1_moveh
			p1_update()
			return
		end
	end

	if btn(1) then
		local t = m8get(p1.x+8,p1.y)
		if t==0 then
			p1.dx = 1
			p1_update = p1_moveh
			p1_update()
			return
		end
	end	
end

function p1_update()
end

function p1_bump_left()
	p1.timer=8
	hit_block(p1.x-8,p1.y)
end

function p1_bump_right()
	p1.timer=8
	hit_block(p1.x+8,p1.y)
end

function p1_bump_down()
	p1.timer=8
	hit_block(p1.x,p1.y+8)
end

function p1_bump_up()
	p1.timer=8
	hit_block(p1.x,p1.y-8)
end

function hit_block(x,y)
	x = x\8
	y = y\8
	if (x<0 or x>7) return
	local t = mget(x,y)
	if (t==0) return
	mset(x,y,0)
	if (mget(x-1,y)==t) hit_block(8*(x-1),8*y)
	if (mget(x+1,y)==t) hit_block(8*(x+1),8*y)
	if (mget(x,y-1)==t) hit_block(8*x,8*(y-1))
	if (mget(x,y+1)==t) hit_block(8*x,8*(y+1))
end
-->8
--draw
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
__gfx__
00000000ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08181880ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78181877ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78888877ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07888770ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07700770ccccccccddddddddeeeeeeeeffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
