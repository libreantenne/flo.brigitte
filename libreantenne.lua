----------------------------------------------------------------------
-- Mumble/IRC/MPD bot with lua
--
-- require "socket"
-- require "mpd"
----------------------------------------------------------------------

-- local mpd = mpd

-- Boolean if users need to be registered on the server to trigger sounds
local require_registered = true

-- Boolean if sounds should stop playing when another is triggered
local interrupt_sounds = false

-- Boolean if the bot should move into the user's channel to play the sound
local should_move = false

----------------------------------------------------------------------
-- Table with keys being the keywords and values being the sound files
----------------------------------------------------------------------
local sounds = {
   tvois = "tvois.ogg",
   chaud1 = "chaud1.ogg",
   chaud2 = "chaud2.ogg",
   chaud3 = "chaud3.ogg",
   chaud4 = "chaud4.ogg",
   chaud5 = "chaud5.ogg",
   chaud6 = "chaud_himi2.ogg",
   chaud7 = "chaud_est.ogg",
   quoinon = "quoi_non.ogg",
   cage = "cage.ogg",
   enerve = "enerve.ogg",
   fouet1 = "fouet1.ogg",
   fouet2 = "fouet2.ogg",
   pantalon= "pantalon.ogg",
   pantalon2= "pantalon2.ogg",
   rappelons1 = "merde.ogg",
   rappelons2 = "enfants.ogg",
   rappelons3 = "enfants2.ogg",
   radiobatard1 = "radio_batard.ogg",
   radiobatard2 = "radio_batard2.ogg",
   ohoo = "ohoo.ogg",
   paspossible = "pas_possible.ogg",
   microco = "micro_co.ogg",
   fdp = "fdp.ogg",
   chagasse = "chagasse.ogg",
   sodo = "sodo.ogg",
   faim = "faim.ogg",
   rire1 = "rire_crack.ogg",
   shoote = "shoot.ogg",
   flo1 = "flo1.ogg",
   flo2 = "bonjour_flo2.ogg",
   mens = "menstruations.ogg",
   re = "re.ogg",
   combat = "combat_himi.ogg",
   yeux1 = "yeux_ciel.ogg",
   yeux2 = "baisse_les_yeux.ogg",
   nice = "nice.ogg"
}

----------------------------------------------------------------------
-- commands array
----------------------------------------------------------------------
local commands = {
   setvol = "setvol",
   v = "volume",
   volume = "volume",
   youtube = "youtube",
   y = "youtube",
   last = "last",
   next = "next",
   prev = "prev",
   play = "play",
   pause = "pause",
   s = "song",
   random = "random",
   consume = "consume",
   help = "help",
   fadevol = "fadevol",
   song = "song"
}

----------------------------------------------------------------------
-- global configuration variables
----------------------------------------------------------------------
local configuration_file="./bot.conf"
local flags = {
   debug = "",         -- debug flags -> integer
   irc_server = "",    -- irc server address -> IP or DNS
   irc_port = "",      -- irc server port -> integer 2**16   
   irc_chan = "",      -- irc chan -> string
   mpd_server = "",    -- mpd server address -> IP or DNS
   mpd_port = "",      -- mpd port -> integer 2**16
   mumble_server = "", -- mumble server address -> IP or DNS
   mumble_port = "",   -- mumble port -> integer 2**16
   mumble_chan = ""    -- mumble chan -> string
}

local msg_prefix = "<span style='color:#738'>&#x266B;&nbsp;-&nbsp;"
local msg_suffix = "&nbsp;-&nbsp;&#x266B;</span>"

----------------------------------------------------------------------
-- Sound file path prefix
----------------------------------------------------------------------
local prefix = "jingles/"
local mpd_connect = mpd_connect

----------------------------------------------------------------------
-- piepan functions
----------------------------------------------------------------------
function piepan.onConnect()
   if piepan.args.soundboard then
      prefix = piepan.args.soundboard
   end
   print ("Bridgitte chargée")
   print ("Loading configuration...")
   if (parseConfiguration())
   then
      print("ok.")
   else
      print("error.")
   end
end

----------------------------------------------------------------------
-- added to check files existance from:
-- https://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
----------------------------------------------------------------------
function file_exists(name)
   local f = io.open(name,"r")
   if (f~=nil)
   then io.close(f) 
      return true 
   else 
      return false 
   end
end

----------------------------------------------------------------------
-- parseConfiguration function, no arguments 
----------------------------------------------------------------------
function parseConfiguration ()
   if (file_exists(configuration_file)) then
      local file = assert(io.open(configuration_file, "r"))
      local line = file:read()
      local term = {}
   else
      return false
   end
      
   for line in file:lines()
   do
      local i = 0
      if not (string.match(line,'^#') or  
	      string.match(line,'^$'))
      then
	 for word in string.gmatch(line, '([^ ]+)')
	 do
	    term[i] = word
	    i=i+1
	 end
	 setConfiguration(term)
      end
   end
   return true
end

----------------------------------------------------------------------
-- setConfiguration with defined terms into flags array.
----------------------------------------------------------------------
function setConfiguration (array)
   -- debug configuration flags
   if (string.match(array[0], "debug") and
       array[1]~='' and
       string.match(array[1],"%d+")) 
   then
      flags["debug"] = tonumber(array[1])

   -- irc server configuration flags
   elseif (string.match(array[0], 'irc') and
	   string.match(array[1], 'server') and
	   array[2]~='') 
   then
      flags["irc_server"] = array[2]

   -- irc port configuration flags
   elseif (string.match(array[0], 'irc') and
	   string.match(array[1], 'port') and
	   array[2]~='' and
	   string.match(array[2],"%d+")) 
   then
      if (tonumber(array[2])>0 and
	  tonumber(array[2])<65536)
      then
	 flags["irc_port"]=tonumber(array[2])
      end

   -- irc chan configuration flags
   elseif (string.match(array[0], 'irc') and
	   string.match(array[1], 'chan') and
	   array[2]~='') 
   then
      flags["irc_chan"]=array[2]
      
   -- mumble server configuration flag
   elseif (string.match(array[0], 'mumble') and
	   string.match(array[1], 'server') and
	   array[2]~='') 
   then
      flags["mumble_server"]=array[2]
   
   -- mumble port configuration flag
   elseif (string.match(array[0], 'mumble') and
	   string.match(array[1], 'port') and
	   array[2]~='' and
	   string.match(array[2], "%d+")) 
   then
      if (tonumber(array[2])>0 and
	  tonumber(array[2])<65536)
      then
	 flags["mumble_port"]=tonumber(array[2])
      end
   
   -- mumble chan configuration flag
   elseif (string.match(array[0], 'mumble') and
	   string.match(array[1], 'chan') and
	   array[2]~='')
   then
      flags["mumble_chan"]=array[2]
   
   -- mpd server configuration flag
   elseif (string.match(array[0], 'mpd') and
	   string.match(array[1], 'server') and
	   array[2]~='') 
   then
      flags["mpd_server"]=array[2]
   
   -- mpd port configuration flag
   elseif (string.match(array[0], 'mpd') and
	   string.match(array[1], 'port') and
	   array[2]~='' and
	   string.match(array[2], "%d+"))
   then
      if (tonumber(array[2])>0 and
	  tonumber(array[2])<65536)
      then
	 flags["mpd_port"]=tonumber(array[2])
      end
   end
end

----------------------------------------------------------------------
-- split function
----------------------------------------------------------------------
function string:split(sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

----------------------------------------------------------------------
-- formatSong function
----------------------------------------------------------------------
function piepan.formatSong(song)
	print("formatSong : ")
	piepan.showtable(song)
	s = ''
	if(song['Artist']) then s = s .. song['Artist'] .. ' - ' end
	if(song['Album']) then s = s .. song['Album'] .. ' - ' end 
	if(song['Title']) then s = s .. song['Title'] end
	if(song['Date']) then s = s .. ' (' .. song['Date'] .. ')' end
	if('' == s) then s = song['file'] end
	return s
end

----------------------------------------------------------------------
-- from PiL2 20.4
----------------------------------------------------------------------
function piepan.trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

----------------------------------------------------------------------
-- function url_encode
----------------------------------------------------------------------
function piepan.url_encode(str)
  if (str) then
    str = string.gsub (str, "\n", "\r\n")
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str	
end

----------------------------------------------------------------------
-- function show tables
----------------------------------------------------------------------
function piepan.showtable(t)
	for key,value in pairs(t) do
		print("Found member " .. key);
	end
end

----------------------------------------------------------------------
-- function tablelenth
----------------------------------------------------------------------
function piepan.tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

----------------------------------------------------------------------
-- function starts
----------------------------------------------------------------------
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

----------------------------------------------------------------------
-- function string.end
----------------------------------------------------------------------
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

----------------------------------------------------------------------
-- function countsubstring
----------------------------------------------------------------------
function piepan.countsubstring( s1, s2 )
 local magic =  "[%^%$%(%)%%%.%[%]%*%+%-%?]"
 local percent = function(s)return "%"..s end
    return select( 2, s1:gsub( s2:gsub(magic,percent), "" ) )
end

----------------------------------------------------------------------
-- function youtubedl
----------------------------------------------------------------------
function piepan.youtubedl(url)
	n1,n2 = string.find(url,' ')
	if(n1) then
		link = string.sub(url,n1+1)
		link = link:gsub("%b<>", "")
		link = link:gsub("%s+", "+")
		link = link:gsub("'", "+")
		piepan.me.channel:send(msg_prefix .. "Chargement en cours : [" .. link .. "] ..." .. msg_suffix)
		print("Loading [" .. link .. "] ...")
		local file = assert(io.popen('./yt_dl.sh ' .. link, 'r'))
		local output = file:read('*all')
		file:close()
		print(output)
		n1,n2 = string.find(output,"[avconv] Destination: ",nil,true)
		if(n1) then
			n3,n4 = string.find(output,"\n",n2)
			if(n3) then
				file = piepan.trim(string.sub(output,n2,n3))
				print("Found : [" .. file .. "]")
				piepan.me.channel:send(msg_prefix .. "Téléchargement terminé : [" .. file .. "]" .. msg_suffix)
				client:update('download')
				-- client:idle('download')
				-- socket.sleep(5)
				os.execute("sleep " .. tonumber(5))
				uri = '"download/' .. file .. '"'
				-- print(client:add("file://" .. uri))
				print(client:sendrecv("add " .. uri))
				-- client:add("download/" .. file)
				print("Adding : [" .. uri .. "]")
				piepan.me.channel:send(msg_prefix .. "Morceau ajouté à la liste." .. msg_suffix)
			else
				print("Failed to find EOL")
			end
		else
			n1, n2 = string.find(output,"[download] File is larger",nil,true)
			if(n1) then
				piepan.me.channel:send(msg_prefix .. "Fichier trop volumineux (>20Mo)" .. msg_suffix)
			else
				print("Failed to find '[avconv] Destination' in " .. output)
				piepan.me.channel:send(msg_prefix .. "Le téléchargement a merdé." .. msg_suffix)
			end
		end
		-- piepan.me.channel:send(output)
	end
end

----------------------------------------------------------------------
-- function youtubedl_completed
----------------------------------------------------------------------
function piepan.youtubedl_completed(info)
	print("youtubedl_completed " .. (info or '?'))
end

----------------------------------------------------------------------
-- function fadevol
----------------------------------------------------------------------
function piepan.fadevol(dest)
	client = piepan.MPD.mpd_connect(flags["mpd_server"],flags["mpd_port"],true)
	print("fadevol dest = " .. tostring(dest))
	vol = tonumber(client:status()['volume'])
	delta = 1
	print("fadevol vol = " .. tostring(vol))
	if(vol == dest) then return end
	if(dest < vol) then delta = - delta end
	print("fadevol " .. tostring(vol) .. " => " .. tostring(dest) .. " d=" .. tostring(delta))
	while true do
		if delta>0 and dest<=vol then break end
		if delta<0 and dest>=vol then break end
		vol = vol + delta
		print("fadevol => " .. tostring(vol))
		client:set_vol(vol)
		--#print("dv " + str(vol) +" %")$
		 -- time.sleep(0.2) -- = 5% par seconde
		piepan.MPD.sleep(0.2)
	end
	piepan.me.channel:send(msg_prefix .. "Volume ajusté à " .. tostring(vol) .. "%" .. msg_suffix)
end

----------------------------------------------------------------------
-- function fadevol_completed
----------------------------------------------------------------------
function piepan.fadevol_completed(info)
	print("fadevol_completed " .. (info or '?'))
end

----------------------------------------------------------------------
-- function onMessage
----------------------------------------------------------------------
function piepan.onMessage(msg)
    if msg.user == nil then
        return
    end
    print("Received message : " .. msg.text) 
    local search = string.match(msg.text, "#(%w+)")

    if not search then
    	return
    end
    if sounds[search] then
	local soundFile = prefix .. sounds[search]
	if require_registered and msg.user.userId == nil then
		msg.user:send("You must be registered on the server to trigger sounds.")
		return
	end
	if piepan.Audio.isPlaying() and not interrupt_sounds then
		return
	end
	if piepan.me.channel ~= msg.user.channel then
		if not should_move then
			return
		end
		piepan.me:moveTo(msg.user.channel)
	end

	piepan.Audio.stop()
	piepan.me.channel:play(soundFile)
    end
    if(commands[search] or msg.text:starts('#v+') or msg.text:starts('#v-')) then
	c = commands[search]
	client = piepan.MPD.mpd_connect(flags["mpd_server"],flags["mpd_port"],true)
	if("setvol" == c) then
		vol = tonumber(string.sub(msg.text,8))
		vol = math.max(0,math.min(100,vol))
		client:set_vol(vol)
		piepan.me.channel:send(msg_prefix .. "Volume ajusté à " .. tostring(vol) .. "%" .. msg_suffix)
	elseif("fadevol" == c) then
		print("fadevol " .. msg.text)
		vol = tonumber(string.sub(msg.text,9))
		vol = math.max(0,math.min(100,vol))
		-- piepan.fadevol(vol)
		piepan.Thread.new(piepan.fadevol,piepan.fadevol_completed,vol)
	elseif(msg.text:starts('#v+')) then
		print("V+" .. tostring(piepan.countsubstring(msg.text,'+')))
		s = client:status()
		v = tonumber(s['volume'])
		v = math.min(100,v + 5 * piepan.countsubstring(msg.text,'+'))
		piepan.Thread.new(piepan.fadevol,piepan.fadevol_completed,v)
		-- client:set_vol(v)
		-- piepan.me.channel:send(msg_prefix .. "Volume ajusté à " .. tostring(v) .. "%" .. msg_suffix)
	elseif(msg.text:starts('#v-')) then
		print("V-")
		s = client:status()
		v = tonumber(s['volume'])
		v = math.max(0,v - 5 * piepan.countsubstring(msg.text,'-'))
		piepan.Thread.new(piepan.fadevol,piepan.fadevol_completed,v)
		-- client:set_vol(v)
		-- piepan.me.channel:send(msg_prefix .. "Volume ajusté à " .. tostring(v) .. "%" .. msg_suffix)
	elseif(msg.text:starts('#random ')) then
		val = tonumber(string.sub(msg.text,8))
		val = math.max(0,math.min(1,val))
		client:set_random(val)
		piepan.me.channel:send("Ok")
	elseif(msg.text:starts('#consume ')) then
		val = tonumber(string.sub(msg.text,8))
		val = math.max(0,math.min(1,val))
		client:set_consume(val)
		piepan.me.channel:send("Ok")
	elseif("youtube" == c) then
		piepan.Thread.new(piepan.youtubedl,piepan.youtubedl_completed ,msg.text)
		
	elseif("last" == c) then
		pli = client:playlistinfo()
		-- piepan.showtable(pli)
		pli_len = piepan.tablelength(pli)
		print("Playlist length = " .. tostring(pli_len))
		last = pli[pli_len]['Id']
		-- piepan.showtable(pli[pli_len])
		print("Last : " .. tostring(last))
		client:playid(tonumber(last))
	elseif("next" == c) then
		print(client:next())
		piepan.me.channel:send("Ok")
	elseif("play" == c) then
		print(client:pause(0))
		piepan.me.channel:send("Ok")
	elseif("pause" == c) then
		print(client:pause(1))
		piepan.me.channel:send("Ok")
	elseif("prev" == c) then
		print(client:previous())
		piepan.me.channel:send("Ok")
	elseif("help" == c) then
		s = msg_prefix .. "<b>Commandes</b>" .. msg_suffix
		s = s .. "<pre style='color:#777'><ul>"
		s = s .. "<li>#s : Affiche le morceau en cours de lecture</li>"
		s = s .. "<li>#v : Affiche le volume actuel</li>"
		s = s .. "<li>#y -lien- : Télécharge un morceau et l'ajoute à la playlist</li>"
		s = s .. "<li>#setvol -volume- : Ajuste le volume</li>"
		s = s .. "<li>#v+ : Augmente le volume de 5% par '+'</li>"
		s = s .. "<li>#v- : Diminue le volume de 5% par '-'</li>"
		s = s .. "<li>#next, #last, #prev, #play, #pause : Contrôles de lecture</li>"
		s = s .. "<li>#random 0/1, #consume 0/1 : Change les modes de lecture</li>"
		
		s = s .. "</ul></pre>"
		piepan.me.channel:send(s)
	elseif("volume" == c) then
		s = client:status()
		piepan.me.channel:send(msg_prefix .. "Volume : " .. tostring(s['volume']) .. "%" .. msg_suffix)
	elseif ("song" == c) then
		print("Sending song info ...")
		song = client:currentsong()
		s = client:status()
		print("Volume : " .. s['volume'])
		piepan.showtable(s)
		-- piepan.printtable(song)
		-- piepan.printtable(s)
		-- print("Status : " .. s) 
		tstr = ''
		if(s['time']) then
			t = s['time'].split(':')
			print("Time : " .. s['time'])
			piepan.showtable(t)
			-- tstr = '[' .. t[1]
			-- tstr = tstr .. ' / ' .. t[2] .. ']'
			tstr = tostring(s['time'])
		end
		summary = piepan.formatSong(song)
		
		ret = summary .. ' - ' .. tstr .. ' [vol ' .. tostring(s['volume']) .. '% R' .. (s['random'] or '?') .. ' C' .. (s['consume'] or '?') .. ']'
		-- msg.user:send(ret)
		print("Summary : " .. ret)
		piepan.me.channel:send(msg_prefix .. ret .. msg_suffix)
	end
    end
end
