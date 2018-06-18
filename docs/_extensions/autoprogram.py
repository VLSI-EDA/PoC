"""
    sphinxcontrib.autoprogram
    ~~~~~~~~~~~~~~~~~~~~~~~~~

    Documenting CLI programs.

    :copyright: Copyright 2014 by Hong Minhee
    :license: BSD, see LICENSE for details.

"""
# pylint: disable=protected-access,missing-docstring
import argparse
import collections
import os
import re
import sys
import unittest

from docutils import nodes
from docutils.parsers.rst import Directive
from docutils.parsers.rst.directives import unchanged
from docutils.statemachine import StringList, ViewList
from six import exec_
from six.moves import builtins, reduce
from sphinx.domains import std
from sphinx.util.nodes import nested_parse_with_titles

__all__ = ('AutoprogramDirective',
           'AutoprogramDirectiveTestCase', 'ScannerTestCase',
           'import_object', 'scan_programs', 'setup', 'suite')


def get_subparser_action(parser):
    neg1_action = parser._actions[-1]

    if isinstance(neg1_action, argparse._SubParsersAction):
        return neg1_action

    for a in parser._actions:
        if isinstance(a, argparse._SubParsersAction):
            return a


def scan_programs(parser, command=[], maxdepth=0, depth=0, groups=False):
    if maxdepth and depth >= maxdepth:
        return

    if groups:
        yield command, [], parser
        for group in parser._action_groups:
            options = list(scan_options(group._group_actions))
            if options:
                yield command, options, group
    else:
        options = list(scan_options(parser._actions))
        yield command, options, parser

    if parser._subparsers:
        choices = ()

        subp_action = get_subparser_action(parser)

        if subp_action:
            choices = subp_action.choices.items()

        if not (hasattr(collections, 'OrderedDict') and
                isinstance(choices, collections.OrderedDict)):
            choices = sorted(choices, key=lambda pair: pair[0])

        for cmd, sub in choices:
            if isinstance(sub, argparse.ArgumentParser):
                for program in scan_programs(
                    sub, command + [cmd], maxdepth, depth + 1
                ):
                    yield program


def scan_options(actions):
    for arg in actions:
        if not (arg.option_strings or
                isinstance(arg, argparse._SubParsersAction)):
            yield format_positional_argument(arg)

    for arg in actions:
        if arg.option_strings and arg.help is not argparse.SUPPRESS:
            yield format_option(arg)


def format_positional_argument(arg):
    desc = (arg.help or '') % {'default': arg.default}
    name = (arg.metavar or arg.dest).lower()
    return [name], desc


def format_option(arg):
    desc = (arg.help or '') % {'default': arg.default}

    if not isinstance(arg, (argparse._StoreAction, argparse._AppendAction)):
        names = list(arg.option_strings)
        return names, desc

    if arg.choices is not None:
        value = '{{{0}}}'.format(','.join(arg.choices))
    else:
        metavar = arg.metavar or arg.dest
        if not isinstance(metavar, tuple):
            metavar = metavar,
        value = '<{0}>'.format('> <'.join(metavar).lower())

    names = ['{0} {1}'.format(option_string, value)
             for option_string in arg.option_strings]

    return names, desc



def import_object(import_name):
    module_name, expr = import_name.split(':', 1)
    try:
        mod = __import__(module_name)
    except ImportError:
        # This happens if the file is a script with no .py extension. Here we
        # trick autoprogram to load a module in memory with the contents of
        # the script, if there is a script named module_name. Otherwise, raise
        # an ImportError as it did before.
        import glob
        import sys
        import os
        import imp

        for p in sys.path:
            f = glob.glob(os.path.join(p, module_name))
            if len(f) > 0:
                with open(f[0]) as fobj:
                    codestring = fobj.read()
                foo = imp.new_module("foo")
                exec_(codestring, foo.__dict__)

                sys.modules["foo"] = foo
                mod = __import__("foo")
                break
        else:
            raise ImportError("No module named {}".format(module_name))

    mod = reduce(getattr, module_name.split('.')[1:], mod)
    globals_ = builtins
    if not isinstance(globals_, dict):
        globals_ = globals_.__dict__
    return eval(expr, globals_, mod.__dict__)


class AutoprogramDirective(Directive):

    has_content = False
    required_arguments = 1
    option_spec = {
        'prog': unchanged,
        'maxdepth': unchanged,
        'start_command': unchanged,
        'strip_usage': unchanged,
        'no_usage_codeblock': unchanged,
        'groups': unchanged,
    }

    def make_rst(self):
        import_name, = self.arguments
        parser = import_object(import_name or '__undefined__')
        prog = self.options.get('prog')
        if prog:
            original_prog = parser.prog
            parser.prog = prog
        start_command = self.options.get('start_command', '').split(' ')
        strip_usage = 'strip_usage' in self.options
        usage_codeblock = 'no_usage_codeblock' not in self.options
        maxdepth = int(self.options.get('maxdepth', 0))
        groups = 'groups' in self.options

        if start_command[0] == '':
            start_command.pop(0)

        if start_command:
            def get_start_cmd_parser(p):
                looking_for = start_command.pop(0)
                action = get_subparser_action(p)

                if not action:
                    raise ValueError('No actions for command ' + looking_for)

                subp = action.choices[looking_for]

                if start_command:
                    return get_start_cmd_parser(subp)

                return subp

            parser = get_start_cmd_parser(parser)
            if prog and parser.prog.startswith(original_prog):
                parser.prog = parser.prog.replace(original_prog, prog, 1)

        for commands, options, group_or_parser in scan_programs(
            parser, maxdepth=maxdepth, groups=groups
        ):
            if isinstance(group_or_parser, argparse._ArgumentGroup):
                title = group_or_parser.title
                description = group_or_parser.description
                usage = None
                epilog = None
                is_subgroup = True
                is_program = False
            else:
                cmd_parser = group_or_parser
                if prog and cmd_parser.prog.startswith(original_prog):
                    cmd_parser.prog = cmd_parser.prog.replace(
                        original_prog, prog, 1)
                title = cmd_parser.prog.rstrip()
                description = cmd_parser.description
                usage = cmd_parser.format_usage()
                epilog = cmd_parser.epilog
                is_subgroup = bool(commands)
                is_program = True

            for line in render_rst(title, options,
                                   is_program=is_program,
                                   is_subgroup=is_subgroup,
                                   description=description,
                                   usage=usage,
                                   usage_strip=strip_usage,
                                   usage_codeblock=usage_codeblock,
                                   epilog=epilog):
                yield line

    def run(self):
        node = nodes.section()
        node.document = self.state.document
        result = ViewList()
        for line in self.make_rst():
            result.append(line, '<autoprogram>')
        nested_parse_with_titles(self.state, result, node)
        return node.children


def render_rst(title, options, is_program, is_subgroup, description,
               usage, usage_strip, usage_codeblock, epilog):
    if usage_strip:
        to_strip = title.rsplit(' ', 1)[0]
        len_to_strip = len(to_strip) - 4
        usage_lines = usage.splitlines()

        usage = os.linesep.join([
            usage_lines[0].replace(to_strip, '...'),
        ] + [
            l[len_to_strip:] for l in usage_lines[1:]
        ])

    yield ''

    if is_program:
        yield '.. program:: ' + title
        yield ''

    yield title
    yield ('!' if is_subgroup else '?') * len(title)
    yield ''

    for line in (description or '').splitlines():
        yield line
    yield ''

    if usage is None:
        pass
    elif usage_codeblock:
        yield '.. code-block:: console'
        yield ''
        for usage_line in usage.splitlines():
            yield '   ' + usage_line
    else:
        yield usage

    yield ''

    for option_strings, help_ in options:
        yield '.. option:: {0}'.format(', '.join(option_strings))
        yield ''
        yield '   ' + help_.replace('\n', '   \n')
        yield ''

    for line in (epilog or '').splitlines():
        yield line or ''


def patch_option_role_to_allow_argument_form():
    """Before Sphinx 1.2.2, :rst:dir:`.. option::` directive hadn't
    allowed to not start with a dash or slash, so it hadn't been possible
    to represent positional arguments (not options).

    https://bitbucket.org/birkenfeld/sphinx/issue/1357/

    It monkeypatches the :rst:dir:`.. option::` directive's behavior.

    """
    std.option_desc_re = re.compile(r'((?:/|-|--)?[-_a-zA-Z0-9]+)(\s*.*)')


def setup(app):
    app.add_directive('autoprogram', AutoprogramDirective)
    patch_option_role_to_allow_argument_form()


class ScannerTestCase(unittest.TestCase):

    def test_simple_parser(self):
        parser = argparse.ArgumentParser(description='Process some integers.')
        parser.add_argument('integers', metavar='N', type=int, nargs='*',
                            help='an integer for the accumulator')
        parser.add_argument('-i', '--identity', type=int, default=0,
                            help='the default result for no arguments '
                                 '(default: 0)')
        parser.add_argument('--sum', dest='accumulate', action='store_const',
                            const=sum, default=max,
                            help='sum the integers (default: find the max)')
        parser.add_argument('--key-value', metavar=('KEY', 'VALUE'), nargs=2)
        parser.add_argument('--max', help=argparse.SUPPRESS)  # must be opt-out

        programs = scan_programs(parser)
        programs = list(programs)
        self.assertEqual(1, len(programs))
        parser_info, = programs
        program, options, cmd_parser = parser_info
        self.assertEqual([], program)
        self.assertEqual('Process some integers.', cmd_parser.description)
        self.assertEqual(5, len(options))
        self.assertEqual(
            (['n'], 'an integer for the accumulator'),
            options[0]
        )
        self.assertEqual(
            (['-h', '--help'], 'show this help message and exit'),
            options[1]
        )
        self.assertEqual(
            (['-i <identity>', '--identity <identity>'],
             'the default result for no arguments (default: 0)'),
            options[2]
        )
        self.assertEqual(
            (['--sum'], 'sum the integers (default: find the max)'),
            options[3]
        )
        self.assertEqual(
            (['--key-value <key> <value>', ], ''),
            options[4]
        )

    def test_subcommands(self):
        parser = argparse.ArgumentParser(description='Process some integers.')
        subparsers = parser.add_subparsers()
        max_parser = subparsers.add_parser('max', description='Find the max.')
        max_parser.set_defaults(accumulate=max)
        max_parser.add_argument('integers', metavar='N', type=int, nargs='+',
                                help='An integer for the accumulator.')
        sum_parser = subparsers.add_parser('sum',
                                           description='Sum the integers.')
        sum_parser.set_defaults(accumulate=sum)
        sum_parser.add_argument('integers', metavar='N', type=int, nargs='+',
                                help='An integer for the accumulator.')
        programs = scan_programs(parser)
        programs = list(programs)
        self.assertEqual(3, len(programs))
        # main
        program, options, cmd_parser = programs[0]
        self.assertEqual([], program)
        self.assertEqual('Process some integers.', cmd_parser.description)
        self.assertEqual(1, len(options))
        self.assertEqual(
            (['-h', '--help'],
             'show this help message and exit'),
            options[0]
        )
        # max
        program, options, cmd_parser = programs[1]
        self.assertEqual(['max'], program)
        self.assertEqual('Find the max.', cmd_parser.description)
        self.assertEqual(2, len(options))
        self.assertEqual((['n'], 'An integer for the accumulator.'),
                         options[0])
        self.assertEqual(
            (['-h', '--help'],
             'show this help message and exit'),
            options[1]
        )
        # sum
        program, options, cmd_parser = programs[2]
        self.assertEqual(['sum'], program)
        self.assertEqual('Sum the integers.', cmd_parser.description)
        self.assertEqual(2, len(options))
        self.assertEqual((['n'], 'An integer for the accumulator.'),
                         options[0])

    def test_argument_groups(self):
        parser = argparse.ArgumentParser(description='This is a program.')
        parser.add_argument('-v', action='store_true',
                            help='A global argument')
        plain_group = parser.add_argument_group('Plain Options',
                                                description='This is a group.')
        plain_group.add_argument('--plain', action='store_true',
                                 help='A plain argument.')
        fancy_group = parser.add_argument_group('Fancy Options',
                                                description='Another group.')
        fancy_group.add_argument('fancy', type=int, help='Set the fancyness')

        sections = list(scan_programs(parser, groups=True))
        self.assertEqual(4, len(sections))

        # section: unnamed
        program, options, cmd_parser = sections[0]
        self.assertEqual([], program)
        self.assertEqual('This is a program.', cmd_parser.description)
        self.assertEqual(0, len(options))

        # section: default optionals
        program, options, group = sections[1]
        self.assertEqual([], program)
        self.assertEqual('optional arguments', group.title)
        self.assertEqual(None, group.description)
        self.assertEqual(2, len(options))
        self.assertEqual((['-h', '--help'], 'show this help message and exit'),
                         options[0])
        self.assertEqual((['-v'], 'A global argument'), options[1])

        # section: Plain Options
        program, options, group = sections[2]
        self.assertEqual([], program)
        self.assertEqual('Plain Options', group.title)
        self.assertEqual('This is a group.', group.description)
        self.assertEqual(1, len(options))
        self.assertEqual((['--plain'], 'A plain argument.'), options[0])

        # section: Fancy Options
        program, options, group = sections[3]
        self.assertEqual([], program)
        self.assertEqual('Fancy Options', group.title)
        self.assertEqual('Another group.', group.description)
        self.assertEqual(1, len(options))
        self.assertEqual((['fancy'], 'Set the fancyness'), options[0])

    def test_choices(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("--awesomeness", choices=["meh", "awesome"])
        program, options, cmd_parser = list(scan_programs(parser))[0]
        log_option = options[1]
        self.assertEqual((["--awesomeness {meh,awesome}"], ''), log_option)

    def test_parse_epilog(self):
        parser = argparse.ArgumentParser(
            description='Process some integers.',
            epilog='The integers will be processed.'
        )
        programs = scan_programs(parser)
        programs = list(programs)
        self.assertEqual(1, len(programs))
        parser_data, = programs
        program, options, cmd_parser = parser_data
        self.assertEqual('The integers will be processed.', cmd_parser.epilog)


class AutoprogramDirectiveTestCase(unittest.TestCase):

    def setUp(self):
        self.untouched_sys_path = sys.path[:]
        sample_prog_path = os.path.join(os.path.dirname(__file__), '..', 'doc')
        sys.path.insert(0, sample_prog_path)
        self.directive = AutoprogramDirective(
            'autoprogram', ['cli:parser'], {'prog': 'cli.py'},
            StringList([], items=[]), 1, 0,
            '.. autoprogram:: cli:parser\n   :prog: cli.py\n',
            None, None
        )

    def tearDown(self):
        sys.path[:] = self.untouched_sys_path

    def test_make_rst(self):
        """Alt least it shouldn't raise errors during making RST string."""
        list(self.directive.make_rst())


class UtilTestCase(unittest.TestCase):

    def test_import_object(self):
        cls = import_object('sphinxcontrib.autoprogram:UtilTestCase')
        self.assertTrue(cls is UtilTestCase)
        instance = import_object(
            'sphinxcontrib.autoprogram:UtilTestCase("test_import_object")'
        )
        self.assertIsInstance(instance, UtilTestCase)

    if not hasattr(unittest.TestCase, 'assertIsInstance'):
        def assertIsInstance(self, instance, cls):
            self.assertTrue(isinstance(instance, cls),
                            '{0!r} is not an instance of {1.__module__}.'
                            '{1.__name__}'.format(instance, cls))


suite = unittest.TestSuite()
for test_case in ScannerTestCase, AutoprogramDirectiveTestCase, UtilTestCase:
    suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(test_case))
