pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

--strings
game_over_label = "game over"
score_label = "" -- updated at game over
continue_label = "press \x8e to continue"

--game state
game={}

function _update()
  game.upd()
end

function _draw()
  game.drw()
end


--Splash Screen game state
function show_splash()
  game.upd = splash_screen_update
  game.drw = splash_screen_draw
end

function splash_screen_update()
  --update the splash screen
  --change to the next state
  --when ready
  start()
end

function splash_screen_draw()
  --draw the splash screen
end


--Game Start game state
function start()
  reset_game()
  game.upd = update_game
  game.drw = draw_game
end

function update_game()
  t=t+1
  if ship.imm then
    ship.t += 1
    if ship.t >30 then
      ship.imm = false
      ship.t = 0
    end
  end
  
  for st in all(stars) do
    st.y += st.s
    if st.y >= 128 then
      st.y = 0
      st.x=rnd(128)
    end
  end
  
  for ex in all(explosions) do
    ex.t+=1
    if ex.t == 13 then
      del(explosions, ex)
    end
  end
  
  if #enemies <= 0 then
    respawn()
  end
  
  for e in all(enemies) do
    e.m_y += 1.3
    e.x = e.r*sin(e.d*t/50) + e.m_x
    e.y = e.r*cos(t/50) + e.m_y
    if coll(ship,e) and not ship.imm and ship.h > 0 then
      ship.imm = true
      ship.h -= 1
      if ship.h <= 0 then
        score_label = "score: "..ship.p
        explode(ship.x,ship.y)
        sfx(2)
        --this timestamp is used to wait some seconds before making the game over screen appear
        death_time_stamp = t
      end
    end
    
    if e.y > 150 then
      del(enemies,e)
    end
  end
  
  for b in all(bullets) do
    b.x+=b.dx
    b.y+=b.dy
    if b.x < 0 or b.x > 128 or
    b.y < 0 or b.y > 128 then
      del(bullets,b)
    end
    for e in all(enemies) do
      if coll(b,e) then
        del(enemies,e)
        del(bullets,b)
        ship.p += 1
        explode(e.x,e.y)
        -- Explosion sound
        sfx(0)
      end
    end
  end

  if ship.h <= 0 then
    --ship disappears after it loses all lives
    ship.sp=0
  else
    if(t%6<3) then
      ship.sp=1
    else
      ship.sp=2
    end
  end

  -- The ship only moves and shoots if it still has lives
  if ship.h > 0 then
    -- Here it checks if the ship is going out of the screen
    if btn(0) and ship.x>0 then ship.x-=1 end
    if btn(1) and ship.x<128-7 then ship.x+=1 end
    if btn(2) and ship.y>0 then ship.y-=1 end
    if btn(3) and ship.y<128-7 then ship.y+=1 end
    if btnp(4) then fire() end
  end

  if ship.h <= 0 then
    if t == death_time_stamp + 90 then game_over() end
  end
end

function draw_game()
  cls()
  for st in all(stars) do
    pset(st.x,st.y,6)
  end
  
  print(ship.p,9)

  if not ship.imm or t%8 < 4 then
    spr(ship.sp,ship.x,ship.y)
  end
  
  for ex in all(explosions) do
    circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
  end
  
  for b in all(bullets) do 
    spr(b.sp,b.x,b.y)
  end
  
  for e in all(enemies) do
    spr(e.sp,e.x,e.y)
  end
  
  for i=1,4 do
    if i<=ship.h then 
      spr(33,80+6*i,3)
    else
      spr(34,80+6*i,3)
    end
  end
end

--Game Over game state
function game_over()
		sfx(1)
  game.upd = update_over
  game.drw = draw_over
end
  
function update_over()
    if (btn(4)) then start() end
end
  
function draw_over()
  cls()
  print(game_over_label,hcenter(game_over_label),50,4)
  print(score_label,hcenter(score_label),60,4)
  print(continue_label,hcenter(continue_label),80,4)
end


--Functions

function wait(a) for i = 1,a do flip() end end

function _init()
  start()
end

function reset_game()
  t=0
  
  ship = {
    sp=1,
    x=60,
    y=100,
    h=4,
    p=0,
    t=0,
    imm=false,
    box = {x1=0,y1=0,x2=7,y2=7}}
  bullets = {}
  enemies = {}
  explosions = {}
  stars = {}
  
  for i=1,128 do
    add(stars,{
      x=rnd(128),
      y=rnd(128),
      s=rnd(2)+1
    })
  end 
end
  
function respawn()
  local n = flr(rnd(9))+2
  for i=1,n do
    local d = -1
    if rnd(1)<0.5 then d=1 end
    add(enemies, {
      sp=17,
      m_x=i*16,
      m_y=-20-i*8,
      d=d,
      x=-32,
      y=-32,
      r=12,
      box = {x1=0,y1=0,x2=7,y2=7}
    })
  end
end
  
function abs_box(s)
  local box = {}
  box.x1 = s.box.x1 + s.x
  box.y1 = s.box.y1 + s.y
  box.x2 = s.box.x2 + s.x
  box.y2 = s.box.y2 + s.y
  return box
end
  
function coll(a,b)
  -- todo
  local box_a = abs_box(a)
  local box_b = abs_box(b)
  
  if box_a.x1 > box_b.x2 or
  box_a.y1 > box_b.y2 or
  box_b.x1 > box_a.x2 or
  box_b.y1 > box_a.y2 then
    return false
  end
  return true 
end
  
function explode(x,y)
  add(explosions,{x=x,y=y,t=0})
end
  
function fire()
  local b = {
    sp=3,
    x=ship.x,
    y=ship.y,
    dx=0,
    dy=-3,
    box = {x1=2,y1=0,x2=5,y2=4}
  }
  add(bullets,b)
end

--String utils

function hcenter(s)
  -- screen center minus the
  -- string length times the 
  -- pixels in a char's width,
  -- cut in half
  return 64-#s*2
end

function vcenter(s)
  -- screen center minus the
  -- string height in pixels,
  -- cut in half
  return 61
end

__gfx__
00000000008008000080080000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008008000080080000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088880000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088118800881188000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088cc880088cc88000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080880800808808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a00000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000a000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bb0000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b0bbbb0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb77bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb00bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bb77bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b0bbbb0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b00b000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080800000606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888880006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088800000666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
66600000000000000000000000000000000000000000000000000060600000000000000000000000000000600000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600000000000000000000000000000000000000000000000000000000000000000000000000000000000080800080800080800080800000000000000000000
66600000000000000000000000000000000000000000000000000000000000000000000000000000000000888880888880888880888880000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000088800088800088800088800060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000008000008060008000000000000000000000
00000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000
00000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb00000
00000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000bb70b0000
00000000000000000000000000000000000006000000000000000000000000000000060000000000000600000000000000000000000000000000000bb77b0000
00000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000bb77b0000
0000000000000000000000000000000000000000000000000600000000000000000060660000000000000000000000000000000000000000000000b0bbb0b000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00b000b00
00000000000000000000000000000000000000000000000000006006000000000000000000000000000000000000000060000000000000000000000000b00000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000bbb00
00000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000bb70b0
06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000bb77b0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb77b0
0000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0bbb0b
0000000000000006000000000000000060000000000000000000000000060000000000000000000000000000000000000000000000000000000000000b00b000
00000000000000600000000000000000000000006000000000000000000000060000000000000000000000000000000000000000000000000000000000000b00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000600000000000000000000000000000000000000000000000000000000bbb0006000000000000000000000000000000000
000000000000060000000000000000000000000000000000000000000000000000000000000000000000000bb70b000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb77b000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000060000990000000000000000000000bb77b000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000099000000006000000000000b0bbb0b00000000000000006000600000000000000
00000000000600000000000000000000000000000000000000000000000000099000000000000000000000b00b000b0000000000000006000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000b0000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb0000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb70b000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600bb77b000000000000000000600000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb77b000000000000000000000000000000000
00000000000000000000000000000000000000000000000000600000000000000000000000000000000000000b0bbb0b00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00b000b0000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000bbb00000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000006000000bb70b0000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000099000000000bb77b0006000000000000000000060600000000000000000060000
00000000000000000000000000000000000000000000000000000000060000099000000000bb77b0000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000009900000000b0bbb0b000000000000600000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000b00b000b00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000060060000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000
0000000000000000000000060000000000000000bbb0000000000000000000000000000000060000000000000000000000000000000006000000000000000600
000000000000000000000000000000000000000bb70b000000000000000000000000000000000000000000000006000000000000000000000000000000000000
000000000000000000000000000000000000000bb77b000000000000000600000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000bb77b000000000000000000000000000000000000000000000000000000000000000000000000060000000000
00000000000000000000000000000000000000b0bbb0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000b00b000b0000000000060000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000b0000000000006000000000006000000000000000600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000bbb0000000000000000000000000000000006000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000bb70b000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000006000000000000000000000bb77b000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000bb77b000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000b0bbb0b00000000000000099000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000b00b000b0000000000000099000000000000000000000000000000000000000060000000000000000000000
000000000000000000000000000006000000000000000b0000000000000000099000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bbb00000000000000000000000006000000000000000000000000000000600000000000000000000000000600000000000000
00000000006000000000000000bb70b0000000000000000000000000000000000000000000000000000000600000600000000000000000000000000000000000
00000000000000000000000000bb77b0600000000000000000000000000600000000000000000000000000000000000000000000000600000000000000000000
00000000000000000000000000bb77b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000006000000000b0bbb0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000b00b000b00000000000000000000000000000000000000000000000000000000000000000000000000060000000000000600000
00000000000000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000600000000000000000000000000000600000000000000000000000000000000000000000000000000000
00000000000600000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000060000000000000000000000000000000000000000000f000000000000f0000000000000000000000000
000000000000000000000000000000000000000000f0000000600000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000f000000000000000000000000000000000
00000000f00f00f00000f000000000000000000000000000000000000000000000f0000f0000000000000000000000000f00000f000000000000000000060000
0000000000000000000000000000000000000000000000000000000000000000000000000000000f00000f000000000000000000000000000000000000000000
000000000f0000000000000000000000000000000000f0000000000000000600000000f000000000000000000000000600000000000000000000000000000000
00000000000000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000f00f00
000000000000000000000000000000f00000000000000000000000000000000f0600000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000060000000000000006000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000800800000000000000000000000000000000006000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000800800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000888800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008811880000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000088cc880000000060000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008088080000000000000000000000000000000000000000000060000000000000000
0000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000
000000000000000000000600000000000000000000000000000000000000000a0000000006000000000000000000000000000000000000000000600000000000
60000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000
00000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000600000000000000000000000000000000
00000000000060000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000
00000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006000006000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000700001e6101f6101f6102d6102d610006100261021600196000d6000d600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001a05019050180501705017050170500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000000660216603c66000660216603c6620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000