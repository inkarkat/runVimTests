SELF TESTS
==========

The self tests exercise runVimTests on the test directory (.) and various test
suites (*.suite) under some configurations, and compare the actual output with
the previously captured nominal output. The command-line arguments to
runVimTests and the test file are embedded in the captured output filename and
are extracted automatically. 

To run a particular self test, execute: 
    compareLog {name}.log
To run all tests, execute: 
    compareAllLogs
The test run should list no differences. 

The test suite for interactive tests cannot be automated. 
Invoke it manually via: 
    runVimTests interactive.suite
If you follow the instructions, this test should pass. 

The automatic comparison is brittle, especially on Windows. 
