
mtLeftMenu_x		= SCREEN.OFF_X + 10
mtLeftMenu_w		= 240
subMenuTop		= 10
subMenuLeft		= 8
subMenuSpace		= 16
subMenuHight		= 26
mtRightMenu_x		= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w		= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select	= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

leftInfoBox_x		= 0
leftInfoBox_y		= 0
leftInfoBox_w		= 0
leftInfoBox_h		= 0

mtList			= {}

old_selectChannel	= ""

function playVideo()
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= "") then flag_max = true end
	if (mtList[mtRightMenu_select].url ~= "") then flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= "") then flag_min = true end

	local url = ""
	-- conf=max: 1. max, 2. normal, 3. min
	if (conf.streamQuality == "max") then
		if (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_small
		end
	-- conf=min: 1. min, 2. normal, 3. max
	elseif (conf.streamQuality == "min") then
		if (flag_min == true) then
			url = mtList[mtRightMenu_select].url_small
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_hd
		end
	-- conf=normal: 1. normal, 2. max, 3. min
	else
		if (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		elseif (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		else
			url = mtList[mtRightMenu_select].url_small
		end
	end

	local screen = saveFullScreen()
	hideMtWindow()
	n:setBlank(true)
	os.execute("pzapit -unmute")

	n:PlayFile(mtList[mtRightMenu_select].title, url, mtList[mtRightMenu_select].theme, url);

	n:enableInfoClock(false)
--	collectgarbage();
	os.execute("pzapit -mute")
	posix.sleep(1)
	n:ShowPicture(backgroundImage)
	restoreFullScreen(screen, true)
end

function changeChannel(channel)
	old_selectChannel = conf.playerSelectChannel
	conf.playerSelectChannel = channel
	return MENU_RETURN.EXIT_ALL;
end

function channelMenu()
	local screen = saveFullScreen()
	m_channels = menu.new{name="Senderwahl", icon=pluginIcon};
	m_channels:addItem{type="subhead", name=langStr_channelSelection};
	m_channels:addItem{type="separator"};
	m_channels:addItem{type="back"};
	m_channels:addItem{type="separatorline"};
--	m_channels:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_channels:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

--	url_listChannels1a	= url_base .. "/?action=listVideo&channel=";


	local query_url = url_base .. "/?action=listChannels"
	local dataFile = createCacheFileName(query_url, "json")
	local s = getJsonData(query_url, dataFile);
	local j_table = {}
	j_table = decodeJson(s)
	if (j_table == nil) then
		os.execute("rm -f " .. dataFile)
		return false
	end
	if checkJsonError(j_table) == false then
		os.execute("rm -f " .. dataFile)
		return false
	end
	for i=1, #j_table.entry do
		m_channels:addItem{type="forwarder", action="changeChannel", id=j_table.entry[i].channel, name=j_table.entry[i].channel};
	end

	m_channels:exec()
	restoreFullScreen(screen, true)
	if (conf.playerSelectChannel ~= old_selectChannel) then
		mtRightMenu_select	= 1
		mtRightMenu_view_page	= 1
		mtRightMenu_list_start	= 0
		paintMtRightMenu()

		leftMenuEntry[2][2] = conf.playerSelectChannel
		paintMtLeftMenu(leftMenuEntry)
		paintMtRightMenu()
	end

end

function paint_mtItemLine(viewChannel, count)
	_item_x = mtRightMenu_x + 8
	_itemLine_y = itemLine_y + subMenuHight*count
	local bgCol  = 0
	local txtCol = 0
	local select
	if (count == mtRightMenu_select) then select=true else select=false end
--print(select)
	if (select == true) then
		txtCol = COL.MENUCONTENTSELECTED_TEXT
		bgCol  = COL.MENUCONTENTSELECTED_PLUS_0
	elseif ((count % 2) == 0) then
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_0
	else
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_1
	end
	n:PaintBox(rightItem_x, _itemLine_y, rightItem_w, subMenuHight, bgCol)

	local function paintItem(vH, txt, center)
		local _x = 0
		if (center == 0) then _x=6 end
		local w = ((rightItem_w / 100) * vH)
		if (vH > 20) then txt = adjustStringLen(txt, w-_x*2, fontLeftMenu1) end
		n:RenderString(useDynFont, fontLeftMenu1, txt, _item_x+_x, _itemLine_y+subMenuHight, txtCol, w, subMenuHight, center)
		_item_x = _item_x + w
	end

	if (count <= #mtList) then
		local cw = 10
		if (viewChannel == true) then
			paintItem(cw, "", 1);
			cw = 0
		end
		paintItem(24+cw/2, mtList[count].theme,    0);
		paintItem(35+cw/2, mtList[count].title,    0);
		paintItem(11,      mtList[count].date,     1);
		paintItem(6,       mtList[count].time,     1);
		paintItem(9,       mtList[count].duration, 1);
		local geo = ""
		if (mtList[count].geo ~= "") then geo = "X" end
		paintItem(5,       geo,      1);
	end
end

function paintMtRightMenu()
	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.MENUCONTENT_TEXT
	local textColor		= COL.MENUCONTENT_TEXT

	gui.paintSimpleFrame(mtRightMenu_x, mtMenu_y, mtRightMenu_w, mtMenu_h, frameColor, 0)

	local x		= mtRightMenu_x + 8
	local y		= mtMenu_y+subMenuTop
	rightItem_w	= mtRightMenu_w-subMenuLeft*2
	local item_x	= x
	rightItem_x	= x

	local function paintHead(vH, txt)
		local paint = true
		if (vH < 1) then
			vH = math.abs(vH)
			paint = false
		end
		local w = ((rightItem_w / 100) * vH)
		n:RenderString(useDynFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
		item_x = item_x + w
		if (paint == true) then
			n:paintVLine(item_x, y, subMenuHight, frameColor)
		end
	end

	local function paintHeadLine(viewChannel)
		gui.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
		local cw = 10
		if (viewChannel == true) then
			paintHead(cw, "Sender")
			cw = 0
		end
		paintHead(24+cw/2, "Thema")
		paintHead(35+cw/2, "Titel")
		paintHead(11, "Datum")
		paintHead(6, "Zeit")
		paintHead(9, "Dauer")
		paintHead(-5, "Geo")
	end

	itemLine_y = mtMenu_y+subMenuTop+2
	_item_x = 0
	paintHeadLine(false)

	local i = 1
	while (itemLine_y+subMenuHight*i < mtMenu_h+mtMenu_y-subMenuHight) do
		i = i + 1
	end
	mtRightMenu_count = i-1

-- json query
	local channel   = url_encode(conf.playerSelectChannel)
--	local channel   = url_encode("ORF")
	local theme     = url_encode("")
	local timeFrom  = "now"
	local period    = 7*DAY
	local minDuration = 300
	local start     = mtRightMenu_list_start
	local limit     = mtRightMenu_count
	local query_url = url_base .. "/?action=listVideos&channel=" .. channel .. 
					"&theme=" .. theme .. 
					"&timeFrom=" .. timeFrom .. 
					"&period=" .. period .. 
					"&minDuration=" .. minDuration .. 
					"&start=" .. start .. 
					"&limit=" .. limit
	local dataFile = createCacheFileName(query_url, "json")
	local s = getJsonData(query_url, dataFile);
	local j_table = {}
	j_table = decodeJson(s)
	if (j_table == nil) then
		os.execute("rm -f " .. dataFile)
		return false
	end
	if checkJsonError(j_table) == false then
		os.execute("rm -f " .. dataFile)
		return false
	end

	mtRightMenu_list_total = j_table.head.total
	mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)

	if (#mtList > #j_table.entry) then
		while (#mtList > #j_table.entry) do table.remove(mtList) end
	end
	for i=1, #j_table.entry do
		mtList[i] = {}
		mtList[i].channel	= j_table.entry[i].channel
		mtList[i].theme		= j_table.entry[i].theme
		mtList[i].title		= j_table.entry[i].title
		mtList[i].date		= os.date("%d.%m.%Y", j_table.entry[i].date_unix)
		mtList[i].time		= os.date("%H:%M", j_table.entry[i].date_unix)
		mtList[i].duration	= formatDuration(j_table.entry[i].duration)
		mtList[i].geo		= j_table.entry[i].geo
		mtList[i].description	= j_table.entry[i].description
		mtList[i].url		= j_table.entry[i].url
		mtList[i].url_small	= j_table.entry[i].url_small
		mtList[i].url_hd	= j_table.entry[i].url_hd
		mtList[i].parse_m3u8	= j_table.entry[i].parse_m3u8
	end

	for i = 1, mtRightMenu_count do
		paint_mtItemLine(false, i)
	end

	paintLeftInfoBox("Seite "..mtRightMenu_view_page.." von "..mtRightMenu_max_page)
end

function paintLeftInfoBox(txt)
	gui.paintSimpleFrame(leftInfoBox_x, leftInfoBox_y, leftInfoBox_w, leftInfoBox_h,
			COL.MENUCONTENT_TEXT, COL.MENUCONTENT_PLUS_1)
	n:RenderString(useDynFont, fontLeftMenu2, txt, 
			leftInfoBox_x, leftInfoBox_y+subMenuHight,
			COL.MENUCONTENT_TEXT, leftInfoBox_w, subMenuHight, 1)
end

function paintMtLeftMenu(entry)

--	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.MENUCONTENT_TEXT
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	-- get button size
	buttonCol_w, buttonCol_h = n:GetSize(btnBlue)

	-- left frame
	gui.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	-- infobox
	leftInfoBox_x = mtLeftMenu_x+subMenuLeft
	leftInfoBox_y = mtMenu_y+mtMenu_h-subMenuHight-subMenuLeft
	leftInfoBox_w = mtLeftMenu_w-subMenuLeft*2
	leftInfoBox_h = subMenuHight
	paintLeftInfoBox("")

	local y = 0
	local buttonCol_x = 0
	local buttonCol_y = 0

	local function paintItem(txt1, txt2, btn, enabled)
		if (enabled == true) then
			txtCol = COL.MENUCONTENT_TEXT
			bgCol  = COL.MENUCONTENT_PLUS_0
		else
			txtCol = COL.MENUCONTENTINACTIVE_TEXT
			bgCol  = COL.MENUCONTENTINACTIVE
		end
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
		n:paintVLine(mtLeftMenu_x+subMenuLeft+subMenuHight, y, subMenuHight, frameColor)
		n:RenderString(useDynFont, fontLeftMenu1, txt1, 
				mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2
		buttonCol_y = y+(subMenuHight-buttonCol_h)/2
		n:DisplayImage(btn, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
--		if (enabled == true) then
			n:RenderString(useDynFont, fontLeftMenu2, txt2, 
					mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
--		end
	end

	-- items
	local i = 0
	y = mtMenu_y+subMenuTop
	for i = 1, #entry do
		if (entry[i][4] == true) then
			paintItem(entry[i][1], entry[i][2], entry[i][3], entry[i][5])
			y = y + subMenuHight + subMenuSpace
		end
	end
end

function paintMtWindow(menuOnly)
	if (menuOnly == false) then
		h_mtWindow:paint{do_save_bg=true}
	end

	local hh	= h_mtWindow:headerHeight()
	local fh	= h_mtWindow:footerHeight()
	mtMenu_y	= SCREEN.OFF_Y + hh + 14
	mtMenu_h	= SCREEN.END_Y - mtMenu_y - hh - fh + 18

	paintMtLeftMenu(leftMenuEntry)
	paintMtRightMenu()
end

function hideMtWindow()
	h_mtWindow:hide()
	n:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)

end

function newMtWindow()
	local x = SCREEN.OFF_X
	local y = SCREEN.OFF_Y
	local w = SCREEN.END_X - x
	local h = SCREEN.END_Y - y
	h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, show_footer=false, name=pluginName .. " - v" .. pluginVersion, icon=pluginIcon};
	paintMtWindow(false)
	mtScreen = saveFullScreen()
	return h_mtWindow;
end

function startMediathek()

	leftMenuEntry = {}
	local function fillLeftMenuEntry(e1, e2, e3, e4, e5)
		local i = #leftMenuEntry+1
		leftMenuEntry[i]	= {}
		leftMenuEntry[i][1]	= e1
		leftMenuEntry[i][2]	= e2
		leftMenuEntry[i][3]	= e3
		leftMenuEntry[i][4]	= e4
		leftMenuEntry[i][5]	= e5
	end

	fillLeftMenuEntry("Suche",      "", btnBlue, true, false)
	fillLeftMenuEntry("Senderwahl", conf.playerSelectChannel, btnYellow, true, true)
	fillLeftMenuEntry("Thema",      "", btnGreen, true, false)
	fillLeftMenuEntry("Zeitraum",   "7 Tage", btnRed, true, false)
	fillLeftMenuEntry("min. Länge",  "5 min.", btn1, true, false)
	fillLeftMenuEntry("Sortieren",  "Datum", btn2, true, false)

	h_mtWindow = newMtWindow()

	repeat
		local msg, data = n:GetInput(500)

		if (msg == RC.down) then
			local select_old = mtRightMenu_select
			local aktSelect = (mtRightMenu_view_page-1)*mtRightMenu_count + mtRightMenu_select
			if (aktSelect < mtRightMenu_list_total) then
				mtRightMenu_select = mtRightMenu_select+1
				if (mtRightMenu_select > mtRightMenu_count) then
					if (mtRightMenu_view_page < mtRightMenu_max_page) then
						mtRightMenu_select = 1
						msg = RC.right
					else
						mtRightMenu_select = select_old
					end
				else
					paint_mtItemLine(false, select_old)
					paint_mtItemLine(false, mtRightMenu_select)
				end
			else
				mtRightMenu_select = select_old
		    end
		end
		if ((msg == RC.right) or (msg == RC.page_down)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start + mtRightMenu_count
				if (mtRightMenu_list_start < mtRightMenu_list_total) then
					mtRightMenu_view_page = mtRightMenu_view_page+1

					local aktSelect = (mtRightMenu_view_page-1)*mtRightMenu_count + mtRightMenu_select
					if (aktSelect > mtRightMenu_list_total) then
						mtRightMenu_select = mtRightMenu_list_total-(mtRightMenu_max_page-1)*mtRightMenu_count
					end
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_start
				end
			end
		end

		if (msg == RC.up) then
			local select_old = mtRightMenu_select
			mtRightMenu_select = mtRightMenu_select-1
			if (mtRightMenu_select < 1) then
				if (mtRightMenu_view_page > 1) then
					mtRightMenu_select = mtRightMenu_count
					msg = RC.left
				else
					mtRightMenu_select = select_old
				end
			else
				paint_mtItemLine(false, select_old)
				paint_mtItemLine(false, mtRightMenu_select)
			end
		end
		if ((msg == RC.left) or (msg == RC.page_up)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start - mtRightMenu_count
				if (mtRightMenu_list_start >= 0) then
					mtRightMenu_view_page = mtRightMenu_view_page-1
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_start
				end
			end
		end

		if (msg == RC.info) then
			paintMovieInfo()
		elseif (msg == RC.yellow) then
			channelMenu()
		elseif (msg == RC.ok) then
			playVideo()
		end
		menuRet = msg
	until msg == RC.home;
end

function paintMovieInfo()

	local box_w	= 860
	local box_h	= 520
	if box_w > SCREEN.X_RES then box_w = SCREEN.X_RES-80 end
	if box_h > SCREEN.Y_RES then box_h = SCREEN.Y_RES-80 end
	local box	= mtInfoBox("Filminfo (" .. mtList[mtRightMenu_select].channel .. ")", box_w, box_h)

	local hh	= box:headerHeight()
	local fh	= box:footerHeight()
	local x		= ((SCREEN.END_X - SCREEN.OFF_X) - box_w) / 2
	local y		= (((SCREEN.END_Y - SCREEN.OFF_Y) - box_h) / 2) + hh
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	local real_h	= box_h - hh - fh

	local space_x = 6
	local space_y = 6
	local frame_x = x + space_x
	local frame_y = y + space_y
	local frame_w = box_w - 2*space_x
	local frame_h = real_h - 2*space_y
	gui.paintSimpleFrame(frame_x, frame_y, frame_w, frame_h,
			COL.MENUCONTENT_TEXT, 0)

	local function paintInfoItem(_x, _y, info1, info2, frame)
		local tmp1_h = fontLeftMenu1_h+4
		local tmp2_h = fontLeftMenu2_h+4
		local _y1 = _y
		local _y = _y+fontLeftMenu1_h+10
		n:RenderString(useDynFont, fontLeftMenu1, info1, _x+14, _y,
				COL.MENUCONTENT_TEXT, frame_w, tmp1_h, 0)
		_y = _y + tmp1_h+0
	
		if type(info2) ~= "table" then
			n:RenderString(useDynFont, fontLeftMenu2, info2, _x+12+10, _y,
					COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
		else
			local maxLines = 4
			local lines = #info2
			if (lines > maxLines) then lines = maxLines end
			local i = 1
			for i=1, lines do
				local txt = string.gsub(info2[i],"\n", " ");
				n:RenderString(useDynFont, fontLeftMenu2, txt, _x+12+10, _y,
						COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
				_y = _y + tmp2_h
			end
			_y = _y - tmp2_h
		end
		if (frame == true) then
			gui.paintSimpleFrame(_x+8, _y1+6, frame_w-16, _y-_y1, COL.MENUCONTENT_TEXT, 0)
		end
		return _y
	end

	local step = 6
	-- theme
	local start_y = frame_y
	start_y = paintInfoItem(frame_x, start_y, "Thema", mtList[mtRightMenu_select].theme, true)

	-- title
	start_y = start_y + step
	local txt = adjustStringLen(mtList[mtRightMenu_select].title, frame_w-36, fontLeftMenu2)
	start_y = paintInfoItem(frame_x, start_y, "Titel", txt, true)

	-- date
	start_y = start_y + step
	txt = mtList[mtRightMenu_select].date .. " / " .. mtList[mtRightMenu_select].time
	paintInfoItem(frame_x, start_y, "Datum / Zeit", txt, true)
		-- duration
		txt = mtList[mtRightMenu_select].duration
		start_y = paintInfoItem(frame_x+frame_w/2, start_y, "Dauer", txt, false)

	-- description
	if (#mtList[mtRightMenu_select].description > 0) then
		start_y = start_y + step
		txt = autoLineBreak(mtList[mtRightMenu_select].description, frame_w-36, fontLeftMenu2)
		start_y = paintInfoItem(frame_x, start_y, "Beschreibung", txt, true)
	end

	-- qual
	start_y = start_y + step
	local bottom_y = y+real_h-hh-fontLeftMenu1_h-fontLeftMenu2_h+0
	txt = ""
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= "") then flag_max = true end
	if (mtList[mtRightMenu_select].url ~= "") then flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= "") then flag_min = true end
	if (flag_max == true) then
		txt = "Maximal"
		if ((flag_normal == true) or (flag_min == true)) then
			txt = txt .. ", "
		end
	end
	if (flag_normal == true) then
		txt = txt .. "Normal"
		if (flag_min == true) then
			txt = txt .. ", "
		end
	end
	if (flag_min == true) then
		txt = txt .. "Minimal"
	end

	paintInfoItem(frame_x, bottom_y, "verfügbare Streamqualität", txt, true)
		-- geo
		start_y = start_y + step
		txt = mtList[mtRightMenu_select].geo
		paintInfoItem(frame_x+frame_w/2, bottom_y, "Geoblocking", txt, false)

--[[
mtList[mtRightMenu_select].theme
mtList[mtRightMenu_select].title
mtList[mtRightMenu_select].date
mtList[mtRightMenu_select].time
mtList[mtRightMenu_select].duration
mtList[mtRightMenu_select].geo
mtList[mtRightMenu_select].url
mtList[mtRightMenu_select].url_small
mtList[mtRightMenu_select].url_hd
]]

	repeat
		local msg, data = n:GetInput(500)
		if (msg == RC.info) then
		end
		menuRet = msg
	until msg == RC.red or msg == RC.home;
	gui.hideInfoBox(box)
end
