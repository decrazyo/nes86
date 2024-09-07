#!/usr/bin/env python3.6

# TODO: check that macros are linted correctly.
# TODO: return non-zero value if there are warnings

"""
A poorly implemented linter for 6502 assembly with ca65 syntax.
This is intended to enforce my personal coding standards.
The linter will probably work as long as you're code assembles
and wasn't deliberately designed to break the linter.
"""

# i don't feel like splitting this up into multiple modules.
# pylint: disable=too-many-lines

import argparse
import re

from collections import namedtuple
from enum import Enum, auto

# code should be indented in increments of 4 spaces.
TAB_SIZE = 4

# maximum allowed line length.
LINE_LEN = 100

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

# this does not represent all ca65 commands
# simply because i can't be bothered to extract them all from the ca65 docs.
COMMANDS = [
    '.asize',
    '.cpu',
    '.isize',
    '.paramcount',
    '.time',
    '.version',
    '.addrsize',
    '.bank',
    '.bankbyte',
    '.blank',
    '.concat',
    '.const',
    '.def',
    '.defined',
    '.definedmacro',
    '.hibyte',
    '.hiword',
    '.ident',
    '.ismnem',
    '.ismnemonic',
    '.left',
    '.lobyte',
    '.loword',
    '.match',
    '.max',
    '.mid',
    '.min',
    '.ref',
    '.referenced',
    '.right',
    '.sizeof',
    '.sprintf',
    '.strat',
    '.string',
    '.strlen',
    '.tcount',
    '.xmatch',
    '.a16',
    '.a8',
    '.addr',
    '.align',
    '.asciiz',
    '.assert',
    '.autoimport',
    '.bankbytes',
    '.bss',
    '.byt',
    '.byte',
    '.case',
    '.charmap',
    '.code',
    '.condes',
    '.constructor',
    '.data',
    '.dbyt',
    '.debuginfo',
    '.define',
    '.delmac',
    '.delmacro',
    '.destructor',
    '.dword',
    '.else',
    '.elseif',
    '.end',
    '.endenum',
    '.endif',
    '.endmac',
    '.endmacro',
    '.endproc',
    '.endrep',
    '.endrepeat',
    '.endscope',
    '.endstruct',
    '.endunion',
    '.enum',
    '.error',
    '.exitmac',
    '.exitmacro',
    '.export',
    '.exportzp',
    '.faraddr',
    '.fatal',
    '.feature',
    '.fileopt',
    '.fopt',
    '.forceimport',
    '.global',
    '.globalzp',
    '.hibytes',
    '.i16',
    '.i8',
    '.if',
    '.ifblank',
    '.ifconst',
    '.ifdef',
    '.ifnblank',
    '.ifndef',
    '.ifnref',
    '.ifp02',
    '.ifp4510',
    '.ifp816',
    '.ifpc02',
    '.ifpdtv',
    '.ifpsc02',
    '.ifref',
    '.import',
    '.importzp',
    '.incbin',
    '.include',
    '.interruptor',
    '.list',
    '.listbytes',
    '.literal',
    '.lobytes',
    '.local',
    '.localchar',
    '.macpack',
    '.mac',
    '.macro',
    '.org',
    '.out',
    '.p02',
    '.p4510',
    '.p816',
    '.pagelen',
    '.pagelength',
    '.pc02',
    '.pdtv',
    '.popcharmap',
    '.popcpu',
    '.popseg',
    '.proc',
    '.psc02',
    '.pushcharmap',
    '.pushcpu',
    '.pushseg',
    '.referto',
    '.refto',
    '.reloc',
    '.repeat',
    '.res',
    '.rodata',
    '.scope',
    '.segment',
    '.set',
    '.setcpu',
    '.smart',
    '.struct',
    '.tag',
    '.undef',
    '.undefine',
    '.union',
    '.warning',
    '.word',
    '.zeropage ',
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


class LinterTag(Enum):
    """Linter tags that may appear in comments."""

    NONE = auto() # unidentifiable or non-existent linter tag.
    FALL_THROUGH = auto() # execution falls through the end of a procedure.
    TAIL_JUMP = auto() # execution jumps elsewhere at the end of a procedure.
    TAIL_BRANCH = auto() # execution branches at the end of a procedure.
    CODE_LABEL = auto() # label should obey code label rules.
    DATA_LABEL = auto() # label should obey data label rules.


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
            '(?:(@?[a-zA-Z_\\w]+):)?' # label (colon not captured)
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
            '(;[^\r\n]*)?' # comment (semicolon captured)
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
            matches = re.match(line_regex, line)

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

    def __init__(self, linker_config, source_file, strict=False):
        """
        Initialize the linter and lint a tokenized assembly file.

        Arguments:
        linker_config -- LinkerConfig instance.
        source_file -- file object to read assembly code from.
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

        # the linter is fully initialized.
        # check line length and trailing whitespace here
        # since that can't be done on tokenized lines.
        source_file.seek(0)
        for line_num, line in enumerate(iter(source_file.readline, '')):
            line_num += 1
            line = line.rstrip('\n')
            line = line.rstrip('\r')
            line_len = len(line)
            lenght_msg = 'line length is greater than'

            if line_len > LINE_LEN:
                self.warn(f'{lenght_msg} "{LINE_LEN}" chars', line_num)

            if line.endswith(' ') or line.endswith('\t'):
                self.warn('Trailing whitespace', line_num)

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

    @property
    def block(self):
        """Return the current block name or an empty string."""
        return self.blocks[-1] if self.blocks else ''


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

        # warning message format is meant to mimic that of ca65.
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
        return bool(re.fullmatch(r'[a-z][a-z0-9_]*', text))


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

        return bool(re.fullmatch(r'(?:[A-Z0-9][A-Za-z0-9]*)+', text))


    @staticmethod
    def is_upper_case(text):
        """
        Check if a string is written in "UPPER_CASE".

        Arguments:
        text -- string to check.
        """

        return bool(re.fullmatch(r'[A-Z_][A-Z0-9_]*', text))


    def is_documented(self):
        """Check for documentation above the current line."""

        # if we are at the start of the file then there is no previous line.
        # therefore there is no documentation above the current line.
        if not self.index:
            return False

        # get the previous line
        index = self.index - 1
        line = self.lines[index]

        # check if the line is a comment
        return line.type == LineType.COMMENT


    def get_magic_numbers(self, text=None):
        """
        Extract "magic numbers" from a sting.
        Such numbers should be assigned to an identifier before being used.
        Return a list of magic number strings.

        Arguments:
        text -- a string to extract magic numbers from.
        """

        # we want to ignore anything in quotes.
        # we'll do this be removing quoted content from the text.

        # default to the current line's arguments
        if text is None:
            text = self.args

        if not text:
            return []

        regex = (
            '('
                "'[^'\r\n]'" # quoted character
                '|'
                '""' # empty quoted string
                '|'
                '".*?[^\\\\]"' # quoted string
                '|'
                '[^\'""]+' # not quotes
            ')'
        )

        # split the text into quoted strings, quoted chars, and everything else.
        matches = re.findall(regex, text)

        # remove any matches that have single or double quotes in them.
        matches = [m for m in matches if not any(q in m for q in '\'"')]

        # text should now contain only numbers, symbols, and operators.
        text = ' '.join(matches)

        # split text into numbers and symbols.
        regex = r'(?:^|[^\w%$]+)([\w%$]+)'
        matches = re.findall(regex, text)

        # build a dictionary that maps strings to their integer values.
        numbers = {}

        for key in matches:
            # remove underscores if there are any.
            num_str = key.replace('_', '')

            try:
                # parse binary numbers
                if num_str.startswith('%'):
                    num_str = num_str.lstrip('%')
                    value = int(num_str, base=2)
                # parse hexadecimal numbers
                elif num_str.startswith('$'):
                    num_str = num_str.lstrip('$')
                    value = int(num_str, base=16)
                # parse decimal numbers
                elif num_str.isdigit():
                    value = int(num_str)
                # not a number
                else:
                    continue
            except ValueError:
                # catch and ignore errors from int()
                # if we end up here then ca65 should be complaining
                # or it's a linting edge case that i don't really care about.
                continue

            numbers[key] = value


        # these numbers are commonly used and well understood at a glance.
        # as such, they don't need identifiers defined for them.
        common_numbers = [
            0x00, # zero
            0x01, # one
            0x7f, # max signed byte
            0x80, # min signed byte
            0xff, # max unsigned byte or negative one
            0x7fff, # max signed word
            0x8000, # min signed word
            0xffff, # max unsigned word or negative one
        ]

        # return only the magical numbers.
        return [k for k, v in numbers.items() if v not in common_numbers]


    def get_prefix_name(self, ident=None):
        """
        Split an identifier into its prefix and name.
        Return the prefix and name as a tuple.

        Arguments:
        ident -- an identifier that should have a prefix.
        """

        # default to the current line's label
        if ident is None:
            ident = self.label

        # try to match a prefixed identifier like this.
        # 'rbaMyReadonlyByteArray'
        # split the identifier into a prefix and name.
        # ('rba', 'MyReadonlyByteArray')
        matches = re.fullmatch(r'([a-z]+)([A-Z0-9].*)', ident)

        if matches:
            return matches.groups()

        # the identifier doesn't appear to have a prefix.
        return ('', ident)


    def get_linter_tag(self, line=None):
        """
        Extract a linter tag from a comment.
        Return a LinterTag.

        Arguments:
        line -- a line TokenizedLine instance.
        """

        # we need a TokenizedLine so that warnings use the correct line number.

        # default to the current line
        if line is None:
            line = self.line

        # if there is no comment then there can be no linter tag.
        if not line.tokens.comment:
            return LinterTag.NONE

        # parse the linter tag out of the comment.
        # the comment should contain only the tag and whitespace.
        # example:
        # "; [fall_through]"
        matches = re.fullmatch(r';\s*\[(\w+)\]\s*', line.tokens.comment)

        # if there is no match then there is no tag
        # or the comment contained more then just a tag and whitespace.
        # in the latter case, the absence of a tag will cause other warnings.
        # that will effectively inform the user of the issue.
        if not matches:
            return LinterTag.NONE

        tag_name = matches.group(1)

        if not tag_name.islower():
            self.warn(f'Linter tag "{tag_name}" should be lowercase.', line.num)

        # lookup the tag name and generate a warning if it's not found.
        try:
            return LinterTag[tag_name.upper()]
        except KeyError:
            self.warn(f'Linter tag "{tag_name}" is not recognized.', line.num)
            return LinterTag.NONE


    def get_command_alias(self, command=None):
        """
        Return the preferred alias for a command when an illegal command is provided.
        Return an empty string otherwise.
        If "command" is None then "self.command is used".

        Arguments:
        command -- ca65 command string. e.g. ".struct".
        """

        if command is None:
            command = self.command
        else:
            command = command.lower()

        # always use the long form of a command
        aliases = {
            '.zeropage': '.segment "ZEROPAGE"',
            '.bss': '.segment "BSS"',
            '.data': '.segment "DATA"',
            '.rodata': '.segment "RODATA"',
            '.code': '.segment "CODE"',
            '.byt': '.byte',
            '.delmac': '.delmacro',
            '.endmac': '.endmacro',
            '.endrep': '.endrepeat',
            '.exitmac': '.exitmacro',
            '.fopt': '.fileopt',
            '.mac': '.macro',
            '.pagelen': '.pagelength',
            '.refto': '.referto',
            '.undef': '.undefine',
            '.def': '.defined',
            '.ismnem': '.ismnemonic',
            '.ref': '.referenced',
        }

        return aliases.get(command, '')


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
        self.lint_args()
        self.lint_comment()
        self.lint_command() # must be done last for recursion reasons


    def lint_whitespace(self):
        """Check whitespace rules for the current line."""

        if '\r' in self.end:
            self.warn('Found Windows line ending. Expected UNIX line ending.')

        if '\t' in self.indent:
            self.warn('Found tab char in indent. Only spaces are allowed.')

        # nothing more to check for blank lines.
        if self.type == LineType.BLANK:
            return

        indent_size = TAB_SIZE * len(self.blocks)

        # labels should be indented 1 tab less than everything else.
        if self.label:
            indent_size -= TAB_SIZE

        indent = ' ' * indent_size

        # check indent depth.
        if self.indent != indent:
            if self.type == LineType.COMMENT:
                # sometimes it's appropriate for comments to disobey indent rules.
                self.cry(f'Incorrect indent depth. Expected {indent_size} spaces.')
            else:
                self.warn(f'Incorrect indent depth. Expected {indent_size} spaces.')

        # blank line rules are more complex after an ".endproc" command.
        # those rules will be enforced by "lint_command_endproc"
        if self.type == LineType.COMMAND and self.command == '.endproc':
            return

        count = 0

        # count the number of blank lines after the current line.
        # the current line is necessarily not blank.
        for line in (self.lines[i] for i in range(self.index+1, len(self.lines))):
            if line.type == LineType.BLANK:
                count += 1
                line_num = line.num
            else:
                break

        if count > 1:
            self.warn(f'Too many blank lines. Found {count}, Expected 1.', line_num)


    def lint_command(self):
        """Check ca65 command rules for the current line."""

        if self.type != LineType.COMMAND:
            return

        if not self.instr.islower():
            self.warn(f'Command "{self.instr}" should be lowercase.')

        alias = self.get_command_alias()

        if alias:
            self.warn(f'Illegal command "{self.command}". Use "{alias}" instead.')

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
        self.lint_command_define()


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
        else:
            return

        self.set_segment(segment)


    def lint_command_struct(self):
        """Check .struct command rules for the current line."""

        if self.command != '.struct':
            return

        ident = self.args

        if ident:
            prefix, name = self.get_prefix_name(ident)

            if not prefix:
                self.warn(f'Struct "{ident}" has no prefix.')

            if 's' not in prefix:
                self.warn(f'Struct "{ident}" is missing "s" prefix.')

            if len(set(prefix)) != len(prefix) not in prefix:
                self.warn(f'Struct "{ident}" has repeated prefix characters.')

            if not all(ch == 's' for ch in prefix):
                self.warn(f'Struct "{ident}" has invalid prefix.')

            if not self.is_pascal_case(name):
                self.warn(f'Struct "{ident}" name is not pascal case.')
        else:
            self.cry('Unnamed struct.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endstruct':
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_union(self):
        """Check .union command rules for the current line."""

        if self.command != '.union':
            return

        ident = self.args

        if ident:
            prefix, name = self.get_prefix_name(ident)

            if not prefix:
                self.warn(f'Union "{ident}" has no prefix.')

            if 'u' not in prefix:
                self.warn(f'Union "{ident}" is missing "u" prefix.')

            if len(set(prefix)) != len(prefix) not in prefix:
                self.warn(f'Union "{ident}" has repeated prefix characters.')

            if not all(ch == 'u' for ch in prefix):
                self.warn(f'Union "{ident}" has invalid prefix.')

            if not self.is_pascal_case(name):
                self.warn(f'Union "{ident}" name is not pascal case.')
        else:
            self.cry('Unnamed union.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endunion':
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_enum(self):
        """Check .enum command rules for the current line."""

        if self.command != '.enum':
            return

        ident = self.args

        if ident:
            prefix, name = self.get_prefix_name(ident)

            if not prefix:
                self.warn(f'Enum "{ident}" has no prefix.')

            if 'e' not in prefix:
                self.warn(f'Enum "{ident}" is missing "e" prefix.')

            if len(set(prefix)) != len(prefix) not in prefix:
                self.warn(f'Enum "{ident}" has repeated prefix characters.')

            if not all(ch == 'e' for ch in prefix):
                self.warn(f'Enum "{ident}" has invalid prefix.')

            if not self.is_pascal_case(name):
                self.warn(f'Enum "{ident}" name is not pascal case.')
        else:
            self.cry('Unnamed enum.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endenum':
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_scope(self):
        """Check .scope command rules for the current line."""

        if self.command != '.scope':
            return

        name = self.args

        if not name:
            self.cry(f'Scope has no name.')
        elif not self.is_pascal_case(name):
            self.warn(f'Scope "{name}" name is not pascal case.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endscope':
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_repeat(self):
        """Check .rep command rules for the current line."""

        if self.command != '.repeat':
            return

        magic = self.get_magic_numbers()

        for num in magic:
            self.cry(f'Magic number "{num}" in .repeat arguments.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endrepeat':
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_macro(self):
        """Check .mac* command rules for the current line."""

        if self.command not in ('.mac', '.macro'):
            return

        # args will contain a macro name and possibly macro arguments.
        # strip off arguments since we don't need them.
        name = self.args.split()[0]

        if not self.is_snake_case(name):
            self.warn(f'Macro name "{name}" is not snake case.')

        if not self.is_documented():
            self.warn(f'Macro "{name}" is not documented.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command in ('.endmac', '.endmacro'):
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_proc(self):
        """Check .proc command rules for the current line."""

        if not self.command == '.proc':
            return

        name = self.args

        if not self.is_snake_case(name):
            self.warn(f'Procedure name "{name}" is not snake case.')

        if not self.is_documented():
            self.warn(f'Procedure "{name}" is not documented.')

        self.blocks.append(self.command)

        while self.next_line():
            if self.command == '.endproc':
                self.lint_command_endproc()
                self.blocks.pop()
                self.lint_line()
                break

            self.lint_line()


    def lint_command_endproc(self):
        """Check linter tags at the end of a procedure."""

        # can't be bothered to fix these.
        # pylint: disable=too-many-branches
        # pylint: disable=too-many-statements

        if self.command != '.endproc':
            return

        # we have a ".endproc" at the start of the file.
        # this code probable doesn't even assemble.
        # ignore it.
        if not self.index:
            return

        index = self.index - 1
        line = self.lines[index]

        # get a linter tag from the end of the procedure if there is one.
        # we will only consider the line immediately preceding the current line.
        linter_tag = self.get_linter_tag(line)

        valid_tags = [
            LinterTag.NONE,
            LinterTag.FALL_THROUGH,
            LinterTag.TAIL_JUMP,
            LinterTag.TAIL_BRANCH,
        ]

        # filter out linter tags that we don't care about.
        if linter_tag not in valid_tags:
            linter_tag = LinterTag.NONE

        tag_line = line
        tag_name = linter_tag.name.lower()

        if linter_tag != LinterTag.NONE and line.type != LineType.COMMENT:
            self.warn(f'Linter tag "{tag_name}" should be on its own line ', line.num)

        # iterate backwards through the lines.
        for line in (self.lines[i] for i in range(index, -1, -1)):
            if line.type == LineType.COMMAND and line.tokens.instr.lower() == '.proc':
                # we reached the start of the procedure.
                return
            if line.type == LineType.MNEMONIC:
                # found the last mnemonic in the procedure.
                break
        else:
            # can't find a mnemonic nor the start of the procedure.
            return

        mnemonic = line.tokens.instr.lower()

        max_count = 1

        # check if the correct linter tag is given for the last mnemonic.
        if linter_tag == LinterTag.NONE:
            if mnemonic in RETURNS:
                max_count = 2
            elif mnemonic == 'jmp':
                max_count = 2
                self.warn('Missing "tail_jump" linter tag.')
            elif mnemonic in BRANCHES:
                self.warn('Missing "tail_branch" linter tag.')
            else:
                self.warn('Missing "fall_through" linter tag.')
        elif mnemonic in RETURNS:
            max_count = 2
            self.warn(f'Return incorrectly tagged as "{tag_name}".', tag_line.num)
        elif mnemonic == 'jmp':
            max_count = 2
            if linter_tag != LinterTag.TAIL_JUMP:
                self.warn(f'Tail jump incorrectly tagged as "{tag_name}".', tag_line.num)
        elif mnemonic in BRANCHES:
            if linter_tag != LinterTag.TAIL_BRANCH:
                self.warn(f'Tail branch incorrectly tagged as "{tag_name}".', tag_line.num)
        elif linter_tag != LinterTag.FALL_THROUGH:
            self.warn(f'Fall through incorrectly tagged as "{tag_name}".', tag_line.num)

        count = 0
        line_num = self.num

        # count the number of blank lines after '.endproc'.
        for line in (self.lines[i] for i in range(self.index+1, len(self.lines))):
            if line.type == LineType.BLANK:
                count += 1
                line_num = line.num
            else:
                break
        else:
            # end of file.
            max_count = 0

        # 1 blank line must follow procedures that tail branch or fall through.
        # 2 blank lines must follow procedures that tail jump or return.
        if count < max_count:
            self.warn(f'Too few blank lines. Found {count}, Expected {max_count}.', line_num)
        if count > max_count:
            self.warn(f'Too many blank lines. Found {count}, Expected {max_count}.', line_num)


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


    def lint_command_define(self):
        """Check .define command rules for the current line."""

        if self.command != '.define':
            return

        # strip off macro value
        name = self.args.split()[0]

        # strip off macro parameters
        name = name.split('(')[0]

        if not self.is_upper_case(name):
            self.warn(f'Define-style macro "{name}" is not upper case.')


    def lint_label(self):
        """Check label rules for the current line."""

        if not self.label:
            return

        linter_tag = self.get_linter_tag()

        # check if we are in a code block.
        if self.block == '.proc' or "CODE" in self.segment:
            # we are in a code block or code segment.
            # labels should be code labels unless a linter tag says otherwise.
            if linter_tag == LinterTag.DATA_LABEL:
                self.lint_label_data()
            else:
                self.lint_label_code()
        else:
            # we are not in a code block nor code segment.
            # labels should be data labels unless a linter tag says otherwise.
            if linter_tag == LinterTag.CODE_LABEL:
                self.lint_label_code()
            else:
                self.lint_label_data()


    def lint_label_code(self):
        """Check code label rules for the current line."""

        # account for cheap local labels.
        if self.label.startswith('@'):
            label = self.label.lstrip('@')
        else:
            label = self.label

        if not self.is_snake_case(label):
            self.warn(f'Code label "{label}" is not snake case.')

        if self.type != LineType.LABEL:
            self.warn('Only comments are allowed after code labels.')


    def lint_label_data(self):
        """Check data label rules for the current line."""

        # this method is kind of a cluster-fuck but it works.
        # pylint: disable=too-many-branches

        # account for cheap local labels.
        if self.label.startswith('@'):
            self.warn(f'Cheap local data label are not allowed.')
            label = self.label.lstrip('@')
        else:
            label = self.label

        prefix, name = self.get_prefix_name(label)

        if not prefix:
            self.warn(f'Data label "{self.label}" has no prefix.')

        if not name:
            self.warn(f'Data label "{self.label}" has no name.')
        elif not self.is_pascal_case(name):
            self.warn(f'Data label "{self.label}" name is not pascal case.')

        label_prefixes = 'rzbwdqasp'

        for char in prefix:
            if char not in label_prefixes:
                self.warn(f'Data label "{self.label}" uses an invalid prefix character "{char}".')

        if len(set(prefix)) != len(prefix):
            self.warn(f'Data label "{self.label}" has repeated prefix characters.')

        prefix_order = iter(label_prefixes)

        # check that prefix characters appear in the right order.
        if not all(any(y == x for y in prefix_order) for x in prefix):
            self.warn(f'Data label "{self.label}" has an incorrect prefix order.')

        # these prefixes are mutually exclusive
        type_prefix = {
            'b': 'byte',
            'w': 'word',
            'd': 'double word',
            'q': 'quad word',
            's': 'string',
        }

        # check if the label contains mutually exclusive prefixes.
        prefixes = [char for char in type_prefix if char in prefix]
        prefixes_len = len(prefixes)

        msg = f'Data label "{self.label}" is prefixed with mutually exclusive types'

        if prefixes_len > 1:
            types = ', '.join(type_prefix[prefixes[:-1]])

            if prefixes_len > 2:
                types = types + ','

            types = types + f' and {type_prefix[prefixes[-1]]}'
            self.warn(f'{msg} {types}.')

        # check if the label is prefixed as a string array.
        # this is disallowed because a sting array could be ambiguous.
        # i.e. an array of C strings or an array of string pointers.
        # in either case, only an array prefix should be used.
        if all(c in prefix for c in 'sa'):
            self.warn(f'{msg} string and array.')

        # data labels have extra rules based on the segment type.
        if self.segment_type == SegmentType.ZP and 'z' not in prefix:
            self.warn(f'Zero-page data label "{self.label}" missing zero-page prefix.')

        if self.segment_type != SegmentType.ZP and 'z' in prefix:
            self.warn(f'Non-zero-page data label "{self.label}" prefixed as zero-page.')

        if self.segment_type == SegmentType.RO and 'r' not in prefix:
            self.warn(f'Read-only data label "{self.label}" missing read-only prefix.')

        # writable data is allowed to be prefixed as read-only.
        # that is useful for exported variables
        # which should be treated as read-only by the importer.


    def lint_symbol(self):
        """Check symbol rules for the current line."""

        if self.type != LineType.SYMBOL:
            return

        if not self.is_upper_case(self.instr):
            self.warn(f'Symbol "{self.instr}" is not upper case.')


    def lint_mnemonic(self):
        """Check mnemonic rules for the current line."""

        if self.type != LineType.MNEMONIC:
            return

        if self.block != '.proc':
            self.warn('Found mnemonic outside of ".proc" block.')

        if not self.instr.islower():
            self.warn('Mnemonic should be lower case.')

        if self.mnemonic in BRANCHES and not self.comment:
            self.cry('Branch mnemonic missing inline comment.')

        magic = self.get_magic_numbers()

        for num in magic:
            self.cry(f'Magic number "{num}" in mnemonic arguments.')

        # the last rule only applies to 'jsr' mnemonics.
        if self.mnemonic != 'jsr':
            return

        # line types to ignore while looking ahead in the file
        ignore_line_types = (
            LineType.BLANK,
            LineType.WHITESPACE,
            LineType.COMMENT,
            LineType.SYMBOL,
        )

        # look ahead for a 'rts' mnemonic to find unoptimized tail calls.
        for line in (self.lines[i] for i in range(self.index + 1, len(self.lines))):
            # these lines wouldn't interfere with optimizing a tail call.
            if line.type in ignore_line_types:
                continue

            if line.type == LineType.MNEMONIC:
                mnemonic = line.tokens.instr.lower()

                if mnemonic == 'rts':
                    self.warn('Unoptimized tail call.')

            break


    def lint_macro(self):
        """Check macro rules for the current line."""

        # too lazy to fix this.
        # pylint: disable=too-many-branches

        if self.type != LineType.MACRO:
            return

        if self.block == '.enum':
            # enum values get classified as macros.
            # these should be upper case.
            if not self.is_upper_case(self.instr):
                self.warn(f'Enum value "{self.instr}" is not upper case.')
        elif self.block in ('.struct', '.union'):
            # struct and union attributes get classified as macros.
            # these have similar rules to data labels.
            prefix, name = self.get_prefix_name(self.instr)

            if not prefix:
                self.warn(f'Attribute "{self.instr}" has no prefix.')

            if not name:
                self.warn(f'Attribute "{self.instr}" has no name.')
            elif not self.is_pascal_case(name):
                self.warn(f'Attribute "{self.instr}" name is not pascal case.')

            attr_prefixes = 'bwdqasp'

            for char in prefix:
                if char not in attr_prefixes:
                    self.warn((f'Attribute "{self.instr}" '
                        'uses an invalid prefix character "{char}".'))

            if len(set(prefix)) != len(prefix):
                self.warn(f'Attribute "{self.instr}" has repeated prefix characters.')

            prefix_order = iter(attr_prefixes)

            # check that prefix characters appear in the right order.
            if not all(any(y == x for y in prefix_order) for x in prefix):
                self.warn(f'Attribute "{self.instr}" has an incorrect prefix order.')

            # these prefixes are mutually exclusive
            type_prefix = {
                'b': 'byte',
                'w': 'word',
                'd': 'double word',
                'q': 'quad word',
                's': 'string',
            }

            # check if the attribute contains mutually exclusive prefixes.
            prefixes = [char for char in type_prefix if char in prefix]
            prefixes_len = len(prefixes)

            msg = f'Attribute "{self.instr}" is prefixed with mutually exclusive types'

            if prefixes_len > 1:
                types = ', '.join(type_prefix[prefixes[:-1]])

                if prefixes_len > 2:
                    types = types + ','

                types = types + f' and {type_prefix[prefixes[-1]]}'
                self.warn(f'{msg} {types}.')

            # check if the attribute is prefixed as a string array.
            # this is disallowed because a sting array could be ambiguous.
            # i.e. an array of C strings or an array of string pointers.
            # in either case, only an array prefix should be used.
            if all(c in prefix for c in 'sa'):
                self.warn(f'{msg} string and array.')

            # the 's' prefix is pulling double duty for strings and structs.
            # in context, the difference should be clear.
        else:
            if not self.is_snake_case(self.instr):
                self.warn(f'Macro name "{self.instr}" is not snake case.')

            magic = self.get_magic_numbers()

            for num in magic:
                self.cry(f'Magic number "{num}" in macro arguments.')

    def lint_args(self):
        """Check argument rules for the current line."""

        # we're just going to search for commands in arguments and check some basic rules.
        # this will probably be good enough to catch common errors.

        # pattern match ca65 commands in arguments.
        commands = re.findall(r'(\.[a-zA-Z0-9]+)', self.args)

        # filter matches down to valid commands.
        commands = [c for c in commands if c.lower() in COMMANDS]

        for command in commands:
            if not command.islower():
                self.warn(f'Command "{command}" should be lowercase.')

            alias = self.get_command_alias(command)

            if alias:
                self.warn(f'Illegal command "{command}". Use "{alias}" instead.')



    def lint_comment(self):
        """Check comment rules for the current line."""

        if not self.comment:
            return

        regex = r'^;\s*(TODO|NOTE):\s*(.*?)\s*'
        matches = re.fullmatch(regex, self.comment, re.IGNORECASE)

        if not matches:
            return

        comment_data = []
        comment_type, content = matches.groups()
        comment_data.append(content)

        # comments may span multiple lines.
        # gather those lines and join them together.
        for index in range(self.index+1, len(self.lines)):
            # get the next line.
            line = self.lines[index]

            # the line must contain only a comment.
            if line.type != LineType.COMMENT:
                break

            line_comment = line.tokens.comment

            # check if this line starts a new TODO or NOTE comment.
            if re.match(r'^;\s*(TODO|NOTE)', line_comment, re.IGNORECASE):
                break

            # this should always match. no need to check the return value.
            matches = re.fullmatch(r'^;\s*(.*?)\s*', line_comment)

            content = matches.group(1)
            comment_data.append(content)

        full_comment = ' '.join(comment_data)

        if comment_type.upper() == 'TODO':
            self.warn(f'TODO: {full_comment}')
        else: # NOTE
            self.cry(f'NOTE: {full_comment}')


def main(linker_config_path, source_path, strict=False):
    """Entry point for this script."""

    with open(linker_config_path, 'r', encoding='utf-8', newline='') as linker_file:
        linker_config = LinkerConfig(linker_file)

    with open(source_path, 'r', encoding='utf-8', newline='') as source_file:
        linter = Linter(linker_config, source_file, strict)

    for warning in linter.warnings:
        print(f'{source_path}{warning}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Lint a 6502 assembly file written with ca65 syntax.')

    parser.add_argument('linker_config_path',
        help='path to the cl65 linker config file for the project')
    parser.add_argument('source_path',
        help='path to a ca65 *.s or *.inc source file to lint')
    parser.add_argument('-s', '--strict',
        help='enable stricter linting rules',
        action='store_true')

    args = parser.parse_args()

    main(args.linker_config_path, args.source_path, args.strict)
