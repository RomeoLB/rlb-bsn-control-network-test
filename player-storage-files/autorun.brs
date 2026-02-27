' 25/02/25 Test Standalone Load HTML widget run network test and dump log - Debug Generic - RLB
'if proxy is enabled the node server is unable to serve local html page on Chromium 120
'DWS password set to "romeo" to start pcap capture on eth0 for 100 seconds and save to file network-test-capture.pcap on SD card, 
'which can be retrieved for analysis.

Sub Main()

	m.msgPort = CreateObject("roMessagePort")
	b = CreateObject("roByteArray")
	b.FromHexString("ff000000")
	color_spec% = (255*256*256*256) + (b[1]*256*256) + (b[2]*256) + b[3]
	videoMode = CreateObject("roVideoMode")
	videoMode.SetBackgroundColor(color_spec%)
	videomode.Setmode("1920x1080x50p")
	m.sTime = createObject("roSystemTime")
	gpioPort = CreateObject("roControlPort", "BrightSign")
	gpioPort.SetPort(m.msgPort)
	m.SystemLog = CreateObject("roSystemLog")	
	m.PluginInitHTMLWidgetStatic = PluginInitHTMLWidgetStatic
	m.InitNodeJS = InitNodeJS
	m.FirstDumpTimerTimeout = 30
	'proxy string with auth - "http://user:password@hostname:port"
	' targetProxy$ = "http://144.124.227.90:21074"
	targetProxy$ = ""

	SetDWSwithPassword()

	use_brightsign_media_player = "0"

	ubmp_set = false
	targetChromiumVersion_set = false
	curl_set = false
	wired_debug_set = false

	'targetChromiumVersion = "chromium120"
	targetChromiumVersion = "chromium87"

	rs = createobject("roregistrysection", "html")
    ubmp = rs.read("use-brightsign-media-player")
    if ubmp <> use_brightsign_media_player then
        rs.write("use-brightsign-media-player", use_brightsign_media_player)
        rs.flush()
		ubmp_set = true
		print " @@@ use-brightsign-media-player set to " + use_brightsign_media_player + " @@@ "
    end if

	wt = rs.read("widget_type")
    if wt <> targetChromiumVersion then
        rs.write("widget_type",targetChromiumVersion)
        rs.flush()
		targetChromiumVersion_set = true
		print " @@@ widget_type set to targetChromiumVersion @@@ "
    end if

	rsNet = createobject("roregistrysection", "networking")
    curl = rsNet.read("curl_debug")
    if curl <> "1" then
        rsNet.write("curl_debug", "1")
        rsNet.flush()
		curl_set = true
		print " @@@ curl_debug set to 1 @@@ "
    end if

	wired_debug = rsNet.read("wired_debug")
    if wired_debug <> "1" then
        rsNet.write("wired_debug", "1")
        rsNet.flush()
		wired_debug_set = true
		print " @@@ wired_debug set to 1 @@@ "
    end if

	if ubmp_set = true or targetChromiumVersion_set = true or curl_set = true or wired_debug_set = true then
		print " @@@ Rebooting system to apply changes @@@ "
		m.SystemLog.SendLine(" @@@ Rebooting system to apply changes @@@ ")
		RebootSystem()
	else
		print " @@@ No changes to registry settings @@@ "
		m.SystemLog.SendLine(" @@@ No changes to registry settings @@@ ")
	end if

	k = CreateObject("roKeystore")
	ok = k.AddCACertificate("cert.pem")
	
	if ok then
		m.SystemLog.SendLine("@@@ Self-Signed Cert SUCCESFULLY added to roKeyStore @@@")
	else
		Failure_Reason$ = k.GetFailureReason()
		m.SystemLog.SendLine(" @@@ Failed to Add Cert to roKeyStore @@@ " + Failure_Reason$)
	end if

	nc = CreateObject("roNetworkConfiguration",0)
	nc.SetProxy(targetProxy$)
	nc.Apply()

	m.SystemLog.SendLine(" @@@ Script for running network test and capturing kernel log... @@@ ")
	print " @@@ Script for running network test and capturing kernel log... @@@ "
	Notify(" Script for running network test and capturing kernel log..")	

	netconf = nc.GetCurrentConfig()
	print " *** netconf *** " netconf
	if netconf <> invalid then
		if netconf.link = true AND netconf.ip4_address <> "" then
			IP_OK = true
			print " $$$ netconf.ip4_address $$$ " netconf.ip4_address
		end if
	end if		

	m.loginURL = "http://" + netconf.ip4_address + ":3000/bs-player-netcheck-report.html"

	print " *** m.loginURL *** " m.loginURL

	StartInitNodeJSTimer()
	StartFirstDumpTimer()

	while true
	    
		msg = wait(0, m.msgPort)
		print "type of msgPort is ";type(msg)
	
		if type(msg) = "roTimerEvent" then	
			timerIdentity = msg.GetSourceIdentity()
			print "Timer msgPort Received " + stri(timerIdentity)
				
			if type (m.InitNodeJSTimer) = "roTimer" then 
				if m.InitNodeJSTimer.GetIdentity() = msg.GetSourceIdentity() then	
					m.InitNodeJS()
				end if
			end if
			if type(m.FirstDumpTimer) = "roTimer" then
				if m.FirstDumpTimer.GetIdentity() = msg.GetSourceIdentity() then
					LogDump()
				end if
			end if
			if type(m.LoadHtmlWidgetTimer) = "roTimer" then
				if m.LoadHtmlWidgetTimer.GetIdentity() = msg.GetSourceIdentity() then
					m.PluginInitHTMLWidgetStatic()
				end if
			end if					
		else if type(msg) = "roHtmlWidgetEvent" then
			eventData = msg.GetData()
			if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
				Print "roHtmlWidgetEvent = " + eventData.reason
			end if	
		else if type(msg) = "roControlDown" then
			button = msg.GetInt()
			if button = 12 then 
				print " @@@ GPIO 12 pressed @@@  "
				stop
			end if
		else if type(msg) = "roUrlEvent" then

			print " @@@ msg.GetResponseCode() @@@ : " msg.GetResponseCode()
			print " @@@ msg.GetFailureReason() @@@ : " msg.GetFailureReason()
			print " @@@ msg.GetString() @@@ : " msg.GetString()	
			'-28 is expected from WS test 

			userData = msg.GetUserData()
			print "roURLEvent UserData: "; userData
	else if type(msg) = "roNodeJsEvent" then
		print " @@@ roNodeJsEvent @@@ "
		eventData = msg.GetData()
		print eventData	
		if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
				if eventData.reason = "process_exit" then
					print "=== BS: Node.js instance exited with code " ; eventData.exit_code
				else if eventData.reason = "message" then
					print "=== BS: Received message "; eventData.message

					if eventData.message.jsmsg <> invalid then
						print "Message from Node.js: " + eventData.message.jsmsg
						if eventData.message.jsmsg = "report_done" then
							RunBrightscriptNetworkTest()
						end if
					end if
					' To use this: msgPort.PostBSMessage({text: "my message"});
					' if eventData.message.event <> invalid then
					' end if
				else
					print "======= UNHANDLED NODEJS EVENT ========="
					print eventData.reason
				endif
			else
				print "=== BS: Unknown eventData: "; type(eventData)
			endif								
		end if				
	end while
End Sub



Function StartInitNodeJSTimer()
	
	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(5)
	m.InitNodeJSTimer = CreateObject("roTimer")
	m.InitNodeJSTimer.SetPort(m.msgPort)
	m.InitNodeJSTimer.SetDateTime(newTimeout)
	ok = m.InitNodeJSTimer.Start()
End Function



Function PluginInitHTMLWidgetStatic()

	m.PluginRect = CreateObject("roRectangle", 0,0,1920,1080)
	'filepath$ = "Login.js"
	
	is = {
		port: 2999
	}
	m.config = {
		nodejs_enabled: true,
		javascript_injection: { 
		   document_creation: [], 
			document_ready: [],
			deferred: [] 
			'deferred: [{source: filepath$ }]
		},
		javascript_enabled: true,
		port: m.msgPort,
		inspector_server: is,
		brightsign_js_objects_enabled: true,
		url: m.loginURL,
		mouse_enabled: true,
		'storage_quota: "20000000000",
		'storage_path: "CacheFolder",
		security_params: {websecurity: true, camera_enabled: false, audio_capture_enabled: true}
		'transform: "rot90" 
	}
	
	m.PluginHTMLWidget = CreateObject("roHtmlWidget", m.PluginRect, m.config)
	m.PluginHTMLWidget.Show()
End Function



Function InitNodeJS()
	'm.node_js = CreateObject("roNodeJs", "rl_main.js", {message_port: m.msgPort, arguments: []}) ' no inspector loaded
	m.node_js = CreateObject("roNodeJs", "bundle.js", {message_port: m.msgPort, node_arguments: ["--inspect=0.0.0.0:3001"]}) 'just for loading the inspector
	'm.node_js = CreateObject("roNodeJs", "rl_main.js", {message_port: m.msgPort, node_arguments: ["--inspect-brk=0.0.0.0:2999"]}) 'stops at breakpoints

	if type(m.node_js)<>"roNodeJs" then 
        print " @@@ Error: failed to create roNodeJs  @@@"
	else
		print " @@@ roNodeJs successfully created  @@@"
	end if
End Function



Function LogDump()

	'print " @@@ DUMPing data @@@ "

	m.logFile = invalid
	capturedTime = m.sTime.GetLocalDateTime().GetString()

	infostr = "@@@ Writing DWS LOG Dump to disk @@@ - " + capturedTime

	m.SystemLog.SendLine(infostr)
	
	log = CreateObject("roSystemLog").ReadLog()
	m.logFile = CreateObject("roCreateFile", "kernel_log.txt")
	
	currentLog = ""
	
	for each line in log
		'print line
		'currentLog = currentLog + line + chr(13) + chr(10)
		
		LineLength = len(line)
		Chr1StartPos = -1
		Chr2StartPos = -1
		Chr3StartPos = -1
		
		Chr1StartPos = instr(0, line, "<12>") 
		Chr2StartPos = instr(0, line, "<14>")
		Chr3StartPos = instr(0, line, "<30>")

		if Chr1StartPos > 0 then
			line = mid(line, Chr1StartPos + 4, LineLength - 3)
		else if Chr2StartPos > 0 then
			line = mid(line, Chr2StartPos + 4, LineLength - 3)
		else if Chr3StartPos > 0 then
			line = mid(line, Chr3StartPos + 4, LineLength - 3)	
		end if		
		
		currentLog = currentLog + line + chr(13) + chr(10)
	next
	
	m.logFile.SendLine(currentLog)
	m.logFile.Flush()	
	
	m.SystemLog.SendLine(" @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on SD card ... @@@ ")
	print " @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on SD card... @@@ "

	StartLoadHTMLWidgetTimer()
End Function



Function StartFirstDumpTimer()

	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(m.FirstDumpTimerTimeout)
	m.FirstDumpTimer = CreateObject("roTimer")
	m.FirstDumpTimer.SetPort(m.msgPort)
	m.FirstDumpTimer.SetDateTime(newTimeout)
	m.FirstDumpTimer.Start()
End Function



Function StartLoadHTMLWidgetTimer()
	
	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(10)
	m.LoadHtmlWidgetTimer = CreateObject("roTimer")
	m.LoadHtmlWidgetTimer.SetPort(m.msgPort)
	m.LoadHtmlWidgetTimer.SetDateTime(newTimeout)
	m.LoadHtmlWidgetTimer.Start()
End Function



Function Notify(message As String)

	print message
	videoMode = CreateObject("roVideoMode")
	resX = videoMode.GetResX()
	resY = videoMode.GetResY()
	videoMode = invalid
	rectangle = CreateObject("roRectangle", 0, resY/2-resY/64, resX, resY/32)
	textParameters = CreateObject("roAssociativeArray")
	textParameters.LineCount = 1
	textParameters.TextMode = 2
	textParameters.Rotation = 0
	textParameters.Alignment = 1
	m.textWidget = CreateObject("roTextWidget", rectangle, 1, 2, textParameters)
	m.textWidget.PushString(message)
	m.textWidget.Show()
End Function



Function CheckEndpointAccess(link as String, positionName as String) as boolean

	print " Check Endpoint Access..."; positionName

	restRequestURL$ = link

	posted = false

	m.xferList[positionName] = CreateObject("roUrlTransfer")

	userdata = {}
    userdata.FunctionName = positionName

	m.xferList[positionName].SetPort(m.msgPort)
	m.xferList[positionName].SetUrl(restRequestURL$)
	m.xferList[positionName].SetTimeout(2000)
	m.xferList[positionName].SetUserData(userdata)

	aa = { }
	aa.method = "HEAD"
	'aa.method = "GET"
	m.xferList[positionName].AsyncMethod(aa)
End Function



Function RunBrightscriptNetworkTest()

	downloadList = []
	m.xferList = {}
	FileRead = ReadAsciiFile("brightscript-head-checks.json")
	download_config = ParseJson(FileRead)
	if download_config.count() > 0 then

		index = 0
		for each item in download_config

			link = download_config[index].url
			downloadList.push(link)
			index$ = str(index)
			formatIndex$ = mid(index$,2)
			print " @@@ Added to download list @@@ : " + link
			CheckEndpointAccess(link, "endpoint" + formatIndex$)
			'stop
			index = index + 1
			sleep(3000)
		next	
	else
		print " @@@ No file downloads configured or failed to read config file @@@ "
	end if
End Function



Function SetDWSwithPassword()

	'password - romeo
	obfuscatedPass$ = "A47ECD3014763B3B2CD4F6E1AD9CBEAE5A0AA6FCC98102B0990833067C2A6938C"
	rs = createobject("roregistrysection", "networking")
	dwsAA = CreateObject("roAssociativeArray")
	dwsAA["port"] = "80" 
	dwsAA["password"] = obfuscatedPass$
	nc = CreateObject("roNetworkConfiguration", 0)
	nc.SetupDWS(dwsAA)
	ok = nc.Apply()

	print "DWS Setup with romeo password"
End Function