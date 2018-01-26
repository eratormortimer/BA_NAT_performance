local mg     = require "moongen"
local memory = require "memory"
local device = require "device"
local ts     = require "timestamping"
local filter = require "filter"
local hist   = require "histogram"
local stats  = require "stats"
local timer  = require "timer"
local arp    = require "proto.arp"
local log    = require "log"

-- set addresses here
local DST_MAC		= nil -- resolved via ARP on GW_IP or DST_IP, can be overriden with a string here
local SRC_IP_BASE	= "10.0.0.10" -- actual address will be SRC_IP_BASE + random(0, flows)
local DST_IP_BASE	= "10.1.0.10" -- same as above
local SRC_PORT		= 1 --changed to 1 for testing them all
local DST_PORT		= 319 --needs to stay, needed to accuratly measure time 

-- answer ARP requests for this IP on the rx port
-- change this if benchmarking something like a NAT device
local RX_IP		= DST_IP_BASE
-- used to resolve DST_MAC
local GW_IP		= DST_IP_BASE
-- used as source IP to resolve GW_IP to DST_MAC
local ARP_IP	= SRC_IP_BASE

function configure(parser)
	parser:description("Generates UDP traffic and measure latencies. Edit the source to modify constants like IPs.")
	parser:argument("txDev", "Device to transmit from."):convert(tonumber)
	parser:argument("rxDev", "Device to receive from."):convert(tonumber)
	parser:option("-r --rate", "Transmit rate in Mbit/s."):default(10000):convert(tonumber)
	parser:option("-f --flows", "Number of flows (randomized source IP)."):default(4):convert(tonumber)
	parser:option("-s --size", "Packet size."):default(60):convert(tonumber)
end

function master(args)
	txDev = device.config{port = args.txDev, rxQueues = 3, txQueues = 3}
	rxDev = device.config{port = args.rxDev, rxQueues = 3, txQueues = 3}
	device.waitForLinks()
	-- max 1kpps timestamping traffic timestamping
	-- rate will be somewhat off for high-latency links at low rates
	if args.rate > 0 then
		txDev:getTxQueue(0):setRate(args.rate - (args.size + 4) * 8 / 1000)
	end
	mg.startTask("loadSlave", txDev:getTxQueue(0), rxDev, args.size, args.flows)
	mg.startTask("timerSlave", txDev:getTxQueue(1), rxDev:getRxQueue(1), args.size, args.flows)
	arp.startArpTask{
		-- run ARP on both ports
		{ rxQueue = rxDev:getRxQueue(2), txQueue = rxDev:getTxQueue(2), ips = RX_IP },
		-- we need an IP address to do ARP requests on this interface
		{ rxQueue = txDev:getRxQueue(2), txQueue = txDev:getTxQueue(2), ips = ARP_IP }
	}
	mg.waitForTasks()
end

local function fillUdpPacket(buf, len)
	buf:getUdpPacket():fill{
		ethSrc = queue,
		ethDst = DST_MAC,
		ip4Src = SRC_IP,
		ip4Dst = DST_IP,
		udpSrc = SRC_PORT,
		udpDst = DST_PORT,
		pktLength = len
	}






end

local function doArp()
	if not DST_MAC then
		log:info("Performing ARP lookup on %s", GW_IP)
		DST_MAC = arp.blockingLookup(GW_IP, 5)
		if not DST_MAC then
			log:info("ARP lookup failed, using default destination mac address")
			return
		end
	end
	log:info("Destination mac: %s", DST_MAC)
end

function loadSlave(queue, rxDev, size, flows)
	doArp()
	local mempool = memory.createMemPool(function(buf)
		fillUdpPacket(buf, size)
	end)
	local bufs = mempool:bufArray()
	local counterSRC = 0
    local counterDST = 0
    local counterSRCPort = 0
	local txCtr = stats:newDevTxCounter(queue, "plain")
	local rxCtr = stats:newDevRxCounter(rxDev, "plain")
	local baseSrcIP = parseIPAddress(SRC_IP_BASE)
    local baseDstIP = parseIPAddress(DST_IP_BASE)
    while mg.running() do
            bufs:alloc(size)
            for i, buf in ipairs(bufs) do
                local pkt = buf:getUdpPacket()
                pkt.ip4.src:set(baseSrcIP + counterSRC)
                pkt.ip4.dst:set(baseDstIP + counterDST)
                pkt.udp:setSrcPort(SRC_PORT + counterSRCPort)

                --test with as much src ips we allow with flows
                counterSRC = incAndWrap(counterSRC, flows)
                --test with all DST ips we want
                if counterSRC == 0 then 
                    counterDST = incAndWrap(counterDST, flows) --TODO
                end
                --test with all possible src ports
                if counterSRC == 0 and counterDST == 0 then
                    counterSRCPort = incAndWrap(counterSRCPort, 65534)
                end

            end


        -- UDP checksums are optional, so using just IPv4 checksums would be sufficient here
		bufs:offloadUdpChecksums()
		queue:send(bufs)
		txCtr:update()
		rxCtr:update()
	end
	txCtr:finalize()
	rxCtr:finalize()
end

function timerSlave(txQueue, rxQueue, size, flows)
	doArp()
	if size < 84 then
		log:warn("Packet size %d is smaller than minimum timestamp size 84. Timestamped packets will be larger than load packets.", size)
		size = 84
	end
	local timestamper = ts:newUdpTimestamper(txQueue, rxQueue)
	local hist = hist:new()
	mg.sleepMillis(1000) -- ensure that the load task is running
	local counterSRC = 0
	local counterDST = 0
	local counterSRCPort = 0
	local rateLimit = timer:new(0.001)
	local baseSrcIP = parseIPAddress(SRC_IP_BASE)
   	local baseDstIP = parseIPAddress(DST_IP_BASE)
	while mg.running() do
		hist:update(timestamper:measureLatency(size, function(buf)
			fillUdpPacket(buf, size)
			local pkt = buf:getUdpPacket()
			pkt.ip4.src:set(baseSrcIP + counterSRC)
            pkt.ip4.dst:set(baseDstIP + counterDST)
            pkt.udp:setSrcPort(SRC_PORT + counterSRCPort)
	    counterSRC = incAndWrap(counterSRC, flows)
            if counterSRC == 0 then
                counterDST = incAndWrap(counterDST, flows) --TODO get new or different variable for flow, maybe new input
		print("DstIP: " .. baseDstIP + counterDST)
            end
            --test with all possible src ports
            if counterSRC == 0 and counterDST == 0 then
            	counterSRCPort = incAndWrap(counterSRCPort, 65534)
		print("Port: " .. counterSRCPort)
            end

        end))
        rateLimit:wait()
		rateLimit:reset()
	end
	-- print the latency stats after all the other stuff
	mg.sleepMillis(300)
	hist:print()
	hist:save("histogram.csv")
end

