
function playLivestream(_id)

	local returnAll = false

	i = tonumber(_id);
	local title = videoTable[i][1] .. " Livestream";
	local url = videoTable[i][2];
	local parse_m3u8 = tonumber(videoTable[i][3]);

	local bw;
	local res;
	local qual;
	if (conf.streamQuality == 2) then
		qual = "max";
	elseif (conf.streamQuality == 1) then
		qual = "normal";
	else
		qual = "min";
	end
	if (parse_m3u8 == 1) then
		m3u8Ret = get_m3u8url(url);
		url = m3u8Ret['url'];
		bw = tonumber(m3u8Ret['bandwidth']);
		res = m3u8Ret['resolution'];
	else
		bw = nil;
		res = "*";
	end
	if (bw == nil) then
		bw = "-";
	else
		bw = tostring(math.floor(bw/1000 + 0.5)) .. "K";
	end
	local msg1 = string.format("Bitrate: %s, Auflösung: %s, Qualität: %s", bw, res, qual);

	local screen = saveFullScreen()
	hideMenu(m_live)
	hideMainWindow()
	n:setBlank(true)
	os.execute("pzapit -unmute")

	n:PlayFile(title, url, msg1, url);

	n:enableInfoClock(false)
--	collectgarbage();
	os.execute("pzapit -mute")
	posix.sleep(1)
	n:ShowPicture(backgroundImage)
	
	if (returnAll == true) then
		return MENU_RETURN.EXIT_ALL;
	else
		restoreFullScreen(screen, true)
		return MENU_RETURN.REPAINT;
	end
end

function getLivestreams()
	local s = getJsonData(url_livestream);
	local j_table = decodeJson(s);
	if checkJsonError(j_table) == false then return false end

	m_live = menu.new{name=pluginName .. "-Livestreams", icon=pluginIcon};
	m_live:addItem{type="subhead", name=langStr_channelSelection};
	m_live:addItem{type="separator"};
	m_live:addItem{type="back"};
	m_live:addItem{type="separatorline"};

--	m_live:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_live:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	for i = 1, #j_table.entry do
		local name = j_table.entry[i].title;
		name = string.gsub(name, " Livestream", "");
		local id = j_table.entry[i].id;
		videoTable[i] = {};
		videoTable[i][1] = name;
		videoTable[i][2] = j_table.entry[i].url;
		videoTable[i][3] = j_table.entry[i].parse_m3u8;
		m_live:addItem{type="forwarder", action="playLivestream", id=i, name=name};
	end

	m_live:exec()
	restoreFullScreen(mainScreen, false)

	if ret == MENU_RETURN.EXIT_ALL then
		return ret
	end
	return MENU_RETURN.REPAINT;
end

