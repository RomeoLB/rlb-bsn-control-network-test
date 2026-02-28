' 27/02/25 Test Standalone Load HTML widget run network test and dump log - Debug Generic - RLB
'if proxy is enabled the node server is unable to serve local html page on Chromium 120
'DWS password set to "romeo" to start pcap capture on eth0 for 100 seconds and save to file network-test-capture.pcap on player storage, 
'which can be retrieved for analysis.
'This test should last 100 seconds to allow enough time for the network test to complete and the pcap file and kernel log dump to be generated
'test cert.pem should be place on root of storage

Sub Main()

	m.msgPort = CreateObject("roMessagePort")
	b = CreateObject("roByteArray")
	b.FromHexString("ff000000")
	color_spec% = (255*256*256*256) + (b[1]*256*256) + (b[2]*256) + b[3]
	m.videoMode = CreateObject("roVideoMode")
	m.videoMode.SetBackgroundColor(color_spec%)
	m.videoMode.SetMode("1920x1080x50p")
	m.sTime = createObject("roSystemTime")
	gpioPort = CreateObject("roControlPort", "BrightSign")
	gpioPort.SetPort(m.msgPort)
	m.SystemLog = CreateObject("roSystemLog")	
	m.PluginInitHTMLWidgetStatic = PluginInitHTMLWidgetStatic
	m.CheckEndpointAccess = CheckEndpointAccess
	m.InitNodeJS = InitNodeJS
	m.FirstDumpTimerTimeout = 100
	m.Storage = GetDefaultDrive()
	'proxy string with auth - "http://user:password@hostname:port"
	' targetProxy$ = "http://144.124.227.90:21074" - public proxy for testing - not recommended for security reasons
	targetProxy$ = ""
	countdownValue = 100

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
	'Notify(" Script for running network test and capturing kernel log..")
	InitCountdownTextWidget()	

	netconf = nc.GetCurrentConfig()
	'print " *** netconf *** " netconf

	networkDetails = "Current Network Configuration: " + chr(13) + chr(10)
	for each item in netconf

		value$ = "invalid"
		finalValue$ = ""

		' print "type(netconf[item]): "; type(netconf[item])

		if type(netconf[item]) = "roBoolean" then
			'stop
			if netconf[item] = true then
				value$ = "true"
			else
				value$ = "false"
			end if	

		else if type(netconf[item]) = "roInt" then
			value$ = str(netconf[item])	

		else if type(netconf[item]) = "roArray" then
			if netconf[item].Count() = 0 then
				value$ = "empty array"
			else
				value$ = "["
				for each element in netconf[item]
					value$ = value$ + element + ", "
				next
				value$ = mid(value$, 1, len(value$)-2) + "]"
			end if
		end if

		if value$ = "invalid" then
			finalValue$ = item + " = " + netconf[item]
		else 
			finalValue$ = item + " = " + value$
		end if
		networkDetails = networkDetails + " " + finalValue$ + chr(13) + chr(10)
	next	

	m.SystemLog.SendLine(networkDetails)
	print networkDetails
	'stop
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
	StartCountdown(countdownValue)

	while true
	    
		msg = wait(0, m.msgPort)
		'print "type of msgPort is ";type(msg)
	
		if type(msg) = "roTimerEvent" then	
			timerIdentity = msg.GetSourceIdentity()
			'print "Timer msgPort Received " + stri(timerIdentity)
			if type(m.countdownTimer) = "roTimer" and m.countdownTimer.GetIdentity() = msg.GetSourceIdentity() then
				'print "Countdown: " + stri(m.countdownValue) + " seconds remaining"
				displayText = "Network Test and data capture running: " + stri(m.countdownValue) + " seconds remaining"
				if m.countdownTextWidget <> invalid then
					m.countdownTextWidget.PushString(displayText)
					m.countdownTextWidget.Show()
				end if
				m.countdownValue = m.countdownValue - 1
				if m.countdownValue < 0 then
					'print "Countdown complete!"
					if m.countdownTextWidget <> invalid then
						m.countdownTextWidget.PushString("Network Test and data capture complete!")
						m.countdownTextWidget.Show()
					end if					
					m.countdownTimer.Stop()
				else
					m.countdownTimer.SetElapsed(1, 0) ' Schedule next tick
					m.countdownTimer.Start()
				end if
			end if		
			
			if type(m.downloadTimer) = "roTimer" and m.downloadTimer.GetIdentity() = msg.GetSourceIdentity() then
				if m.downloadIndex < m.downloadList.Count()
					link = m.downloadList[m.downloadIndex]
					print " @@@ Added to download list @@@ : " + link
					index$ = str(m.downloadIndex)
					formatIndex$ = mid(index$,2)					
					m.CheckEndpointAccess(link, "endpoint" + formatIndex$)
					m.downloadIndex = m.downloadIndex + 1
					m.downloadTimer.SetElapsed(3, 0)
					m.downloadTimer.Start()
				else
					m.downloadTimer.Stop()
				end if
			end if			
				
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
			if type(m.SnapshotDelayTimer) = "roTimer" then
				if m.SnapshotDelayTimer.GetIdentity() = msg.GetSourceIdentity() then
					TakeScreenshot()
				end if
			end if				
		else if type(msg) = "roHtmlWidgetEvent" then
			eventData = msg.GetData()
			if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
				Print "roHtmlWidgetEvent = " + eventData.reason
				if eventData.reason = "load-finished" then
					StartSnapshotDelayTimer()
					print " **** Snapshot delay started due to load-finished event **** "
				end if 

			end if	
		else if type(msg) = "roControlDown" then
			button = msg.GetInt()
			if button = 12 then 
				print " @@@ GPIO 12 pressed @@@  "
				stop
			end if
		else if type(msg) = "roUrlEvent" then

			' print " @@@ msg.GetResponseCode() @@@ : " msg.GetResponseCode()
			' print " @@@ msg.GetFailureReason() @@@ : " msg.GetFailureReason()
			'-28 is expected from WS test 

			userData = msg.GetUserData()

			if userData.FunctionName <> invalid then
				if instr(0, userData.FunctionName, "endpoint") then
					m.SystemLog.SendLine(" @@@ roURLTransfer endpoint check for " + userData.Link + " completed with response code " + stri(msg.GetResponseCode()) + " and failure reason " + msg.GetFailureReason() + " @@@ ")
					print " @@@ roURLTransfer endpoint check for " + userData.Link + " completed with response code " + stri(msg.GetResponseCode()) + " and failure reason " + msg.GetFailureReason() + " @@@ "
				end if 	
			end if	
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

	m.theRegistry = CreateObject("roRegistrySection", "networking")
	's.log = CreateObject("roSystemLog").ReadLog()

	m.newFile = CreateObject("roCreateFile", "kernel_log.txt")
	m.newFile.SendLine("")
	m.newFile.SendLine("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	m.newFile.SendLine("")
	m.newFile.SendLine("Test Log Results")
	m.newFile.SendLine("")
	
    m.RegistryItems = m.theRegistry.GetKeyList()

	'Print" m.RegistryItems  " m.RegistryItems

	m.newFile.SendLine("")
	m.newFile.SendLine("************************************ NetWorking Registry Capture ************************************")
	m.newFile.SendLine("")

	'Print"Getting Registry Info"

	for each item in m.RegistryItems
		m.line = m.theRegistry.Read(item) 
		m.newFile.SendLine(item+"  "+m.line)
		'print "m.line " m.line
	next

	m.CaptureLogTime = m.sTime.GetLocalDateTime()
	m.newFile.SendLine("") 
	m.newFile.SendLine("********************************* Generated "+m.CaptureLogTime.getstring()+"  *********************************")
	m.newFile.SendLine("")   
	m.newFile.Flush()

	m.newFile.SendLine("")
	m.newFile.SendLine("")
	m.newFile.SendLine("************************************ System Software Log Capture ************************************")
	m.newFile.SendLine("")

	m.logFile = invalid
	capturedTime = m.sTime.GetLocalDateTime().GetString()

	infostr = "@@@ Writing DWS LOG Dump to disk @@@ - " + capturedTime

	m.SystemLog.SendLine(infostr)
	
	log = m.SystemLog.ReadLog()

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
		
		' currentLog = currentLog + line + chr(13) + chr(10)
		if len(line) > 0 then
			currentLog = currentLog + line + chr(13) + chr(10)
		end if
	next
	
	m.newFile.SendLine(currentLog)
	m.newFile.Flush()	
	
	m.SystemLog.SendLine(" @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on player storage ... @@@ ")
	print " @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on player storage... @@@ "

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


Function StartSnapshotDelayTimer()
	
	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(2)
	m.SnapshotDelayTimer = CreateObject("roTimer")
	m.SnapshotDelayTimer.SetPort(m.msgPort)
	m.SnapshotDelayTimer.SetDateTime(newTimeout)
	m.SnapshotDelayTimer.Start()
End Function


Function StartCountdown(seconds as Integer)
    m.countdownValue = seconds
    m.countdownTimer = CreateObject("roTimer")
    m.countdownTimer.SetPort(m.msgPort)
    m.countdownTimer.SetElapsed(1, 0) ' 1 second interval
    m.countdownTimer.Start()
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



Function InitCountdownTextWidget()
    CountvideoMode = CreateObject("roVideoMode")
    resX = CountvideoMode.GetResX()
    resY = CountvideoMode.GetResY()
    rectangle = CreateObject("roRectangle", 0, resY/2-resY/64, resX, resY/32)
    textParameters = CreateObject("roAssociativeArray")
    textParameters.LineCount = 1
    textParameters.TextMode = 2
    textParameters.Rotation = 0
    textParameters.Alignment = 1
    m.countdownTextWidget = CreateObject("roTextWidget", rectangle, 1, 2, textParameters)
    m.countdownTextWidget.Show()
End Function


Function CheckEndpointAccess(link as String, positionName as String) as boolean

	print " Check Endpoint Access..."; positionName

	restRequestURL$ = link

	posted = false

	m.xferList[positionName] = CreateObject("roUrlTransfer")

	userdata = {}
    userdata.FunctionName = positionName
	userdata.Link = link

	m.xferList[positionName].SetPort(m.msgPort)
	m.xferList[positionName].SetUrl(restRequestURL$)
	m.xferList[positionName].SetTimeout(2000)
	m.xferList[positionName].SetUserData(userdata)

	aa = { }
	'aa.method = "HEAD"
	aa.method = "GET"
	m.xferList[positionName].AsyncMethod(aa)
End Function



' Function RunBrightscriptNetworkTest()

' 	downloadList = []
' 	m.xferList = {}
' 	FileRead = ReadAsciiFile("brightscript-head-checks.json")
' 	download_config = ParseJson(FileRead)
' 	if download_config.count() > 0 then

' 		index = 0
' 		for each item in download_config

' 			link = download_config[index].url
' 			downloadList.push(link)
' 			index$ = str(index)
' 			formatIndex$ = mid(index$,2)
' 			print " @@@ Added to download list @@@ : " + link
' 			CheckEndpointAccess(link, "endpoint" + formatIndex$)
' 			'stop
' 			index = index + 1
' 			sleep(3000)
' 		next	
' 	else
' 		print " @@@ No file downloads configured or failed to read config file @@@ "
' 	end if
' End Function


Function RunBrightscriptNetworkTest()

	m.downloadList = []
	m.xferList = {}
	m.downloadIndex = 0
	FileRead = ReadAsciiFile("brightscript-head-checks.json")
	download_config = ParseJson(FileRead)
	if download_config.count() > 0 then
		for each item in download_config
			m.downloadList.push(item.url)
		next
		m.downloadTimer = CreateObject("roTimer")
		m.downloadTimer.SetPort(m.msgPort)
		m.downloadTimer.SetElapsed(3, 0) ' 3 seconds
		m.downloadTimer.Start()
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



Function TakeScreenshot()

	screenShotParam = CreateObject("roAssociativeArray")
	'screenShotParam["filename"] = m.Storage + m.Path + "TestScreenShot.jpg"
	screenShotParam["filename"] = m.Storage + "TestScreenShot.jpg"
	screenShotParam["width"] = m.videomode.GetResX()
	screenShotParam["height"] = m.videomode.GetResY()
	screenShotParam["filetype"] = "JPEG"
	screenShotParam["quality"] = 100
	screenShotParam["async"] = 0
	
	screenShotTaken = m.videomode.Screenshot(screenShotParam)
	
	if screenShotTaken then
		status = "true"
		Print " @@@ Screenshot Taken @@@  " screenShotTaken	

		m.SystemLog.SendLine("")
		m.SystemLog.SendLine("@@@ Screenshot Taken @@@ ")
		m.SystemLog.SendLine("")  
	else
		status = "false"
	end if 
End Function