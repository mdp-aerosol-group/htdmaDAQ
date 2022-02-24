# This function polls the gui for port information.
# Opens and configures port
function configure_serial_port(n)
	CPC = get_gtk_property(gui["CPCType$n"], "active-id", String)
	q = get_gtk_property(gui["CPCSampleFlow$n"], "text", String)
	baud = get_gtk_property(gui["BaudRate$n"], "active-id", String)
	dbits = get_gtk_property(gui["DataBits$n"], "active-id", String)
	p = get_gtk_property(gui["Parity$n"], "active-id", String)
	sbits = get_gtk_property(gui["StopBits$n"], "active-id", String)
	flow = get_gtk_property(gui["FlowControl$n"], "active-id", String)
	channel = get_gtk_property(gui["DAQChannelCPC$n"], "active-id", String)

	flowRate = parse(Float64,q)
	FIO = parse(Int,channel)
	CPCType = Symbol(CPC)
	
	serialPort = get_gtk_property(gui["SerialPort$n"], "text", String)
	baudRate = parse(Int,baud)
	dataBits = parse(Int,dbits)
	stopBits = parse(Int,sbits)
	parity = eval(Symbol(p))
	flowControl = eval(Symbol(flow))

	port = sp_get_port_by_name(serialPort)
	sp_open(port, SP_MODE_READ_WRITE)
	config = sp_get_config(port)
	sp_set_config_baudrate(config, baudRate)
	sp_set_config_parity(config, parity)
	sp_set_config_bits(config, dataBits)
	sp_set_config_stopbits(config, stopBits)
	sp_set_config_rts(config, SP_RTS_OFF)
	sp_set_config_cts(config, SP_CTS_IGNORE)
	sp_set_config_dtr(config, SP_DTR_OFF)
	sp_set_config_dsr(config, SP_DSR_IGNORE)

	sp_set_config(port, config)
	#print_port_settings(port)
    
	return CPCType, flowRate, FIO, port
end

function readCPC(port, CPCType, flowRate)
	sp_drain(port)
	if CPCType == :TSI3762
		sp_nonblocking_write(port, "RB\r")
		nbytes_read, bytes = sp_nonblocking_read(port,  10)
		c = String(bytes)
		f = split(c,"\r")
		N = try 
			parse(Float64,f[1])/60.0
		catch 
			0.0
		end
		N = N*3.0/flowRate
		#N = 3*parse(Float64,f[1])
	end
	if CPCType == :TSI3771 || CPCType == :TSI3772
		sp_nonblocking_write(port, "RALL\r")
		sleep(0.5)
		nbytes_read, bytes = sp_nonblocking_read(port,  80)
		c = String(bytes)
		f = split(c,",")
		N = try 
			parse(Float64, f[1])
		catch
			0.0
		end
	end
	if CPCType == :TSI3776C 
		sp_nonblocking_write(port, "RALL\r")
		nbytes_read, bytes = sp_nonblocking_read(port,  80)
		c = String(bytes)
		f = split(c,",")
		N = try 
			parse(Float64, f[1])
		catch
			0.0
		end
	end

	residual = try
		split(c,"\r")
	catch
		"NONE"
	end

	return N, residual
end
