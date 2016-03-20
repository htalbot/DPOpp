#!/usr/bin/perl

use File::Type;

package DPONewProductOpenDDS;

sub new
{
    my ($class,
        $source_path,
        $version,
        $frame) = @_;

    my $self =
    {
        source_path => $source_path,
        version => $version,
        frame => $frame
    };

    bless($self, $class);

    return $self;
}

sub validate_root_path
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub validate_pool_path
{
    my ($self, $pool_path, $msg_ref) = @_;

    my ($pool_path_fname) = $pool_path =~ /.*\/(.*)$/;

   if ( uc($pool_path_fname) ne "DDS" )
    {
        $$msg_ref = "You have to select a \"ace\" directory.";
        return 0;
    }

    return 1;
}

sub get_mpc_compliant_mpbs_dirs
{
    my ($self, $mpbs_dirs_ref) = @_;

    push(@$mpbs_dirs_ref, "$self->{source_path}/MPC/config");
    push(@$mpbs_dirs_ref, "$self->{source_path}/dds");
}

sub get_mpc_compliant_modules_dirs
{
    my ($self, $libs_dirs_ref) = @_;

    push(@$libs_dirs_ref, "$self->{source_path}/lib");
}

sub special_mpb_name
{
    my ($self, $lib_id, $mpb_name_ref, $mpb_name_lib_id_ref) = @_;

    if ($lib_id =~ "OpenDDS_Model")
    {
        $$mpb_name_ref = "dds_model";
        $$mpb_name_lib_id_ref = "OpenDDS_Model";
        return 1;
    }

    return 0;
}

sub exclude_module
{
    my ($self, $module_name) = @_;

    if ($module_name =~ "OpenDDS_Federator")
    {
        return 1;
    }

    if ($module_name =~ "OpenDDS_InfoRepoServ")
    {
        return 1;
    }

    if ($module_name =~ "OpenDDS_InfoRepoLib")
    {
        return 1;
    }

    return 0;
}

sub get_product_name
{
    my ($self) = @_;

    return "DDS";
}

sub get_product_version
{
    my ($self) = @_;

    return $self->{version};
}

sub copy
{
    my ($self, $pool_path) = @_;

    print "Copy begin...\n";

    my $source = $self->{source_path};
    my $version = $self->{version};
    my $dpo_target = "$pool_path";

    # headers
    print "copy headers...\n";
    if (!$self->copy_headers($source, $dpo_target, $version))
    {
        return 0;
    }

    # libs
    print "copy libs...\n";
    if (!$self->copy_libs($source, $dpo_target))
    {
        return 0;
    }

    # executables
    print "copy executables...\n";
    if (!$self->copy_executables($source, $dpo_target))
    {
        return 0;
    }

    # scripts
    print "copy scripts...\n";
    if (!$self->copy_scripts($source, $dpo_target))
    {
        return 0;
    }

    print "copy mpc...\n";
    if (!$self->copy_MPC($source, $dpo_target, ""))
    {
        return 0;
    }

    if (!DPOUtils::set_permissions($dpo_target))
    {
        return 0;
    }

    print "...copy end.\n";

    return 1;
}

sub copy_headers
{
    my ($self, $source, $target_dir, $version) = @_;

    # get headers from these directories only:

    my $related_cpp_text="";
    if ($^O eq "linux")
    {
        $related_cpp_text = " and related cpp";
    }

    print "copy headers$related_cpp_text from $source/dds...\n";
    if (!$self->copy_headers_from("$source/dds", "$target_dir/dds"))
    {
        return 0;
    }

    my $contrib = "";
    if ($version ge "2.2.0")
    {
        $contrib = "contrib/";
    }
    print "copy headers$related_cpp_text from $source/$contrib"."wrapper...\n";
    if (!$self->copy_headers_from("$source/$contrib"."wrapper", "$target_dir/$contrib"."wrapper"))
    {
        return 0;
    }

    return 1;
}


sub copy_headers_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_dir]);
        return 0;
    }

    foreach my $file (@dir_content)
    {
        my $complete = "$src_dir/$file";

        if (-f $complete && $complete =~ /(\.h|\.inl|\.pidl|\.idl|\.mpb|\/idl\/.*\.txt)$/)
        {
            if (!DPOUtils::make_path($target_dir))
            {
                return 0;
            }

            if (!$self->copy_($complete, "$target_dir/$file"))
            {
                return 0;
            }
            if (!$self->copy_related_cpp($src_dir, $file, $target_dir))
            {
                return 0;
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
        {
            if ($file ne "example")
            {
                if (!$self->copy_headers_from($complete, "$target_dir/$file"))
                {
                    return 0;
                }
            }
        }
    }

    return 1;
}


sub copy_libs
{
    my ($self, $source, $target_dir) = @_;

    my $lib_dir = "$target_dir/lib";

    print "copy libs from $source/lib...\n";
    if (!$self->copy_libs_from("$source/lib", $lib_dir))
    {
        return 0;
    }

    return 1;
}


sub copy_libs_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_dir]);
        return 0;
    }

    foreach my $file (@dir_content)
    {
        my $complete = "$src_dir/$file";

        if (-f $complete)
        {
            my $extension_cond = 0;

            if ($^O =~ /Win/)
            {
                if ($complete =~ /(\.lib|\.dll)/)
                {
                    $extension_cond = 1;
                }
            }
            else
            {
                if ($complete =~ /\.so.+/)
                {
                    $extension_cond = 1;
                }
            }

            if (-f $complete && $extension_cond)
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!$self->copy_($complete, "$target_dir/$file"))
                {
                    return 0;
                }

                if ($^O eq "linux" &&
                    $complete =~ /\/(\d+.\d+.\d+)$/)
                {
                    # create symlink (softlink) for each *.so.x.y.z file
                    my ($so_only,
                        $version) = $complete =~ /.*\/(.*\.so)\.(\d+.\d+.\d+)$/;
                    symlink("$src_dir/$so_only", "$target_dir/$so_only");
                }
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
        {
            if (!$self->copy_libs_from($complete, $target_dir))
            {
                return 0;
            }
        }
    }

    return 1;
}


sub copy_executables
{
    my ($self, $source, $target_dir) = @_;

    my $bin_dir = "$target_dir/bin";

    print "copy executables from $source/bin...\n";
    if (!$self->copy_executables_from("$source/bin", $bin_dir))
    {
        return 0;
    }

    if (!$self->copy_perl_module_from("$source/bin", $bin_dir))
    {
        return 0;
    }

    return 1;
}


sub copy_executables_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_dir]);
        return 0;
    }

    my $ft = File::Type->new();

    foreach my $file (@dir_content)
    {
        my $complete = "$src_dir/$file";

        if (-f $complete)
        {
            if (DPOUtils::is_executable($complete, $ft))
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!$self->copy_($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
        {
            if ($file ne "DevGuideExamples"
                && $file ne "examples"
                && $file ne ".shobj"
                && $file ne "performance-tests"
                && $file ne "tests")
            {
                if (!$self->copy_executables_from($complete, $target_dir))
                {
                    return 0;
                }
            }
        }
    }

    return 1;
}

sub copy_perl_module_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_dir]);
        return 0;
    }

    foreach my $file (@dir_content)
    {
        my $complete = "$src_dir/$file";

        if (-f $complete)
        {
            if ($file =~ /\.pm$/)
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!$self->copy_($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
        {
            if ($file ne "DevGuideExamples"
                && $file ne "examples"
                && $file ne ".shobj"
                && $file ne "performance-tests"
                && $file ne "tests")
            {
                if (!$self->copy_perl_module_from($complete, "$target_dir/$file"))
                {
                    return 0;
                }
            }
        }
    }

    return 1;
}


sub copy_scripts
{
    my ($self, $source, $target_dir) = @_;

    print "copy scripts from $source/bin...\n";
    if (!$self->copy_scripts_from("$source/bin", "$target_dir/bin"))
    {
        return 0;
    }

    return 1;
}


sub copy_scripts_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_dir]);
        return 0;
    }

    my $ft = File::Type->new();

    foreach my $file (@dir_content)
    {
        my $complete = "$src_dir/$file";

        if (-f $complete)
        {
            if (DPOUtils::is_script($complete, $ft))
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!$self->copy_($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $file ne "." && $file ne ".." && $file ne ".svn")
        {
            if (!$self->copy_scripts_from($complete, "$target_dir/$file"))
            {
                return 0;
            }
        }
    }

    return 1;
}

sub copy_MPC
{
    my ($self, $src, $dpo_target, $subdir) = @_;

    if ($subdir)
    {
        print "copy $subdir/MPC...\n";
        $subdir = "/$subdir/MPC";
    }
    else
    {
        print "copy MPC...\n";
        $subdir = "/MPC";
    }

    if (!DPOUtils::TreeCopy("$src$subdir", "$dpo_target$subdir"))
    {
        return 0
    }

    return 1;
}

sub copy_related_cpp
{
    my ($self, $src_dir, $header, $target_dir) = @_;

    my @lines=();
    if (!DPOUtils::get_file_lines("$src_dir/$header", \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, ["$src_dir/$header"]);
        return 0;
    }

    foreach my $line (@lines)
    {
        if ($line =~ /#/)
        {
            if ($line =~ /include /)
            {
                if ($line =~ /\.cpp/)
                {
                    my ($file) = $line =~ /.*[\/|\"](.*\.cpp)\"?/;
                    if (!$self->copy_("$src_dir/$file", "$target_dir/$file"))
                    {
                        return 0;
                    }
                }
            }
        }
    }

    return 1;
}

sub copy_
{
    my ($self, $source, $target) = @_;

    if (!File::Copy::copy($source, $target))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$source, $target, $!]);
        return 0;
    }

    return 1;
}

sub rollback
{
    my ($self, $pool_path) = @_;

    if (!DPOUtils::remove_dir("$pool_path/$self->{version}"))
    {
        return 0;
    }

    return 1;
}


1;

