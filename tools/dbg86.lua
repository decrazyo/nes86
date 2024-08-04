
script = "dbg86"

socket = require("socket.core")
tcp = socket.tcp()
-- tcp:settimeout(2)
res, msg = tcp:connect("localhost", 8086)

if res == nil then
    emu.displayMessage(script, msg)
    emu.log(msg)
    emu.log("did you start dbg86.py?")
end

-- get the addresses that store the CPU state we care about.
ax_addr = emu.getLabelAddress("zwAX")["address"]
bx_addr = emu.getLabelAddress("zwBX")["address"]
cx_addr = emu.getLabelAddress("zwCX")["address"]
dx_addr = emu.getLabelAddress("zwDX")["address"]

si_addr = emu.getLabelAddress("zwSI")["address"]
di_addr = emu.getLabelAddress("zwDI")["address"]
bp_addr = emu.getLabelAddress("zwBP")["address"]
sp_addr = emu.getLabelAddress("zwSP")["address"]

cs_addr = emu.getLabelAddress("zwCS")["address"]
ds_addr = emu.getLabelAddress("zwDS")["address"]
es_addr = emu.getLabelAddress("zwES")["address"]
ss_addr = emu.getLabelAddress("zwSS")["address"]

ip_addr = emu.getLabelAddress("zwIP")["address"]
fl_addr = emu.getLabelAddress("zwFlags")["address"]

len_addr = emu.getLabelAddress("zbInstrLen")["address"]
instr_addr = emu.getLabelAddress("zbInstrBuffer")["address"]


-- read the CPU state out of memory.
function getCpuState()
    -- get the length of the most recently executed instruction
    local len = emu.read(len_addr, emu.memType.nesDebug)
    local instr = {}

    -- get the most recently executed instruction
    for i=0,len,1 do
        instr[i] = emu.read(instr_addr+i, emu.memType.nesDebug)
    end

    -- build a table of all the CPU state we care about.
    local state = {
        ax = emu.read16(ax_addr, emu.memType.nesDebug),
        bx = emu.read16(bx_addr, emu.memType.nesDebug),
        cx = emu.read16(cx_addr, emu.memType.nesDebug),
        dx = emu.read16(dx_addr, emu.memType.nesDebug),

        si = emu.read16(si_addr, emu.memType.nesDebug),
        di = emu.read16(di_addr, emu.memType.nesDebug),
        bp = emu.read16(bp_addr, emu.memType.nesDebug),
        sp = emu.read16(sp_addr, emu.memType.nesDebug),

        cs = emu.read16(cs_addr, emu.memType.nesDebug),
        ds = emu.read16(ds_addr, emu.memType.nesDebug),
        es = emu.read16(es_addr, emu.memType.nesDebug),
        ss = emu.read16(ss_addr, emu.memType.nesDebug),

        ip = emu.read16(ip_addr, emu.memType.nesDebug),
        fl = emu.read16(fl_addr, emu.memType.nesDebug),

        len = len,
        instr = instr
    }

    return state
end


function checkCpuState()
    local state = getCpuState()
    local data

    -- skip the initial state since the CPU hasn't done anything yet.
    if state["len"] == 0 then
        emu.displayMessage(script, "skipping initial state")
        emu.log("skipping initial state")
        return
    end

    -- pack the CPU state into strings and send them to dbg86.py
    for key, value in pairs(state) do
        if key == "len" then
            data = string.format("%s:%02X\n", key, value)
        elseif key == "instr" then
            local hex = {}
            for i=0,state["len"],1 do
                hex[i] = string.format("%02X", value[i])
            end
            data = string.format("%s:%s\n", key, table.concat(hex, " ", 0, state["len"]-1))
        else
            data = string.format("%s:%04X\n", key, value)
        end

        tcp:send(data)
    end

    -- signal end of CPU state data.
    tcp:send("\n")

    -- wait for a response
    -- 0 = continue execution
    -- otherwise pause the emulator
    status = tcp:receive()

    if status ~= "0" then
        emu.breakExecution()
        emu.displayMessage(script, "break")
        emu.log("break")
    end
end

-- hook nes86's step function.
-- each call to step will execute an instruction and acknowledge interrupts.
-- this will let us check the CPU state just before it is changed.
step = emu.getLabelAddress("step")
emu.addMemoryCallback(checkCpuState, emu.callbackType.exec, step["address"], nil, nil, step["memType"])

emu.displayMessage(script, "ready")
