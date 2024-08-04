#!/usr/bin/env python3

import sys
import socket
from functools import partial

class Dbg86:
    def __init__(self, host='localhost', port=8086):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind((host, port))
        self._sock.listen()
        self._conn,self._address = self._sock.accept()
        self._update = True
        return

    def _get_state(self):
        state = {}
        flag_masks = {
            'of' : 0b0000100000000000,
            'df' : 0b0000010000000000,
            'if' : 0b0000001000000000,
            'tf' : 0b0000000100000000,
            'sf' : 0b0000000010000000,
            'zf' : 0b0000000001000000,
            'af' : 0b0000000000010000,
            'pf' : 0b0000000000000100,
            'cf' : 0b0000000000000001
        }

        data = self._get_data()

        # parse instruction buffer
        instr_len = int(data[b'len'], 16)
        instr = data[b'instr'].split(b' ')
        del data[b'len']
        del data[b'instr']

        if len(instr) != instr_len:
            raise Exception(f'inconsistent instruction length')

        state['instr'] = list(int(x, 16) for x in instr)

        # parse flags register
        flags = int(data[b'fl'], 16)

        for flag, mask in flag_masks.items():
            state[flag] = 1 if flags & mask else 0

        # parse all remaining registers
        for key, value in data.items():
            state[key.decode()] = int(value, 16)

        self._state = state

    def _get_data(self):
        data = {}
        keys = (
            b'ax',b'bx',b'cx',b'dx',
            b'si',b'di',b'bp',b'sp',
            b'cs',b'ds',b'es',b'ss',
            b'ip',b'fl',
            b'len', b'instr')

        for line in iter(self._get_line, b''):
            # each line should be a key/value pair separated by a colon
            items = line.split(b':')

            if len(items) != 2:
                raise Exception(f'incorrect data format "{line}"')

            key, value = items
            data[key] = value

        if not all(key in data for key in keys):
            raise Exception(f'data is missing required key')

        return data

    def _get_line(self):
        return b''.join(c for c in iter(partial(self._conn.recv, 1), b'\n'))

    def _send_response(self, pause):
        self._conn.send(b'1\n' if pause else b'0\n')
        self._update = True

    def state(self):
        if self._update:
            self._get_state()
            self._update = False

        return self._state

    def pause(self):
        self._send_response(pause=True)

    def step(self):
        self._send_response(pause=False)


def main():
    main_reg = ['ax','bx','cx','dx','fl']
    index_reg = ['si','di','ip','sp','bp']
    seg_reg = ['ds','es','cs','ss']
    flags = ['cf', 'pf', 'af', 'zf', 'sf', 'tf', 'if', 'df', 'of',]

    print('waiting for connection...')
    sys.stdout.flush()
    dbg86 = Dbg86()
    print('connected')
    sys.stdout.flush()

    while True:
        s = dbg86.state()
        dbg86.step()

        # approximate emu86 debug output to make comparisons easier
        print('')
        print(f'instr  0x{(s["cs"] << 4) + s["sp"]:05X}')
        print(f'stack  0x{(s["ss"] << 4) + s["ip"]:05X}')
        print(f'src    0x{(s["ds"] << 4) + s["si"]:05X}')
        print(f'dst    0x{(s["es"] << 4) + s["di"]:05X}')
        print('')
        print(' '.join(f'{x:02X}' for x in s['instr']))
        print('  '.join(f'{k.upper()} {s[k]:04X}' for k in main_reg))
        print('  '.join(f'{k.upper()} {s[k]:04X}' for k in index_reg))
        print('  '.join(f'{k.upper()} {s[k]:04X}' for k in seg_reg))
        print('')
        print('  '.join(f'{k.upper()} {s[k]:X}' for k in flags))
        print('')
        print('>', end='')
        sys.stdout.flush()


if __name__ == '__main__':
    main()
