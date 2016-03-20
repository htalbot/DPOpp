#!/usr/bin/perl -w

use strict;
use Cwd;

my $cwd = getcwd();

my $scripts_dir = $ENV{DPO_CORE_ROOT} . "/tools/scripts";

chdir($scripts_dir);

system("$scripts_dir/dpo_set_all_env_vars_impl.pl --source \"$cwd\"");

chdir($cwd);

