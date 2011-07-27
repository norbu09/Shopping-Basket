use inc::Module::Install;

name     'Shopping-Basket';
all_from 'lib/Shopping/Basket.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Mouse';
requires 'Store::CouchDB';
requires 'Data::UUID';

auto_install;

WriteAll;

