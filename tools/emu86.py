#!/usr/bin/env python3

import socket
from functools import partial
from subprocess import PIPE, Popen

emu86_buffer = [b'0000:0000  90              NOP     0000h']

sync_cs = 0xe062
sync_ip = 0x1141

def main():
    # start the emu86 emulator
    print("starting emu86")
    proc = start_emu86()
    print("started emu86")

    # step emu86 execution until INT 0x19 is executed
    print("syncing emu86")
    while True:
        emu86_state = read_emu86(proc)
        step_emu86(proc)
        if int(emu86_state[b'ip'], 16) == sync_ip and int(emu86_state[b'cs'], 16) == sync_cs:
            break
    print("synced")

    # connect to the nes86 emulator
    print("connecting to nes86")
    conn = open_connection()
    print("connected")

    # step nes86 execution until INT 0x19 is executed
    print("syncing emu86")
    while True:
        nes86_state = recv_data(conn)
        send_status(conn, False)
        if int(nes86_state[b'ip'], 16) == sync_ip and int(nes86_state[b'cs'], 16) == sync_cs:
            break
    print("synced")
    # the emulators should now be synced.

    while True:
        emu86_state = emu86_skip_int(proc)
        nes86_state = nes86_skip_int(conn)

        print("STEP")

        status = cmp_states(emu86_state, nes86_state, proc, conn)

        if status:
            print("ERROR")
            print(emu86_prev.decode(), end='')
            print(b''.join(emu86_buffer).decode())

        send_status(conn, status)
        step_emu86(proc)


def cmp_states(emu86_state, nes86_state, proc, conn):
    if emu86_state[b'instr'][0] == b'F2' or emu86_state[b'instr'][0] == b'F3':
        print("REP")
        ip = emu86_state[b'ip']
        step_emu86(proc)
        emu86_state = emu86_skip_int(proc)
        while emu86_state[b'ip'] == ip:
            send_status(conn, False)
            step_emu86(proc)
            emu86_state = emu86_skip_int(proc)
            nes86_state = nes86_skip_int(conn)
        step_emu86(proc)
        emu86_state = emu86_skip_int(proc)


    if emu86_state[b'ip'] == nes86_state[b'ip'] and emu86_state[b'cs'] == nes86_state[b'cs']:
        return False
    else:
        return True


INTS = [b'CC', b'CD', b'CE']
IRET = b'CF'

def emu86_skip_int(proc):
    emu86_state = read_emu86(proc)

    if emu86_state[b'instr'][0] in INTS:
        print("emu86 INT ", end='')
        print(emu86_state[b'instr'])

        # INT 10 is strange
        if emu86_state[b'instr'][0] == b'CD' and emu86_state[b'instr'][1] == b'10':
            step_emu86(proc)
            return read_emu86(proc)

        while True:
            step_emu86(proc)
            emu86_state = emu86_skip_int(proc)
            if emu86_state[b'instr'][0] == IRET:
                print("emu86 IRET")
                break

        step_emu86(proc)
        emu86_state = emu86_skip_int(proc)

    return emu86_state


def nes86_skip_int(conn):
    nes86_state = recv_data(conn)

    if nes86_state[b'instr'][0] in INTS:
        print("nes86 INT ", end='')
        print(nes86_state[b'instr'])

        while True:
            send_status(conn, False)
            nes86_state = nes86_skip_int(conn)
            if nes86_state[b'instr'][0] == IRET:
                print("nes86 IRET")
                break

        send_status(conn, False)
        nes86_state = nes86_skip_int(conn)

    return nes86_state




def start_emu86():
    cmd = [
        'emu86',
        '-w', '0xe0000',
        '-f', 'elks/elks/arch/i86/boot/Image',
        '-w', '0x80000',
        '-f', 'elks/image/romfs.bin',
        '-i'
    ]

    proc = Popen(cmd, stdin=PIPE, stdout=PIPE)

    # skip over the startup messages
    for _ in range(8):
        line = proc.stdout.readline()

    return proc


def read_emu86(proc):
    global emu86_prev
    global emu86_buffer

    data = {}

    emu86_prev = emu86_buffer[0]

    # get the debugger output.
    emu86_buffer = list(proc.stdout.readline() for _ in range(8))

    # handle INT 10 printing a newline that fucks up parsing
    if emu86_buffer[0] == b'>\n':
        emu86_buffer = emu86_buffer[1:]
        emu86_buffer.append(proc.stdout.readline())

    # remove the first line since we don't need it.
    # remove blank lines.
    # strip trailing newlines
    lines = list(line.rstrip(b'\n') for line in emu86_buffer[1:] if line != b'\n')

    try:
        for line in lines:
            for reg in line.split(b'  '):
                key, value = reg.split(b' ')
                data[key.lower()] = value
    except Exception as e:
        print(b''.join(emu86_buffer).decode())
        print(reg)
        raise


    # get the bytes of the most recently executed instruction
    instr = emu86_prev.split(b'  ')[1].split(b' ')

    data[b'instr'] = instr
    data[b'len'] = len(instr)

    return data


def step_emu86(proc):
    proc.stdin.write(b'\n')
    proc.stdin.flush()
    return



def open_connection():
    # bind a TCP socket.
    # using port 8086 because it isn't reserved for any particular purpose.
    # also i think it's funny.
    # get it? because we're using it debug an 8086 emulator.
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('localhost', 8086))
    sock.listen()
    conn,address=sock.accept()
    return conn


def send_status(conn, status):
    conn.send(b'1\n' if status else b'0\n')


# receive CPU state from Mesen2 and convert it into a dictionary
def recv_data(conn):
    data = {}

    for line in iter(partial(recv_line, conn), b''):
        # each line should be a key/value pair separated by a colon
        items = line.split(b':')

        if len(items) != 2:
            raise Exception(f'protocol error: incorrect data format "{line}"')

        key, value = items
        data[key] = value

    flag_masks = {
        b'of' : 0b0000100000000000,
        b'df' : 0b0000010000000000,
        b'if' : 0b0000001000000000,
        b'tf' : 0b0000000100000000,
        b'sf' : 0b0000000010000000,
        b'zf' : 0b0000000001000000,
        b'af' : 0b0000000000010000,
        b'pf' : 0b0000000000000100,
        b'cf' : 0b0000000000000001
    }

    flags = int(data[b'fl'], 16)

    for key, value in flag_masks.items():
        data[key] = b'1' if flags & value else b'0'

    data[b'len'] = int(data[b'len'], 16)
    data[b'instr'] = data[b'instr'].split(b' ')

    return data


# receive data one byte at a time until a newline is received.
# convert the received data into a sting.
def recv_line(conn):
    return b''.join(c for c in iter(partial(conn.recv, 1), b'\n'))


if __name__ == '__main__':
    main()
