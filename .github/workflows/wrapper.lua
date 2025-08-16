----------------------------------------------------------------
-- LibWoWQRCode
----------------------------------------------------------------
-- Author:  Sebastian Lindfors (Munk / MunkDev)
-- Website: https://github.com/seblindfors/LibWoWQRCode

local MAJOR = 'LibWoWQRCode'
local MINOR = __REV__
if not LibStub then error(MAJOR .. ' requires LibStub.') end
local QR = LibStub:NewLibrary(MAJOR, MINOR)
if not QR then return end;
local private = {};

local function Release(canvas)
	private.frPool:Release(canvas)
	local txs = {};
	for tx in private.txPool:EnumerateActive() do
		if tx:GetParent() == canvas then
			txs[#txs+1] = tx
		end
	end
	for i=1, #txs do
		private.txPool:Release(txs[i])
	end
	return #txs > 0;
end

local function Draw(data, size, parent, drawLayer, subLevel)
	local canvas, newObj = private.frPool:Acquire()
	if newObj then
		function canvas:Release()
			Release(self)
		end
	end
	canvas:SetParent(parent or private.qrSink)
	canvas:SetSize(size, size)
	canvas:Show()

	drawLayer = drawLayer or 'ARTWORK';
	subLevel  = Clamp(tonumber(subLevel) or 1, -8, 6);

	local t = private.txPool:Acquire()
	t:SetParent(canvas)
	t:SetAllPoints(canvas)
	t:SetColorTexture(1, 1, 1)
	t:SetDrawLayer(drawLayer, subLevel)
	t:Show()

	local c, l = #data[1];
	local s = math.max(math.ceil(size / (c + 2)), 2)
	local p = math.max(0, (size - (c * s)) / 2)
	for y = 1, c do
		for x = 1, c do
			l = data[y][x] > 0 and 0 or 1;
			t = private.txPool:Acquire()
			t:SetSize(s, s)
			t:SetParent(canvas)
			t:SetPoint('TOPLEFT', canvas, 'TOPLEFT', p + (x - 1) * s, -(p + (y - 1) * s))
			t:SetDrawLayer(drawLayer, subLevel + 1)
			t:SetColorTexture(l, l, l)
			t:Show()
		end
	end
	return canvas;
end

local function Init()
	private.qrSink = CreateFrame('FRAME')
	private.qrSink:Hide()

	local function ResetObject(_, obj)
		obj:SetParent(private.qrSink)
		obj:ClearAllPoints()
		obj:Hide()
	end

	private.frPool = CreateFramePool('FRAME', private.qrSink, nil, ResetObject)
	private.txPool = CreateTexturePool(private.qrSink, nil, nil, nil, ResetObject)
	Init = nil;
end

local function Acquire(_, str, size, parent, drawLayer, subLevel)
	if type(str) ~= 'string' or not tonumber(size) then
		error('Usage: LibWoWQRCode(str, size, [parent, drawLayer, subLevel])', 2)
	end
	local success, data = private.qrcode(str)
	if not success then
		error(data)
	end
	if Init then Init() end;
	return Draw(data, size, parent, drawLayer, subLevel)
end

Mixin(private, (function(testing)
--[[QRENCODE_PLACEHOLDER]]
end)(false))

setmetatable(QR, {
	__call      = Acquire;
	__newindex  = function() error('LibWoWQRCode is read-only') end;
	__metatable = false;
})