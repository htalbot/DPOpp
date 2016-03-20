#!/usr/bin/perl

use strict;
use Cwd;
use File::Path;
use File::Type;
use File::Copy;
use List::MoreUtils;
use Tie::IxHash;
use Time::HiRes;

use DPOLog;
use DPOEnvVars;
use DPOEvents;


package DPOModuleCorbaInterface;

sub new
{
    my ($class,
        $module_name) = @_;

    my $self =
    {
        module_name => $module_name
    };

    bless($self, $class);

    $self->{interfaces} = [];

    return $self;
}

1;


package DPOModuleOpenDDSTopic;

sub new
{
    my ($class,
        $module_name) = @_;

    my $self =
    {
        module_name => $module_name
    };

    bless($self, $class);

    $self->{topics} = [];

    return $self;
}

1;


package PoolTreeNode;

sub new
{
    my ($class,
        $id) = @_;

    my $self =
    {
        id => $id
    };

    bless($self, $class);

    $self->{nodes} = [];

    return $self;
}

sub add
{
    my ($self, $path) = @_;

    my $node = 0;

    if ($path =~ /(.*?)\/(.*)/)
    {
        my $new_node_id = $1;
        my $rest = $2;
        if (!List::MoreUtils::any {$_->{id} eq $new_node_id} @{$self->{nodes}})
        {
            my $new_node = PoolTreeNode->new($new_node_id);
            $new_node->add($rest);
            push(@{$self->{nodes}}, $new_node);
        }
        else
        {
            foreach my $sub_node (@{$self->{nodes}})
            {
                if ($sub_node->{id} eq $new_node_id)
                {
                    my $new_node = PoolTreeNode->new($new_node_id);
                    $sub_node->add($rest);
                }
            }
        }
    }
    else
    {
        if (!List::MoreUtils::any {$_->{id} eq $path} @{$self->{nodes}})
        {
            $node = PoolTreeNode->new($path);
            push(@{$self->{nodes}}, $node);
        }
    }
}

1;


package VersionBlockProject;
use parent 'Clone';

sub new
{
    my ($class,
        $project_name,
        $version,
        $status) = @_;

    my $self =
    {
        project_name => $project_name,
        version => $version,
        status => $status
    };

    bless($self, $class);

    return $self;
}

1;


package VersionBlock;

sub new
{
    my ($class,
        $version,
        $timestamp) = @_;

    my $self =
    {
        version => $version,
        timestamp => $timestamp
    };

    bless($self, $class);

    $self->{projects} = [];

    return $self;
}

1;



package DPOUtils;

use constant {
    BUILD_CONFIG_NOT_SET => 0,
    BUILD_CONFIG_DEBUG => 1,
    BUILD_CONFIG_RELEASE => 2,
    BUILD_CONFIG_DEBUG_RELEASE => 3
};

################################################################################
# Get the lines from a file
# $file: file to read
# $lines_ref: lines read
################################################################################
sub get_file_lines
{
    my ($file, $lines_ref) = @_;

    if (!open (FILE, $file))
    {
        return 0;
    }

    @$lines_ref = <FILE>;
    close(FILE);

    return 1;
}


################################################################################
# Get version from a project
# $dir: project root directory
################################################################################
sub read_project_version
{
    my ($dir, $major, $minor, $patch) = @_;

    $dir =~ s/\\/\//g;

    my $pre;
    my $version;
    my $project_name;
    if (in_dpo_pool($dir))
    {
        ($pre, $project_name, $version) = $dir =~ /(.*)\/(.*)\/(.*)$/;
        ($$major, $$minor, $$patch) = $version =~ /(\d+)\.(\d+)\.(\d+)/;
        return 1;
    }
    else
    {
        ($pre, $project_name) = $dir =~ /(.*)\/(.*)$/;
    }

    my $version_file = "$dir/include/$project_name/version.h";
    my @lines=();
    if (!get_file_lines($version_file, \@lines))
    {
        print "Cannot get lines from file $version_file.\n";
        return 0;
    }

    my $major_version_string = uc($project_name) . "_MAJOR";
    my $minor_version_string = uc($project_name) . "_MINOR";
    my $patch_version_string = uc($project_name) . "_PATCH";

    foreach (@lines)
    {
        chomp($_);

        trim(\$_);

        if (!/^$/)
        {
            if (/\Q$major_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$major = $tokens[$#tokens];
            }

            if (/\Q$minor_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$minor = $tokens[$#tokens];
            }

            if (/\Q$patch_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$patch = $tokens[$#tokens];
            }
        }
    }

    my $major_version_missing=0;
    my $minor_version_missing=0;
    my $patch_version_missing=0;
    if (length($major)==0)
    {
        $major_version_missing = 1;
        print "major version is missing in $version_file.\n";
    }

    if (length($minor)==0)
    {
        $minor_version_missing = 1;
        print "minor version is missing in $version_file.\n";
    }

    if (length($patch)==0)
    {
        $patch_version_missing = 1;
        print "patch version is missing in $version_file.\n";
    }

    if ($major_version_missing
        || $minor_version_missing
        || $patch_version_missing)
    {
        return 0;
    }

    return 1;
}


################################################################################
# Trim string at both ends
# $string: the string to be trimmed
################################################################################
sub trim
{
    my ($string) = @_;

    if ($$string)
    {
        $$string =~ s/^\s+//;
        $$string =~ s/\s+$//;
    }
}

################################################################################
# Trim string at left end
# $string: the string to be trimmed
################################################################################
sub ltrim
{
    my ($string) = @_;

    if ($$string)
    {
        $$string =~ s/^\s+//;
    }
}


################################################################################
# Trim string at rigth end
# $string: the string to be trimmed
################################################################################
sub rtrim
{
    my ($string) = @_;

    if ($$string)
    {
        $string =~ s/\s+$//;
    }
}


################################################################################
# Returns 1 (true) if $path is in the current pool directory.
# $path: the path to check.
################################################################################
sub in_dpo_pool
{
    my ($path) = @_;

    if (!$path)
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["$path doesn't exist"]);
        return 0;
    }

    my $dpo_pool = dpo_pool_dir();

    $dpo_pool =~ s/\\/\//g;
    $path =~ s/\\/\//g;

    my $rc = index($path, $dpo_pool);

    if ($rc == -1)
    {
        my $rc = index($path, "dpo_pool-"); # any other pool type

        if ($rc == -1)
        {
            return 0;
        }
        else
        {
            return 1;
        }
    }
    else
    {
        return 1;
    }
}


sub dpo_pool_dir
{
    my $dpo_pool = "\$(DPO_POOL_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$dpo_pool))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["DPO_POOL_ROOT environment variable is not defined. Is DPOUtils::check_essentials() called at the begining of the program?"]);
        return "";
    }

    return $dpo_pool;
}


################################################################################
# Get subdirs and files names contained in a directory
# A default filter is applied to exclude the parent directory and the current
# one.
# Additional filters can be applied as needed.
# $content_ref: outcome - sub-directories and files names.
################################################################################
sub get_dir_content
{
    my ($dir, $content_ref) = @_;

    my $initial_wd = Cwd::getcwd();

    if (!chdir($dir))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't change directory to $dir"]);
        return 0;
    }
    my $cwd = Cwd::getcwd();

    opendir(DIR, $cwd);
    @$content_ref = readdir(DIR);
    closedir(DIR);

    my @purified=();
    foreach(@$content_ref)
    {
        if (($_ ne "." && $_ ne ".." ))
        {
            if (!/.svn$/
                && !/.git/
                && !/.bzr/)
            {
                push(@purified, $_);
            }
        }
    }

    @$content_ref = @purified;

    chdir($initial_wd);

    return 1;
}


################################################################################
# Find the directory of a project from a higher directory.
# $dir: directory from where the search begins.
# $project_name: the name of the project we are searching for the path.
# $path_ref: outcome - the path of the project.
################################################################################
sub get_project_path
{
    my ($dir, $project_name, $path_ref) =  @_;

    my @content;
    if (get_dir_content($dir, \@content))
    {
        if (scalar(@content) == 0)
        {
            return 0;
        }

        foreach my $elem (@content)
        {
            if (-d "$dir/$elem")
            {
                if ($elem eq $project_name)
                {
                    $$path_ref = "$dir/$elem";
                    $$path_ref =~ s/\\/\//g;
                    return 1;
                }

                if (get_project_path("$dir/$elem", $project_name, $path_ref))
                {
                    return 1;
                }
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    return 0;
}


################################################################################
# Gets the features of a project.
# $file: the file that shuold contain features.
# $features_ref: outcome - features found.
################################################################################
sub read_feature_file
{
    my ($file, $features_ref) = @_;

    my @lines=();
    if (!get_file_lines($file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
        return 0;
    }
    else
    {
        foreach my $line(@lines)
        {
            trim(\$line);

            if (($line !~ /^$/)
                && ($line !~ /^\/\//))
            {
                my ($feature, $value) = $line =~ /(.*)=(.*)/;
                if ($feature)
                {
                    trim(\$feature);
                    my ($num) = $value =~ /(\d)/;

                    # if exists, override...
                    my $bFound = 0;
                    foreach my $existing_feature (@$features_ref)
                    {
                        my ($feat) = $existing_feature =~ /^(.*)=/;
                        trim(\$feat);
                        if ($feat eq $feature)
                        {
                            $existing_feature = "$feat=$num";
                            $bFound = 1;
                            last;
                        }
                    }
                    if (!$bFound)
                    {
                        push(@$features_ref, "$feature=$num");
                    }
                }
            }
        }
    }

    return 1;
}

sub check_for_plugin_exec
{
    my ($project_name, $plugin_exec_none_ref) = @_;

    # $plugin_exec_none_ref: the $project_name is a plugin, an executable or none of them.

    my $env_var_id = uc($project_name) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
        return 0;
    }

    # Check for plugin
    my $include_file = "$path/include/$project_name/$project_name\.h";
    if (-e $include_file)
    {
        my @lines=();
        if (get_file_lines($include_file, \@lines))
        {
            foreach my $line (@lines)
            {
                if ($line =~ /plugin_macros\.h/)
                {
                    $$plugin_exec_none_ref = "plugin";
                    return 1;
                }
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$include_file]);
        }
    }

    # Check for executable
    my $mpc_ex_file = "$path/MPC/$project_name" . "_ex.mpb";
    if (-e $mpc_ex_file)
    {
        my @lines=();
        if (get_file_lines($mpc_ex_file, \@lines))
        {
            foreach my $line (@lines)
            {
                trim(\$line);

                if ($line !~ /^\/\//
                    && $line =~ /exename/)
                {
                    $$plugin_exec_none_ref = "executable";
                    return 1;
                }
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$mpc_ex_file]);
        }
    }

    $$plugin_exec_none_ref = "none";

    return 1;
}

sub gen_export_file
{
    my ($dir, $name, $gen_export_cmd, $msg_ref) = @_;

    my $initial_wd = Cwd::getcwd();

    my $export_file_dir = "$dir/include/$name";

    if (!chdir($export_file_dir))
    {
        $$msg_ref = "Cannot change dir to $export_file_dir.";
        return 0;
    }

    my $rc = system($gen_export_cmd);
    if ($rc != 0)
    {
        $$msg_ref = "Cannot generate export ".
                "file header (for dll).";
        chdir $initial_wd;
        return 0;
    }

    chdir $initial_wd;

    return 1;
}

sub get_ace_related_mpc_includes
{
    my ($mpc_related_includes, $err_msg_ref) = @_;

    my $ace_root = "\$(ACE_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$ace_root))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, ["ACE_ROOT"]);
        return 0;
    }

    my $mpc_path = "\$(MPC_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$mpc_path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, ["MPC_ROOT"]);
        return 0;
    }

    my %valid_cfg = (#'command_line'     => 1,
                     #'default_type'     => 1,
                     'dynamic_types'    => 1,
                     'includes'         => 1,
                     #'logging'          => 1,
                     'main_functions'   => 1,
                     #'verbose_ordering' => 1,
                    );

    if ($mpc_path =~ /\Q$ace_root\E/)
    {
        # use MPC ConfigParser module to get default mpc includes from ACE
        unshift(@INC, "$mpc_path/modules");
        require ConfigParser;

        my $file = "$ace_root/bin/MakeProjectCreator/config/MPC.cfg";

        # Disable output to STDOUT
        open my $saveout, ">&STDOUT";
        open STDOUT, '>', "/dev/null";

        my $cfg = new ConfigParser(\%valid_cfg);
        my($status, $error) = $cfg->read_file($file);

        # Reenable output to STDOUT
        open STDOUT, ">&", $saveout;

        if (!$status)
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["MPC ConfigParser can't read file $file"]);
            return 0;
        }

        my %dyn;
        my @dynamic_types = split(/,/, $cfg->{clean}->{dynamic_types});
        foreach my $dynamic_type (@dynamic_types)
        {
            if ($dynamic_type =~ /\$(\?)?([\(\w\)]+)\/(.*)/)
            {
                my $optional = $1;
                my $env_var_id = $2;
                $env_var_id =~ s/[\(\)]//g;

                my $path = $3;

                $dyn{$env_var_id} = $path;
            }
        }

        foreach my $key (keys %dyn)
        {
            my $env_var_id = "\$($key)";
            my $env_var_value = $env_var_id;
            if (!DPOEnvVars::expand_env_var(\$env_var_value))
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$key]);
                next;
            }
            my $path = "$env_var_value/$dyn{$key}";

            if (-d "$path/templates")
            {
                push(@$mpc_related_includes, "$env_var_id/$dyn{$key}/templates");
            }

            if (-d "$path/config")
            {
                push(@$mpc_related_includes, "$env_var_id/$dyn{$key}/config");
            }
        }

        # includes
        my $includes = $cfg->get_value("includes");
        if (!DPOEnvVars::expand_env_var(\$includes))
        {
            DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$includes]);
            return 0;
        }

        my @tokens_includes = split(/,/, $includes);
        foreach my $token (@tokens_includes)
        {
            trim(\$token);
            my $related_inc = "\$(ACE_ROOT)" . $token;
            if (!List::MoreUtils::any {$_ eq $related_inc} @$mpc_related_includes)
            {
                push(@$mpc_related_includes, $related_inc);
            }
        }
    }

    push(@$mpc_related_includes, "\$(MPC_ROOT)/templates");
    push(@$mpc_related_includes, "\$(MPC_ROOT)/config");

    foreach(@$mpc_related_includes)
    {
        trim(\$_);
    }

    return 1;
}

sub create_new_project
{
    my($parent_dir, $project_name, $type_id, $type, $msg_ref) = @_;

    my $new_dir = $parent_dir . "/" . $project_name;

    # check for existing directory
    if (-e $new_dir)
    {
        $$msg_ref = "Already exists ($new_dir directory exists).\n";
        return 0;
    }

    my $project_root_id = uc($project_name) . "_PRJ_ROOT";

    # check for existing env. var. definition
    foreach my $key (keys(%ENV))
    {
        if (uc($key) eq $project_root_id)
        {
            $$msg_ref = "The project \"$project_name\" already exists ".
                    "($project_root_id env. var. is already defined).";
            return 0;
        }
    }

    my @cust_envvars=();
    if (!DPOEnvVars::get_custom_env_var(\@cust_envvars))
    {
        $$msg_ref = "Can't get custom environment variables (Linux).";
        return 0;
    }
    foreach (@cust_envvars)
    {
        if (uc($_->{name}) eq $project_root_id)
        {
            $$msg_ref = "The project \"$project_name\" already ".
                        "exists ($project_root_id env. var. is already defined).";
            return 0;
        }
    }

    if (!DPOUtils::make_path($new_dir))
    {
        $$msg_ref = "Failed to make path $new_dir.";
        return 0;
    }

    tie (my %templates, 'Tie::IxHash'); #preserve order;
    if (!DPOUtils::available_templates(\%templates))
    {
        $$msg_ref = "Failed to get available templates.";
        return 0;
    }

    if (!DPOUtils::TreeCopy($templates{$type_id}, $new_dir))
    {
        $$msg_ref = "Cannot copy $templates{$type} to $new_dir.";
        remove_dir($new_dir);
        return 0;
    }
    my $propagate_msg="";
    if (!DPOUtils::propagate_changes($new_dir, $project_name, \$propagate_msg))
    {
        $$msg_ref = "Cannot propagate changes to \"$project_name\".\n\n";
        $$msg_ref .= $propagate_msg;
        remove_dir($new_dir);
        return 0;
    }

    my @content;
    if (DPOUtils::get_dir_content($new_dir, \@content))
    {
        foreach my $elem (@content)
        {
            if ($elem =~ /NewProject_/)
            {
                unlink "$new_dir/$elem";
                last;
            }
        }
    }

    # Set permissions on project scripts
    my $os = $^O;
    if ($os eq "linux")
    {
        if (!DPOUtils::set_permissions($new_dir))
        {
            $$msg_ref = "Cannot set permissions for \"$project_name\"";
            remove_dir($new_dir);
            return 0;
        }
    }

    return 1;
}

sub propagate_changes
{
    my ($new_dir, $project_name, $msg) = @_;

    if  (!rename_dir_and_files($new_dir, $project_name))
    {
        $$msg = "propagate_changes - Cannot rename directories/files.";
        return 0;
    }

    if (!replace_in_file($new_dir, $project_name))
    {
        $$msg = "propagate_changes - Cannot replace strings in files.";
        return 0;
    }

    return 1;
}

sub rename_dir_and_files
{
    my ($dir, $new_value) = @_;

    my @content=();
    if (!get_dir_content($dir, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    foreach my $file (@content)
    {
        my $complete = "$dir/$file";

        if (-f $complete)
        {
            (my $n=$file) =~ s/xyz/\Q$new_value\E/;
            rename "$dir/$file", "$dir/$n";
            (my $n2=$file) =~ s/Xyz/\Q$new_value\E/;
            rename "$dir/$file", "$dir/$n2";
        }

        if (-d $complete && $file ne "." && $file ne ".." )
        {
            if (!rename_dir_and_files($complete, $new_value))
            {
                return 0;
            }

            (my $n=$file) =~ s/xyz/\Q$new_value\E/;
            rename "$dir/$file", "$dir/$n";
        }
    }

    return 1;
}

sub replace_in_file
{
    my ($dir, $new_string, $content_in) = @_;

    my @content=();
    my $true_dir = "$dir/";

    if ($content_in)
    {
        $true_dir = "";
        @content = @$content_in;
    }
    else
    {
        if (!get_dir_content($dir, \@content))
        {
            DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
            return 0;
        }
    }

    foreach my $file (@content)
    {
        my $tmp_file = "$true_dir" . "tmpfile";

        my $complete = "$true_dir" . "$file";

        if (-f $complete)
        {
            if (!open (THE_FILE, $complete))
            {
                DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["Open", $complete, $!]);
                return 0;
            }

            binmode(THE_FILE);

            # read file
            my @lines = <THE_FILE>;
            close(THE_FILE);

            if (!open (OUT, ">$tmp_file"))
            {
                DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["Open", $tmp_file, $!]);
                return 0;
            }

            binmode(OUT);
            foreach my $line (@lines)
            {
                my $xyz_lc = "xyz";

                # uppercase
                my $xyz_uc = "XYZ";
                my $new_string_uc = uc($new_string);

                # mixed case (for class name in project templates)
                my $xyz_mixted = "Xyz";
                my ($first, $remain) = $new_string =~ /(.)(.*)/;
                my $new_string_mixted = uc($first) . $remain;

                $line =~ s/$xyz_lc/$new_string/g;

                $line =~ s/$xyz_uc/$new_string_uc/g;

                $line =~ s/$xyz_mixted/$new_string_mixted/g;

                print OUT $line;
            }

            close(OUT);

            rename($tmp_file, $complete);
            my $ft = File::Type->new();
            if (is_script($complete, $ft))
            {
                set_permissions_on_file($complete);
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." )
        {
            if (!replace_in_file($complete, $new_string))
            {
                return 0;
            }
        }
    }

    return 1;
}

sub set_permissions_on_file
{
    my ($file) = @_;

    if ($^O !~ /Win/)
    {
        open(my $fh, "<", $file);
        my $perm = (stat $fh)[2] & 07777;
        my $rc = chmod($perm | 0100, $fh);
        close($fh);
    }
}

sub set_permissions
{
    my ($dir) = @_;

    if ($^O !~ /Win/)
    {
        my @content=();
        if (!get_dir_content($dir, \@content))
        {
            DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
            return 0;
        }

        my $ft = File::Type->new();

        foreach my $file (@content)
        {
            my $complete = "$dir/$file";

            if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
            {
                if (!set_permissions($complete))
                {
                    return 0;
                }
            }
            else
            {
                if (is_executable($complete, $ft) || is_script($complete, $ft))
                {
                    set_permissions_on_file($complete);
                }
            }
        }
    }

    return 1;
}

sub remove_dir
{
    my ($target, $timeout) = @_;

    if (!defined($timeout))
    {
        $timeout = 5;
    }

    my $errs;
    File::Path::remove_tree($target, {error => \$errs});

    if (@$errs)
    {
        foreach my $err (@$errs)
        {
            my ($file, $message) = %$err;
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["$message ($file)"]);
        }
        return 0;
    }
    else
    {
        eval
        {
            local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
            alarm $timeout;
            while (-d $target)
            {
                #print "still there...\n";
                sleep 1;
            }
            alarm 0;
        };

        if ($@)
        {
            if ($@ eq "alarm\n")
            {
                DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["$target not removed even after waiting $timeout seconds."]);
                return 0;
            }
        }
    }

    return 1;
}

sub valid_version_format
{
    my ($prev_version, $new_version, $prevent_older_check) = @_;

    if (! ($new_version =~ /^\d+\.\d+\.\d+$/) )
    {
        DPOLog::report_msg(DPOEvents::INVALID_VERSION_FORMAT, [$new_version]);
        return 0;
    }

    if (!defined($prevent_older_check))
    {
        my ($major, $minor, $patch) = $new_version =~ /(\d+)\.(\d+)\.(\d+)/;

        my ($prev_major,
            $prev_minor,
            $prev_patch) = $prev_version =~ /(\d+)\.(\d+)\.(\d+)/;

        if ($patch < $prev_patch)
        {
            if ($minor <= $prev_minor)
            {
                if ($major <= $prev_major)
                {
                    DPOLog::report_msg(DPOEvents::SMALLER_VERSION, [$new_version, $prev_version]);
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub TreeScan
{
    my ($dir, $out) = @_;

    my @content=();
    if (!get_dir_content($dir, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    foreach (@content)
    {
        my $complete = "$dir/$_";
        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if (!TreeScan($complete, $out))
            {
                return 0;
            }
        }
        else
        {
            if (-f $complete)
            {
                push(@$out, $complete);
            }
        }
    }

    return 1;
}

sub get_complete_lines
{
    # get lines where the key is.
    my ($lines, $key, $complete_lines) = @_;

    my $complete_line="";
    foreach(@$lines)
    {
        my $line = $_;

        chomp $line;

        trim(\$line);

        if (!($line =~ /^$/))
        {
            # the line is not empty

            # append the new line to the previous if the previous one
            # was ending with a backslash
            $line = $complete_line . $line;

            my $two_first_chars = substr($line, 0, 2);
            if ($two_first_chars ne "//")
            {
                if ($line =~ /\\$/)
                {
                    # the line ends with a backslash.
                    # keep this line for prepending with the subsequent one.
                    $complete_line = substr($line, 0, length($line) - 1);
                }
                else
                {
                    if ($line =~ /\Q$key\E/)
                    {
                        # save the line containing key.
                        push(@$complete_lines, $line);
                    }
                    # reset the prepending line
                    $complete_line = "";
                }
            }
        }
    }
}

sub read_features_from
{
    my ($from, $features) = @_;

    my $config_dir="";

    if (!find_dir("config", $from, \$config_dir))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't find 'config' directory in $from"]);
        return 0;
    }

    my $global = "$config_dir/global.features";

    if (-f $global)
    {
        if (!read_feature_file($global, $features))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't read feature file $global"]);
            return 0;
        }
    }

    my $default = "$config_dir/default.features";
    if (-f $default)
    {
        if (!read_feature_file($default, $features))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't read feature file $default"]);
            return 0;
        }
    }

    return 1;
}

sub is_executable
{
    my ($file, $ft) = @_;

    my $type = $ft->checktype_filename($file);

    if (!defined($type))
    {
        return 0;
    }

    if ($type =~ /x.*-executable/)
    {
        if ( -f $file
            && ($file !~ /\.dll$/)
            && ($file !~ /.*\.so$/)
            && ($file !~ /.*\.so\.\d+\.\d+\.\d+$/) )
        {
            return 1;
        }
    }

    return 0;
}

sub is_dynamic_lib
{
    my ($file, $ft) = @_;

    my $type = $ft->checktype_filename($file);

    if (!defined($type))
    {
        return 0;
    }

    if ($type =~ /x.*-executable/)
    {
        if ( -f $file
            && (($file =~ /\.dll$/)
                    || ($file =~ /.*\.so$/)
                    || ($file =~ /.*\.so\.\d+\.\d+\.\d+$/)) )
        {
            return 1;
        }
    }

    return 0;
}

sub find_dir
{
    my ($dir, $path, $path_out) = @_;

    my @dir_content=();
    if (!get_dir_content($path, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$path]);
        return 0;
    }

    foreach(@dir_content)
    {
        my $complete = "$path/$_";
        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if ($_ eq $dir)
            {
                $$path_out = $complete;
                last;
            }
            else
            {
                if (!find_dir($dir, $complete, $path_out))
                {
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub is_script
{
    my ($file, $ft) = @_;

    my $type = $ft->checktype_filename($file);

    if (-f $file)
    {
        if ( $file =~ /(\.pl|\.sh)$/ )
        {
            return 1;
        }
    }

    return 0;
}

sub TreeCopy
{
    my ($dir, $dest ) = @_;

    my @content=();
    if (!get_dir_content($dir, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    if (!DPOUtils::make_path($dest))
    {
        return 0;
    }

    foreach my $f (@content)
    {
        my $complete = "$dir/$f";

        if (-d $complete && $f ne "." && $f ne ".." && $f ne ".svn")
        {
            if (!TreeCopy($complete, "$dest/$f"))
            {
                return 0;
            }
        }
        else
        {
            if (-f $complete)
            {
                if (!File::Copy::syscopy($complete, "$dest/$f"))
                {
                    DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$complete, "$dest/$f", $!]);
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub check_essentials
{
    my ($msg_ref) = @_;

    my $rc = 1;

    my $dpo_core_root = "\$(DPO_CORE_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$dpo_core_root))
    {
        if (defined($$msg_ref))
        {
            $$msg_ref .= "\n";
        }
        $$msg_ref .= "DPO_CORE_ROOT env. var. is not defined";
        $rc=0;
    }

    my $dpo_pool_root = "\$(DPO_POOL_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$dpo_pool_root))
    {
        if (defined($$msg_ref))
        {
            $$msg_ref .= "\n";
        }
        $$msg_ref .= "DPO_POOL_ROOT env. var. is not defined";
        $rc=0;
    }

    my $mpc_root = "\$(MPC_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$mpc_root))
    {
        if (defined($$msg_ref))
        {
            $$msg_ref .= "\n";
        }
        $$msg_ref .= "MPC_ROOT env. var. is not defined";
        $rc=0;
    }
    else
    {
        unless (-d $mpc_root)
        {
            if (defined($$msg_ref))
            {
                $$msg_ref .= "\n";
            }
            $$msg_ref .= "MPC_ROOT env. var. value ($mpc_root) does not exist";
            $rc=0;
        }
    }

    return $rc;
}


sub get_tree_item_path
{
    my ($tree, $item) = @_;

    my $path = $tree->GetItemText($item);

    my $root = $tree->GetRootItem();

    if ($item == $root)
    {
        return $path;
    }

    while (1)
    {
        my $parent = $tree->GetItemParent($item);
        my $parent_text = $tree->GetItemText($parent);
        my $slash = "/";
        if ($parent_text eq "")
        {
            $slash = "";
        }
        $path = "$parent_text$slash$path";
        if ($parent == $root)
        {
            last;
        }

        $item = $parent;
    }

    return $path;
}

sub point_in_widget
{
    my ($widget, $point_ref) = @_;

    my $rect = $widget->GetScreenRect();

    if ($$point_ref[0] >= $rect->GetX() && $$point_ref[0] <= $rect->GetRight()
        && $$point_ref[1] >= $rect->GetY() && $$point_ref[1] <= $rect->GetBottom())
    {
        return 1;
    }

    return 0;
}

sub get_available_corba_interfaces
{
    my ($interfaces) = @_;

    # Get environment variables currently defined (*_ROOT)
    my $env_vars = DPOEnvVars->new();
    $env_vars->load();

    # Find relevant (corba interface) projects
    foreach my $key (keys %$env_vars)
    {
        my $env_var = $env_vars->{$key};
        my $path = $env_var->{value};

        # What is the project?
        my $project_name;
        if ($path =~ /\d+\.\d+\.\d+$/)
        {
            ($project_name) = $path =~ /.*\/(.*)\/\d+\.\d+\.\d+/;
        }
        else
        {
            ($project_name) = $path =~ /.*\/(.*)?$/;
        }

        my $include_path = "$path/include/$project_name";

        # Check existence of the mandatory files to be a Corba interface
        if (-e $include_path)
        {
            if (-e "$include_path/DPOCorbaInterface.track")
            {
                my $src_path = $include_path;
                if (!in_dpo_pool($path))
                {
                    $src_path = "$path/src";
                }

                my @content;
                if (get_dir_content($src_path, \@content))
                {
                    foreach my $file (@content)
                    {
                        if ($file =~ /(.*)\.idl$/)
                        {
                            my $module_corba_interfaces = DPOModuleCorbaInterface->new($project_name);
                            if (!extract_interfaces_from_idl($src_path, $file, $module_corba_interfaces))
                            {
                                DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't extract interfaces from $src_path/$file"]);
                                return 0;
                            }
                            push(@$interfaces, $module_corba_interfaces);
                        }
                    }
                }
                else
                {
                    DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_path]);
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub get_available_opendds_topics
{
    my ($topics) = @_;

    # Get environment variables currently defined (*_ROOT)
    my $env_vars = DPOEnvVars->new();
    $env_vars->load();

    # Find relevant (corba interface) projects
    foreach my $key (keys %$env_vars)
    {
        my $env_var = $env_vars->{$key};
        my $path = $env_var->{value};

        # What is the project?
        my $project_name;
        if ($path =~ /\d+\.\d+\.\d+$/)
        {
            ($project_name) = $path =~ /.*\/(.*)\/\d+\.\d+\.\d+/;
        }
        else
        {
            ($project_name) = $path =~ /.*\/(.*)?$/;
        }

        #~ my $src_path = "$path/src";
        my $include_path = "$path/include/$project_name";

        # Check existence of the mandatory files to be a Corba interface
        if (-e $include_path)
        {
            if (-e "$include_path/DPOOpenDDSTopic.track")
            {
                my $src_path = "$path/src";
                my @content;
                if (get_dir_content($src_path, \@content))
                {
                    foreach my $file (@content)
                    {
                        if ($file =~ /(.*)\.idl$/)
                        {
                            my $module_open_dds_topics = DPOModuleOpenDDSTopic->new($project_name);
                            if (!extract_open_dds_topics_from_idl($src_path, $file, $module_open_dds_topics))
                            {
                                DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't extract topics from $src_path/$file"]);
                                return 0;
                            }
                            push(@$topics, $module_open_dds_topics);
                        }
                    }
                }
                else
                {
                    DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_path]);
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub extract_interfaces_from_idl
{
    my ($path, $file, $module_corba_interfaces) = @_;

    my @lines;
    if (get_file_lines("$path/$file", \@lines))
    {
        foreach my $line (@lines)
        {
            if ($line =~ /interface\s*(.*?)(\:|\s|\{|\n)/)
            {
                push(@{$module_corba_interfaces->{interfaces}}, $1);
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, ["$path/$file"]);
        return 0;
    }

    return 1;
}

sub extract_open_dds_topics_from_idl
{
    my ($path, $file, $module_open_dds_topics) = @_;

    my @lines;
    if (get_file_lines("$path/$file", \@lines))
    {
        foreach my $line (@lines)
        {
            #pragma DCPS_DATA_TYPE "XYZ_ns::Xyz"
            if ($line =~ /pragma DCPS_DATA_TYPE/)
            {
                my ($topic) = $line =~ /\"(.*)\"/;
                push(@{$module_open_dds_topics->{topics}}, $topic);
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, ["$path/$file"]);
        return 0;
    }

    return 1;
}

sub replace_string_in_file
{
    my ($dir, $string, $new_string) = @_;

    my @content=();
    if (!get_dir_content($dir, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    foreach my $file (@content)
    {
        my $tmp_file = "$dir/tmpfile";

        my $complete = "$dir/$file";

        if (-f $complete
            && uc($file) !~ "\.SDF")
        {
            if (!open (THE_FILE, $complete))
            {
                print "Cannot open file : $complete.\n";
                return 0;
            }

            binmode(THE_FILE);

            # read file
            my @lines = <THE_FILE>;
            close(THE_FILE);

            if (!open (OUT, ">$tmp_file"))
            {
                print "Cannot open $tmp_file.\n";
                return 0;
            }

            binmode(OUT);
            foreach my $line (@lines)
            {
                my $xyz_lc = $string;

                # uppercase
                my $xyz_uc = uc($string);
                my $new_string_uc = uc($new_string);

                # mixed case (for class name in project templates)
                my $first_mixted = uc(substr($string, 0, 1));
                my $remain_mixted = substr($string, 1);
                my $xyz_mixted = $first_mixted . $remain_mixted;
                #~ my $xyz_mixted = "Xyz";
                my ($first, $remain) = $new_string =~ /(.)(.*)/;
                my $new_string_mixted = uc($first) . $remain;

                if ($xyz_lc ne $xyz_uc)
                {
                    $line =~ s/$xyz_uc/$new_string_uc/g;
                }

                if ($xyz_mixted ne $xyz_uc)
                {
                    $line =~ s/$xyz_mixted/$new_string_mixted/g;
                }

                $line =~ s/$xyz_lc/$new_string/g;

                print OUT $line;

                #~ my $xyz_lc = $string;

                #~ # uppercase
                #~ my $xyz_uc = uc($string);
                #~ my $new_string_uc = uc($new_string);

                #~ $line =~ s/$xyz_lc/$new_string/g;

                #~ if ($xyz_lc ne $xyz_uc)
                #~ {
                    #~ $line =~ s/$xyz_uc/$new_string_uc/g;
                #~ }

                #~ print OUT $line;
            }

            close(OUT);

            rename($tmp_file, $complete);
            my $ft = File::Type->new();
            if (is_script($complete, $ft))
            {
                set_permissions_on_file($complete);
            }
        }

        if (-d $complete && $file ne "." && $file ne ".."
            && uc($file) ne "DEBUG"
            && uc($file) ne "RELEASE"
            && uc($file) ne "BUILD"
            && uc($file) ne "BIN"
            && uc($file) ne "LIB"
            && uc($file) ne "IPCH")
        {
            if (!replace_string_in_file($complete, $string, $new_string))
            {
                return 0;
            }
        }
    }

    return 1;
}

sub find_sub_projects
{
    my ($path, $sub_projects_ref) = @_;

    my @content;
    if (get_dir_content($path, \@content))
    {
        foreach my $elem (@content)
        {
            my $complete = "$path/$elem";
            if (-d $complete)
            {
                if (-e "$complete/DPOProject.xml")
                {
                    my ($project_name) = $complete =~ /.*\/(.*)/;
                    push(@$sub_projects_ref, $project_name);
                }

                if (!DPOUtils::find_sub_projects($complete, $sub_projects_ref))
                {
                    return 0;
                }
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$path]);
        return 0;
    }

    return 1;
}

sub update_deps_version_and_type
{
    my ($project, $new_project, $panel_product) = @_;

    if (!DPOUtils::update_deps_version_and_type_in($project, "dynamic", $new_project, $panel_product))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't update dynamic dependencies version and type in $project->{name}"]);
        return 0;
    }
    if (!DPOUtils::update_deps_version_and_type_in($project, "static", $new_project, $panel_product))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't update static dependencies version and type in $project->{name}"]);
        return 0;
    }

    my @sub_projects;

    # Update sub projects too.
    my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
        return 0;
    }

    my @sub_projects_names;
    if (DPOUtils::find_sub_projects($path, \@sub_projects_names))
    {
        foreach my $project_name (@sub_projects_names)
        {
            if ($project_name ne $new_project->{name})
            {
                my $sub_project;
                if (!$panel_product->get_project($project_name, \$sub_project))
                {
                    DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$project_name]);
                    return 0;
                }
                else
                {
                    if (!DPOUtils::update_deps_version_and_type($sub_project, $new_project, $panel_product))
                    {
                        return 0;
                    }

                    if (!$panel_product->save_project($sub_project))
                    {
                        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't save project $sub_project->{name}"]);
                        return 0;
                    }
                }
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't find subprojects from $path"]);
        return 0;
    }

    return 1;
}

sub update_deps_version_and_type_in
{
    my ($project, $type, $new_project, $panel_product) = @_;

    my $deps = 0;
    if ($type eq "dynamic")
    {
        $deps = $project->{dependencies_when_dynamic};
    }
    else
    {
        $deps = $project->{dependencies_when_static};
    }

    foreach my $dep (@$deps)
    {
        if ($dep->{dpo_compliant}->{value})
        {
            my $proj;
            if (!$panel_product->get_project($dep->{name}, \$proj))
            {
                DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$dep->{name}]);
                return 0;
            }

            # Version
            $dep->{version} = $proj->{version};
            $dep->{target_version} = $proj->{target_version};

            # Type
            if ($dep->{type} == 4)
            {
                if ($type eq "dynamic")
                {
                    # Priority to dynamic type
                    if ($proj->is_dynamic_library())
                    {
                        # Set type (by default) to dynamic if the dependency type is dynamic
                        $dep->{type} = 6;
                    }
                    else
                    {
                        if ($proj->is_static_library())
                        {
                            # Set type to static if the dependency type is static only
                            $dep->{type} = 5;
                        }
                    }
                }
                else
                {
                    # Priority to static type
                    if ($proj->is_static_library())
                    {
                        # Set type (by default) to static if the dependency type is static
                        $dep->{type} = 5;
                    }
                    else
                    {
                        if ($proj->is_dynamic_library())
                        {
                            # Set type to dynamic if the dependency type is dynamic only
                            $dep->{type} = 6;
                        }
                    }
                }
            }
        }
        else
        {
            my $product_name = $dep->{dpo_compliant}->{product_name};
            my $product;
            if (DPOProductConfig::get_product_with_name($product_name, \$product))
            {
                # Version
                $dep->{version} = $product->{version};
                $dep->{target_version} = $product->{version};

                # Type
                if ($dep->{type} == 4)
                {
                    foreach my $non_compliant_lib (@{$product->{dpo_compliant_product}->{non_compliant_lib_seq}})
                    {
                        if ($non_compliant_lib->{lib_id} eq $dep->{name})
                        {
                            if ($type eq "dynamic")
                            {
                                # Priority to dynamic type
                                if ($non_compliant_lib->{dynamic_debug_lib} ne ""
                                    || $non_compliant_lib->{dynamic_release_lib} ne "")
                                {
                                    $dep->{type} = 6;
                                }
                                else
                                {
                                    if ($non_compliant_lib->{static_debug_lib} ne ""
                                        || $non_compliant_lib->{static_release_lib} ne "")
                                    {
                                        # Set type to static if the dependency type is static only
                                        $dep->{type} = 5;
                                    }
                                }
                            }
                            else
                            {
                                # Priority to static type
                                if ($non_compliant_lib->{static_debug_lib} ne ""
                                    || $non_compliant_lib->{static_release_lib} ne "")
                                {
                                    # Set type (by default) to static if the dependency type is static
                                    $dep->{type} = 5;
                                }
                                else
                                {
                                    if ($non_compliant_lib->{dynamic_debug_lib} ne ""
                                        || $non_compliant_lib->{dynamic_release_lib} ne "")
                                    {
                                        # Set type to dynamic if the dependency type is dynamic only
                                        $dep->{type} = 6;
                                    }
                                }
                            }

                            last;
                        }
                    }
                }
            }
            else
            {
                DPOLog::report_msg(DPOEvents::GET_PRODUCT_FAILURE, [$product_name]);
                return 0;
            }
        }
    }

    return 1;
}

sub make_path
{
    my ($path) = @_;

    unless (-d $path)
    {
        File::Path::mkpath($path, {error => \my $err});
        if (@$err)
        {
            for my $diag (@$err)
            {
                my ($file, $message) = %$diag;
                if ($file eq '')
                {
                    DPOLog::report_msg(DPOEvents::MAKE_PATH_FAILURE, [$message, "no file implied"]);
                }
                else
                {
                    DPOLog::report_msg(DPOEvents::MAKE_PATH_FAILURE, [$message, $file]);
                }
            }

            return 0;
        }
    }

    return 1;
}

sub valid_input
{
    my ($input) = @_;

    if ($input =~ /[a-z|A-Z|0-9|_]/)
    {
        return 1;
    }

    return 0;
}

sub available_architectures
{
    my ($self, $arch) = @_;

    push(@$arch, "i686");
    push(@$arch, "x86_64");
}


sub available_os
{
    my ($self, $oses) = @_;

    my $os = $^O;

    if ($os =~ /Win/)
    {
        push(@$oses, "windows");
    }

    if ($os eq "linux")
    {
        push(@$oses, "linux");
    }
}


sub available_tool_chains
{
    my ($self, $tools, $all) = @_;

    my $os = $^O;

    if ($os eq "linux" || $all)
    {
        push(@$tools, "gnu");
    }

    if ($os =~ /Win/ || $all)
    {
        push(@$tools, "vc71");
        push(@$tools, "vc8");
        push(@$tools, "vc9");
        push(@$tools, "vc10");
    }
}


sub available_templates
{
    my ($templates_ref) = @_;

    my @template_dirs;

    # DPO projects
    my $dpo_templates_root = "\$(DPO_TEMPLATES_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$dpo_templates_root))
    {
        print "DPO_TEMPLATES_ROOT environment variable is not defined.\n";
        return 0;
    }
    my $dpo_templates_dir = "$dpo_templates_root/project";

    push(@template_dirs, $dpo_templates_dir);

    # Private projects
    my $dpo_private_dir = "\$(DPO_PRIVATE_TEMPLATES_ROOT)";
    if (DPOEnvVars::expand_env_var(\$dpo_private_dir))
    {
        my @tokens = split(/;/, $dpo_private_dir);
        foreach my $tok (@tokens)
        {
            $tok .= "/project";
            push(@template_dirs, $tok);
        }
    }
    else
    {
        print "Available templates: no private templates defined.\n";
        # Don't return.
    }

    foreach my $dir (@template_dirs)
    {
        my @content;
        $dir =~ s/\\/\//g;
        if (DPOUtils::get_dir_content($dir, \@content))
        {
            foreach my $elem (@content)
            {
                my $complete = "$dir/$elem";
                if (-d $complete)
                {
                    my @project_file_candidates;
                    my @new_project_file_candidates;
                    if (DPOUtils::get_dir_content($complete, \@project_file_candidates))
                    {
                        foreach my $candidate (@project_file_candidates)
                        {
                            if ($candidate =~ /NewProject_(.*)\.pm/)
                            {
                                my $project_file = "$dir/$elem/$candidate";
                                my @lines;
                                if (DPOUtils::get_file_lines($project_file, \@lines))
                                {
                                    foreach my $line (@lines)
                                    {
                                        $line =~ s/\s*//g;
                                        if ($line =~ /TemplateID=(.*)/)
                                        {
                                            my $id = $1;
                                            my $new_dir = "$dir/$elem";
                                            $new_dir =~ s/\\/\//g;
                                            $templates_ref->{$id} = $new_dir; # tuple: templateID - path
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return 1;
}

sub now_text
{
    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d.%03d",
                                    $year+1900,
                                    $mon+1,
                                    $mday,
                                    $hour,
                                    $min,
                                    $sec,
                                    $microseconds / 1000);

    return "$timestamp - ";
}

sub get_projects_paths
{
    my ( $dir, $projects_paths_ref) = @_;

    my @content;
    if (get_dir_content($dir, \@content))
    {
        foreach my $elem (@content)
        {
            my $complete = "$dir/$elem";
            $complete =~ s/\\/\//g;
            if (-d $complete)
            {
                if (-e "$complete/DPOProject.xml")
                {
                    push(@$projects_paths_ref, $complete);
                }

                if (!get_projects_paths($complete, $projects_paths_ref))
                {
                    return 0;
                }
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    return 1;
}


sub get_versions_blocks
{
    my ($versions_log, $versions_blocks_ref) = @_;

    my @lines;
    if (!DPOUtils::get_file_lines($versions_log, \@lines))
    {
        return 0;
    }

    my @version_blocks;

    my @blocks;
    my @block;
    foreach my $line (reverse @lines)
    {
        chomp $line;

        if ($line =~ /^$/) # not an empty line
        {
            next;
        }

        push(@block, $line);

        if ($line =~ /\[.*\]/)
        {
            my @reverse = reverse @block;
            push(@blocks, \@reverse);
            @block = ();
        }
    }

    @blocks = reverse @blocks;

    foreach my $block (@blocks)
    {
        my $version_block = 0;

        my $i = 0;
        foreach my $line (@$block)
        {
            if ($i == 0)
            {
                my ($product_version, $timestamp) = $line =~ /\[(.*)\]\s*(.*)/;
                $version_block = VersionBlock->new($product_version, $timestamp);
            }
            else
            {
                my $status;
                my $project_name;
                my $project_version;

                if ($line =~ /-->/)
                {
                    ($status,
                        my $project_name_old,
                        my $project_version_old,
                        $project_name,
                        $project_version) = $line =~ /^(.{1})\s*(.*)-(\d+.\d+.\d+)\s*--> \s*(.*)-(\d+.\d+.\d+)/;
                }
                else
                {
                    ($status, $project_name, $project_version) = $line =~ /^(.{1})\s*(.*)-(\d+.\d+.\d+)/;
                }

                my $project = VersionBlockProject->new($project_name, $project_version, $status);
                push(@{$version_block->{projects}}, $project);
            }

            $i++;
        }

        push(@$versions_blocks_ref, $version_block);
    }

    return 1;
}


1;
