RUN VIM TESTS
===============================================================================
_by Ingo Karkat_

MOTIVATION
------------------------------------------------------------------------------

Every script writer knows how tedious it is to update a published plugin. In
addition to the basic functionality, many corner cases (empty line, last line,
etc.) and failures (invalid filename, nomodifiable buffer) need to be tested,
and people use Vim on different platforms (Windows / Linux), UIs (Console /
GUI), with different sets of settings (.vimrc) and other loaded plugins.
There already exist multiple unit test plugins and assertion facilities [1],
and since version 8.0 Vim itself has various assertions (assert\_equal()),
which are good for checking invariants and verifying side effect-free
implementation functions (see https://stackoverflow.com/a/56054542/813602 how
to do this with the assert functions), but it is still hard to verify the
complete plugin functionality because custom commands and mappings typically
change the buffer contents, open additional windows, or produce other side
effects.

This work aims to show that Vim, together with a shell script driver built
around it, allows to write succinct, fully automated regression test suites
through a combination of these verification methods:
- Comparing buffer contents with a predefined nominal file.
- Matching actual Vim message output with a set of expected messages.
- Running unit tests or assertions inside Vim and evaluating the test results.

With this testing framework, Test-Driven Development can finally be practiced
for Vim plugins, too. If you have existing plugins, just add a couple of basic
test cases for a start. Soon, further updates and modifications can be done
much more rapidly with reduced testing effort, and you can finally tackle that
big refactoring that you've been wanting to do all the time, but were too
afraid of because of the testing effort. The author has been following both
approaches with great success.

[1]
- vimUnit (by Staale Flock), [vimscript #1125](http://www.vim.org/scripts/script.php?script_id=1125)
- tAssert (by Tom Link), [vimscript #1730](http://www.vim.org/scripts/script.php?script_id=1730)
- VimTAP (by Meikel Brandmeyer), [vimscript #2213](http://www.vim.org/scripts/script.php?script_id=2213)
- spec.vim (by Tom Link), [vimscript #2580](http://www.vim.org/scripts/script.php?script_id=2580)
- UT (by Luc Hermitte), https://github.com/LucHermitte/vim-UT
- vim-unittest (by h1mesuke), https://github.com/h1mesuke/vim-unittest
- Ultimate Test Utility (by Kevin Biskar), [vimscript #4724](http://www.vim.org/scripts/script.php?script_id=4724) is a pure Vimscript
  implementation providing various test grouping and assertion functions.

### RELATED WORKS

- robot-vim (https://github.com/mrmargolis/robot-vim) by Matt Margolis allows
  to TDD Vim scripts using Ruby scripts that launch Vim instances, pass text,
  execute commands and then run assertions against the buffer text in Ruby.
- vspec ([vimscript #3012](http://www.vim.org/scripts/script.php?script_id=3012)) by Kana Natsuno allows to write tests BDD-style with
  custom matchers, and is driven by a small Bash script.
- Vader ([vimscript #4832](http://www.vim.org/scripts/script.php?script_id=4832)) by Junegunn Choi implements BDD-style testing from
  within Vim via a test script in a custom syntax.
- doctest ([vimscript #4998](http://www.vim.org/scripts/script.php?script_id=4998)) embeds test expressions as comments in a
  Vimscript, and provides a :DocTest command to execute them.
- stunter.vim ([vimscript #5585](http://www.vim.org/scripts/script.php?script_id=5585)) is sourced inside a test script, offers a
  simple Test() assertion and finally prints test results in a TAP-like format
  within Vim.
- VRoom (https://github.com/google/vroom) is a Python-based runner that
  executes test scripts that specify Vim commands and can verify buffer
  contents, messages, and more, by launching a Vim server.

DESCRIPTION
------------------------------------------------------------------------------

runVimTests implements a testing framework for Vim.

Similar to the tests that are part of Vim's source distribution, each test
consists of a testXXX.vim file which is executed in a a separate Vim instance.
The outcome of a test can be determined by a combination of the following
methods:

### SAVED BUFFER OUTPUT
If a testXXX.ok file is provided, the testXXX.vim should save a testXXX.out
file at the end of its execution. The contents of the testXXX.out test file
must be identical to the provided testXXX.ok file for the test to succeed. The
test can either generate the test output itself, or start by editing a
testXXX.in (or similar) file and doing modifications to it.
Use this method to test commands or mappings that modify buffer contents.

### CAPTURED MESSAGES
If a testXXX.msgok file is provided, the testXXX.vim file should generate Vim
messages (from built-in Vim commands, or via :echo[msg]), which are captured
during test execution in a testXXX.msgout file. The testXXX.msgok file
contains multiple message assertions (separated by empty lines), each of which
is compiled into a Vim regexp and then matched against the captured messages.
Each assertion can match exactly once, and all assertions must match in the
same order in the captured Vim messages. (But there can be additional Vim
messages before, after and in between matches, so that you can omit irrelevant
or platform-specific messages from the testXXX.msgok file.) For details, see
runVimMsgFilter.
This method can verify that errors are reported correctly. Also use this
method to test commands or mappings that print informational messages.

### TAP UNIT TESTS
If a testXXX.tap file exists at the end of a test execution, it is assumed to
represent unit test output in the Test Anything Protocol [2], which is then
parsed and incorporated into the test run. This method allows detailed
verification of custom commands, mappings as well as internal functions; the
entire determination of the test result is done in Vim script. Each TAP unit
test counts as one test, even though all those test results are produced by a
single testXXX.vim file. If a plan announced more or less tests than what was
found in the test output, the test is assumed to be erroneous.
Use this method to test the internal implementation functions, or to verify
things that can be checked easily with Vim script.

[2]
web site: http://testanything.org,
original implementation: http://search.cpan.org/~petdance/TAP-1.00/TAP.pm,
TAP protocol for Vim: http://www.vim.org/scripts/script.php?script_id=2213

A test causes an error if none of these ok-files exist for a test, and no
testXXX.tap file was generated (so actually no verification is possible), or
if the test execution does not produce the corresponding output files.

USAGE
------------------------------------------------------------------------------

    A test run is started through the "runVimTests.(sh|cmd)" script:
        $ runVimTests [{options}] test001.vim|testsuite.txt|path/to/testdir/ [...]

    The tests are specified through these three methods, which can be combined:
    - Directly specify the filespec of testXXX.vim test script file(s).
    - Specify a directory; all *.vim files inside this directory (except for an
      optional special _setup.vim file) will be used as test scripts.
    - A test suite is a text file containing (relative or absolute) filespecs to
      test scripts, directories or other test suites, one filespec per line.
      (Commented lines start with #.)

    The script returns 0 if all tests were successful, 1 if any errors or failures
    occurred, 2 if it wasn't invoked correctly (i.e. bad or missing command-line
    arguments) or prerequisites weren't met, 3 in case of an internal error.

    After test execution, a summary is printed like this:
        20 files with 33 tests; 2 skipped, 27 run: 16 OK, 11 failures, 6 errors.
        Tests with skips: test006.vim
        Skipped tests: test007.vim
            2 SKIP (tap): Need 'autochdir' option
        Failed tests: test002.vim test012.vim test014.vim test022.vim test032.vim
        Tests with errors: test003.vim test013.vim test023.vim test033.vim

    A test is counted as each existing *.[msg]ok file, or by an announcement of
    the planned tests by a TAP test. Tests have "run" when corresponding output
    has been produced. If it hasn't, that's an ERROR, as well as when there were
    neither *.[msg]ok files nor any TAP output, or if the test result evaluation
    had a problem. The result of a correct test evaluation is either OK or FAIL.
    Tests can also SKIP parts of the verification (the test is then listed under
    Tests with skips), or the entire test (this is a Skipped test), e.g. when
    there are missing dependencies or if certain checks aren't implemented for
    that particular platform.

INVOKING
------------------------------------------------------------------------------

The runVimTests script and thus the environment in which the tests are run can
be configured via command-line options.

Additonal Vim scripts can be sourced via the --source {filespec} and --runtime
{filespec} options. (Though it's often better to do this permanently in
\_setup.vim or by sourcing the scripts from within the testXXX.vim. Cp.
runVimTests-setup.)

The Vim executable and version to run the tests can be specified via the
--vimexecutable {path/to/vim} option (on Windows alternatively via
--vimversion {NN}). Without this option, the default "vim" executable as found
in $PATH is used. (You always need this default Vim, even if you specify a
different executable for test execution, because that Vim is used to process
the message output.) The --graphical options uses the GUI version GVIM.

In order to ensure that your script-under-test is compatible with other users'
settings and not dependent on any of your personal settings, it is advisable
to test with the default Vim settings; this is the default behavior. To use no
plugins or all of your user customizations, the plugin load level can be
specified:
    -0 / --pure     Starts Vim without loading any .vimrc and plugins, but in
                    'nocompatible' mode. This is the most pure mode of using
                    Vim.
    -1 / --default  Starts Vim only with default settings and plugins from the
                    system $VIM directory. No user .vimrc or plugins are
                    loaded. This emulates a fresh install of Vim.
    -2 / --user     Starts Vim with user .vimrc and plugins, and thus provides
                    exactly your personal setup you're used to.
Tip: If you want to test with especially unusual or tough settings, put them
into a separate Vim script and use --source to include it in the test run.

Normally, only results of tests that do not succeed are listed, so that you
can quickly focus on the problems. To see the entire test output, specify
option --verbose. On the other hand, if you're only interested in a summary of
the test execution, not in the individual test results, use --summaryonly.

To debug problematic tests, you normally can only inspect the message output
after the fact. By specifying --debug, this option is accessible to the test
via the g:runVimTests variable and can be used to add additional debug
information or to leave the Vim instance running after the test has finished,
so that you can inspect things in the live environment. The vimtest#Quit()
function behaves in exactly this way.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-runVimTests
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This framework is packaged as a ZIP archive. You can unpack it directly into
your-runtime-dir (~/.vim), but you can also install the script executables
somewhere else.

The script executables are in the bin/ subdirectory:

    bin/runVimTests.cmd
    bin/runVimTests.sh
    bin/runVimMsgFilter.vim

They can be put anywhere (preferably somewhere in $PATH for easy invocation).
runVimMsgFilter.vim must be in the same directory as the shell script.

The doc/ subdirectory contains the documentation. Put the files into
~/.vim/doc and execute :helptags ~/.vim/doc to re-generate the help tags.

The autoload/ subdirectory contains optional convenience and helper functions.
(E.g. vimtest#Quit(), vimtest#SaveOut(), vimtest#RequestInput(), and
more. See vimtest-usage for a full reference.)
Their use is not required, but they simplify the writing of tests.

The VimTAP plugin ([vimscript #2213](http://www.vim.org/scripts/script.php?script_id=2213)) needs to be installed separately.
The examples here use the API of version 0.3.0; version 0.4.0 of the plugin
introduced compatibility-breaking changes, which I don't like; the functions
are now cumbersome to use, and the added commands don't offer much
convenience, but pollute the test environment in my opinion. If you like, you
can use my own fork of version 0.3.0; it also has additional assertions:
    https://github.com/inkarkat/VimTAP
Note that nothing prevents you from using the latest, original version for
your own tests. The default runVimTestsSetup.vim will automatically include
VimTAP into 'runtimepath' if it's located in a repository next to runVimTests,
in an adjacent pack plugin tree, or if the environment variable $VIMTAP\_HOME
points to its base directory.

The tests/ subdirectory contains example test suites and a self-test of the
test framework. For a simple sanity check, execute:

    $ runVimTests tests/runVimTests/successful.suite

which should print something like:
```
    9 files with 19 tests; 0 skipped, 19 run: 19 OK, 0 failures, 0 errors.
```
If this is the case, you can start exploring the example tests (in the
tests/example/ subdirectory) or just start writing your own
runVimTests-testscripts!

### DEPENDENCIES

- Requires Vim 7.2 or higher as the default Vim found in $PATH (which is
  always used for the matching of Vim message output against the captured
  messages). You can use a different Vim version to execute the tests, but at
  least Vim 7.0 is required to use captured messages (as this depends on the
  'verbosefile' option) and TAP unit tests (vimtap.vim is an autoload script).
  The saved buffer output method even works with Vim 6, but the driver will
  generate errors in that case.

The Windows version requires (\* = optional) these ported Unix tools:
- grep, sed, diff, sort(\*), uniq(\*)

Windows binaries can be downloaded from the GnuWin32 project:
    http://gnuwin32.sourceforge.net/
These binaries must be accessible through %PATH%. Alternatively, you can just
make accessible an Windows shell script named "unix.cmd", which is then
sourced in order to modify %PATH% to include the Unix tools. This way, you can
avoid to permanently place these Unix tools into %PATH%.

- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.012 or
  higher, only for Vim 7.0 and 7.1.

FRAMEWORK
------------------------------------------------------------------------------

Each testXXX.vim test is executed in a separate Vim process. The test file is
sourced via the |-S|testXXX.vim command-line argument. No filename is passed,
i.e. the test run starts with a single empty buffer. The CWD is always the
test's directory.

The test framework sets these variables within the Vim test process:

The g:runVimTest variable contains the absolute filespec of the currently
executing test (i.e. the same as expand('&lt;sfile&gt;:p')).

The g:runVimTests variable contains the test options for this test run,
concatenated with ",". The test options correspond to the default options and
command-line arguments.
The Vim mode is one of:
    pure    Test without loading .vimrc and plugins.
    default Test without loading user .vimrc and plugins.
    user    (Default) test with user .vimrc and plugins.
In addition, these flags may be set:
    debug   In test debugging mode (runVimTests --debug).

Tests can send signals back to the test framework by echoing a line in the
following format:

    runVimTests: {signal} [{reason}]

Signals are used to skip validations, announce errors or completely bail out
of the test run. The test driver understands these signals; the optional
{reason} is included in the test output and should explain why this signal was
given.
    SKIP            Skip the entire test; all test output should be disregarded.
    SKIP(out)       Disregard the saved buffer output.
    SKIP(msgout)    Disregard the captured messages.
    SKIP(tap)       Disregard the TAP tests.
    ERROR           Signal an error in the test.
    BAILOUT!        All testing on the current level should terminate; no
                    further test scripts from the current directory or test
                    suite should be run.
Though you can simply use :echo to submit a signal, it is recommended to use
the helper functions for vimtest-signals. Multiple signals can be given in
no particular order.

Setup scripts can be sourced automatically by the framework before the
execution of a testXXX.vim test. It is recommended to only do this for
functionality common to ALL tests. Alternatively, you can explicitly source
additional scripts from a testXXX.vim test. Do this if only a few tests
require some additional library functions:

    " buffertest001.vim
    source helpers/listbuffers.vim
    ...
    call IsBufferList(['foo.txt', 'bar.txt'], 'opened all text files')

A global setup script "runVimTestsSetup.vim" can reside in the same directory
as the "runVimTests" shell script. It should contain system-specific setup
code (e.g. if you have set a non-default 'runtimepath' in your .vimrc and you
also want this set when run in pure mode, as your .vimrc isn't sourced then).

A local setup script "\_setup.vim" is sourced if it is found in the
testXXX.vim's directory. You can use this to :source the script under test
and/or source some general helper scripts that all tests in this directory are
using.

TEST SCRIPTS
------------------------------------------------------------------------------

Each test is implemented in a testXXX.vim file. Actually, you can use any
filename with a .vim file extension. You may for example use prefixes like
"basic" or "errorcondition", or structure the tests around "MyCommand",
"MyOtherCommand", etc. By including a number, you establish an execution order
(from simple to more advanced tests), and make it easy to add additional
tests.

Depending on which method(s) shall be used for verification, the tests need
to do the following:

### SAVED BUFFER OUTPUT
Load a predefined test input (e.g. testXXX.in), or start from scratch in the
empty buffer, and make modifications to it. Finally, save the result in
testXXX.out (in the same directory as the test itself). You can do this via
:saveas testXXX.out, but the vimtest#SaveOut() function is more comfortable
and avoids hard-coding of the test name.

    " Test successful saved buffer output.
    normal! iSuccessful execution.
    call vimtest#SaveOut()
    call vimtest#Quit()

In addition, you need to provide a testXXX.ok file to which the output is
compared against:

    Successful execution.

### CAPTURED MESSAGES
Issue :echo  or :echomsg, or execute commands that will cause messages.
The messages are automatically captured in testXXX.msgout.

    " Test successful message output.
    echomsg 'Successful execution.'
    call vimtest#Quit()

In addition, you need to provide a testXXX.msgok file to which the captured
messages are compared against; the runVimMsgFilter also allows to match
against patterns:

    /Successful \([rR]un\|[eE]xecution\)./

### TAP UNIT TESTS
Initialize the TAP testing framework with the output file name testXXX.tap,
submit a plan (i.e. how many tests you intend to run; this is optional, but
highly recommended), execute the test and verify the outcomes with the
TAP-provided functions. The TAP framework will automatically save the TAP
output.

    " Test successful TAP output.
    call vimtest#StartTap()
    call vimtap#Plan(3)
    call vimtap#Ok(1, 'all right')
    call vimtap#Is(1, 1, '1 == 1')
    call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')
    call vimtap#Diag('Some diagnostic message.')
    call vimtest#Quit()

Here, no additional file needs to be provided, as the verification is
implemented in the TAP test itself.

### GENERAL CONSIDERATIONS
If the first line of the test contains a comment starting with: '" Test', this
is taken as the test synopsis and included in the test header that is printed
before each test is executed. Example:

    " Test mutation that adds lines after the current line.

Finally, the test must :quit Vim (unless the --debug option was specified), so
that the next test can be executed in a newly spawned Vim instance. The
vimtest#Quit() function takes care of that.

Tip: If you are a hands-on person, there are simple annotated example scripts
in the tests/example/ subdirectory.

TODO
------------------------------------------------------------------------------

- Store failed tests in lastfailed.suite and add option --lastfailed to
  re-run.

### IDEAS

- Replace the bash / Windows shell scripts with a cross-platform (Perl, Ruby?)
  script once it becomes too unwieldy. (Many will argue it already did.)
- Do we also need a TODO signal (and vimtest#Todo...() functions)?

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-runVimTests/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 1.32    RELEASEME
- BUG: With -1 / --default, user autoload functions are still picked up from
  the ~/.vim/pack directory. For example. functions from my ingo-library are
  still loaded, not just when vimtest#AddDependency() is used. Don't undo the
  modification of 'packpath' done so far only temporarily during Vim startup.

##### 1.31    09-Nov-2024
- VimTAP now also is automatically located if it's in an adjacent pack plugin
  tree. Its location can be overridden via the $VIMTAP\_HOME environment
  variable.

##### 1.30    03-Feb-2020
- Add vimtest#AddDependency() and vimtest#features#SupportsNormalWithCount().
- CHG: Print full absolute path to tests instead of just the test name itself.
  When running complete suites or tests with subdirectories, it is difficult
  to locate a failing test with just the name.
- ENH: Add -o|--output parameter that redirects all script output into a
  FILESPEC or &amp;N file descriptor. Piping the entire output of runVimTests is
  problematic because the started Vim instances expect to write the UI to
  stdout; without that, the screen does not update / is messed up, and you
  cannot do debugging in there.

##### 1.25    09-May-2017
- vimtest#Quit(): Don't exit Vim when not running inside the runVimTests test
  framework. This is better behavior when accidentally (or for testing)
  executing the test script in plain Vim.
- FIX: "cd" might print the path when CDPATH is set; discard it. Thanks to
  Raimondi for sending a pull request.
  https://github.com/inkarkat/runVimTests/pull/11
- ENH: Make runVimTestsSetup.vim accept any directory starting with VimTAP;
  thanks to Marcelo Montu for the pull request.
  https://github.com/inkarkat/runVimTests/pull/9
- With -1 / --default, newer Vim versions still pick up user plugins from the
  ~/.vim/pack directory. Temporarily modify 'packpath' during Vim startup to
  avoid that.

##### 1.24    29-Jan-2014
- Don't clobber the default viminfo file with the test results; use a special
  ~/.vimtestinfo value for the actual test run (to enable tests that use
  viminfo), and no viminfo for the checking and processing steps.
- Show _all_ global, non-test-specific Vim arguments in the initial message.
- Convert the filespec passed to --source to an absolute one; relative ones
  only work when the test driver script doesn't cd into a different directory.
- BUG: runVimTestsSetup.vim isn't sourced on Unix when invoked through
  runVimTests.sh (with the .sh file extension). Reported by Ryan Carney.
  https://github.com/inkarkat/runVimTests/issues/6
- Replace the distributed escapings.vim autoload script with an optional
  dependency (for Vim 7.0 and 7.1) to the ingo-library. !!! You need to
  separately install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.012 (or higher)!
  !!!

##### 1.23    25-Mar-2013
- Add support for Mac OS X; thanks to Israel Chauca Fuentes for sending a pull
  request. https://github.com/inkarkat/runVimTests/pull/1
- Add support for BSD (tested on PC-BSD 9.1).

##### 1.22    15-Mar-2013
- Include the version 1.21 changes in the Windows runVimTests.cmd, too.
- Switch to Git for the plugin's development to prevent such omissions (caused
  by my manual syncing, which is more complex in this case with files
  distributed over many different directory trees).

##### 1.21    07-Mar-2013
- FIX: Prevent script errors when the error message containing the full
  command line from a failing vimtest#System() contains characters like
  ['"()].
- CHG: Drop comma in the lists of failed / skipped / errored test and add .vim
  extension, so that the file list can be copy-and-pasted to another
  runVimTests invocation or :argedit'ed in Vim.
- CHG: Change default mode from "user" to "default"; this is what I use all
  the time, anyway, as the "user" mode is too susceptible to incompatible
  customizations.

##### 1.20    27-Jul-2012
- ENH: Handle file globs in the passed tests and in suite entries on Windows,
  too. (In contrast to the Unix shell, these must be explicitly expanded on
  Windows.)

##### 1.19    18-Jul-2012 (unreleased)
- BUG: In the Windows test runner, remove duplicate quoting when vimExecutable
  isn't found. This actually prevented execution when passing --vimexecutable
  "C:\\Program Files (x86)\\vim\\vim73\\vim.exe"

##### 1.18    19-Oct-2011
- BUG: When everything is skipped and no TAP tests have been run, this would
  be reported as a "No test results at all" error.
- CHG: Bail out only aborts from the current recursion level, i.e. it skips
  further tests in the same directory, suite, or passed arguments, but not
  testing entirely. Otherwise, a super-suite that includes individual suites
  would be aborted by a single bail out.

##### 1.17    04-Sep-2011
- BUG: When runVimTests.sh is invoked via a relative filespec, $scriptDir is
  relative and this makes the message output comparison (but not the
  prerequisite check) fail with "ERROR (msgout): Evaluation of test messages
  failed." when CWD has changed into $testDirspec. Thanks to Javier Rojas for
  sending a patch.

##### 1.16    28-Feb-2011
- Minor bugfixes and tweaks to the self-test.

##### 1.15    03-Oct-2010 (unreleased)
- Renamed directory that the tests reside in from "test/" to "tests/". This is
  just a personal preference, you can still put the tests into whatever
  directory structure.
- ENH: Added vimtest#ErrorAndQuit() for convenience.

##### 1.14    10-Jul-2009 (unreleased)
- Only bugfix and enhancement to the vimtest#System() function.

##### 1.13    29-May-2009
- ENH: Now including SKIP reasons in the summary (identical reasons are
condensed and counted) when not running with verbose output. I always wanted
to know why certain tests were skipped. (This requires GNU sort and uniq on
Windows.)

##### 1.12    14-Mar-2009
- Added quoting of regexp in addToList(), which is needed in bash 3.0 and 3.1.
  Thanks to Anders Thøgersen for the patch.
- Now checking bash version.
- Only exiting with exit code 1 in case of test failures; using code 2 for
  invocation errors (i.e. wrong command-line arguments) and code 3 for
  internal errors.

##### 1.11    12-Mar-2009
- TAP output is now parsed for SKIP and TODO directives, and the "Bail out"
  message.
- TODO TAP tests are included in the test output like failing tests.

##### 1.10    10-Mar-2009
- runVimTests drivers now also count test files (\*.vim).
- Implemented skipping of tests via special message in \*.msgout; not yet in
  TAP output.
- ENH: Message output is now parsed for signals to the test driver.
  Implemented signals: BAILOUT!, ERROR, SKIP, SKIP(out), SKIP(msgout),
  SKIP(tap).

##### 1.01    03-Mar-2009
- Added annotated example tests.

##### 1.00    02-Mar-2009
- First published version.

##### 0.10    11-Feb-2009
- Completed initial porting of runVimTests.cmd to Bash shell script
runVimTests.sh.

##### 0.01    12-Jan-2009
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2009-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
