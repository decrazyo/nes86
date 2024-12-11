
-- debug script for Mesen2

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

s0x_addr = emu.getLabelAddress("zwS0X")["address"]
s1x_addr = emu.getLabelAddress("zwS1X")["address"]
s2x_addr = emu.getLabelAddress("zwS2X")["address"]

d0x_addr = emu.getLabelAddress("zwD0X")["address"]
d1x_addr = emu.getLabelAddress("zwD1X")["address"]
d2x_addr = emu.getLabelAddress("zwD2X")["address"]

fl_addr = emu.getLabelAddress("zwFlags")["address"]
instr_len_addr = emu.getLabelAddress("zbInstrLen")["address"]
instr_addr = emu.getLabelAddress("zbInstrBuffer")["address"]

-- read the CPU state out of memory.
function getCpuState()

    -- get the length of the most recently executed instruction
    local instr_len = emu.read(instr_len_addr, emu.memType.nesDebug)
    local instr = {}

    -- get the most recently executed instruction
    for i=1,instr_len,1 do
        instr[i] = emu.read(instr_addr+i-1, emu.memType.nesDebug)
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
        s0x = emu.read16(s0x_addr, emu.memType.nesDebug),
        s1x = emu.read16(s1x_addr, emu.memType.nesDebug),
        s2x = emu.read16(s2x_addr, emu.memType.nesDebug),
        d0x = emu.read16(d0x_addr, emu.memType.nesDebug),
        d1x = emu.read16(d1x_addr, emu.memType.nesDebug),
        d2x = emu.read16(d2x_addr, emu.memType.nesDebug),
        fl = emu.read16(fl_addr, emu.memType.nesDebug),
        instr = instr,
    }
    return state
end

-- log the CPU state in the same format used by emu86
function logCpuState()
    local state = getCpuState()
    local instr = ""
    local adjusted_ip = state["ip"] - #state["instr"]

    for _, byte in ipairs(state["instr"]) do
        instr = instr .. string.format("%02X ", byte)
    end

    emu.log(string.format("%04X:%04X  %s ", state["cs"], adjusted_ip, instr))
    emu.log("")
    emu.log(string.format("AX %04X  BX %04X  CX %04X  DX %04X  FL %04X",
        state["ax"], state["bx"], state["cx"], state["dx"], state["fl"]))
    emu.log(string.format("SI %04X  DI %04X  IP %04X  SP %04X  BP %04X",
        state["si"], state["di"], adjusted_ip, state["sp"], state["bp"]))
    emu.log(string.format("DS %04X  ES %04X  CS %04X  SS %04X",
        state["ds"], state["es"], state["cs"], state["ss"]))
    emu.log("")

    FLAG_MASKS = {
        CF = 0x0001,
        PF = 0x0004,
        AF = 0x0010,
        ZF = 0x0040,
        SF = 0x0080,
        TF = 0x0100,
        IF = 0x0200,
        DF = 0x0400,
        OF = 0x0800,
    }

    FLAG_NAMES = {
        "CF",
        "PF",
        "AF",
        "ZF",
        "SF",
        "TF",
        "IF",
        "DF",
        "OF",
    }

    local flags = ""

    for _, name in ipairs(FLAG_NAMES) do
        local mask = FLAG_MASKS[name]

        local value = 0

        if state["fl"] & mask == mask then
            value = 1
        end

        flags = flags .. string.format("%s %d  ", name, value)
    end

    emu.log(flags)
    emu.log("")

end

-- hook = emu.getLabelAddress("step")
-- hook = emu.getLabelAddress("fetch")
hook = emu.getLabelAddress("decode")
-- hook = emu.getLabelAddress("execute")
-- hook = emu.getLabelAddress("write")
-- hook = emu.getLabelAddress("interrupt")
emu.addMemoryCallback(logCpuState, emu.callbackType.exec, hook["address"], nil, nil, hook["memType"])
logCpuState()
