#!/usr/bin/env python
'''
This is a script for checking that the Semigroups package is releasable, i.e.
that it passes all the tests in all configurations.
'''

#TODO verbose mode

import textwrap, os, argparse, tempfile, subprocess, sys, os, signal, dots

################################################################################
# Strings for printing
################################################################################

_WRAPPER = textwrap.TextWrapper(break_on_hyphens=False, width=80)

def _red_string(string, wrap=True):
    'red string'
    if wrap:
        return '\n        '.join(_WRAPPER.wrap('\033[31m' + string + '\033[0m'))
    else:
        return '\033[31m' + string + '\033[0m'

def _green_string(string):
    'green string'
    return '\n        '.join(_WRAPPER.wrap('\033[32m' + string + '\033[0m'))

def _cyan_string(string):
    'cyan string'
    return '\n        '.join(_WRAPPER.wrap('\033[36m' + string + '\033[0m'))

def _blue_string(string):
    'blue string'
    return '\n        '.join(_WRAPPER.wrap('\033[44m' + string + '\033[0m'))

def _magenta_string(string):
    'magenta string'
    return '\n        '.join(_WRAPPER.wrap('\033[35m' + string + '\033[0m'))

_MAGENTA_DOT = _magenta_string('. ')
_CYAN_DOT = _cyan_string('. ')

def hide_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()

def show_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

################################################################################
# Parse the arguments
################################################################################

_LOG_NR = 0

def _run_gap(gap_root, verbose=False):
    'returns the bash script to run GAP and detect errors'
    out = gap_root + 'bin/gap.sh -r -A -T -m 1g'
    if not verbose:
        out += ' -q'
    return out

def _log_file(tmp_dir):
    'returns the string "LogTo(a unique file);"'
    global _LOG_NR
    _LOG_NR += 1
    log_file = os.path.join(tmp_dir, 'test-' + str(_LOG_NR) + '.log')
    return log_file

################################################################################
# Functions
################################################################################

def _run_test(gap_root, message, stop_for_diffs, *arg):
    '''echo the GAP commands in the string <commands> into _GAPTest, after
       printing the string <message>.'''

    dots.dotIt(_MAGENTA_DOT, _run_test_base, gap_root, message,
               stop_for_diffs, *arg)

def _run_test_base (gap_root, message, stop_for_diffs, *arg):
    hide_cursor()
    print _pad(_magenta_string(message + ' . . . ')),
    sys.stdout.flush()

    tmpdir = tempfile.mkdtemp()
    log_file = _log_file(tmpdir)
    commands = 'echo "LogTo(\\"' + log_file + '\\");\n' + '\n'.join(arg) + '"'
    pro1 = subprocess.Popen(commands,
                            stdout=subprocess.PIPE,
                            shell=True)
    try:
        devnull = open(os.devnull, 'w')
        pro2 = subprocess.Popen(_run_gap(gap_root),
                                stdin=pro1.stdout,
                                stdout=devnull,
                                stderr=devnull,
                                shell=True)
        pro2.wait()
    except KeyboardInterrupt:
        pro1.terminate()
        pro1.wait()
        pro2.terminate()
        pro2.wait()
        show_cursor()
        print _red_string('Killed!')
        sys.exit(1)
    except subprocess.CalledProcessError:
        print _red_string('FAILED!')
        if stop_for_diffs:
            show_cursor()
            sys.exit(1)

    try:
        log = open(log_file, 'r').read()
    except IOError:
        sys.exit(_red_string('test.py: error: ' + log_file + ' not found!'))

    if len(log) == 0:
        print _red_string('test.py: warning: ' + log_file + ' is empty!')

    if (log.find('########> Diff') != -1
            or log.find('# WARNING') != -1
            or log.find('#E ') != -1
            or log.find('Error') != -1
            or log.find('brk>') != -1
            or log.find('LoadPackage("semigroups", false);\nfail') != -1):
        print _red_string('FAILED!')
        for line in open(log_file, 'r').readlines():
            print _red_string(line.rstrip(), False)
        if stop_for_diffs:
            show_cursor()
            sys.exit(1)
    show_cursor()
    print ''

################################################################################

def _get_ready_to_make(pkg_dir, package_name):
    os.chdir(pkg_dir)
    package_dir = None
    for pkg in os.listdir(pkg_dir):
        if os.path.isdir(pkg) and pkg.startswith(package_name):
            package_dir = pkg

    if not package_dir:
        sys.exit(_red_string('test.py: error: can\'t find the ' + package_name
                             + ' directory'))
    os.chdir(package_dir)

################################################################################

def _exec(command):
    try: #FIXME use popen here
        pro = subprocess.call(command + ' &> /dev/null',
                              shell=True)
    except KeyboardInterrupt:
        os.kill(pro.pid, signal.SIGKILL)
        print _red_string('Killed!')
        sys.exit(1)
    except subprocess.CalledProcessError:
        sys.exit(_red_string('test.py: error: ' + command + ' failed!!'))

################################################################################

def _make_clean(gap_root, name):
    hide_cursor()
    print _cyan_string(_pad('Deleting ' + name + ' binary') + ' . . . '),
    cwd = os.getcwd()
    sys.stdout.flush()
    _get_ready_to_make(gap_root, name)
    _exec('make clean')
    os.chdir(cwd)
    print ''
    show_cursor()

################################################################################

def _configure_make(directory, name):
    hide_cursor()
    print _cyan_string(_pad('Compiling ' + name) + ' . . . '),
    cwd = os.getcwd()
    sys.stdout.flush()
    _get_ready_to_make(directory, name)
    _exec('./configure')
    _exec('make')
    os.chdir(cwd)
    print ''
    show_cursor()

################################################################################

def _man_ex_str(gap_root, name):
    return ('ex := ExtractExamples(\\"'  + gap_root + 'doc/ref\\", \\"'
            + name + '\\", [\\"' + name + '\\"], \\"Section\\");' +
            ' RunExamples(ex);')

def _pad(string, extra=0):
    for i in xrange(extra + 27 - len(string)):
        string += ' '
    return string

################################################################################
# the GAP commands to run the tests
################################################################################

_LOAD = 'LoadPackage(\\"semigroups\\", false);'
_LOAD_SMALLSEMI = 'LoadPackage(\\"smallsemi\\", false);'
_LOAD_ONLY_NEEDED = 'LoadPackage(\\"semigroups\\", false : OnlyNeeded);'
_TEST_STANDARD = 'SemigroupsTestStandard();'
_TEST_INSTALL = 'SemigroupsTestInstall();'
_TEST_ALL = 'SemigroupsTestAll();'
_TEST_SMALLSEMI = 'SmallsemiTestAll();\n SmallsemiTestManualExamples();'
_TEST_MAN_EX = 'SemigroupsTestManualExamples();'
_MAKE_DOC = 'SemigroupsMakeDoc();'

def _validate_package_info(gap_root, pkg_name):
    return ('ValidatePackageInfo(\\"' + gap_root +
            'pkg/' + pkg_name + '/PackageInfo.g\\");')

def _test_gap_quick(gap_root):

    string = 'Test(\\"' + gap_root + 'tst/testinstall/trans.tst\\");'
    string += 'Test(\\"' + gap_root + 'tst/testinstall/pperm.tst\\");'
    string += 'Test(\\"' + gap_root + 'tst/testinstall/semigrp.tst\\");'
    string += 'Test(\\"' + gap_root + 'tst/teststandard/reesmat.tst\\");'
    string += _man_ex_str(gap_root, 'trans.xml')
    string += _man_ex_str(gap_root, 'pperm.xml')
    string += _man_ex_str(gap_root, 'invsgp.xml')
    string += _man_ex_str(gap_root, 'reesmat.xml')
    string += _man_ex_str(gap_root, 'mgmadj.xml')
    string += 'Test(\\"' + gap_root + 'tst/teststandard/bugfix.tst\\");'
    string += 'Read(\\"' + gap_root + 'tst/testinstall.g\\");'

    return string

############################################################################
# Run the tests
############################################################################

def semigroups_make_doc(gap_root):
    _run_test(gap_root, 'Compiling the doc          ', True, _LOAD, _MAKE_DOC)

def run_semigroups_tests(gap_root, pkg_dir, pkg_name):

    #print '\033[35musing temporary directory: ' + tmpdir + '\033[0m'
    print ''
    print _blue_string(_pad('Running tests in ' + gap_root))

    _run_test(gap_root,
              'Validating PackageInfo.g   ',
              True,
              _validate_package_info(gap_root, pkg_name))
    _run_test(gap_root, 'Loading package            ', True, _LOAD)
    _run_test(gap_root, 'Loading only needed        ', True, _LOAD_ONLY_NEEDED)
    _run_test(gap_root, 'Loading Smallsemi first    ', True, _LOAD_SMALLSEMI, _LOAD)
    _run_test(gap_root, 'Loading Smallsemi second   ', True, _LOAD, _LOAD_SMALLSEMI)

    _make_clean(pkg_dir, 'grape')
    _run_test(gap_root, 'Loading Grape not compiled ', True, _LOAD)

    dots.dotIt(_CYAN_DOT, _configure_make, pkg_dir, 'grape')
    _run_test(gap_root, 'Loading Grape compiled     ', True, _LOAD)

    _make_clean(pkg_dir, 'orb')
    _run_test(gap_root, 'Loading Orb not compiled   ', True, _LOAD)

    dots.dotIt(_CYAN_DOT, _configure_make, pkg_dir, 'orb')
    _run_test(gap_root, 'Loading Orb compiled       ', True, _LOAD)

    _run_test(gap_root, 'Compiling the doc          ', True, _LOAD, _MAKE_DOC)
    _run_test(gap_root, 'Testing Smallsemi          ',
              True,
              _LOAD,
              _LOAD_SMALLSEMI,
              _TEST_SMALLSEMI)

    print ''
    print _blue_string('Testing with Orb compiled')
    _run_test(gap_root, 'testinstall.tst            ', True, _LOAD, _TEST_INSTALL)
    _run_test(gap_root, 'manual examples            ', True, _LOAD, _TEST_MAN_EX)
    _run_test(gap_root, 'test standard              ', True, _LOAD, _TEST_STANDARD)
    _run_test(gap_root, 'GAP quick tests            ', False, _LOAD,
              _test_gap_quick(gap_root))

    print ''
    print _blue_string('Testing with Orb uncompiled')
    _make_clean(pkg_dir, 'orb')
    _run_test(gap_root, 'testinstall.tst            ', True, _LOAD, _TEST_INSTALL)
    _run_test(gap_root, 'manual examples            ', True, _LOAD, _TEST_MAN_EX)
    _run_test(gap_root, 'test standard              ', True, _LOAD, _TEST_STANDARD)
    _run_test(gap_root, 'GAP quick tests            ', False, _LOAD,
              _test_gap_quick(gap_root))
    dots.dotIt(_CYAN_DOT, _configure_make, pkg_dir, 'orb')

    print ''
    print _blue_string('Testing only needed')
    _run_test(gap_root, 'testinstall.tst            ', True, _LOAD_ONLY_NEEDED,
              _TEST_INSTALL)
    _run_test(gap_root, 'manual examples            ', True, _LOAD_ONLY_NEEDED,
              _TEST_MAN_EX)
    _run_test(gap_root, 'test standard              ', True, _LOAD_ONLY_NEEDED,
              _TEST_STANDARD)
    _run_test(gap_root, 'GAP quick tests            ', False, _LOAD,
              _test_gap_quick(gap_root))

    print '\n\033[32mSUCCESS!\033[0m'
    return

################################################################################
# Run the script
################################################################################

def main():
    parser = argparse.ArgumentParser(prog='test.py',
                                     usage='%(prog)s [options]')
    parser.add_argument('--gap-root', nargs='?', type=str,
                        help='the gap root directory (default: ~/gap)',
                        default='~/gap/')
    parser.add_argument('--pkg-dir', nargs='?', type=str,
                        help='the pkg directory (default: gap-root/pkg/)',
                        default='~/gap/pkg/')
    parser.add_argument('--pkg-name', nargs='?', type=str,
                        help='the pkg name (default: semigroups)',
                        default='semigroups')
    parser.add_argument('--verbose', dest='verbose', action='store_true',
                        help='verbose mode (default: False)')
    parser.set_defaults(verbose=False)

    args = parser.parse_args()

    if not args.gap_root[-1] == '/':
        args.gap_root += '/'
    if not args.pkg_dir[-1] == '/':
        args.pkg_dir += '/'

    args.gap_root = os.path.expanduser(args.gap_root)
    args.pkg_dir = os.path.expanduser(args.pkg_dir)

    if not (os.path.exists(args.gap_root) and os.path.isdir(args.gap_root)):
        sys.exit(_red_string('release.py: error: can\'t find GAP root' +
                             ' directory!'))
    if not (os.path.exists(args.pkg_dir) or os.path.isdir(args.pkg_dir)):
        sys.exit(_red_string('test.py: error: can\'t find package' +
                             ' directory!'))

    run_semigroups_tests(args.gap_root, args.pkg_dir, args.pkg_name)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print _red_string('Killed!')
        sys.exit(1)
