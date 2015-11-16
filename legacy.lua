--[[
--This file is inteded for placing unused code which may be useful
--for later work.
--
--This file will not be maintained in any way, other than having functions
--added and removed.
--
--]]

--intended for optimisation, will later be used for cubic noise instead
--[[
local solidblockfiller_2d = function(blockvalue,blocksize,table,tablesize,blockstart)
	local tableit = blockstart 
	local zbuf = tablesize.x - blocksize.x
	local x,z = 1,1
	local blocklength = blocksize.x*blocksize.z
	for i=1,blocklength do
		if x > blocksize.x then
			x = 1
			z = z + 1
			tableit = tableit + zbuf
		end
		table[tableit] = blockvalue
		tableit = tableit + 1
		x = x + 1
	end
end

--for 2d use (x,y) rather than (x,0,z)
local solidblockfiller = function(blockvalue,blocksize,table,tablesize,blockstart)
	local tableit = blockstart 
	local ybuf,zbuf = tablesize.x - blocksize.x,(tablesize.y - blocksize.y)*tablesize.x
	local x,y,z = 1,1,1
	local blocklength = blocksize.x*blocksize.y*(blocksize.z or 1)
	for i=1,blocklength do
		if x > blocksize.x then
			x = 1
			y = y + 1
			tableit = tableit + ybuf
		end
		if y > blocksize.y then
			y = 1
			z = z + 1
			tableit = tableit + zbuf
		end
		table[tableit] = blockvalue
		tableit = tableit + 1
		x = x + 1
	end
end
--]]
