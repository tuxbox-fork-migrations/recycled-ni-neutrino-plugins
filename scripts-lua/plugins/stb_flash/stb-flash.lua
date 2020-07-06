-- The Tuxbox Copyright
--
-- Copyright 2018 The Tuxbox Project. All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification, 
-- are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice, this list
-- of conditions and the following disclaimer. Redistributions in binary form must
-- reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS ``AS IS`` AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
-- AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
-- HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of the Tuxbox Project.

caption = "STB-Flash"

local posix = require "posix"
n = neutrino()
fh = filehelpers.new()

bootfile = "/boot/STARTUP"
locale = {}

locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die Flash-Partition aus",
	start_partition1 = "Image downloaden und in die gewählte Partition ",
	start_partition2 = " flashen?",
	flash_partition1 = "Image wird in die Partition ",
	flash_partition2 = "Daten werden gesichert \n\nBitte warten...",
	flash_partition3 = " geflasht \n\nBitte warten...",
	flash_partition4 = "Image ist bereits auf dem aktuellen Stand...",
	flash_partition5 = "Flash erfolgreich",
	flash_partition6 = "Es wird mindestens 1G freier Speicherplatz auf der Festplatte benötigt",
	flash_partition7 = "Image Download fehlgeschlagen",
	flash_partition8 = "Entpacken des Images fehlgeschlagen",
	flash_partition9 = "Flashen des Kernel fehlgeschlagen",
	flash_partition10 = "Flashen des Rootfs fehlgeschlagen",
	flash_partition11 = "Partitionsschema ungültig",
	prepare_system = "System wird vorbereitet ... Bitte warten",

}

locale["english"] = {
	current_boot_partition = "The current start partition is: ",
	choose_partition = "\n\nPlease choose the new flash partition",
	start_partition1 = "Download image and flash into partition ",
	start_partition2 = "?",
	flash_partition1 = "Image will be flashed into partition ",
	flash_partition2 = "Data will be saved \n\nPlease wait...",
	flash_partition3 = " \n\nPlease wait...",
	flash_partition4 = "Image is already up to date ...",
	flash_partition5 = "Flash succeeded",
	flash_partition6 = "You need at least 1G of free space on your HDD",
	flash_partition7 = "Downloading the image failed",
	flash_partition8 = "Unpacking the image failed",
	flash_partition9 = "Writing the kernel failed",
	flash_partition10 = "Writing the rootfs failed",
	flash_partition11 = "Partitionscheme invalid",
	prepare_system = "System is getting prepared ... please stand by",
}

function islink(path)
	return fh:exist(path, "l")
end

function has_gpt_layout()
	if islink("/dev/disk/by-partlabel/linuxrootfs") then
		return false
	end
	return true
end

if has_gpt_layout() then
	devpath = "/mnt/"
	devbase = "rootfs"
else
	devpath = "/mnt/userdata/"
	devbase = "linuxrootfs"
end

function devnum_to_image(root)
	if (has_gpt_layout()) then
		if (root == 3) then ret = 1 end
		if (root == 5) then ret = 2 end
		if (root == 7) then ret = 3 end
		if (root == 9) then ret = 4 end
	else
		ret = root
	end
	return ret
end

for line in io.lines(bootfile) do
	if not has_gpt_layout() then
		_, j = string.find(line, devbase)
		if (j ~= nil) then
			current_root = tonumber(string.sub(line,j+1,j+1))
		end
	else
		for line in io.lines("/proc/cmdline") do
			if line:match("root=") then
				local _,j = string.find(line, "root=")
				current_root = devnum_to_image(tonumber(string.sub(line, j+14, j+14)))
			end
		end
	end
end

function sleep(n)
	os.execute("sleep " .. tonumber(n))
end

function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

function exists(file)
	local ok, err, exitcode = os.rename(file, file)
	if not ok then
		if exitcode == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

function isdir(path)
	return exists(path .. "/")
end

function get_value(str,root)
	for line in io.lines(devpath .. devbase  .. root  .. "/etc/image-version") do
		if line:match(str .. "=") then
			local _,j = string.find(line, str .. "=")
			ret = string.sub(line, j+1, #line)
		end
	end
	return ret
end

function get_imagename(root)
		if exists(devpath .. devbase .. root  .. "/etc/image-version") then
			imagename = get_value("distro", root) .. " " .. get_value("imageversion", root)
		else
			local glob = require "posix".glob
			for _, j in pairs(glob('/boot/*', 0)) do
				for line in io.lines(j) do
					if (j ~= bootfile) or (j ~= nil) then
						if line:match(devbase .. root) then
							imagename = basename(j)
						end
					end
				end
			end
		end
	return imagename
end


function is_active(root)
	if (current_root == root) then
		active = " *"
	else
		active = ""
	end
	return active
end

--imageversion_source = "https://tuxbox-images.de/images/" .. get_value("machine", current_root) .. "/imageversion"
imageversion_source = "https://update.tuxbox-neutrino.org/dist/" .. get_value("machine", current_root) .. "/" .. get_value("imageversion", current_root) .. "/images/imageversion"
neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/etc/neutrino/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")

if locale[lang] == nil then
	lang = "english"
end

timing_menu = neutrino_conf:getString("timing.menu", "0")

chooser_dx = n:scale2Res(700)
chooser_dy = n:scale2Res(200)
chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

chooser = cwindow.new {
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	title = caption,
	icon = "settings",
	has_shadow = true,
	btnRed = get_imagename(1) .. is_active(1),
	btnGreen = get_imagename(2) .. is_active(2),
	btnYellow = get_imagename(3) .. is_active(3),
	btnBlue = get_imagename(4) .. is_active(4)
}

chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].current_boot_partition .. get_imagename(current_root) .. locale[lang].choose_partition,
	font_text = FONT.MENU,
	mode = "ALIGN_CENTER"
}

chooser:paint()

i = 0
d = 500 -- ms
t = (timing_menu * 1000) / d

if t == 0 then
	t = -1 -- no timeout
end

colorkey = nil
repeat
i = i + 1
msg, data = n:GetInput(d)

if (msg == RC['red']) then
	root = 1
	colorkey = true
elseif (msg == RC['green']) then
	root = 2
	colorkey = true
elseif (msg == RC['yellow']) then
	root = 3
	colorkey = true
elseif (msg == RC['blue']) then
	root = 4
	colorkey = true
end

until msg == RC['home'] or colorkey or i == t

chooser:hide()

if colorkey then
	res = messagebox.exec {
	title = caption,
	icon = "settings",
	text = locale[lang].start_partition1 .. get_imagename(root) .. locale[lang].start_partition2,
	timeout = 0,
	buttons={ "yes", "no" }
	}

	if res == "yes" then
		local a,b,c = os.execute("mountpoint -q /media/hdd")
		if (c == 0) then
			device = "hdd"
		else
			device = "usb"
		end
		local file = assert(io.popen("md5sum /media/" .. device .. "/service/image/imageversion_partition_" .. root .. " " .. "| cut -d' ' -f1"))
		local md5_local = file:read('*all')
		file:close()

		local file = assert(io.popen("curl --silent " .. imageversion_source .. " | md5sum | cut -d' ' -f1"))
		local md5_online = file:read('*all')
		file:close()

		if (md5_online == md5_local) then
			local ret = hintbox.new { title = caption, icon = "settings", text = locale[lang].flash_partition4, timeout=3 };
			ret:paint()
			sleep (3)
			ret:hide()
			return
		end

		if (root == current_root) then
			local file = assert(io.popen("etckeeper commit -a", 'r'))
		end
		local file = assert(io.popen("systemctl start flash@" .. root, 'r'))
		return
	end
end

