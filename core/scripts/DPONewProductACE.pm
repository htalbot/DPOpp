#!/usr/bin/perl

use File::Type;
use DPOUtils;

package DPONewProductACE;

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

    if ( ! -d "$self->{source_path}/ACE_wrappers" )
    {
        $$msg_ref = "ACE_wrappers must be a subdirectory of $self->{source_path}.";
        return 0;
    }

    return 1;
}

sub validate_pool_path
{
    my ($self, $pool_path, $msg_ref) = @_;

    my ($pool_path_fname) = $pool_path =~ /.*\/(.*)$/;

   if ( uc($pool_path_fname) ne "ACE" )
    {
        $$msg_ref = "You have to select a \"ace\" directory.";
        return 0;
    }

    return 1;
}

sub get_mpc_compliant_mpbs_dirs
{
    my ($self, $mpbs_dirs_ref) = @_;

    push(@$mpbs_dirs_ref, "$self->{source_path}/ACE_Wrappers/bin/MakeProjectCreator/config");
    push(@$mpbs_dirs_ref, "$self->{source_path}/ACE_Wrappers/TAO/MPC/config");
}

sub get_mpc_compliant_modules_dirs
{
    my ($self, $libs_dirs_ref) = @_;

    push(@$libs_dirs_ref, "$self->{source_path}/ACE_Wrappers/lib");
}

sub special_mpb_name
{
    my ($self, $lib_id, $mpb_name_ref, $mpb_name_lib_id_ref) = @_;

    if ($lib_id =~ "TAO_FTORB_Utils")
    {
        $$mpb_name_ref = "ftorbutils";
        $$mpb_name_lib_id_ref = "TAO_FTORB_Utils";
        return 1;
    }

    if ($lib_id =~ "TAO_FT_ServerORB")
    {
        $$mpb_name_ref = "ftserverorb";
        $$mpb_name_lib_id_ref = "TAO_FT_ServerORB";
        return 1;
    }

    if ($lib_id =~ "TAO_FT_ClientORB")
    {
        $$mpb_name_ref = "ftclientorb";
        $$mpb_name_lib_id_ref = "TAO_FT_ClientORB";
        return 1;
    }

    return 0;
}

sub exclude_module
{
    my ($self, $module_name) = @_;

    if ($module_name =~ "TAO_IDL_BE")
    {
        return 1;
    }

    return 0;
}

sub get_product_name
{
    my ($self) = @_;

    return "ACE";
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

    my $ACE_wrappers = "$self->{source_path}/ACE_Wrappers";
    my $tao_too = 0;
    if (-d "$ACE_wrappers/TAO")
    {
        $tao_too = 1;
    }

    my $dpo_target = "$pool_path";

    # headers
    if (!$self->copy_headers($ACE_wrappers, $dpo_target, $tao_too))
    {
        return 0;
    }

    # libs
    if (!$self->copy_libs($ACE_wrappers, $dpo_target))
    {
        return 0;
    }

    # executables
    if (!$self->copy_executables($ACE_wrappers, $dpo_target, $tao_too))
    {
        return 0;
    }

    # scripts
    if (!$self->copy_scripts($ACE_wrappers, $dpo_target, $tao_too))
    {
        return 0;
    }

    # modules (.pm)
    if (!$self->copy_modules($ACE_wrappers, $dpo_target, $tao_too))
    {
        return 0;
    }

    # it is not the include path to set to includes
    if (!$self->copy_ace_include($ACE_wrappers, $dpo_target, "include"))
    {
        return 0;
    }

    if (!$self->copy_MPC($ACE_wrappers, $dpo_target, ""))
    {
        return 0;
    }

    if ($tao_too)
    {
        if (!$self->copy_MPC($ACE_wrappers, $dpo_target, "TAO"))
        {
            return 0;
        }
    }

    if (!$self->copy_MakeProjectCreator("$ACE_wrappers/bin", "$dpo_target/bin"))
    {
        return 0;
    }

    if ($tao_too)
    {
        if (!$self->copy_TAO("$ACE_wrappers/TAO", "$dpo_target/TAO"))
        {
            return 0;
        }
    }

    #~ if (!$self->copy__set_this_env_var_script($dpo_target))
    #~ {
        #~ return 0;
    #~ }

    if (!DPOUtils::set_permissions($dpo_target))
    {
        return 0;
    }

    print "...copy end.\n";

    return 1;
}


sub copy_headers
{
    my ($self, $ace_wrappers_dir, $target_dir, $tao_too) = @_;

    # get headers from these directories only:

    my $related_cpp_text="";
    if ($^O eq "linux")
    {
        $related_cpp_text = " and related cpp";
    }

    print "copy headers$related_cpp_text from $ace_wrappers_dir/ace...\n";
    if (!$self->copy_headers_from("$ace_wrappers_dir/ace", "$target_dir/ace"))
    {
        return 0;
    }

    print "copy headers$related_cpp_text from".
            " $ace_wrappers_dir/netsvcs/lib...\n";
    if (!$self->copy_headers_from("$ace_wrappers_dir/netsvcs/lib",
                            "$target_dir/netsvcs/lib"))
    {
        return 0;
    }

    if ($tao_too)
    {
        print "copy headers$related_cpp_text from $ace_wrappers_dir/TAO/tao...\n";
        if (!$self->copy_headers_from("$ace_wrappers_dir/TAO/tao", "$target_dir/TAO/tao"))
        {
            return 0;
        }

        print "copy headers$related_cpp_text from $ace_wrappers_dir/TAO/".
                "orbsvcs/orbsvcs...\n";
        if (!$self->copy_headers_from("$ace_wrappers_dir/TAO/orbsvcs/orbsvcs",
                                "$target_dir/TAO/orbsvcs/orbsvcs"))
        {
            return 0;
        }

        print "copy headers$related_cpp_text from ".
                "$ace_wrappers_dir/TAO/TAO_IDL...\n";
        if (!$self->copy_headers_from("$ace_wrappers_dir/TAO/TAO_IDL",
                                "$target_dir/TAO/TAO_IDL"))
        {
            return 0;
        }

        print "copy needed stuff by OpenDDS from ".
                "$ace_wrappers_dir/TAO/TAO_IDL...\n";
        if (!$self->copy_stuff_needed_by_opendds("$ace_wrappers_dir/TAO/TAO_IDL",
                                            "$target_dir/TAO/TAO_IDL"))
        {
            return 0;
        }
    }

    return 1;
}


sub copy_headers_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        print "can not get content of $src_dir\n";
        return 0;
    }

    foreach(@dir_content)
    {
        my $complete = "$src_dir/$_";

        if (-f $complete && /(.h|.inl|.pidl|.idl)$/)
        {
            if (!DPOUtils::make_path($target_dir))
            {
                return 0;
            }

            if (!File::Copy::copy($complete, "$target_dir/$_"))
            {
                return 0;
            }

            if (!copy_related_cpp($src_dir, $_, $target_dir))
            {
                print "copy_related_cpp($src_dir, $_, $target_dir)\n";
                return 0;
            }
        }

        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if (!$self->copy_headers_from($complete, "$target_dir/$_"))
            {
                return 0;
            }
        }
    }

    return 1;
}


sub copy_libs
{
    my ($self, $ace_wrappers_dir, $target_dir) = @_;

    my $lib_dir = "$target_dir/lib";

    print "copy libs from $ace_wrappers_dir/lib...\n";
    if (!$self->copy_libs_from("$ace_wrappers_dir/lib", $lib_dir))
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
        print "can not get content of $src_dir\n";
        return 0;
    }

    foreach(@dir_content)
    {
        my $complete = "$src_dir/$_";

        if (-f $complete)
        {
            my $extension_cond = 0;

            if ($^O =~ /Win/)
            {
                #~ if ($complete =~ /(\.lib|\.dll|\.pdb)/)
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

                if (!File::Copy::copy($complete, "$target_dir/$_"))
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

        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
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
    my ($self, $ace_wrappers_dir, $target_dir, $tao_too) = @_;

    my $bin_dir = "$target_dir/bin";

    print "copy executables from $ace_wrappers_dir/bin...\n";
    if (!$self->copy_executables_from("$ace_wrappers_dir/bin", $bin_dir))
    {
        return 0;
    }

    if ($tao_too)
    {
        print "copy executables from $ace_wrappers_dir/TAO...\n";
        if (!$self->copy_executables_from("$ace_wrappers_dir/TAO", $bin_dir))
        {
            return 0;
        }
    }

    return 1;
}


sub copy_executables_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        print "can not get content of $src_dir\n";
        return 0;
    }

    my $ft = File::Type->new();

    foreach(@dir_content)
    {
        my $complete = "$src_dir/$_";

        if (-f $complete)
        {
            if (DPOUtils::is_executable($complete, $ft))
                #~ || ($complete =~ /\.pdb/))
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!File::Copy::copy($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if ($_ ne "DevGuideExamples"
                && $_ ne "examples"
                && $_ ne ".shobj"
                && $_ ne "performance-tests"
                && $_ ne "tests")
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


sub copy_scripts
{
    my ($self, $ace_wrappers_dir, $target_dir, $tao_too) = @_;

    print "copy scripts from $ace_wrappers_dir/bin...\n";
    if (!$self->copy_scripts_from("$ace_wrappers_dir/bin", "$target_dir/bin"))
    {
        return 0;
    }

    if ($tao_too)
    {
        print "copy scripts from $ace_wrappers_dir/TAO/bin...\n";
        if (!$self->copy_scripts_from("$ace_wrappers_dir/TAO/bin", "$target_dir/TAO/bin"))
        {
            return 0;
        }
    }

    return 1;
}


sub copy_scripts_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        print "can not get content of $src_dir\n";
        return 0;
    }

    my $ft = File::Type->new();

    foreach(@dir_content)
    {
        my $complete = "$src_dir/$_";

        if (-f $complete)
        {
            if (DPOUtils::is_script($complete, $ft))
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!File::Copy::copy($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if (!$self->copy_scripts_from($complete, "$target_dir/$_"))
            {
                return 0;
            }
        }
    }

    return 1;
}


sub copy_modules
{
    my ($self, $ace_wrappers_dir, $target_dir, $tao_too) = @_;

    print "copy modules from $ace_wrappers_dir/bin...\n";
    if (!$self->copy_modules_from("$ace_wrappers_dir/bin", "$target_dir/bin"))
    {
        return 0;
    }

    if ($tao_too)
    {
        print "copy modules from $ace_wrappers_dir/TAO/bin...\n";
        if (!$self->copy_modules_from("$ace_wrappers_dir/TAO/bin", "$target_dir/TAO/bin"))
        {
            return 0;
        }
    }

    return 1;
}


sub copy_modules_from
{
    my ($self, $src_dir, $target_dir) = @_;

    my @dir_content=();
    if (!DPOUtils::get_dir_content($src_dir, \@dir_content))
    {
        print "can not get content of $src_dir\n";
        return 0;
    }

    foreach(@dir_content)
    {
        my $complete = "$src_dir/$_";

        if (-f $complete)
        {
            if (/\.pm$/)
            {
                if (!DPOUtils::make_path($target_dir))
                {
                    return 0;
                }

                if (!File::Copy::copy($complete, $target_dir))
                {
                    return 0;
                }
            }
        }

        if (-d $complete && $_ ne "." && $_ ne ".." && $_ ne ".svn")
        {
            if (!$self->copy_modules_from($complete, "$target_dir/$_"))
            {
                return 0;
            }
        }
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


sub copy_ace_include
{
    # it is not the include path to set to includes
    my ($self, $ACE_wrappers, $new_dpo_target, $subdir) = @_;

    print "copy include (not headers)...\n";

    if (!DPOUtils::TreeCopy("$ACE_wrappers/$subdir", "$new_dpo_target/$subdir"))
    {
        return 0;
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
        print "DPOUtils::TreeCopy($src$subdir, $dpo_target$subdir) failed\n";
        return 0;
    }

    return 1;
}


sub copy_MakeProjectCreator
{
    my ($self, $src, $target) = @_;

    print "copy bin/MakeProjectCreator...\n";

    if (!DPOUtils::TreeCopy("$src/MakeProjectCreator", "$target/MakeProjectCreator"))
    {
        print "DPOUtils::TreeCopy($src/MakeProjectCreator, $target/MakeProjectCreator) failed\n";
        return 0;
    }

    return 1;
}


sub copy_TAO
{
    my ($self, $src, $target) = @_;

    print "copy TAO...\n";

    if (!DPOUtils::make_path($target))
    {
        return 0;
    }

    if (!File::Copy::copy("$src/rules.tao.GNU", "$target/rules.tao.GNU"))
    {
        return 0;
    }

    if (!File::Copy::copy("$src/VERSION", "$target/VERSION"))
    {
        return 0;
    }

    return 1;
}


sub copy_related_cpp
{
    my ($src_dir, $header, $target_dir) = @_;

    my @lines=();
    if (!DPOUtils::get_file_lines("$src_dir/$header", \@lines))
    {
        print "Couldn't get lines from $src_dir/$header: $!\n";
        return 0;
    }

    foreach(@lines)
    {
        if (/#/)
        {
            if (/include /)
            {
                if (/\.cpp/)
                {
                    my ($file) = $_ =~ /.*[\/|\"](.*\.cpp)\"?/;
                    if (!File::Copy::copy("$src_dir/$file", "$target_dir/$file"))
                    {
                        return 0;
                    }
                }
            }
        }
    }

    return 1;
}


#~ sub copy__set_this_env_var_script
#~ {
    #~ my ($self, $target) = @_;

    #~ print "set_this_env_var.pl script...\n";

    #~ my $env_var_id =  "\$(DPO_CORE_ROOT)/scripts";
    #~ my $path = $env_var_id;
    #~ if (!DPOEnvVars::expand_env_var(\$path))
    #~ {
        #~ Wx::MessageBox("DPO_CORE_ROOT not defined", "", Wx::wxOK | Wx::wxICON_ERROR);
        #~ return 0;
    #~ }

    #~ my $file = "$path/dpo_set_env_var.pl";

    #~ if (!File::Copy::copy($file, $target))
    #~ {
        #~ return 0;
    #~ }

    #~ if ($^O !~ /Win/)
    #~ {
        #~ my $output = `chmod +x $target/dpo_set_env_var.pl`;
    #~ }

    #~ return 1;
#~ }

sub copy_stuff_needed_by_opendds
{
    my ($self, $src_dir, $target_dir) = @_;

    if (!DPOUtils::make_path("$target_dir/driver"))
    {
        return 0;
    }

    if (!File::Copy::copy("$src_dir/tao_idl.cpp", "$target_dir/tao_idl.cpp"))
    {
        return 0;
    }

    if (!File::Copy::copy("$src_dir/driver/drv_args.cpp", "$target_dir/driver/drv_args.cpp"))
    {
        return 0;
    }

    if (!File::Copy::copy("$src_dir/driver/drv_preproc.cpp", "$target_dir/driver/drv_preproc.cpp"))
    {
        return 0;
    }

    return 1;
}


1;

