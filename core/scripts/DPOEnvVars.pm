use lib $ENV{DPO_CORE_ROOT} . "/scripts";
use strict;
use Tie::IxHash;
use DPOLog;

package DPOEnvVar;

sub new
{
    my ($class, $name, $value) = @_;

    my $self = {
        name => $name,
        value => $value,
        status => undef
    };

    bless($self, $class);

    return $self;
}

1;


package DPOEnvVars;

BEGIN {
    if ($^O =~ /Win/)
    {
        eval "use Win32::Env";
        eval "use constant DPO_ENV_USER => ENV_USER";
        eval "use constant DPO_ENV_SYSTEM => ENV_SYSTEM";
        eval "use Win32API::GUID";
    }
    else
    {
        eval "use constant DPO_ENV_USER => ''";
        eval "use constant DPO_ENV_SYSTEM => ''";
    }
}

my $pathDPO_id = "PATH_DPO";
my $dpo_envvar_section_reserved= "##### DPO_ENVVAR - RESERVED... #####";
my $dpo_envvar_section_begin = "##### DPO_ENVVAR - BEGIN #####";
my $dpo_envvar_section_end = "##### DPO_ENVVAR - END #####";
my $ld_library_pathDPO_id = "LD_LIBRARY_PATH_DPO";

sub new
{
    my ($class) = @_;

    my $self = {};

    bless($self, $class);

    return $self;
}


sub load
{
    my ($self) = @_;

    foreach my $x (sort keys(%ENV))
    {
        if ($x =~ /(.*)_ROOT$/)
        {
            my $value = "\$($x)";

            if (!expand_env_var(\$value))
            {
                next;
            }

            # When there is DPOProject.xml file,
            # the directory is a candidate.
            # When the directory is MPC_ROOT or DPO_CORE_ROOT
            # we must consider them too because they
            # don't contain any DPOProject.xml.
            if ( -f "$value/DPOProject.xml"
                || $x eq "DPO_CORE_ROOT"
                || $x eq "DPO_POOL_ROOT"
                || $x eq "MPC_ROOT")
            {
                my $env_var = DPOEnvVar->new($x, $value);
                $self->{$x} = $env_var;
            }
            else
            {
                # not a dpo project
            }
        }
    }
}


sub get_value
{
    my ($self, $id) = @_;

    if ($self->{$id})
    {
        return $self->{$id}->{value};
    }

    return undef;
}


################################################################################
# This routine expands environment variable from these two formats:
#       $(ENVIRONMENT_VARIABLE)
#       %ENVIRONMENT_VARIABLE%
#
# But not from this format: $ENVIRONMENT_VARIABLE
################################################################################
sub expand_env_var
{
    my ($in_out) = @_;

    $$in_out =~ s/^\s+//;
    $$in_out =~ s/\s+$//;

    # $(XYZ) format
    while (1)
    {
        my @vars = $$in_out =~ /\$\((.*?)\)/g;

        if (scalar(@vars) > 0)
        {
            foreach my $x (@vars)
            {
                my $env_var_value = $ENV{$x};
                if (!defined($env_var_value))
                {
                    #~ print "Environment variable $x is not defined.\n";
                    return 0;
                }
                $$in_out =~ s/\$\((.*?)\)/$ENV{$x}/;
            }
        }
        else
        {
            last;
        }
    }

    # %XYZ% format
    while (1)
    {
        my @vars = $$in_out =~ /\%(.*?)\%/g;

        if (scalar(@vars) > 0)
        {
            foreach my $x (@vars)
            {
                my $env_var_value = $ENV{$x};
                if (!defined($env_var_value))
                {
                    #~ print "Environment variable $x is not defined.\n";
                    return 0;
                }
                $$in_out =~ s/\%(.*?)\%/$env_var_value/;
            }
        }
        else
        {
            last;
        }
    }

    # Change backslashes by slashes
    $$in_out =~ s/\\/\//g;

    return 1;
}

sub system_set_env_vars
{
    my ($env_var_values) = @_;

    my $os = $^O;
    if ($os =~ /Win/)
    {
        if (!system_set_user_env_var_mswin32($env_var_values))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't set environment variables"]);
            return 0;
        }
    }
    else
    {
        my $rc = 1;
        foreach (@$env_var_values)
        {
            $rc &= system_set_env_var_linux($_->{name}, $_->{value});
        }

        if (!$rc)
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't set environment variables"]);
            return 0;
        }
    }

    return 1;
}

sub system_set_user_env_var_mswin32
{
    my ($listEnvVarValue) = @_;

    # Build hash with new env. vars.
    tie (my %new_env_vars,'Tie::IxHash'); #preserve order

    foreach my $env_var (@$listEnvVarValue)
    {
        $new_env_vars{$env_var->{name}} = $env_var->{value};
    }

    # Build hash with current env. vars.
    tie (my %current_env_vars, 'Tie::IxHash'); #preserve order

    foreach my $env_var_id (get_user_env_var_list())
    {
        $current_env_vars{$env_var_id} = get_user_env_var_value($env_var_id);
    }

    # Update current env. vars or append new env. vars. to current env. vars.
    foreach my $key (keys %new_env_vars)
    {
        $current_env_vars{$key} = $new_env_vars{$key};
    }

    # Set env. vars.
    foreach my $key (keys %current_env_vars)
    {
        my $env_var_value = $current_env_vars{$key};
        if ($env_var_value)
        {
            $env_var_value =~ s/\//\\/g;
        }

        SetEnv(DPO_ENV_USER,
                $key,
                $env_var_value ? $env_var_value : "",
                1); # expandable


        # Set current application instance environment variables.
        if (uc($key) eq "PATH")
        {
            # PATH is system environment variable too.
            # If we set PATH user environment variable with '$ENV{PATH}',
            # PATH user environment variable values will take place and
            # PATH system environment variable values will be missing
            # for the current application instance.
            next;
        }

        $ENV{$key} = $env_var_value;
    }

    # Make sure that 'path' (user) env. var. is defined
    # and make sure that PATH_DPO is part of the value of 'path'
    my $bPathPresent=0;
    foreach my $key (keys %current_env_vars)    # I don't use the 'defined'
                                                # function...
    {
        if (uc($key) eq "PATH") # that's why I didn't use the 'defined'
                                # function to determine if 'path' is defined.
        {
            $bPathPresent = 1;

            # Make sure that PATH_DPO is part of the value of 'path'
            if ($key !~ /$pathDPO_id/)
            {
                my $sep = "";
                if ($current_env_vars{$key})
                {
                    $sep = ";";
                }

                $current_env_vars{$key} .= $sep . "\%" . $pathDPO_id . "\%";
            }
        }
    }

    # Append path (and path_dpo) if not already present.
    if (!$bPathPresent)
    {
        SetEnv(DPO_ENV_USER,
                'Path',
                "\%$pathDPO_id\%",
                1); # expandable
    }

    print "system_set_user_env_var_mswin32 - broadcast...\n";
    BroadcastEnv();
    print "system_set_user_env_var_mswin32 - ...broadcast\n";

    return 1;
}

sub system_set_env_var_linux
{
    my ($var_name, $var_value) = @_;

    $ENV{$var_name} = $var_value ? $var_value : "";

    my $home = "\$(HOME)";
    if (!DPOEnvVars::expand_env_var(\$home))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$home]);
        return 0;
    }

    my $file = "$home/.dpo_env_vars";
    my $tmp_file = "tmpfile";

    if (-f $file)
    {
        my @lines = ();
        if (!get_file_lines($file, \@lines))
        {
            DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
            return 0;
        }

        if (!open (OUT, ">$tmp_file"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["Open", $tmp_file, $!]);
            return 0;
        }

        my $new_line = "export " . $var_name . "=" . $var_value . "\n";

        print "Set ", $var_name, "=", $var_value ? $var_value : "", "\n";
        $ENV{$_->{name}} = $_->{value} ? $_->{value} : "";

        my @new_file_lines=();

        my $bExportFound = 0;

        foreach(@lines)
        {
            my $bFound = 0;
            my $line = $_;
            my $check_comment = $_;
            $check_comment =~ s/^\s*//;

            my $first = substr($check_comment, 0, 1);

            if ($first ne '#')
            {
                if ($line =~ /\Q$var_name\E/)
                {
                    my @tokens = split(/[\ \=]/, $line);
                    my @non_null_tokens=();
                    foreach (@tokens)
                    {
                        if ($_)
                        {
                            push(@non_null_tokens, $_);
                        }
                    }

                    my $count = $#non_null_tokens + 1;
                    if ($count == 3)
                    {
                        if ($non_null_tokens[0] eq "export")
                        {
                            if ($non_null_tokens[1] eq $var_name)
                            {
                                $bFound = 1;
                                $bExportFound = 1;
                            }
                        }
                    }

                    if ($bFound)
                    {
                        push(@new_file_lines, $new_line);
                    }
                    else
                    {
                        push(@new_file_lines, $line);
                    }
                }
                else
                {
                    push(@new_file_lines, $line);
                }
            }
            else
            {
                push(@new_file_lines, $line);
            }
        }

        if ($bExportFound)
        {
            foreach (@new_file_lines)
            {
                print OUT $_;
            }
        }
        else
        {
            # look for automated generated section by this function

            # if section is found, append new variable to it
            my $bStringToSearchFound = 0;
            foreach(@lines)
            {
                if (/$dpo_envvar_section_reserved/)
                {
                    print OUT $new_line;
                    print OUT $_;
                    $bStringToSearchFound = 1;
                }
                else
                {
                    print OUT $_;
                }
            }

            # if section does not exist, create it vith the new variable
            if (!$bStringToSearchFound)
            {
                print OUT "\n\n";
                print OUT $dpo_envvar_section_begin;
                print OUT "\n";
                if (uc($var_name) ne $pathDPO_id
                        && uc($var_name) ne $ld_library_pathDPO_id)
                {
                    print OUT $new_line;
                }
                print OUT $dpo_envvar_section_reserved;
                print OUT "\n";
                if (uc($var_name) eq $pathDPO_id
                        || uc($var_name) eq $ld_library_pathDPO_id)
                {
                    print OUT $new_line;
                }
                else
                {
                    print OUT "export $pathDPO_id=";
                    print OUT "\n";
                    print OUT "export $ld_library_pathDPO_id=";
                    print OUT "\n";
                }

                print OUT "export PATH=\$PATH:\$$pathDPO_id";
                print OUT "\n";
                print OUT "export LD_LIBRARY_PATH=\$PATH:\$$ld_library_pathDPO_id";
                print OUT "\n";
                print OUT $dpo_envvar_section_end;
                print OUT "\n\n";
            }
        }

        close(OUT);

        rename($tmp_file, $file);
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["$file is not a file"]);
        return 0
    }

    return 1;
}

sub system_del_env_var_linux
{
    DPOLog::report_msg(DPOEvents::GENERIC_INFO, ["system_del_env_var_linux : Not implemented yet"]);
    return 0;
}

sub get_user_env_var_list
{
    my ($self) = @_;

    return eval "Win32::Env::ListEnv(DPO_ENV_USER)";
}

sub get_user_env_var_value
{
    my ($env_var_id) = @_;

    return Win32::Env::GetEnv(DPO_ENV_USER, $env_var_id);
}

sub get_custom_env_var
{
    my ($env_vars) = @_;

    my $os = $^O;
    if (lc($os) eq "linux")
    {
        my $home = "\$(HOME}";
        if (!DPOEnvVars::expand_env_var(\$home))
        {
            DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$home]);
            return 0;
        }
        my $file = "$home/.dpo_env_vars";

        if (-f $file)
        {
            my @lines=();
            if (!get_file_lines($file, \@lines))
            {
                DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
                return 0;
            }

            my $found = 0;
            foreach(@lines)
            {
                my $line = $_;

                if ($line =~ /\Q$dpo_envvar_section_reserved\E/)
                {
                    last;
                }

                if ($line =~ /\Q$dpo_envvar_section_begin\E/)
                {
                    $found = 1;
                    next;
                }

                if ($line =~ /\Q$dpo_envvar_section_end\E/)
                {
                    $found = 0;
                    next;
                }

                if ($found)
                {
                    trim(\$line);
                    if ($line !~ /\#/)
                    {
                        my ($env_var_id, $value) = $line =~ /export (.*)=(.*)/;
                        my $env_var = DPOEnvVar->new($env_var_id, $value);
                        push(@$env_vars, $env_var);
                    }
                }
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["$file is not a file"]);
            return 0
        }
    }

    return 1;
}

sub system_del_env_vars
{
    my ($env_var_values) = @_;

    my $os = $^O;
    if ($os =~ /Win/)
    {
        if (!system_del_user_env_var_mswin32($env_var_values))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't delete environment variables"]);
            return 0;
        }
    }
    else
    {
        my $rc = 1;
        foreach (@$env_var_values)
        {
            $rc &= system_del_env_var_linux($_->{name}, $_->{value});
        }

        if (!$rc)
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't delete environment variables"]);
            return 0;
        }
    }

    return 1;
}

sub system_del_user_env_var_mswin32
{
    my ($listEnvVarValue) = @_;

    foreach my $x (@$listEnvVarValue)
    {
        DelEnv(DPO_ENV_USER,
                $x->{name}); # expandable
        delete $ENV{$x->{name}};
    }

    BroadcastEnv();

    return 1;
}


1;
