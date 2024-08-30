#!/usr/bin/env python3

"""
A poorly implemented linter for 6502 assembly with ca65 syntax.
"""

import argparse
import re

from collections import namedtuple
from enum import Enum, auto

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


# code should be indented in increments of 4 spaces.
TAB_SIZE = 4

# maximum allowed line length.
LINE_LEN = 100
# maximum suggested line length.
STRICT_LINE_LEN = 80

# all 6502 mnemonics.
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

# 6502 return mnemonics.
RETURNS = [
    'rts', 'rti'
]

# 6502 branch mnemonics.
BRANCHES = [
    'bcc', 'bcs', 'beq', 'bmi', 'bne', 'bpl', 'brk', 'bvc', 'bvs',
]

class SegmentType(Enum):
    """ca65 segment types."""

    UNKNOWN = auto() # unidentifiable segment.
    RO = auto() # read-only.
    RW = auto() # read/write (unused).
    BSS = auto() # uninitialized.
    ZP = auto() # zero-page.
    OVERWRITE = auto() # overwrites all or parts of another segment (unused).

class LineType(Enum):
    """Tokenizer line types."""

    UNKNOWN = auto() # unidentifiable line.
    BLANK = auto() # blank line.
    WHITESPACE = auto() # only whitespace.
    # the following types my include whitespace.
    COMMENT = auto() # comment.
    # the following types my include comments.
    LABEL = auto() # label definition.
    SYMBOL = auto() # symbol definition.
    COMMAND = auto() # ca65 command.
    MNEMONIC = auto() # 6502 assembly mnemonic.
    MACRO = auto() # ca65 macro.

# tokens that Tokenizer will generate from a line of assembly code.
# all values will be stings. the strings may be empty.
LineTokens = namedtuple(
    'LineTokens',
    [
        'indent', # leading whitespace.
        'label', # label definition.
        'instr', # symbol name, command name, macro name, or assembly mnemonic.
        'args', # instruction arguments.
        'comment', # comment contents.
        'end', # line ending character(s).
    ])

# Tokenizer line data.
TokenizedLine = namedtuple(
    'TokenizedLine',
    [
        'num', # line number (1-indexed).
        'tokens', # LineTokens instance.
        'type', # LineType.
])


class LinkerConfigError(Exception):
    """Raised by LinkerConfig if a parsing error occurs."""


class LinkerConfig(dict):
    """Nested dictionary representation of an ld65 linker config."""

    def __init__(self, file):
        """
        Parses an ld65 linker config into nested dictionaries.

        Arguments:
        file -- file object to read the linker config from.

        Example linker config:
        MEMORY {
            ZEROPAGE: file = "", start = $0000, size = $0100, type = rw;
        }

        SEGMENTS {
            TEMP: load = ZEROPAGE, type = zp, define = yes;
        }

        Parsed example linker config:
        linker_config = {
            'MEMORY': {
                'ZEROPAGE': {
                    'file' = '""',
                    'start' = '$0000',
                    'size' = '$0100',
                    'type' = 'rw',
                }
            },
            'SEGMENTS': {
                'TEMP': {
                    'load' = 'ZEROPAGE',
                    'type' = 'zp',
                    'define' = 'yes',
                }
            }
        }
        """

        # read the linker config line by line.
        lines = (line for line in iter(file.readline, ''))
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
    """Raised by Tokenizer if a tokenization error occurs."""


class Tokenizer(list):
    """List of tokenized lines. See TokenizedLine."""

    def __init__(self, file):
        """
        Tokenize each line of a ca65 assembly file.

        Arguments:
        file -- file object to read assembly code from.
        """

        line_regex = (
            '^'
            '([\t ]+)?' # indent
            '([a-zA-Z_\\w]+:)?' # label
            '(?:[\t ]*)?' # whitespace (not captured)
            # instruction
            '(?:'
                # mnemonic, macro, control command, or symbol definition
                '(\\.?[a-zA-Z_]\\w*)'
                '(?:[\t ]*)?' # whitespace (not captured)
                # arguments
                '((?:'
                    "'[^'\r\n]'" # quoted character
                    '|'
                    '""' # empty quoted string
                    '|'
                    '".*?[^\\\\]"' # quoted string
                    '|'
                    '[^;\r\n]' # not a comment
                ')*)'
                '(?:[\t ]*)?' # whitespace (not captured)
            ')?'
            '(;[^\r\n]*)?' # comment
            '(\r?\n)?' # line end
        )

        lines = []
        enum_lines = enumerate(iter(file.readline, ''))

        # recursively join continued lines into a single line.
        # https://cc65.github.io/doc/ca65.html#line_continuations
        def line_cont(line):
            if line.endswith('\\\n'):
                try:
                    _, next_line = next(enum_lines)
                    line = line.rstrip('\\\n')
                    line = line + line_cont(next_line)
                except StopIteration:
                    pass
            return line

        # enumerate is zero-indexed.
        # add 1 since text editors are usually one-indexed.
        for i, line in ((i+1, line_cont(line)) for i, line in enum_lines):
            matches = re.search(line_regex, line)

            if not matches:
                raise TokenizerError(f'Line {i} cannot be tokenized.')

            groups = matches.groups()

            # replace None values with empty strings.
            # this will make linting easier later.
            tokens = list(token if token is not None else '' for token in groups)
            line_tokens = LineTokens(*tokens)
            line_type = self._get_line_type(line_tokens)

            if line_type == LineType.UNKNOWN:
                raise TokenizerError(f'Line {i} is not recognized.')

            tokenized_line = TokenizedLine(i, line_tokens, line_type)
            lines.append(tokenized_line)
            super().__init__(lines)

    @staticmethod
    def _get_line_type(tokens):
        """
        Classify lines based on their content.

        Arguments:
        tokens -- LineTokens instance.
        """

        line_type = LineType.UNKNOWN

        # check if the line contains nothing but a line ending.
        if all(t == '' for t in tokens[:-1]):
            line_type = LineType.BLANK

        # check if the line contains nothing but whitespace.
        elif tokens.indent and all(t == '' for t in tokens[1:-1]):
            line_type = LineType.WHITESPACE

        # check if the line contains nothing but a comment.
        elif tokens.comment and not (tokens.label or tokens.instr or tokens.args):
            line_type = LineType.COMMENT

        # check if the line contains nothing but a label definition.
        elif tokens.label and not (tokens.instr or tokens.args):
            line_type = LineType.LABEL

        # check if the line contains some kind of instruction.
        elif tokens.instr:
            # check if the instruction is a symbol definition.
            # example: SYMBOL_NAME = "value"
            if tokens.args.startswith('='):
                line_type = LineType.SYMBOL

            # check if the instruction is a ca65 command.
            # example: .segment "ZEROPAGE"
            elif tokens.instr.startswith('.'):
                line_type = LineType.COMMAND

            # check if the instruction is a 6502 assembly mnemonic.
            # example: lda #69
            elif tokens.instr.lower() in MNEMONICS:
                line_type = LineType.MNEMONIC

            # assume that the instruction is a macro.
            # example: my_custom_macro foo, bar
            # that is not always the case.
            # things like enum values get classified as macros because of this.
            # example:
            # .enum
            #     FOO ; this is classified as a macro
            #     BAR ; and so is this.
            # .endenum
            # the linter will be able to work that out from context later.
            else:
                line_type = LineType.MACRO

        return line_type


class LinterError(Exception):
    """Raised by Linter if a linting error occurs."""


class Linter:
    """Check that an assembly file complies with coding style guidelines."""

    # i don't feel like putting in the work to fix these.
    # pylint: disable=too-many-instance-attributes
    # pylint: disable=too-many-public-methods

    def __init__(self, source_file, linker_config, strict=False):
        """
        Initialize the linter and lint a tokenized assembly file.

        Arguments:
        source_file -- file object to read assembly code from.
        linker_config -- LinkerConfig instance.
        strict -- Enables strict mode.
                  Strict mode enforces some additional linting rules.
                  These rules are suggestions and don't need to be followed.
        """

        self.lines = Tokenizer(source_file)
        self.strict = strict
        self.segments = {}
        self.index = -1
        self.warnings = []
        self.blocks = []
        self.segment = None
        self.segment_type = None

        # the data we need is in the "SEGMENTS" section.
        if 'SEGMENTS' not in linker_config:
            raise LinterError('Linker config is missing a "SEGMENTS" section.')

        # build a dictionary of segments and their type.
        # linting rules depend on the type of section we are linting.
        for name, keywords in linker_config['SEGMENTS'].items():
            segment_type_name = keywords.get('type', 'unknown').upper()
            segment_type = SegmentType[segment_type_name]

            if segment_type == SegmentType.UNKNOWN:
                raise LinterError(f'Unknown segment type for segment "{name}"')

            self.segments[name] = segment_type

        # ca65 defaults to a "CODE" segment when none has been specified.
        self.set_segment('CODE')

        # the linter is fully initialized. check line length here since
        # this process can't be done on tokenized lines.
        source_file.seek(0)
        for line_num, line in enumerate(iter(source_file.readline, '')):
            line_num += 1
            line_len = len(line)
            msg = 'line length is greater than'

            if line_len > LINE_LEN:
                self.warn(f'{msg} "{LINE_LEN}" chars', line_num)

            if line_len > STRICT_LINE_LEN:
                self.cry(f'{msg} "{STRICT_LINE_LEN}" chars', line_num)

        # the rest of the linting process will operate on tokenized lines.
        self.lint()

    @property
    def line(self):
        """Return the current tokenized line."""
        return self.lines[self.index]

    @property
    def num(self):
        """Return the current tokenized line's line number."""
        return self.line.num

    @property
    def tokens(self):
        """Return the current tokenized line's tokens."""
        return self.line.tokens

    @property
    def type(self):
        """Return the current tokenized line's type."""
        return self.line.type

    @property
    def indent(self):
        """Return the current tokenized line's indent token."""
        return self.tokens.indent

    @property
    def label(self):
        """Return the current tokenized line's label token."""
        return self.tokens.label

    @property
    def instr(self):
        """Return the current tokenized line's instruction token."""
        return self.tokens.instr

    @property
    def args(self):
        """Return the current tokenized line's instruction arguments token."""
        return self.tokens.args

    @property
    def comment(self):
        """Return the current tokenized line's comment token."""
        return self.tokens.comment

    @property
    def end(self):
        """Return the current tokenized line's line end token."""
        return self.tokens.end

    @property
    def command(self):
        """
        Return the current tokenized line's instruction token as a command.
        """
        return self.instr.lower()

    @property
    def mnemonic(self):
        """
        Return the current tokenized line's instruction token as a mnemonic.
        """
        return self.instr.lower()

    def next_line(self):
        """
        Select the next tokenized line of the source file.

        Returns False if we have reached the end of the file.
        Returns True otherwise.
        """
        self.index += 1

        if self.index >= len(self.lines):
            self.index -= 1
            return False

        return True

    def warn(self, message, num=None):
        """
        Append a warning message to self.warnings.

        Arguments:
        message -- warning message to append.
        num -- line number associated with the warning message.
        """
        if num is None:
            num = self.num
        self.warnings.append(f'({num}): Warning: Linter: {message}')

    # 'cry' is an abbreviation of 'cry wolf'
    # since most warnings from this method can be safely ignored.
    def cry(self, message, num=None):
        """
        Append a warning message to self.warnings if in strict mode is enabled.

        The warning message will be labeled as a strict warning.

        Arguments:
        message -- warning message to append.
        num -- line number associated with the warning message.
        """
        if self.strict:
            self.warn(f'Strict: {message}', num)

    def set_segment(self, segment):
        """
        Change the current segment name and type.

        Arguments:
        segment -- new segment name.
        """
        self.segment = segment
        self.segment_type = self.segments.get(segment, SegmentType.UNKNOWN)

        if self.segment_type == SegmentType.UNKNOWN:
            self.warn(f'Unknown segment type for segment "{segment}".')

    @staticmethod
    def is_snake_case(text):
        """
        Check if a string is written in "snake_case".

        Arguments:
        text -- string to check.
        """
        return bool(re.fullmatch('[a-z][a-z0-9_]*', text))

    @staticmethod
    def is_pascal_case(text):
        """
        Check if a string is written in "PascalCase".

        We're using a pretty loose definition of pascal case here.
        For example, all of the following can be used.
        FooBar (preferred)
        FooBAR (allowed but discouraged)
        FOOBar (allowed but discouraged)
        FOOBAR (allowed but discouraged)

        Arguments:
        text -- string to check.
        """
        return bool(re.fullmatch('(?:[A-Z][A-Za-z0-9]+)+', text))

    @staticmethod
    def is_upper_case(text):
        """
        Check if a string is written in "UPPER_CASE".

        Arguments:
        text -- string to check.
        """
        return bool(re.fullmatch('[A-Z][A-Z0-9_]*', text))

    def lint(self):
        """Lint each tokenized line of a source file."""

        while self.next_line():
            self.lint_line()

        last = self.lines[-1]

        if not last.tokens.end.endswith('\n'):
            self.warn('File does not end with a newline.', last.num)

    def lint_line(self):
        """Lint a single tokenized line of a source file."""
        self.lint_whitespace()
        self.lint_label()
        self.lint_symbol()
        self.lint_mnemonic()
        self.lint_macro()
        self.lint_command() # must be done last for recursion reasons

    def lint_whitespace(self):
        """Check whitespace rules for the current line."""
        if self.end == '\r\n':
            self.warn('Found Windows line ending. Expected UNIX line ending.')

        if '\t' in self.indent:
            self.warn('Found tab char in indent. Only spaces are allowed.')

        size = TAB_SIZE * len(self.blocks)
        spaces = ' ' * size

        # allow blank lines.
        if self.type != LineType.BLANK:
            pass
        # allow labels to not be indented.
        elif self.type != LineType.LABEL and not self.indent:
            pass
        # check indent depth and allow blank lines.
        if self.indent != spaces:
            self.warn(f'Incorrect indent depth. Expected {size} spaces.')

    def lint_command(self):
        """Check ca65 command rules for the current line."""
        if self.type != LineType.COMMAND:
            return

        if not self.instr.islower():
            self.warn(f'Command "{self.instr}" should be lowercase.')

        # lint the specific commands that we care about.
        self.lint_command_segment()
        self.lint_command_struct()
        self.lint_command_union()
        self.lint_command_enum()
        self.lint_command_scope()
        self.lint_command_repeat()
        self.lint_command_macro()
        self.lint_command_proc()
        self.lint_command_if()

    def lint_command_segment(self):
        """Check .segment command rules for the current line."""

        illegal = [
            '.zeropage',
            '.bss',
            '.data',
            '.rodata',
            '.code',
        ]

        if self.command == '.segment':
            segment = self.args.split('"')[1]
        elif self.command in illegal:
            segment = self.command[1:].upper()
            msg = (f'Illegal command "{self.command}". '
                f' Use \'.segment "{segment}"\' instead.')
            self.warn(msg)
        else:
            return

        self.set_segment(segment)

    def lint_command_struct(self):
        """Check .struct command rules for the current line."""

        if self.command != '.struct':
            return

        name = self.args

        if name:
            if not name.startswith('s'):
                self.warn(f'Struct name "{name}" is missing "s" prefix.')
            else:
                name = name[1:]

            if not self.is_pascal_case(name):
                self.warn(f'Struct name "{name}" is not in pascal case.')
        else:
            self.cry('Unnamed struct.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endstruct':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_union(self):
        """Check .union command rules for the current line."""

        if self.command != '.union':
            return

        name = self.args

        if name:
            if not name.startswith('u'):
                self.warn(f'Union name "{name}" is missing "u" prefix.')
            else:
                name = name[1:]

            if not self.is_pascal_case(name):
                self.warn(f'Union name "{name}" is not in pascal case.')
        else:
            self.cry('Unnamed union.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endunion':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_enum(self):
        """Check .enum command rules for the current line."""

        if self.command != '.enum':
            return

        name = self.args

        if name:
            if not name.startswith('e'):
                self.warn(f'Enum name "{name}" is missing "e" prefix.')
            else:
                name = name[1:]

            if not self.is_pascal_case(name):
                self.warn(f'Enum name "{name}" is not in pascal case.')
        else:
            self.cry('Unnamed enum.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endenum':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_scope(self):
        """Check .scope command rules for the current line."""

        if self.command != '.scope':
            return

        name = self.args

        if not self.is_pascal_case(name):
            self.warn(f'Scope name "{name}" is not in pascal case.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endscope':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_repeat(self):
        """Check .rep command rules for the current line."""

        if not self.command.startswith('.rep'):
            return

        if self.command == '.rep':
            self.warn(f'Illegal command "{self.command}". Use ".repeat" instead.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command.startswith('.endrep'):
                if self.command == '.endrep':
                    self.warn(f'Illegal command "{self.command}". Use ".endrepeat" instead.')

                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_macro(self):
        """Check .mac* command rules for the current line."""

        if not self.command.startswith('.mac'):
            return

        if self.command == '.mac':
            self.warn(f'Illegal command "{self.command}". Use ".macro" instead.')

        # args may contain a macro name and macro arguments.
        # strip off arguments.
        name = self.args.split()[0]

        if not self.is_snake_case(name):
            self.warn(f'Macro name "{name}" is not in snake case.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command.startswith('.endmac'):
                if self.command == '.endmac':
                    self.warn(f'Illegal command "{self.command}". Use ".endmacro" instead.')

                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_proc(self):
        """Check .proc command rules for the current line."""

        if not self.command == '.proc':
            return

        name = self.args

        if not self.is_snake_case(name):
            self.warn(f'Proc name "{name}" is not in snake case.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endproc':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_command_if(self):
        """Check .if* command rules for the current line."""

        if not self.command.startswith('.if'):
            return

        self.blocks.append(self.command)

        while self.next_line():
            if self.command.startswith('.else'):
                block = self.blocks.pop()
                self.lint_line()
                self.blocks.append(block)
            elif self.command == '.endif':
                self.blocks.pop()
                self.lint_line()
                break
            else:
                self.lint_line()

    def lint_label(self):
        """Check label rules for the current line."""
        if not self.line.tokens.label:
            return

    def lint_symbol(self):
        """Check symbol rules for the current line."""

    def lint_mnemonic(self):
        """Check mnemonic rules for the current line."""

    def lint_macro(self):
        """Check macro rules for the current line."""


def main(linker_path, source_path):
    """Entry point for this script."""

    with open(linker_path, 'r', encoding='utf-8', newline='') as linker_file:
        linker = LinkerConfig(linker_file)

    with open(source_path, 'r', encoding='utf-8', newline='') as source_file:
        linter = Linter(source_file, linker)

    for warning in linter.warnings:
        print(f'{source_path}{warning}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='lint a ca65 assembly file')
    # parser.add_argument('linker_conf')
    parser.add_argument('filename')
    args = parser.parse_args()
    main('conf/ld.cfg', args.filename)
