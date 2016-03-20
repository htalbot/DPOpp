#!/usr/bin/perl -w

use strict;
use Cwd;

my $cwd = getcwd();

my $scripts_dir = $ENV{DPO_CORE_ROOT} . "/scripts";

chdir($scripts_dir);

system("dpo_set_as_current_pool_impl.pl --source \"$cwd\"");

chdir($cwd);

