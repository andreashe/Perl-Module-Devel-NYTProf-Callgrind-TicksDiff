use inc::Module::Install;
name 'Devel-NYTProf-Callgrind-TicksDiff';
all_from 'lib/Devel/NYTProf/Callgrind/TicksDiff.pm';

requires 'MooseX::Declare'              =>  0;
requires 'Getopt::Long::Descriptive'    =>  0;
requires 'MooseX::App::Cmd::Command'    =>  0;
requires 'MooseX::App::Cmd'             =>  0;
requires 'MooseX::Getopt'               =>  0;
requires 'App::Cmd'                     =>  '0.313';

tests 't/*.t';

install_script 'bin/callgrind';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
