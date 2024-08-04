#!/usr/bin/env python3

import argparse
import re

from collections import namedtuple
from enum import Enum, auto
from functools import partial

# general rules
#   snake_case function names
#   PascalCase variables
#   variable prefixes
#   zero-page viable prefix
#   read-only rom prefix
#   enum prefix
#   struct prefix
#   union prefix
#   UPPER_CASE contents
#   function documentation
#   macro documentation
#   snake_case macro names
#   function tags
#       tail_jump
#       tail_branch
#       fall_through
# strict rules
#   module documentation
#   branch documentation
#   magic numbers


TAB_SIZE = 4

MNEMONICS = [
    'adc', 'and', 'asl', 'bcc', 'bcs', 'beq', 'bit',
    'bmi', 'bne', 'bpl', 'brk', 'bvc', 'bvs', 'clc',
    'cld', 'cli', 'clv', 'cmp', 'cpx', 'cpy', 'dec',
    'dex', 'dey', 'eor', 'inc', 'inx', 'iny', 'jmp',
    'jsr', 'lda', 'ldx', 'ldy', 'lsr', 'nop', 'ora',
    'pha', 'php', 'pla', 'plp', 'rol', 'ror', 'rti',
    'rts', 'sbc', 'sec', 'sed', 'sei', 'sta', 'stx',
    'sty', 'tax', 'tay', 'tsx', 'txa', 'txs', 'tya'
]

RETURNS = [
    'rts', 'rti'
]

BRANCHES = [
    'bcc', 'bcs', 'beq', 'bmi', 'bne', 'bpl', 'brk', 'bvc', 'bvs',
]

class SegmentType(Enum):
    UNKNOWN = auto()
    RO = auto()
    RW = auto() # unused
    BSS = auto()
    ZP = auto()
    OVERWRITE = auto() # unused

class LineType(Enum):
    UNKNOWN = auto()
    BLANK = auto()
    WHITESPACE = auto()
    COMMENT = auto()
    LABEL = auto()
    SYMBOL = auto()
    COMMAND = auto()
    MNEMONIC = auto()
    MACRO = auto()

TokenizedLine = namedtuple(
    'TokenizedLine',
    ['num', 'tokens', 'type'])

LineTokens = namedtuple(
    'LineTokens',
    ['indent', 'label', 'instr', 'args', 'comment', 'end'])


class LinkerConfigError(Exception):
    pass


class LinkerConfig(dict):
    def __init__(self, stream):
        # read the linker config line by line.
        lines = (line for line in iter(stream.readline, ''))
        # remove comments.
        lines = (line.split('#')[0] for line in lines)
        # remove whitespace.
        lines = (''.join(line.split()) for line in lines)
        # combine all lines while removing empty lines.
        lines = '\n'.join(line for line in lines if line)


        re_sections = '(\\w+)\n*\\{([\\s\\S]*?)\\}'
        matches = re.findall(re_sections, lines)

        if not matches:
            raise LinkerConfigError('Cannot parse linker sections.')

        sections = dict(matches)

        re_names = '([a-zA-Z_]\\w*)\n*:\n*([\\s\\S]*?;)'
        for section, section_data in sections.items():
            matches = re.findall(re_names, section_data)

            if not matches:
                raise LinkerConfigError('Cannot parse linker names.')

            names = dict(matches)
            sections[section] = names

            re_keywords = '(\\w+)\n*=\n*([\\s\\S]+?)[,\n;]'
            for name, name_data in names.items():
                matches = re.findall(re_keywords, name_data)

                if not matches:
                    raise LinkerConfigError('Cannot parse linker keywords.')

                keywords = dict(matches)
                sections[section][name] = keywords

        super().__init__(sections)


class TokenizerError(Exception):
    pass


class Tokenizer(list):
    def __init__(self, stream):
        line_regex = (
            '^'
            '([\t ]+)?' # indent
            '([a-zA-Z_\\w]+:)?' # label
            '(?:[\t ]*)?' # whitespace
            # instruction
            '(?:'
                # mnemonic, macro, control command, or symbol definition
                '(\\.?[a-zA-Z_]\\w*)'
                '(?:[\t ]*)?' # whitespace
                # arguments
                '((?:'
                    "'[^']'" # quoted character
                    '|'
                    '""' # empty quoted string
                    '|'
                    '".*?[^\\\\]"' # quoted string
                    '|'
                    '[^;]' # not a comment
                ')*)'
                '(?:[\t ]*)?' # whitespace
            ')?'
            '(;[^\r\n]*)?' # comment
            '(\r?\n)?' # line end
        )

        lines = []
        enum_lines = enumerate(iter(stream.readline, ''))

        # join continued lines into a single line.
        # https://cc65.github.io/doc/ca65.html#line_continuations
        def line_cont(line):
            if line.endswith('\\\n'):
                try:
                    i, next_line = next(enum_lines)
                    line = line.rstrip('\\\n')
                    line = line.rstrip('\\\r')
                    line = line + line_cont(next_line)
                except StopIteration as e:
                    pass
            return line

        for i, line in ((i, line_cont(line)) for i, line in enum_lines):
            matches = re.search(line_regex, line)

            if not matches:
                raise TokenizerError(f'Line {i} cannot be tokenized.')

            groups = matches.groups()
            tokens = list(token if token != None else '' for token in groups)
            line_tokens = LineTokens(*tokens)
            line_type = self.get_line_type(line_tokens)

            if line_type == LineType.UNKNOWN:
                print(line_tokens)
                raise TokenizerError(f'Line {i} is not recognized.')

            tokenized_line = TokenizedLine(i, line_tokens, line_type)
            lines.append(tokenized_line)
            super().__init__(lines)

    @staticmethod
    def get_line_type(tokens):
        if all(t == '' for t in tokens[:-1]):
            return LineType.BLANK
        if tokens.indent and all(t == '' for t in tokens[1:-1]):
            return LineType.WHITESPACE
        if tokens.comment and not (tokens.label or tokens.instr or tokens.args):
            return LineType.COMMENT
        elif tokens.label and not (tokens.instr or tokens.args):
            return LineType.LABEL
        if tokens.instr:
            if tokens.args.startswith('='):
                return LineType.SYMBOL
            if tokens.instr.startswith('.'):
                return LineType.COMMAND
            if tokens.instr.lower() in MNEMONICS:
                return LineType.MNEMONIC
            else:
                return LineType.MACRO
        return LineType.UNKNOWN


class LinterError(Exception):
    pass


class Linter:
    def __init__(self, tokenizer, linker, strict=False):
        self.lines = tokenizer
        self.strict = strict
        self.segments = {}
        self.index = -1
        self.warnings = []
        self.blocks = []
        self.segment = None
        self.segment_type = None

        # the data we need is in the "SEGMENTS" section.
        if 'SEGMENTS' not in linker:
            raise LinterError('Linker config is missing a "SEGMENTS" section.')

        # build a dictionary of segments and their type.
        # linting rules depend on the type of section we are linting.
        for name, keywords in linker['SEGMENTS'].items():
            segment_type_name = keywords.get('type', 'unknown').upper()
            segment_type = SegmentType[segment_type_name]

            if segment_type == SegmentType.UNKNOWN:
                raise LinterError(f'Unknown segment type for segment "{name}"')

            self.segments[name] = segment_type

        # ca65 defaults to a "CODE" segment when none has been specified.
        self.set_segment('CODE')
        self.lint()

    @property
    def line(self):
        return self.lines[self.index]

    @property
    def command(self):
        return self.lines[self.index].tokens.instr.lower()

    @property
    def mnemonic(self):
        return self.lines[self.index].tokens.instr.lower()

    def next_line(self):
        self.index += 1

        if self.index >= len(self.lines):
            self.index -= 1
            return False

        return True

    def warn(self, message, num=None):
        if num == None:
            num = self.line.num
        self.warnings.append(f'({num}): Warning: Linter: {message}')

    def cry(self, message, num=None):
        if not self.strict:
            return
        self.warn(f'Strict: {message}', num)

    def set_segment(self, segment):
        self.segment = segment
        self.segment_type = self.segments.get(segment, SegmentType.UNKNOWN)

        if self.segment_type == SegmentType.UNKNOWN:
            self.warn('Unknown segment type for segment "{segment}".')

    @staticmethod
    def is_snake(text):
        return True if re.fullmatch('[a-z][a-z_]*', text) else False

    @staticmethod
    def is_pascal(text):
        return True if re.fullmatch('(?:[A-Z][a-z]+)+', text) else False

    def lint(self):
        while(self.next_line()):
            self.lint_line()

        last = self.lines[-1]

        if last.tokens.end != '\n':
            self.warn(f'File does not end with a newline.', last.num)

    def lint_line(self):
        self.lint_whitespace()
        self.lint_command()
        self.lint_label()
        self.lint_symbol()
        self.lint_mnemonic()
        self.lint_macro()

    def lint_whitespace(self):
        if self.line.tokens.end == '\r\n':
            self.warn('Found Windows-style line ending. Expected UNIX-style line ending.')

        if '\t' in self.line.tokens.indent:
            self.warn('Found tab character in indent. Only spaces are allowed.')

        indent_size = TAB_SIZE * len(self.blocks)

        if self.line.tokens.indent != ' ' * indent_size:
            self.warn(f'Incorrect indent depth. Expected {indent_size} spaces.')

    def lint_command(self):
        if self.line.type != LineType.COMMAND:
            return

        if not self.line.tokens.instr.islower():
            self.warn(f'Command should be lowercase.')

        command = self.line.tokens.instr.lower()

        self.lint_command_segment()
        self.lint_command_struct()
        self.lint_command_union()
        self.lint_command_enum()
        self.lint_command_scope()
        self.lint_command_macro()

    def lint_command_segment(self):
        ILLEGAL = [
            '.zeropage',
            '.bss',
            '.data',
            '.rodata',
            '.code',
        ]

        if self.command == '.segment':
            segment = self.line.tokens.args.split('"')[1]
        elif self.command in ILLEGAL:
            segment = self.command[1:].upper()
            self.warn(f'Illegal segment command. Use \'.segment "{segment}"\' instead.')
        else:
            return

        self.set_segment(segment)

    # def lint_command_end_block(self):
    #     command = self.line.tokens.instr.lower()

    #     if not command.startswith('.end'):
    #         return

    #     if not self.blocks:
    #         return


    def lint_command_struct(self):
        if self.command != '.struct':
            return

        name = self.line.tokens.args

        if not name:
            self.cry('Unnamed struct.')

        if name and not name.startswith('s'):
            self.warn('Struct name missing "s" prefix.')

        if name and not self.is_pascal(name[1:]):
            self.warn('Struct name is not in pascal case.')

        self.blocks.append(self.command)

        while(self.next_line()):
            self.lint_command_endstruct()
            self.lint_line()

    def lint_command_endstruct(self):
        if self.command != '.endstruct':
            return

        self.blocks.pop()


    def lint_command_union(self):
        if self.command != '.union':
            return

        # self.blocks.append(self.command)

    def lint_command_enum(self):
        if self.command != '.enum':
            return

        # self.blocks.append(self.command)

    def lint_command_scope(self):
        if self.command != '.scope':
            return

        # self.blocks.append(self.command)

    def lint_command_macro(self):
        if self.command != '.macro':
            return

        # self.blocks.append(self.command)


    def lint_label(self):
        if not self.line.tokens.label:
            return

    def lint_symbol(self):
        pass


    def lint_mnemonic(self):
        pass

    def lint_macro(self):
        pass


def main(linker_file, source_file):
    with open(linker_file, 'r') as f:
        linker = LinkerConfig(f)

    with open(source_file, 'r') as f:
        tokenizer = Tokenizer(f)

    linter = Linter(tokenizer, linker)

    for warning in linter.warnings:
        print(f'{source_file}{warning}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='lint a ca65 assembly file')
    # parser.add_argument('linker_conf')
    parser.add_argument('filename')
    args = parser.parse_args()
    main('conf/ld.cfg', args.filename)
