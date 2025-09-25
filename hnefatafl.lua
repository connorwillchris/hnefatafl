-- Hnefatafl (11x11) - Lua CLI
-- Variant per request:
--  * White (attackers) vs Black (defenders + King)
--  * White wins by capturing the King with a standard 2-side sandwich
--  * Black wins if the King reaches a corner
--  * Only the King may end a move on the throne (center) or corner squares
--  * Captures use sandwiching; corners and throne count as hostile for capturing
--  * Output is via stdout; interactive text UI

-- ========= Board & Rules =========

local SIZE = 11

-- Squares:
-- '.' empty
-- 'W' white attacker
-- 'b' black defender
-- 'K' black king
-- We treat throne/corners by coordinates (they look like '.' unless the King is on them)

local function clone(tbl)
  local t = {}
  for i,v in ipairs(tbl) do
    if type(v) == "table" then t[i] = clone(v) else t[i] = v end
  end
  return t
end

-- Coordinates helpers
local function in_bounds(r,c) return r>=1 and r<=SIZE and c>=1 and c<=SIZE end

local function throne_rc()
  local m = math.floor(SIZE/2)+1 -- 6 on 11x11
  return m,m
end

local function is_throne(r,c)
  local tr,tc = throne_rc()
  return r==tr and c==tc
end

local function is_corner(r,c)
  return (r==1 and c==1) or (r==1 and c==SIZE) or (r==SIZE and c==1) or (r==SIZE and c==SIZE)
end

-- Hostile squares for capturing (count as the "far" friendly in a sandwich)
local function is_hostile_square(r,c)
  return is_corner(r,c) or is_throne(r,c)
end

-- Only the King may *end* a move on these; anyone may move *past* them is irrelevant since rook-move can't pass through occupied anyway
local function square_restricted_for_non_king(r,c)
  return is_corner(r,c) or is_throne(r,c)
end

-- Which side a piece belongs to
local function piece_side(p)
  if p == 'W' then return 'white'
  elseif p == 'b' or p=='K' then return 'black'
  else return nil end
end

local function is_king(p) return p=='K' end

-- ========= Initial Position (classic 11x11-style) =========

local function empty_board()
  local B = {}
  for r=1,SIZE do
    B[r] = {}
    for c=1,SIZE do B[r][c] = '.' end
  end
  return B
end

local function setup_board()
  local B = empty_board()

  -- Attackers (White) - standard 11x11 cross deployment around the edges
  local attackers = {
    -- Row 1 & Row 11, cols 4..8
    {1,4},{1,5},{1,6},{1,7},{1,8},
    {11,4},{11,5},{11,6},{11,7},{11,8},
    -- Col 1 & Col 11, rows 4..8
    {4,1},{5,1},{6,1},{7,1},{8,1},
    {4,11},{5,11},{6,11},{7,11},{8,11},
    -- Extra arms on center lines
    {6,1},{6,2},{6,3},{6,9},{6,10},{6,11},
    {1,6},{2,6},{3,6},{9,6},{10,6},{11,6},
  }
  -- Deduplicate (some duplicates possible)
  local seen = {}
  for _,rc in ipairs(attackers) do
    local key = rc[1]..","..rc[2]
    if not seen[key] then
      if B[rc[1]][rc[2]] == '.' then B[rc[1]][rc[2]] = 'W' end
      seen[key]=true
    end
  end

  -- Defenders (Black) + King clustered at center
  local m = math.floor(SIZE/2)+1 -- 6
  B[m][m] = 'K' -- King at throne

  local defenders = {
    -- plus shape immediately around the king
    {m-1,m},{m+1,m},{m,m-1},{m,m+1},
    -- second ring
    {m-2,m},{m+2,m},{m,m-2},{m,m+2},
    {m-1,m-1},{m-1,m+1},{m+1,m-1},{m+1,m+1}
  }
  for _,rc in ipairs(defenders) do
    if in_bounds(rc[1], rc[2]) and B[rc[1]][rc[2]]=='.' then
      B[rc[1]][rc[2]] = 'b'
    end
  end

  return B
end

-- ========= Display =========

local function print_board(B)
  io.write("\n   ")
  for c=1,SIZE do io.write(string.char(96+c).." ") end -- a..k
  io.write("\n")
  for r=1,SIZE do
    io.write(string.format("%2d ", r))
    for c=1,SIZE do
      local ch = B[r][c]
      -- mark throne/corners lightly (lowercase 't','c') if empty
      if ch=='.' then
        if is_throne(r,c) then io.write("· ")  -- center dot
        elseif is_corner(r,c) then io.write("○ ")
        else io.write(". ")
        end
      else
        io.write(ch.." ")
      end
    end
    io.write(string.format(" %2d\n", r))
  end
  io.write("   ")
  for c=1,SIZE do io.write(string.char(96+c).." ") end
  io.write("\n")
end

-- ========= Move parsing & validation =========

local function parse_square(tok)
  -- expects like 'e6' (file letter a..k, rank 1..11)
  if not tok or #tok < 2 then return nil end
  local file = string.sub(tok,1,1)
  local rank = string.sub(tok,2)
  local c = string.byte(file) - 96 -- 'a' -> 1
  local r = tonumber(rank)
  if not r or not c then return nil end
  if not in_bounds(r,c) then return nil end
  return r,c
end

local function path_clear(B, r1,c1, r2,c2)
  if r1==r2 then
    local step = (c2>c1) and 1 or -1
    for c=c1+step, c2, step do
      if B[r1][c] ~= '.' or (c~=c2 and (is_corner(r1,c) or is_throne(r1,c))) then
        -- can't pass through occupied; we also disallow passing *through* throne/corners?:
        -- Traditional rules forbid stopping on special squares (except king), passing over is moot (no jumping).
        if c~=c2 and (is_corner(r1,c) or is_throne(r1,c)) then
          -- It's empty but we treat it just as a normal empty tile for passing. Since rook moves can't pass "through" any piece anyway,
          -- leaving this check lenient: allow passing over empty special squares.
        end
      end
    end
    -- Second pass only checking pieces (the above note kept for clarity)
    local step2 = (c2>c1) and 1 or -1
    for c=c1+step2, c2-step2, step2 do
      if B[r1][c] ~= '.' then return false end
    end
    return true
  elseif c1==c2 then
    local step = (r2>r1) and 1 or -1
    for r=r1+step, r2-step, step do
      if B[r][c1] ~= '.' then return false end
    end
    return true
  else
    return false
  end
end

local function can_end_on(B, r,c, piece)
  if piece=='K' then return true end
  if square_restricted_for_non_king(r,c) then return false end
  return true
end

local function valid_move(B, side, r1,c1, r2,c2)
  if not in_bounds(r1,c1) or not in_bounds(r2,c2) then return false, "Out of bounds" end
  local p = B[r1][c1]
  if p == '.' then return false, "No piece at source" end
  if piece_side(p) ~= side then return false, "Not your piece" end
  if r1~=r2 and c1~=c2 then return false, "Must move orthogonally" end
  if r1==r2 and c1==c2 then return false, "No move" end
  if B[r2][c2] ~= '.' then return false, "Destination occupied" end
  if not can_end_on(B, r2,c2, p) then return false, "Only the King may end on throne/corner" end
  if not path_clear(B, r1,c1, r2,c2) then return false, "Path blocked" end
  return true
end

-- ========= Captures =========

local DIRS = { {1,0}, {-1,0}, {0,1}, {0,-1} }

local function capture_at(B, side, r,c, dr,dc)
  -- After moving, check enemy piece at r+dr,c+dc; if enemy and square beyond is friendly or hostile => capture
  local er,ec = r+dr, c+dc
  if not in_bounds(er,ec) then return false end
  local enemy = B[er][ec]
  if enemy == '.' then return false end
  if piece_side(enemy) == side then return false end

  local far_r, far_c = er+dr, ec+dc
  if not in_bounds(far_r,far_c) then return false end

  local far_piece = B[far_r][far_c]
  local far_is_friend = (far_piece ~= '.' and piece_side(far_piece)==side)
  local far_is_hostile_square = (far_piece=='.' and is_hostile_square(far_r,far_c))

  if far_is_friend or far_is_hostile_square then
    -- King captured the same way as others (two-side)
    B[er][ec] = '.'
    return true
  end
  return false
end

local function apply_captures(B, side, to_r, to_c)
  local any = false
  for _,d in ipairs(DIRS) do
    local ok = capture_at(B, side, to_r, to_c, d[1], d[2])
    if ok then any = true end
  end
  return any
end

-- ========= Victory =========

local function check_white_win(B)
  -- White wins if King is gone
  for r=1,SIZE do
    for c=1,SIZE do
      if B[r][c]=='K' then return false end
    end
  end
  return true
end

local function check_black_win(B)
  -- Black wins if King reaches any corner
  for r=1,SIZE do
    for c=1,SIZE do
      if B[r][c]=='K' and is_corner(r,c) then return true end
    end
  end
  return false
end

-- ========= Game Loop =========

local function prompt(side)
  io.write(("\n[%s] Enter move (e.g., e6 e9) or 'q' to quit: "):format(side))
  io.flush()
end

local function parse_move_line(line)
  -- Accept "e6 e9" or "e6->e9" or "e6-e9"
  line = line:gsub("->"," "):gsub("-"," ")
  local a,b = line:match("^%s*([a-kA-K]%d+)%s+([a-kA-K]%d+)%s*$")
  if not a or not b then return nil end
  local r1,c1 = parse_square(a:lower())
  local r2,c2 = parse_square(b:lower())
  if not r1 then return nil end
  return r1,c1,r2,c2
end

local function count_pieces(B)
  local w,b,k = 0,0,0
  for r=1,SIZE do
    for c=1,SIZE do
      if B[r][c]=='W' then w=w+1
      elseif B[r][c]=='b' then b=b+1
      elseif B[r][c]=='K' then k=k+1 end
    end
  end
  return w,b,k
end

local function main()
  local B = setup_board()
  local side = 'white' -- White starts

  io.write("\nHnefatafl (11x11) — White (attackers) vs Black (defenders + King)\n")
  io.write("White wins by CAPTURING the King with a two-side sandwich.\n")
  io.write("Black wins if the King reaches a CORNER.\n")
  io.write("Move format: e.g., e6 e9   (file a..k, rank 1..11). Type 'q' to quit.\n")
  io.write("Legend: W=White, b=Black defender, K=King, ·=throne (center), ○=corner, .=empty\n")
  print_board(B)

  while true do
    -- Win checks (in case of weird states)
    if check_white_win(B) then
      io.write("\nWhite wins! The King has been captured.\n")
      break
    end
    if check_black_win(B) then
      io.write("\nBlack wins! The King has escaped to a corner.\n")
      break
    end

    prompt(side)
    local line = io.read("*l")
    if not line then io.write("\nEnd of input.\n"); break end
    if line == 'q' or line=='Q' then io.write("Goodbye.\n"); break end

    local r1,c1,r2,c2 = parse_move_line(line)
    if not r1 then
      io.write("Invalid input. Example: e6 e9\n")
    else
      local ok,msg = valid_move(B, side, r1,c1, r2,c2)
      if not ok then
        io.write("Illegal move: "..msg.."\n")
      else
        -- Make move
        local p = B[r1][c1]
        B[r1][c1] = '.'
        B[r2][c2] = p

        -- Captures
        apply_captures(B, side, r2,c2)

        print_board(B)
        local wcnt, bcnt, kcnt = count_pieces(B)
        io.write(string.format("Counts — White:%d  Black:%d  King:%d\n", wcnt, bcnt, kcnt))

        -- Check win after move/captures
        if check_white_win(B) then
          io.write("\nWhite wins! The King has been captured.\n")
          break
        end
        if check_black_win(B) then
          io.write("\nBlack wins! The King has escaped to a corner.\n")
          break
        end

        side = (side=='white') and 'black' or 'white'
      end
    end
  end
end

main()
