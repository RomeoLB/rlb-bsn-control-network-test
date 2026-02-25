' 25/02/25 Test Standalone Load HTML widget and dump log - Debug Generic - RLB

Sub Main()

	m.msgPort = CreateObject("roMessagePort")
	b = CreateObject("roByteArray")
	'b.FromHexString("ffffffff")
	b.FromHexString("ff000000")
	color_spec% = (255*256*256*256) + (b[1]*256*256) + (b[2]*256) + b[3]
	videoMode = CreateObject("roVideoMode")
	videoMode.SetBackgroundColor(color_spec%)
	'videomode.Setmode("3840x2160x25p:gfxmemlarge")
	'videomode.Setmode("3840x2160x60p:fullres")
	videomode.Setmode("1920x1080x50p")
	m.sTime = createObject("roSystemTime")
	gpioPort = CreateObject("roControlPort", "BrightSign")
	gpioPort.SetPort(m.msgPort)
	m.SystemLog = CreateObject("roSystemLog")	
	m.PluginInitHTMLWidgetStatic = PluginInitHTMLWidgetStatic
	m.InitNodeJS = InitNodeJS
	'm.StartFirstDumpTimer = StartFirstDumpTimer
	m.loginURL = "file:///bs-player-netcheck-report.html"
	m.FirstDumpTimerTimeout = 30



	use_brightsign_media_player = "0"

	ubmp_set = false
	targetChromiumVersion_set = false

	'Non WorkingText flashing 
	targetChromiumVersion = "chromium120"

	'Working as expected
	'targetChromiumVersion = "chromium87"

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

	if ubmp_set = true or targetChromiumVersion_set = true then
		print " @@@ Rebooting system to apply changes @@@ "
		m.SystemLog.SendLine(" @@@ Rebooting system to apply changes @@@ ")
		RebootSystem()
	else
		print " @@@ No changes to registry settings @@@ "
		m.SystemLog.SendLine(" @@@ No changes to registry settings @@@ ")
	end if

    'intialize audio output with initial value of 50
    m.audioHDMIOutput = CreateObject("roAudioOutput", "HDMI")
    m.audioAnalogOutput = CreateObject("roAudioOutput", "Analog")

	audioRouting = {
		mode: "prerouted"
	}
	m.audioConfiguration = CreateObject("roAudioConfiguration")
	m.audioConfiguration.ConfigureAudio(audioRouting)

	volume = 100
	m.audioAnalogOutput.SetVolume(volume)
    m.audioHDMIOutput.SetVolume(volume)

	StartInitNodeJSTimer()
	StartFirstDumpTimer()

	m.SystemLog.SendLine(" @@@ Script for running network test and capturing kernel log... @@@ ")
	print " @@@ Script for running network test and capturing kernel log... @@@ "
	Notify(" Script for running network test and capturing kernel log..")	

	while true
	    
		msg = wait(0, m.msgPort)
		print "type of msgPort is ";type(msg)
	
		if type(msg) = "roTimerEvent" then	
			timerIdentity = msg.GetSourceIdentity()
			print "Timer msgPort Received " + stri(timerIdentity)
				
			if type (m.InitNodeJSTimer) = "roTimer" then 
				if m.InitNodeJSTimer.GetIdentity() = msg.GetSourceIdentity() then	
					'm.PluginInitHTMLWidgetStatic()
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
	else if type(msg) = "roNodeJsEvent" then
		print " @@@ roNodeJsEvent @@@ "
		eventData = msg.GetData()
		print eventData	
		if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
				if eventData.reason = "process_exit" then
					print "=== BS: Node.js instance exited with code " ; eventData.exit_code
				else if eventData.reason = "message" then
					print "=== BS: Received message "; eventData.message
					' To use this: msgPort.PostBSMessage({text: "my message"});
					' if eventData.message.event <> invalid then
					' 	if eventData.message.event = "VIDEO_ENDED" then
					' 		print "=== BS: roNodeJsEvent VIDEO_ENDED: "; 
					' 		'm.PluginSendMessage("next")
					' 	endif
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
	
	print " Set Timer to load NodeJS instance..."
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
	
	'sleep(10000)
	m.SystemLog.SendLine(" @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on SD card ... @@@ ")
	print " @@@ Log file kernel_log.txt and connectivity-test-results.json should be available on SD card... @@@ "
	'm.PluginInitHTMLWidgetStatic()
	StartLoadHTMLWidgetTimer()
End Function



Function StartFirstDumpTimer()

	print "StartFirstDumpTimer..."
	
	newTimeout = m.sTime.GetLocalDateTime()
	newTimeout.AddSeconds(m.FirstDumpTimerTimeout)
	m.FirstDumpTimer = CreateObject("roTimer")
	m.FirstDumpTimer.SetPort(m.msgPort)
	m.FirstDumpTimer.SetDateTime(newTimeout)
	m.FirstDumpTimer.Start()
End Function



Function StartLoadHTMLWidgetTimer()

	print "StartLoadHTMLWidgetTimer..."
	
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