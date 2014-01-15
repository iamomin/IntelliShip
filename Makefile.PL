#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'IntelliShip';
all_from 'lib/IntelliShip.pm';

requires 'DBD::Pg';

requires 'Package::DeprecationManager';
requires 'Test::Requires';
requires 'Package::Stash::XS';
requires 'Class::Load';
requires 'Class::Load::XS';
requires 'Eval::Closure';
requires 'Package::Stash';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'MooseX::MarkAsMethods';
requires 'namespace::autoclean';
requires 'DBIx::Class';
requires 'DBIx::Class::TimeStamp';
requires 'DBIx::Class::PassphraseColumn';
requires 'Catalyst::View::TT';
requires 'Test::Memory::Cycle';
requires 'Devel::Cycle';
requires 'Test::Differences';
requires 'YAML';
requires 'XML::Writer';
requires 'Package::Variant';
requires 'Catalyst::Runtime' => '5.90019';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Config::General'; # This should reflect the config file format you've chosen
                            # See Catalyst::Plugin::ConfigLoader for supported formats
requires 'Math::BaseCalc' => '1.011';
requires 'Date::Business';
requires 'Date::Calendar';
requires 'Date::Manip';
requires 'Date::Calc';
requires 'DateTime';
requires 'Email::Stuff';
requires 'Sys::Hostname';
requires 'XML::Simple';
requires 'Email::Valid';
requires 'Spreadsheet::WriteExcel';
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
