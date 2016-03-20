#!/usr/bin/perl -w

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

use strict;
use Getopt::Long;

use Wx qw[:everything];

use DPOEnvVars;

my $source;
my $msg;
if (!GetParam(\$source, \$msg))
{
    Wx::MessageBox(
            $msg,
            "Program arguments",
            Wx::wxOK | Wx::wxICON_ERROR,
            undef);
    exit -1;
}

my $env_var_id = "DPO_POOL_ROOT";
my $env_var = DPOEnvVar->new($env_var_id, $source);
my @listEnvVarValues=();
push(@listEnvVarValues, $env_var);

my $rc = DPOEnvVars::system_set_env_vars(\@listEnvVarValues);
if ($rc)
{
    Wx::MessageBox(
            "$env_var_id has been set to $source.",
            "Environment variables",
            Wx::wxOK | Wx::wxICON_INFORMATION);
}
else
{
    Wx::MessageBox(
            "$env_var_id can not be set.",
            "Environment variables",
            Wx::wxOK | Wx::wxICON_ERROR);
}



sub GetParam
{
    my ($source, $msg) = @_;

    # Syntax string
    my $syntax = "\nusage: $0 --source <project directory>\n";

    # read options
    GetOptions("source:s" => $source);

    if (!defined($$source))
    {
        $$msg = $syntax;
        return 0;
    }
    else
    {
        return 1;
    }
}



