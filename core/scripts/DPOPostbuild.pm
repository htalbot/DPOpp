#!/usr/bin/perl

use strict;
use List::MoreUtils;
use DPOUtils;
use DPOProject;
use DPOEnvVars;
use DPOLog;
use DPOEvents;
use DPOProduct;
use DPOProject;
use DPOMPB;

package NonLocalProductDependencies;

sub new
{
    my ($class,
        $project_name,
        $product_dir) = @_;

    my $self =
    {
        project_name => $project_name,
        product_dir => $product_dir
    };

    bless($self, $class);

    $self->{product_projects_names} = [];
    $self->{loaded_projects} = [];

    return $self;
}

sub copy
{
    my ($self, $target) = @_;

    my $project;
    if (!$self->get_project($self->{project_name}, \$project))
    {
        DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$self->{project_name}]);
        return 0;
    }

    my @projects_paths;
    if (!DPOUtils::get_projects_paths("$self->{product_dir}/projects", \@projects_paths))
    {
        # TO_DO
        print "Can't get projects paths from $self->{product_dir}/projects\n";
        return 0;
    }

    # product projects names
    foreach my $x (@projects_paths)
    {
        $x =~ s/\\/\//g;

        my ($path, $project_name) = $x =~ /(.*)\/(.*)/;
        push(@{$self->{product_projects_names}}, $project_name);
    }

    my @non_product_local_modules;
    my @got;
    $self->get_non_product_local_modules($project, \@non_product_local_modules, \@got);

    my @non_product_local_runtimes;
    $self->get_non_product_local_runtimes($project, \@non_product_local_runtimes);


    # Recopy non_product_local_dependencies

    my @copied_ref=();

    foreach my $non_product_local_dependency (@non_product_local_modules)
    {
        my ($fname) = $non_product_local_dependency =~ /.*\/(.*)/;

        if (!File::Copy::syscopy($non_product_local_dependency, "$target/$fname"))
        {
            print "Failed to copy $non_product_local_dependency to $target/$fname\n";
            return 0;
        }
    }

    foreach my $non_product_local_runtime (@non_product_local_runtimes)
    {
        my ($fname) = $non_product_local_runtime =~ /.*\/(.*)/;

        if (!File::Copy::syscopy($non_product_local_runtime, "$target/$fname"))
        {
            print "Failed to copy $non_product_local_runtime to $target/$fname\n";
            return 0;
        }

        # TO_DO
        #~ if ($^O =~ /linux/)
        #~ {
            #~ if (!set_permissions($target))
            #~ {
                #~ print "Can't set permissions on $target.\n";
                #~ return 0;
            #~ }
        #~ }
    }

    return 1;
}

sub get_non_product_local_modules
{
    my ($self, $project, $non_product_local_modules_ref, $got_ref) = @_;

    # Build dependencies
    foreach my $dep (@{$project->relevant_deps()})
    {
        if ($dep->{name} ne $project->{name})
        {
            if ($dep->{dpo_compliant}->{value})
            {
                my $src = "\$(" . uc($dep->{name}) . "_PRJ_ROOT)";
                if (!DPOEnvVars::expand_env_var(\$src))
                {
                    print "Environment variable $src is not defined.\n";
                    return 0;
                }

                if (!DPOUtils::in_dpo_pool($src))
                {
                    # Local project
                    if (!List::MoreUtils::any {$_ eq $dep->{name}} @{$self->{product_projects_names}})
                    {
                        # Not in this product
                        if ($dep->{type} != 2) # not header_impl/abstract
                        {
                            # TO_DO: linux

                            # Debug
                            my $module = "$src/lib/Debug/$dep->{name}.dll";
                            if (-f $module)
                            {
                                push(@$non_product_local_modules_ref, $module);
                            }

                            my $module_d = "$src/lib/Debug/$dep->{name}d.dll";
                            if (-f $module_d)
                            {
                                push(@$non_product_local_modules_ref, $module_d);
                            }

                            # Release
                            $module = "$src/lib/Release/$dep->{name}.dll";
                            if (-f $module)
                            {
                                push(@$non_product_local_modules_ref, $module);
                            }

                            $module_d = "$src/lib/Release/$dep->{name}d.dll";
                            if (-f $module_d)
                            {
                                push(@$non_product_local_modules_ref, $module_d);
                            }
                        }
                    }
                }
            }
            else
            {
                # since $dep is not compliant, we don't try to copy the modules.
                # Remember that working on multiple projects requires that
                # the projects are compliant.
            }
        }

        my $proj;
        if ($self->get_project($dep->{name}, \$proj))
        {
            $self->get_non_product_local_modules($proj, $non_product_local_modules_ref, $got_ref);
        }
        else
        {
            # TO_DO
        }
    }
}

sub get_non_product_local_runtimes
{
    my ($self, $project, $non_product_local_modules_ref) = @_;

    my $product_name = $project->{dpo_compliant}->{product_name};

    my $env_var_id = uc($product_name) . "_ROOT";
    my $product_path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$product_path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
        return;
    }

    if (!DPOUtils::in_dpo_pool($product_path))
    {
        my $product;
        if (!DPOProductConfig::get_product_with_name($project->{dpo_compliant}->{product_name}, \$product))
        {
            DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, [$project->{dpo_compliant}->{product_name}]);
            # TO_DO
            return;
        }

        foreach my $runtime_product_compliant (@{$product->{runtime}->{runtime_products_compliant}})
        {
            my $env_var_id = uc($runtime_product_compliant->{name}) . "_ROOT";
            my $path = "\$($env_var_id)";
            if (!DPOEnvVars::expand_env_var(\$path))
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
                return;
            }

            foreach my $dep (@{$runtime_product_compliant->{dpo_project_dependencies}})
            {
                # TO_DO: linux

                # Debug
                my $module = "$path/projects/$dep->{name}/lib/Debug/$dep->{name}d.dll";
                if (-e $module)
                {
                    push(@$non_product_local_modules_ref, $module);
                }
                $module = "$path/projects/$dep->{name}/bin/Debug/$dep->{name}d.exe";
                if (-e $module)
                {
                    push(@$non_product_local_modules_ref, $module);
                }

                # Release
                $module = "$path/projects/$dep->{name}/lib/Release/$dep->{name}.dll";
                if (-e $module)
                {
                    push(@$non_product_local_modules_ref, $module);
                }
                $module = "$path/projects/$dep->{name}/bin/Release/$dep->{name}.exe";
                if (-e $module)
                {
                    push(@$non_product_local_modules_ref, $module);
                }
            }
        }
    }
}

sub get_project
{
    my ($self, $project_name, $project_ref) = @_;

    foreach my $loaded_project (@{$self->{loaded_projects}})
    {
        if ($loaded_project->{name} eq $project_name)
        {
            $$project_ref = $loaded_project;
            return 1;
        }
    }

    # Project not loaded yet

    # Is $project_name a new project in the product?
    my $path="";
    foreach my $p (@{$self->{product_projects_paths}})
    {
        $p =~ s/\\/\//g;
        my ($proj_name) = $p =~ /.*\/(.*)$/;
        if ($proj_name eq $project_name)
        {
            $path = $p;
            # Yes, it is a new project in the product.
            last;
        }
    }

    if ($path eq "")
    {
        # It's not a new project in this product.

        # DPO compliant project env. var. is defined as uc(<project_name>_PRJ_ROOT).
        # We can get it's path with env. var.

        # If uc(<project_name>_PRJ_ROOT) is not defined, either it's a dpo
        # compliant project for which the environment variable has not been set
        # yet or it's a non compliant project. In this case, there is a
        # problem with the logic of the program.

        my $env_var_id = uc($project_name) . "_PRJ_ROOT";
        $path = "\$($env_var_id)";
        if (!DPOEnvVars::expand_env_var(\$path))
        {
            DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
            return 0;
        }
    }

    my $file = "$path/DPOProject.xml";

    if (-e $file)
    {
        my $err;
        my $config = DPOProjectConfig->new($file, \$err);
        if ($config)
        {
            my $new_project;
            if ($config->get_project(\$new_project))
            {
                if (!$self->load_project_dependencies($new_project))
                {
                    DPOLog::report_msg(DPOEvents::LOAD_DYN_DEP_FAILURE, [$project_name]);
                    return 0;
                }

                $$project_ref = $new_project;

                push(@{$self->{loaded_projects}}, $new_project);
            }
            else
            {
                DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$project_name]);
                return 0;
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::LOAD_PROJECT_FAILURE, [$file, $err]);
            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::FILE_DOESNT_EXIST, [$file]);
        return 0;
    }

    return 1;
}

sub load_project_dependencies
{
    my ($self, $project) = @_;

    foreach my $dep (@{$project->{dependencies_when_dynamic}}, @{$project->{dependencies_when_static}})
    {
        if (!List::MoreUtils::any {$_->{name} eq $dep->{name}} @{$self->{loaded_projects}})
        {
            if ($dep->{dpo_compliant}->{value})
            {
                my $new_project;
                if (!$self->get_project($dep->{name}, \$new_project))
                {
                    DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$dep->{name}]);
                    return 0;
                }
            }
            else
            {
                # make $dep (DPOProjectDependency) a DPOProject
                my $new_project = DPOProject->new($dep->{name},
                                                    $dep->{version},
                                                    $dep->{target_version},
                                                    $dep->{type},
                                                    $dep->{dpo_compliant});

                # Load dependencies of the new project

                # Get product to allow load_non_compliant_dependencies getting libs types from product
                my $product;
                if (!DPOProductConfig::get_product_with_name($dep->{dpo_compliant}->{product_name}, \$product))
                {
                    DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, [$dep->{dpo_compliant}->{product_name}]);
                    return 0;
                }

                my $dpo_mpb = DPOMpb->new($new_project->{name}, # lib_id
                                            $new_project->{dpo_compliant}->{mpb}, # mpb name
                                            $new_project->{dpo_compliant}->{mpc_includes});

                # Get dependencies of $new_project and put them into loaded_projects
                if (!$dpo_mpb->load_non_compliant_dependencies($product,
                                                            $new_project,
                                                            $self->{loaded_projects},
                                                            $self->{mpbs_scanned}))
                {
                    DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't get non compliant dependencies for $dep->{name}"]);
                    return 0;
                }

                if (!List::MoreUtils::any {$_->{name} eq $new_project->{name}} @{$self->{loaded_projects}})
                {
                    push(@{$self->{loaded_projects}}, $new_project);
                }
            }
        }
    }

    return 1;
}

1;

package DPOPostbuild;

sub dpo_postbuild
{
    my ($project_name) = @_;

    my $env_var_id = uc($project_name) . "_PRJ_ROOT";

    my $src = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$src))
    {
        print "Environment variable $src is not defined.\n";
        return 0;
    }

    my $intial_wd = Cwd::getcwd();

    my $product_dir;

    while (1)
    {
        chdir("..");
        my $cwd = Cwd::getcwd();

        if ($cwd =~ /\/projects$/)
        {
            chdir("..");
            $product_dir = Cwd::getcwd();
            last;
        }
    }

    chdir($intial_wd);

    my $target = "$product_dir/run";

    if (!DPOUtils::make_path($target))
    {
        return 0;
    }
    if (!DPOUtils::make_path("$target/Release"))
    {
        return 0;
    }
    if (!DPOUtils::make_path("$target/Debug"))
    {
        return 0;
    }

    my @copied_ref=();

    my $rc = 1;

    #~ $rc = DPOPostbuild::copy_files_into_run("$src/bin", "$target", \@copied_ref);
    #~ if (!$rc)
    #~ {
        #~ return 0;
    #~ }

    $rc = DPOPostbuild::copy_files_into_run("$src/bin/Release", "$target/Release", \@copied_ref);
    if (!$rc)
    {
        return 0;
    }

    $rc = DPOPostbuild::copy_files_into_run("$src/bin/Debug", "$target/Debug", \@copied_ref);
    if (!$rc)
    {
        return 0;
    }

    #~ $rc = DPOPostbuild::copy_files_into_run("$src/lib", "$target", \@copied_ref);
    #~ if (!$rc)
    #~ {
        #~ return 0;
    #~ }

    $rc = DPOPostbuild::copy_files_into_run("$src/lib/Release", "$target/Release", \@copied_ref);
    if (!$rc)
    {
        return 0;
    }

    $rc = DPOPostbuild::copy_files_into_run("$src/lib/Debug", "$target/Debug", \@copied_ref);
    if (!$rc)
    {
        return 0;
    }

    if ($^O =~ /linux/)
    {
        if (!set_permissions($target))
        {
            print "Can't set permissions on $target.\n";
            return 0;
        }
    }

    # Copy non product local dependencies

    my $non_local_product_local_deps = NonLocalProductDependencies->new($project_name, $product_dir);
    $non_local_product_local_deps->copy($target);

    return 1;
}

sub copy_files_into_run
{
    my ($source, $target, $copied_ref, $ace_only) = @_;

    if(!defined($ace_only))
    {
        $ace_only = 0;
    }

    my $ft = File::Type->new();

    if (-e $source)
    {
        #~ print "   copy $source into $target/run\n";
        my @dir_content=();
        if (DPOUtils::get_dir_content($source, \@dir_content))
        {
            foreach my $file (@dir_content)
            {
                if ($ace_only
                    && $file !~ /^ACE[dD]?\./)
                {
                    next;
                }

                #~ print "      file = $source/$file\n";
                if ($^O =~ /Win/)
                {
                    # It's faster to compare strings than checking file type.
                    if ($file =~ /\.exe$/
                        || $file =~ /\.dll$/)
                        #~ || $file =~ /\.pdb$/)
                    {
                        if (List::MoreUtils::any {$_ eq "$source/$file"} @$copied_ref)
                        {
                            next;
                        }

                        #~ print "         copy $source/$file  to  $target\n";
                        if (!File::Copy::syscopy("$source/$file", "$target/$file"))
                        {
                            DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, ["$source/$file", $target, $!]);
                            return 0;
                        }

                        push(@$copied_ref, "$source/$file");
                    }
                }
                else
                {
                    if (DPOUtils::is_executable("$source/$file", $ft)
                        || DPOUtils::is_dynamic_lib("$source/$file", $ft))
                    {
                        if (List::MoreUtils::any {$_ eq "$source/$file"} @$copied_ref)
                        {
                            next;
                        }

                        #~ print "         copy $source/$file  to  $target\n";
                        if (!File::Copy::syscopy("$source/$file", "$target/$file"))
                        {
                            DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, ["$source/$file", $target, $!]);
                            return 0;
                        }

                        push(@$copied_ref, "$source/$file");
                    }
                }
            }
        }
    }

    return 1;
}


1;
