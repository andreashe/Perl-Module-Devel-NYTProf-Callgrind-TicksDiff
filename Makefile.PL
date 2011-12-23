use inc::Module::Install;
name 'Devel-NYTProf-Callgrind-TicksDiff';
all_from 'lib/Devel/NYTProf/Callgrind/TicksDiff.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
