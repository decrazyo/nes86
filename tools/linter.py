#!/usr/bin/env python3

import sys

# must follow a 'jmp' instruction and the end of a procedure
TAIL_JUMP = 'tail_jump'
# must follow a branch instruction and the end of a procedure
TAIL_BRANCH = 'tail_branch'
# must follow any other non-'ret' instruction and the end of a procedure
FALL_THROUGH ='fall_through'

# TODO: warn the user when a constant is used as an address.
#       add a tag to override the warning.
#       could prevent annoying bugs.
#       i'm going to have to rewrite this thing at some point, aren't i?...

TAGS = (
    TAIL_JUMP,
    TAIL_BRANCH,
    FALL_THROUGH,
)

BRANCHES = (
    'bcc',
    'bcs',
    'beq',
    'bne',
    'bmi',
    'bpl',
    'bvc',
    'bvs',
)

# this code is hot garbage.
# under no circumstances should you take inspiration from it.
def main():
    proc = False
    instr = ''
    tag = ''
    comment = ''

    file_name = sys.argv[1]
    line_num = 0

    def warn(msg):
        print(f'{file_name}({line_num}): Warning: Linter: ' + msg)

    with open(file_name, 'r') as f:
        for line in f:
            line_num += 1
            line = line.lstrip(' \t')


            if not line:
                continue

            # check if we are entering a procedure.
            if not proc and line.startswith('.proc'):
                if not comment:
                    warn(f'undocumented procedure')

                proc = True
                comment = ''
                instr = ''
                tag = ''
                continue

            # check if we are leaving a procedure.
            # if so, check the last instruction and relevant tags.
            if proc and line.startswith('.endproc'):
                if not instr:
                    continue
                elif instr == 'rts' or instr == 'rti':
                    if tag:
                        warn(f'"{instr}" tagged "[{tag}]"')
                elif instr == 'jmp':
                    if tag != TAIL_JUMP:
                        warn(f'missing "[{TAIL_JUMP}]" tag')
                elif instr in BRANCHES:
                    if tag != TAIL_BRANCH:
                        warn(f'missing "[{TAIL_BRANCH}]" tag')
                elif tag != FALL_THROUGH:
                    warn(f'missing "[{FALL_THROUGH}]" tag')

                proc = False
                comment = ''
                instr = ''
                tag = ''
                continue

            # ignore other ca65 commands like '.scope' and '.enum'
            if line[0] == '.':
                tag = ''
                instr = ''
                comment = ''
                continue

            # check if this is a new assembly instruction.
            if proc and len(line) >= 3 and line[:3].isalpha():
                temp = line[:3].lower()

                # identify tail calls
                # i.e.
                #   jsr some_func
                #   rts
                # which could be replaced with a 'jmp'
                # i.e.
                #   jmp some_func
                #   ; [tail_jump]
                if instr == 'jsr' and temp == 'rts':
                    # TODO: don't emit this warning if there is a label between "jsr" and "rts"
                    #       we're getting away this this for now because labels are considered instructions
                    #       and i guess i don't have any "jsrxxx:" labels before an "rts".
                    #       gawd this code sucks.
                    warn('unoptimized tail call')

                instr = temp

                # check if the instruction is a branch without a comment.
                if instr in BRANCHES and ';' not in line:
                    # this might be a little too aggressive.
                    # warn('missing branch comment')
                    pass

                tag = ''
                comment = ''
                continue

            # check if this is a comment.
            if line[0] == ';':
                comment = line # used to check if a procedure has some documentation.
                line = line.lstrip(';')
                line = line.lstrip(' \t')

                # check if the comment contains a tag.
                if proc and line and line[0] == '[' and ']' in line:
                    temp = line[1:line.find(']')]
                    if temp in TAGS:
                        tag = temp
                    else:
                        # this could cause a lot of false positives.
                        # warn(f'typeo in tag name "{temp}"')
                        pass

                continue


if __name__ == '__main__':
    # TODO: use argparse
    if (len(sys.argv) == 2):
        main()
    else:
        print("Usage: linter.py <file.s>")
