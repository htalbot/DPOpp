use lib $ENV{DPO_CORE_ROOT} . "/scripts";
use lib $ENV{DPO_CORE_ROOT} . "/scripts/GUI";

use strict;
use List::MoreUtils;
use File::Copy;
use File::Basename;
use Cwd;

use DPOUtils;
use DPOEvents;
use DPOProductFixDlg;
use DPOProductFreezeDlg;
use DPOProductFreezeChoiceDlg;
use DPOHeaderImplOrAbstractClassToIncludeInWorkspaceDlg;
use DPOEnvVars;

package DPONonWorkspaceProjectsDefinedAsLocal;

sub new
{
    my ($class,
        $project_name,
        $src) = @_;

    my $self =
    {
        project_name => $project_name,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package DPODiffVersion;

sub new
{
    my ($class,
        $target_version,
        $parent_name_version_array,
        $src) = @_;

    my $self =
    {
        target_version => $target_version,
        src => $src
    };

    push(@{$self->{parent_name_version_array}}, $parent_name_version_array);

    bless($self, $class);

    return $self;
}

1;

package DPOIncompatibleConfigVersion;

sub new
{
    my ($class,
        $project_name,
        $actual_version,
        $config_version,
        $parent_name) = @_;

    my $self =
    {
        project_name => $project_name,
        actual_version => $actual_version,
        config_version => $config_version,
        parent_name => $parent_name
    };

    bless($self, $class);

    return $self;
}

1;

package DPOWrongArchOsToolchainVsPool;

sub new
{
    my ($class,
        $project_name,
        $project_version,
        $project_path,
        $dpo_pool_root_path,
        $src) = @_;

    my $self =
    {
        project_name => $project_name,
        project_version => $project_version,
        project_path => $project_path,
        dpo_pool_root_path => $dpo_pool_root_path,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package DPOWrongArchOsToolchainVsWorkspace;

sub new
{
    my ($class,
        $project_name,
        $project_version,
        $arch,
        $os,
        $toolchain,
        $src) = @_;

    my $self =
    {
        project_name => $project_name,
        project_version => $project_version,
        arch =>$arch,
        os => $os,
        toolchain => $toolchain,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package DPOSameActualAndTargetVersions;

sub new
{
    my ($class,
        $project_name,
        $version,
        $src) = @_;

    my $self =
    {
        project_name => $project_name,
        version => $version,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package DPOProjectsThatShouldBeUpgraded;

sub new
{
    my ($class,
        $project_name,
        $dependencies_planned_to_be_upgraded,
        $src) = @_;

    my $self =
    {
        project_name => $project_name,
        dependencies_planned_to_be_upgraded => $dependencies_planned_to_be_upgraded,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package DPODependenciesConfigurations;

sub new
{
    my ($class,
        $parent_name,
        $project_name,
        $type_expected_by_parent,
        $project_type,
        $src) = @_;

    my $self =
    {
        parent_name => $parent_name,
        project_name => $project_name,
        type_expected_by_parent => $type_expected_by_parent,
        project_type => $project_type,
        src => $src
    };

    bless($self, $class);

    return $self;
}

1;

package BadArch;

sub new
{
    my ($class,
        $project_name) = @_;

    my $self =
    {
        project_name => $project_name,
    };

    bless($self, $class);

    return $self;
}

1;



package ToFreezeSourceTarget;

sub new
{
    my ($class, $source, $target) = @_;

    my $self =
    {
        source => $source,
        target => $target
    };

    bless($self, $class);
    return $self;
}

1;


package DPOProductRuntimeCompliantBadVersion;

sub new
{
    my ($class, $proj_name, $proj_version, $proj_dep_version) = @_;

    my $self =
    {
        proj_name => $proj_name,
        proj_version => $proj_version,
        proj_dep_version => $proj_dep_version
    };

    bless($self, $class);
    return $self;
}

1;


package DPOWorkingProjectsWithUndefinedDepType;

sub new
{
    my ($class, $project_name, $dep_name, $type) = @_;

    my $self =
    {
        project_name => $project_name,
        dep_name => $dep_name,
        type => $type
    };

    bless($self, $class);
    return $self;
}

1;


package DPOActions;

use constant {
    ACTION_VALIDATE => 1,
    ACTION_ENV_VARS => 2,
    ACTION_FETCH => 4,
    ACTION_GENERATE => 8,
    ACTION_FREEZE => 16,
    ACTION_FIX => 32,
    ACTION_CLEANUP => 64
};

my $tab = "    ";

sub new
{
    my ($class,
        $action_wanted,
        $panel_product) = @_;

    my $self =
    {
        action_wanted => $action_wanted,
        panel_product => $panel_product
    };

    bless($self, $class);

    return $self;
}

sub go
{
    my ($self, $clear_msg) = @_;

    my $wait = Wx::BusyCursor->new();

    if ($self->{action_wanted} == 0)
    {
        DPOLog::report_msg(DPOEvents::NO_ACTIONS, []);
        return 1;
    }

    if (!defined($clear_msg)
        || $clear_msg == 1)
    {
        $self->{panel_product}->{frame}->{list_ctrl_msg}->DeleteAllItems();
    }

    DPOLog::report_msg(DPOEvents::NEW_ACTIONS, []);

    if (($self->{action_wanted} & ACTION_VALIDATE))
    {
        my $ok = 1;

        # Check PATH_DPO and PATH env. vars. existence and make sure PATH_DPO is defined before PATH.
        if (!$self->path_and_path_dpo())
        {
            return 0;
        }

        # Check dpo_pool vs arch/os/toolchain
        if (!$self->check_dpo_pool_vs_workspace_arch_os_toolchain())
        {
            return 0; # Return immediately because too much useless errors are raised.
        }

        # Validate projects
        my @projects_to_validate = (@{$self->{panel_product}->{workspace_projects}}, @{$self->{panel_product}->{product_runtime}}, @{$self->{panel_product}->{runtime_in_workspace}});
        if (!$self->validate_projects(\@projects_to_validate))
        {
            $ok = 0;
        }

        if (!$ok)
        {
            return 0;
        }
    }


    if (($self->{action_wanted} & ACTION_ENV_VARS))
    {
        if (!$self->set_env_vars($self->{panel_product}->{workspace_projects}))
        {
            return 0;
        }
    }


    if (($self->{action_wanted} & ACTION_GENERATE))
    {
        if (!$self->generate($self->{panel_product}->{workspace_projects}))
        {
            return 0;
        }
    }


    if (($self->{action_wanted} & ACTION_FETCH))
    {
        my $remove_before = 1;

        if ((($self->{action_wanted} & ACTION_FETCH) == ACTION_FETCH))
        {
            my $rc = Wx::MessageBox(
                    "Do you want to keep existing run directory?",
                    "Generating run directory...",
                    Wx::wxYES_NO);
            if ($rc == Wx::wxYES)
            {
                $remove_before = 0;
            }
        }

        if (!$self->fetch_runtime($remove_before))
        {
            return 0;
        }
    }


    if (($self->{action_wanted} & ACTION_FREEZE))
    {
        if (!$self->freeze($self->{panel_product}->{workspace_projects}))
        {
            return 0;
        }
    }


    if (($self->{action_wanted} & ACTION_FIX))
    {
        DPOLog::report_msg(DPOEvents::FIXING, []);

        my $dlg = DPOProductFixDlg->new(
                        $self->{panel_product},
                        undef,
                        -1,
                        "",
                        Wx::wxDefaultPosition,
                        Wx::wxDefaultSize,
                        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);

        my $rc = $dlg->ShowModal();
        if ($rc == Wx::wxID_OK)
        {
            DPOLog::report_msg(DPOEvents::FIXING_DONE, []);

            # Validate projetcs in workspace
            my @projects_to_validate = (@{$self->{panel_product}->{workspace_projects}}, @{$self->{panel_product}->{product_runtime}}, @{$self->{panel_product}->{runtime_in_workspace}});
            $self->validate_projects(\@projects_to_validate);
        }
        else
        {
            DPOLog::report_msg(DPOEvents::FIXING_CANCELED, []);
        }

        $dlg->Destroy();
    }

    if ($self->{action_wanted} & ACTION_CLEANUP)
    {
        print "Cleanup is not implemented yet.\n";
    }

    return 1;
}

sub path_and_path_dpo
{
    my ($self) = @_;

    my $ok = 1;

    tie (my %current_env_vars, 'Tie::IxHash'); #preserve order

    foreach my $env_var_id (DPOEnvVars::get_user_env_var_list())
    {
        $current_env_vars{$env_var_id} = DPOEnvVars::get_user_env_var_value($env_var_id);
    }

    # Check if PATH_DPO and PATH are defined and
    # check if PATH_DPO is defined before PATH.
    my $path_defined = 0;
    my $path_index = 0;
    my $i = 0;
    foreach my $key (keys %current_env_vars)
    {
        if (uc($key) eq "PATH")
        {
            $path_defined = 1;
            $path_index = $i;
            last;
        }

        $i++;
    }

    my $path_dpo_defined = 0;
    my $path_dpo_index = 0;
    $i = 0;
    foreach my $key (keys %current_env_vars)
    {
        if (uc($key) eq "PATH_DPO")
        {
            $path_dpo_defined = 1;
            $path_dpo_index = $i;
            last;
        }

        $i++;
    }

    if (!$path_defined)
    {
        $ok = 0;
        DPOLog::report_msg(DPOEvents::PATH_IS_NOT_DEFINED, []);
    }

    if (!$path_dpo_defined)
    {
        $ok = 0;
        DPOLog::report_msg(DPOEvents::PATH_DPO_IS_NOT_DEFINED, []);
    }
    else
    {
        if ($path_dpo_index > $path_index)
        {
            $ok = 0;
            DPOLog::report_msg(DPOEvents::PATH_DPO_MUST_BE_DEFINED_BEFORE_PATH, []);
        }
    }

    return $ok;
}

sub check_dpo_pool_vs_workspace_arch_os_toolchain
{
    my ($self) = @_;

    my $ok = 1;

    my $dpo_pool_root_path = DPOUtils::dpo_pool_dir();

    if ($dpo_pool_root_path !~ /$self->{panel_product}->{workspace_arch}/)
    {
        $ok = 0;
    }

    if ($dpo_pool_root_path !~ /$self->{panel_product}->{workspace_os}/)
    {
        $ok = 0;
    }

    #~ if ($dpo_pool_root_path !~ /$self->{panel_product}->{workspace_toolchain}/)
    #~ {
        #~ $ok = 0;
    #~ }

    if (!$ok)
    {
        DPOLog::report_msg(DPOEvents::INCOHERENT_DPO_POOL, [$dpo_pool_root_path, $self->{panel_product}->{workspace_arch}, $self->{panel_product}->{workspace_os}, $self->{panel_product}->{workspace_toolchain}]);
    }

    return $ok;
}

sub validate_projects
{
    my ($self, $projects_ref) = @_;

    DPOLog::report_msg(DPOEvents::VALIDATE_PROJECTS, []);

    my @non_workspace_projects_defined_as_local;
    my %different_versions;
    my @incompatible_config_versions;
    my @wrong_arch_os_toolchain_vs_pool;
    my @wrong_arch_os_toolchain_vs_workspace;
    my @wrong_arch_project;
    my @same_actual_and_target_versions;
    my @projects_that_should_be_upgraded;
    my @dependencies_configurations;
    my @undetermined_project_type;
    my @non_existent_dependency_as_type;
    my @product_runtime_compliants;
    my @working_projects_with_undefined_dep_type;

    my @validated;

    foreach my $project (@$projects_ref)
    {
        # Find projects with the same version and target version
        $self->same_actual_and_target_versions(
                            $project,
                            \@same_actual_and_target_versions);

        # Find projects with dependencies that versions are planned to be upgraded.
        $self->projects_that_should_be_upgraded(
                            $project,
                            \@projects_that_should_be_upgraded);

        # Find workspace dependencies with configuration not planned to be built in workspace
        $self->undetermined_project_type(
                            $project,
                            \@undetermined_project_type);

        # Projects that are required to be validated deeply.
        $self->validate_project($project,
                                $self->{panel_product}->{this_product}->{name}, # parent
                                $self->{panel_product}->{this_product}->{version}, # parent
                                1, # parent is product
                                \@non_workspace_projects_defined_as_local,
                                \%different_versions,
                                \@incompatible_config_versions,
                                \@wrong_arch_os_toolchain_vs_pool,
                                \@wrong_arch_os_toolchain_vs_workspace,
                                \@wrong_arch_project,
                                \@dependencies_configurations,
                                \@non_existent_dependency_as_type,
                                \@validated);
    }

    $self->working_projects_with_undefined_dep_type(\@working_projects_with_undefined_dep_type);

    $self->validate_product_runtime_compliants(\@product_runtime_compliants);

    my $ok = 1;

    $self->report_validation(\$ok,
                            \@same_actual_and_target_versions,
                            \@projects_that_should_be_upgraded,
                            \@undetermined_project_type,
                            \@non_workspace_projects_defined_as_local,
                            \%different_versions,
                            \@incompatible_config_versions,
                            \@wrong_arch_os_toolchain_vs_pool,
                            \@wrong_arch_os_toolchain_vs_workspace,
                            \@wrong_arch_project,
                            \@dependencies_configurations,
                            \@non_existent_dependency_as_type,
                            \@working_projects_with_undefined_dep_type,
                            \@product_runtime_compliants);

    if ($ok)
    {
        DPOLog::report_msg(DPOEvents::PROJECTS_VALID, []);
    }
    else
    {
        DPOLog::report_msg(DPOEvents::PROJECTS_NOT_VALID, []);
    }

    return $ok;
}

sub validate_project
{
    my ($self,
        $project,
        $parent_project_name,
        $parent_project_version,
        $parent_is_product,
        $non_workspace_projects_defined_as_local_ref,
        $different_versions_ref,
        $incompatible_config_versions_ref,
        $wrong_arch_os_toolchain_vs_pool_ref,
        $wrong_arch_os_toolchain_vs_workspace_ref,
        $wrong_arch_project_ref,
        $dependencies_configurations_ref,
        $non_existent_dependency_as_type_ref,
        $validated_ref) = @_;

    if (!List::MoreUtils::any {$_ eq "$parent_project_name-$project->{name}"} @$validated_ref)
    {
        # Find 'non workspace' projects defined as local
        $self->non_workspace_project_defined_as_local(
                            $project,
                            $non_workspace_projects_defined_as_local_ref);

        # Find projects that have different version (a project can be included by more than one project that use different version)
        $self->different_version(
                            $project,
                            $parent_project_name,
                            $parent_project_version,
                            $different_versions_ref);

        $self->incompatible_config_version(
                            $project,
                            $parent_project_name,
                            $parent_is_product,
                            $incompatible_config_versions_ref);

        # Find projects with wrong arch/os/toolchain according to pool
        $self->wrong_arch_os_toolchain_vs_pool(
                            $project,
                            $wrong_arch_os_toolchain_vs_pool_ref);

        #~ # Find projects with wrong arch/os/toolchain according to workspace
        $self->wrong_arch_os_toolchain_vs_workspace(
                            $project,
                            $wrong_arch_os_toolchain_vs_workspace_ref);

        # Find projects with wrong arch
        $self->wrong_arch_project(
                            $project,
                            $wrong_arch_project_ref);

        # Find workspace dependencies with configuration not planned to be built in workspace
        $self->dependencies_configurations(
                            $project,
                            0,
                            $dependencies_configurations_ref);

        #~ # Find projects that
        $self->non_existent_dependency_as_type(
                            $project,
                            $non_existent_dependency_as_type_ref);

        # TO_DO: verifier si pour les projets d'un produit, ils correspondent tous au meme flavor ?


        push(@$validated_ref, "$parent_project_name-$project->{name}");

        foreach my $dependency (@{$project->relevant_deps()})
        {
            my $proj;
            $self->{panel_product}->get_project($dependency->{name}, \$proj);

            $self->validate_project($proj,
                                $project->{name},
                                $project->{target_version},
                                0,
                                $non_workspace_projects_defined_as_local_ref,
                                $different_versions_ref,
                                $incompatible_config_versions_ref,
                                $wrong_arch_os_toolchain_vs_pool_ref,
                                $wrong_arch_os_toolchain_vs_workspace_ref,
                                $wrong_arch_project_ref,
                                $dependencies_configurations_ref,
                                $non_existent_dependency_as_type_ref,
                                $validated_ref);
        }
    }
}

sub validate_product_runtime_compliants
{
    my ($self, $product_runtime_compliants_ref) = @_;

    foreach my $runtime_product_compliant (@{$self->{panel_product}->{this_product}->{runtime}->{runtime_products_compliant}})
    {
        foreach my $project_dependency (@{$runtime_product_compliant->{dpo_project_dependencies}})
        {
            my $proj;
            if (!$self->{panel_product}->get_project($project_dependency->{name}, \$proj))
            {
                DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$project_dependency->{name}]);
            }
            else
            {
                if ($proj->{version} ne $project_dependency->{version})
                {
                    my $x = DPOProductRuntimeCompliantBadVersion->new($proj->{name}, $proj->{version}, $project_dependency->{version});
                    push(@$product_runtime_compliants_ref, $x);
                }
            }
        }
    }
}

sub report_validation
{
    my ($self,
        $ok_ref,
        $same_actual_and_target_versions_ref,
        $projects_that_should_be_upgraded_ref,
        $undetermined_project_type_ref,
        $non_workspace_projects_defined_as_local_ref,
        $different_versions_ref,
        $incompatible_config_versions_ref,
        $wrong_arch_os_toolchain_vs_pool_ref,
        $wrong_arch_os_toolchain_vs_workspace_ref,
        $wrong_arch_project_ref,
        $dependencies_configurations_ref,
        $non_existent_dependency_as_type_ref,
        $working_projects_with_undefined_dep_type_ref,
        $product_runtime_compliants_bad_version_ref) = @_;

    foreach my $x (@$same_actual_and_target_versions_ref)
    {
        #~ #$$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::SAME_ACTUAL_AND_TARGET_VERSIONS,
                                    [$x->{project_name},
                                    $x->{version}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$projects_that_should_be_upgraded_ref)
    {
        #~ #$$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::PROJECTS_THAT_SHOULD_BE_UPGRADED,
                                    [$x->{project_name},
                                    $x->{dependencies_planned_to_be_upgraded}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$undetermined_project_type_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::UNDETERMINED_PROJECT_TYPE,
                                    [$x],
                                    (caller(0))[3]);
    }
    if (scalar(@$non_workspace_projects_defined_as_local_ref) != 0)
    {
        $$ok_ref = 1;
        if (($self->{action_wanted} & ACTION_FREEZE))
        {
            $$ok_ref = 0;
        }

        foreach my $x (@$non_workspace_projects_defined_as_local_ref)
        {
            if ($$ok_ref)
            {
                DPOLog::report_msg(DPOEvents::NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL,
                                    [$x->{project_name},
                                     $x->{project_name},
                                     $self->{panel_product}->{this_product}->{name}]);
            }
            else
            {
                DPOLog::report_msg(DPOEvents::NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL_ON_FREEZE, [$x->{project_name}]);
            }
        }
    }

    foreach my $key (keys %$different_versions_ref)
    {
        if (scalar(@{$different_versions_ref->{$key}}) > 1)
        {
            $$ok_ref = 0;

            DPOLog::report_msg(DPOEvents::DIFFERENT_VERSION, [$key]);

            foreach my $x (@{$different_versions_ref->{$key}})
            {
                my $sep = "";
                my $parent_name_version_text;
                foreach my $parent_name_version (@{$x->{parent_name_version_array}})
                {
                    $parent_name_version_text .= "$sep$parent_name_version";
                    if ($sep eq "")
                    {
                        $sep = ", ";
                    }
                }
                DPOLog::report_msg(DPOEvents::DIFFERENT_VERSION_PARENT_DEPENDS_ON,
                                            [$parent_name_version_text,
                                            "$key-$x->{target_version}"],
                                            (caller(0))[3]);
            }
        }
    }

    foreach my $x (@$incompatible_config_versions_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::INCOMPATIBLE_CONFIG_VERSION_PARENT_DEFINES,
                                    [$x->{parent_name},
                                    $x->{project_name},
                                    $x->{config_version},
                                    $x->{project_name},
                                    $x->{actual_version}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$wrong_arch_os_toolchain_vs_pool_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::WRONG_ARCH_OS_TOOLCHAIN_VS_POOL,
                                    [$x->{project_path},
                                    $x->{project_name},
                                    $x->{project_version},
                                    $x->{dpo_pool_root_path}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$wrong_arch_os_toolchain_vs_workspace_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::WRONG_ARCH_OS_TOOLCHAIN_VS_WORKSPACE,
                                    [$x->{arch},
                                    $x->{os},
                                    $x->{toolchain},
                                    $x->{project_name},
                                    $x->{project_version},
                                    $self->{panel_product}->{workspace_arch},
                                    $self->{panel_product}->{workspace_os},
                                    $self->{panel_product}->{workspace_toolchain}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$wrong_arch_project_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::WRONG_ARCH,
                                    [$x->{project_name}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$dependencies_configurations_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::DEPENDENCY_CONFIG_NOT_PLANNED_TO_BE_PART_OF_WORKSPACE,
                                    [$x->{parent_name},
                                    $x->{project_name},
                                    $x->{project_type},
                                    $x->{project_name},
                                    $x->{type_expected_by_parent},
                                    @$dependencies_configurations_ref],
                                    (caller(0))[3]);
    }

    # $non_existent_dependency_as_type_ref...

    foreach my $x (@$working_projects_with_undefined_dep_type_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::PROJECT_WITH_UNDEFINED_DEP_TYPE,
                                    [$x->{project_name},
                                    $x->{dep_name},
                                    $x->{type}],
                                    (caller(0))[3]);
    }

    foreach my $x (@$product_runtime_compliants_bad_version_ref)
    {
        $$ok_ref = 0;

        DPOLog::report_msg(DPOEvents::PRODUCT_RUNTIME_DEPENDENCY_BAD_VERSION,
                                    [$x->{proj_name},
                                    $x->{proj_version},
                                    $x->{proj_dep_version}],
                                    (caller(0))[3]);
    }
}

sub non_workspace_project_defined_as_local
{
    my ($self, $project, $non_workspace_projects_defined_as_local_ref) = @_;

    if (!List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        # $project is a non workspace project...

        if ($project->{dpo_compliant}->{value})
        {
            my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
            my $env_var_value = "\$($env_var_id)";
            if (DPOEnvVars::expand_env_var(\$env_var_value))
            {
                if (!DPOUtils::in_dpo_pool($env_var_value))
                {
                    if (!List::MoreUtils::any {$_->{project_name} eq $project->{name}} @$non_workspace_projects_defined_as_local_ref)
                    {
                        my $x = DPONonWorkspaceProjectsDefinedAsLocal->new($project->{name});
                        push(@$non_workspace_projects_defined_as_local_ref, $x);
                    }
                }
            }
            else
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_value]);
            }
        }
        else
        {
            my $env_var_id = uc($project->{dpo_compliant}->{product_name}) . "_ROOT";
            my $env_var_value = "\$($env_var_id)";
            if (DPOEnvVars::expand_env_var(\$env_var_value))
            {
                if (!DPOUtils::in_dpo_pool($env_var_value))
                {
                    if (!List::MoreUtils::any {$_->{project_name} eq $project->{name}} @$non_workspace_projects_defined_as_local_ref)
                    {
                        my $x = DPONonWorkspaceProjectsDefinedAsLocal->new($project->{name});
                        push(@$non_workspace_projects_defined_as_local_ref, $x);
                    }
                }
            }
            else
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_value]);
            }
        }
    }
}

sub different_version
{
    my ($self, $project, $parent_name, $parent_version, $versions_ref) = @_;

    if (!defined($versions_ref->{$project->{name}}))
    {
        $versions_ref->{$project->{name}} = [];
    }

    my $diff_version;
    foreach my $x (@{$versions_ref->{$project->{name}}})
    {
        if ($x->{target_version} eq $project->{target_version})
        {
            $diff_version = $x;
            last;
        }
        else
        {
            my $diff_version = DPODiffVersion->new($project->{target_version}, "$parent_name-$parent_version");
            push(@{$versions_ref->{$project->{name}}}, $diff_version);
        }
    }

    if (defined($diff_version))
    {
        my $parent = "$parent_name-$parent_version";
        if (!List::MoreUtils::any {$_ eq $parent} @{$diff_version->{parent_name_version_array}})
        {
            if ($parent_name ne "")
            {
                # Append a parent to $diff_version
                push(@{$diff_version->{parent_name_version_array}}, $parent);
            }
        }
    }
    else
    {
        if ($parent_name ne "")
        {
            # Add a new entry
            my $diff_version = DPODiffVersion->new($project->{target_version}, "$parent_name-$parent_version");
            push(@{$versions_ref->{$project->{name}}}, $diff_version);
        }
    }
}

sub incompatible_config_version
{
    my ($self, $project, $parent_project_name, $parent_is_product, $versions_ref) = @_;

    # Find projects that have different config version versus the actual project version
    my $actual_version = $project->get_actual_version();
    if($actual_version ne "")
    {
        if ($actual_version ne $project->{target_version})
        {
            if (!List::MoreUtils::any {"$_->{project_name}-$_->{actual_version}-$_->{config_version}-$_->{parent_name}"
                    eq "$project->{name}-$actual_version-$project->{version}-$parent_project_name"} @$versions_ref)
            {
                my $product_name = $self->{panel_product}->{this_product}->{name};

                if ($parent_is_product)
                {
                    $parent_project_name .= " (as product)";
                }

                if ((List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{product_runtime}})
                    && $parent_is_product)
                {
                    $parent_project_name .= " (runtime)";
                }

                if ((List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{runtime_in_workspace}})
                    && $parent_is_product)
                {
                    $parent_project_name .= " (workspace runtime)";
                }

                my $x = DPOIncompatibleConfigVersion->new($project->{name}, $actual_version, $project->{target_version}, $parent_project_name);
                push(@$versions_ref, $x);
            }
        }
    }
}

sub wrong_arch_os_toolchain_vs_pool
{
    my ($self, $project, $output_ref) = @_;

    #~ print DPOUtils::now_text(), "wrong_arch_os_toolchain_vs_pool - $project->{name}\n";

    # We need to check for non workspace project only since
    # workspace arch/os/toolchain will be forcely applied to
    # projects of workspace.
    if (!List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
        if (!$project->{dpo_compliant}->{value})
        {
            $env_var_id = uc($project->{dpo_compliant}->{product_name}) . "_ROOT";
        }

        my $project_path = "\$($env_var_id)";
        if (DPOEnvVars::expand_env_var(\$project_path))
        {
            if (DPOUtils::in_dpo_pool($project_path))
            {
                my $dpo_pool_root_path = DPOUtils::dpo_pool_dir();

                if ($project_path !~ /$dpo_pool_root_path/)
                {
                    my $wrong_arch_os_toolchain = DPOWrongArchOsToolchainVsPool->new($project->{name}, $project->{version}, $project_path, $dpo_pool_root_path);
                    push(@$output_ref, $wrong_arch_os_toolchain);
                }
            }
            else
            {
                print "$project->{name} is local. We can't check for arch/os/toolchain (vs pool).\n";
            }
        }
        else
        {
            if ($project->{dpo_compliant}->{value})
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$project_path]);
            }
        }
    }
}

sub wrong_arch_os_toolchain_vs_workspace
{
    my ($self, $project, $output_ref) = @_;

    #~ print DPOUtils::now_text(), "wrong_arch_os_toolchain_vs_pool - $project->{name}\n";

    if ($self->{panel_product}->{workspace_name} eq "")
    {
        return;
    }

    # We need to check for non workspace project only since
    # workspace arch/os/toolchain will be forcely applied to
    # projects of workspace.
    if (!List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
        if (!$project->{dpo_compliant}->{value})
        {
            $env_var_id = uc($project->{dpo_compliant}->{product_name}) . "_ROOT";
        }

        my $project_path = "\$($env_var_id)";
        if (DPOEnvVars::expand_env_var(\$project_path ))
        {
            if (DPOUtils::in_dpo_pool($project_path))
            {
                my $dpo_pool_root_path = DPOUtils::dpo_pool_dir();

                my ($arch, $os) = $project_path =~ /.*\/dpo_pool-(.*)-(.*?)\//;
                my ($tool_chain) = $project_path=~ /\Q$dpo_pool_root_path\E\/(.*?)\//;

                #~ print "ARCH = $arch, OS = $os, $tool_chain ($self->{panel_product}->{workspace_arch}, $self->{panel_product}->{workspace_os}, $self->{panel_product}->{workspace_toolchain})\n";

                if ($arch ne $self->{panel_product}->{workspace_arch}
                    || $os ne $self->{panel_product}->{workspace_os}
                    || $tool_chain ne $self->{panel_product}->{workspace_toolchain})
                {
                    my $wrong_arch_os_toolchain = DPOWrongArchOsToolchainVsWorkspace->new($project->{name}, $project->{version}, $arch, $os, $tool_chain);
                    push(@$output_ref, $wrong_arch_os_toolchain);
                }
            }
            else
            {
                print "$project->{name} is local. We can't check for arch/os/toolchain (vs workspace).\n";
            }
        }
        else
        {
            if ($project->{dpo_compliant}->{value})
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$project_path]);
            }
        }
    }
}

sub wrong_arch_project
{
    my ($self, $project, $output_ref) = @_;

    my $dpo_pool_root_path = DPOUtils::dpo_pool_dir();

    # We need to check for non workspace project only since
    # workspace arch/os/toolchain will be forcely applied to
    # projects of workspace.
    if (!List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        # Don't process product projects (not in the workspace)
        if ($project->{dpo_compliant}->{product_name} ne $self->{panel_product}->{this_product}->{name})
        {
            my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
            if (!$project->{dpo_compliant}->{value})
            {
                $env_var_id = uc($project->{dpo_compliant}->{product_name}) . "_ROOT";
            }

            my $project_path = "\$($env_var_id)";
            if (DPOEnvVars::expand_env_var(\$project_path))
            {
                $project_path =~ s/\\/\//g;

                if ($project_path !~ /$dpo_pool_root_path/)
                {
                    if ($project_path =~ /dpo_pool\-/)
                    {
                        if (!List::MoreUtils::any {$_->{project_name} eq $project->{name}} @$output_ref)
                        {
                            my $bad_arch = BadArch->new($project->{name});
                            push(@$output_ref, $bad_arch);
                        }
                    }
                }
            }
        }
    }
}

sub same_actual_and_target_versions
{
    my ($self, $project, $output_ref) = @_;

    if (List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        if ($project->{version} eq $project->{target_version})
        {
            my $same_actual_and_target_versions = DPOSameActualAndTargetVersions->new($project->{name}, $project->{version});
            push(@$output_ref, $same_actual_and_target_versions);
        }
    }
}

sub projects_that_should_be_upgraded
{
    my ($self, $project, $output_ref) = @_;

    my @dependencies_planned_to_be_upgraded;
    foreach my $dependency (@{$project->relevant_deps()})
    {
        if ($dependency->{version} ne $dependency->{target_version})
        {
            if (!List::MoreUtils::any {$_ eq $dependency->{name}} @dependencies_planned_to_be_upgraded)
            {
                push(@dependencies_planned_to_be_upgraded, "$dependency->{name} ($dependency->{version} -> $dependency->{target_version})");
            }
        }
    }

    if (scalar(@dependencies_planned_to_be_upgraded) != 0)
    {
        my $dependencies_planned_to_be_upgraded = "";
        my $first = 1;
        my $sep = "";
        foreach my $x (@dependencies_planned_to_be_upgraded)
        {
            $dependencies_planned_to_be_upgraded .= "$sep$x";
            if ($first)
            {
                $sep = ", ";
                $first = 0;
            }
        }

        if ($project->{version} eq $project->{target_version})
        {
            my $project_that_should_be_upgraded = DPOProjectsThatShouldBeUpgraded->new($project->{name}, $dependencies_planned_to_be_upgraded);
            push(@$output_ref, $project_that_should_be_upgraded);
        }
    }
}

sub dependencies_configurations
{
    my ($self, $project, $parent, $output_ref) = @_;

    foreach my $workspace_project (@{$self->{panel_product}->{workspace_projects}})
    {
        if ($workspace_project->{name} eq $project->{name})
        {
            if (($workspace_project->{type} & $project->{type}) != $project->{type})
            {
                my $project_type_text;
                if ($project->{type} == 5)
                {
                     $project_type_text = "'static'";
                }
                if ($project->{type} == 6)
                {
                     $project_type_text = "'dynamic'";
                }
                if ($project->{type} == 7)
                {
                     $project_type_text = "'dynamic/static'";
                }

                my $type_expected_by_parent_text;
                if ($workspace_project->{type} == 5)
                {
                     $type_expected_by_parent_text = "'static'";
                }
                if ($workspace_project->{type} == 6)
                {
                     $type_expected_by_parent_text = "'dynamic'";
                }
                if ($workspace_project->{type} == 7)
                {
                     $type_expected_by_parent_text = "'dynamic/static'";
                }

                if ($parent->{type} != 1) # test application along dpo compliant library
                {
                    my $x = DPODependenciesConfigurations->new($parent->{name}, $project->{name}, $type_expected_by_parent_text, $project_type_text);
                    if (!List::MoreUtils::any {$_->{parent_name} eq $x->{parent_name}} @{$output_ref})
                    {
                        push(@{$output_ref}, $x);
                    }
                }
            }
        }
    }
}

sub undetermined_project_type
{
    my ($self, $project, $output_ref) = @_;

    foreach my $workspace_project (@{$self->{panel_product}->{workspace_projects}})
    {
        if ($workspace_project->{name} eq $project->{name})
        {
            if ($project->{type} == 4)
            {
                push(@{$output_ref}, $project->{name});
            }
        }
    }
}

sub non_existent_dependency_as_type
{
    # TO_DO TO_DO TO_DO TO_DO TO_DO TO_DO TO_DO TO_DO
    my ($self, $project, $output_ref) = @_;

    #~ foreach my $dependency (@{$project->{dependencies_when_dynamic}})
    #~ {
        #~ my $dep;
        #~ if ($self->{panel_product}->get_project($dependency->{name}, \$dep))
        #~ {
            #~ if ($dependency->{type} == 6
                #~ ||$dependency->{type} == 7)
            #~ {
                #~ if (!$dep->is_dynamic_library())
                #~ {
                    #~ # ref a une dep qui n'existe pas
                    #~ push(@$output_ref, $dependency->{name});
                #~ }
            #~ }
            #~ else
            #~ {
                #~ if ($dependency->{type} == 5)
                #~ {
                    #~ if ($dep->is_dynamic_library())
                    #~ {
                        #~ # $dependency->{name} definie en tant que static alors que la dynamic existe
                    #~ }

                    #~ if (!$dep->is_static_library())
                    #~ {
                        #~ # ref a une dep qui n'existe pas
                        #~ push(@$output_ref, $dependency->{name});
                    #~ }
                #~ }
            #~ }
        #~ }
        #~ else
        #~ {
            #~ # TO_DO
        #~ }

        #~ $self->non_existent_dependency_as_type($dependency, $output_ref);
    #~ }

    #~ foreach my $dependency (@{$project->{dependencies_when_static}})
    #~ {
        #~ # meme chose mais attention, on est en static icitte.
    #~ }
}

sub working_projects_with_undefined_dep_type
{
    my ($self, $working_projects_with_undefined_dep_type_ref) = @_;

    foreach my $workspace_project (@{$self->{panel_product}->{workspace_projects}})
    {
        my %dep_types;
        foreach my $dep (@{$workspace_project->relevant_deps()})
        {
            if ($dep->{type} == 7
                || $dep->{type} == 4)
            {
                my $p = DPOWorkingProjectsWithUndefinedDepType->new($workspace_project->{name}, $dep->{name}, $dep->{type});
                push(@$working_projects_with_undefined_dep_type_ref, $p);
            }
        }
    }
}

sub set_env_vars
{
    my ($self, $workspace_projects_ref) = @_;

    DPOLog::report_msg(DPOEvents::ENV_VAR_SETTING, []);

    my @listEnvVarValues = ();

    # PATH_DPO env. var.
    my $product_path = $self->{panel_product}->{this_product}->{path};

    my $sep = ":";
    if ($^O =~ /Win/)
    {
        $sep = ";";
    }

    my $path = "$product_path/run";
    $path .= $sep . "$product_path/run/Release";
    $path .= $sep . "$product_path/run/Debug";

    my $path_dpo_env_var = DPOEnvVar->new("PATH_DPO", $path);
    push(@listEnvVarValues, $path_dpo_env_var);

    my @list_of_paths;
    if (!DPOUtils::get_projects_paths("$product_path/projects", \@list_of_paths))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't get paths of projects"]);
        return 0;
    }

    # Workspace projects env. var.
    foreach my $project (@{$self->{panel_product}->{workspace_projects}})
    {
        foreach my $elem (@list_of_paths)
        {
            $elem =~ s/\\/\//g;

            if ($elem =~ /(.*)\/$project->{name}$/)
            {
                my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
                my $path_dpo_env_var = DPOEnvVar->new($env_var_id, $elem);
                #~ print "New env. var. to define: $env_var_id --> $elem\n";
                push(@listEnvVarValues, $path_dpo_env_var);
                next;
            }
        }
    }

    my $rc = DPOEnvVars::system_set_env_vars(\@listEnvVarValues);
    if (!$rc)
    {
        Wx::MessageBox(
                "DPOWorkspace::set_env_vars() - can't set environment variables.",
                "Setting environment variables",
                Wx::wxOK | Wx::wxICON_ERROR);
        DPOLog::report_msg(DPOEvents::ENV_VAR_SETTING_FAILURE, []);
        return 0;
    }

    DPOLog::report_msg(DPOEvents::PATH_DPO_SETTING_OK, [$path]);
    DPOLog::report_msg(DPOEvents::ENV_VAR_SETTING_OK, []);

    return 1;
}

sub fetch_runtime
{
    my ($self, $remove_before) = @_;

    DPOLog::report_msg(DPOEvents::FETCH_RUNTIME, []);

    my $intial_wd = Cwd::getcwd();

    chdir($self->{panel_product}->{workspace_path});

    my $product_dir;

    while (1)
    {
        chdir("..");
        my $cwd = Cwd::getcwd();

        if ($cwd =~ /\/workspaces/)
        {
            chdir("..");
            $product_dir = Cwd::getcwd();
            last;
        }
    }

    chdir($intial_wd);

    my $target = "$product_dir/run";

    if ($remove_before)
    {
        # Remove runtime directory
        while (1)
        {
            if (DPOUtils::remove_dir($target))
            {
                last;
            }

            sleep(2);

            my $msg = "Failed to remove $target directory.\n\nSome processes may be running. Please, close them.\n\nIf the problem persists, look for a process that uses a dependency. For example EventViewer can use ACE.";
            my $rc = Wx::MessageBox(
                    "$msg.\n\n".
                    "Retry ?",
                    "Generating run directory...",
                    Wx::wxYES_NO);

            if ($rc == Wx::wxYES)
            {
                next;
            }
            else
            {
                return 0;
            }
        }
    }

    unless (-d $target)
    {
        # Create paths
        if (!DPOUtils::make_path($target))
        {
            return 0;
        }
    }

    # TO_DO: determine if they are useful
    #~ if (!DPOUtils::make_path("$target/Release"))
    #~ {
        #~ return 0;
    #~ }
    #~ if (!DPOUtils::make_path("$target/Debug"))
    #~ {
        #~ return 0;
    #~ }

    # Fetch

    $self->{fetch_to_copy} = [];
    $self->{fetch_not_found} = []; # list of modules that have not been found

    # Find modules to fetch: $self->{fetch_to_copy}

    # Modules from workspace projects
    foreach my $project (@{$self->{panel_product}->{workspace_projects}})
    {
        foreach my $dep (@{$project->relevant_deps()})
        {
            my $proj;
            $self->{panel_product}->get_project($dep->{name}, \$proj);

            if (!$self->fetch_modules_from_project($proj))
            {
                DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PROJECT_FAILURE, [$proj->{name}]);
                return 0;
            }
        }
    }

    # Modules from runtime dependencies
    if (!$self->fetch_modules_from_product_runtime_dependencies($self->{panel_product}->{this_product}, "product"))
    {
        DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PRODUCT_RUNTIME_DEPENDENCIES_FAILURE, [$self->{panel_product}->{this_product}->{name}]);
        return 0;
    }

    # Modules from workspace runtime (those from projects that are
    # not in workspace)
    if (!$self->fetch_modules_from_workspace_runtime_dependencies())
    {
        DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_WORKSPACE_RUNTIME_DEPENDENCIES_FAILURE, []);
        return 0;
    }

    # Advise that some modules have not been found.
    my $ok = 1;
    if (scalar(@{$self->{fetch_not_found}} != 0))
    {
        my $modules = "";
        foreach my $x (@{$self->{fetch_not_found}})
        {
            $modules .= "- $x\n";
        }

        my $rc = Wx::MessageBox("These modules have not been found.\n\n$modules\nDo you want to continue copying other modules ?",
                                "Fetch runtime",
                                Wx::wxYES_NO);
        if ($rc == Wx::wxNO)
        {
            $ok = 0;
        }
    }

    # Copy $self->{fetch_to_copy} modules into run directory.
    if ($ok)
    {
        foreach my $module (@{$self->{fetch_to_copy}})
        {
            my ($path, $fname) = $module =~ /(.*)\/(.*)/;
            my $target_file = "$product_dir/run/$fname";
            unless (-e $target_file)
            {
                if (!File::Copy::syscopy($module, $target_file))
                {
                    DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$module, $target, $!]);
                    $ok = 0;
                }
            }

            # Now, look for complement. A complement is a debug module if the
            # actual module is release and a release module if the actual
            # module is debug.
            my @suffixes;
            if ($^O =~ /Win/)
            {
                @suffixes = qw(.exe .dll);
            }
            else
            {
                # TO_DO: linux
            }

            my ($filename, $dirs, $ext) = File::Basename::fileparse($module, @suffixes);

            # Copy debug module if it exists
            my $debug_filename = "$path/$filename"."d$ext";
            if (-f $debug_filename)
            {
                my $target_file = "$product_dir/run/$filename"."d$ext";
                unless (-e $target_file)
                {
                    if (!File::Copy::syscopy($debug_filename, $target_file))
                    {
                        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$debug_filename, $target_file, $!]);
                        $ok = 0;
                    }
                }
            }

            # Copy release module if it exists
            if ($filename =~ /(.*)d$/)
            {
                my $release_filename = "$path/$1$ext";

                if (-f $release_filename)
                {
                    my $target_file = "$product_dir/run/$1$ext";
                    unless (-e $target_file)
                    {
                        if (!File::Copy::syscopy($release_filename, $target_file))
                        {
                            DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$release_filename, $target_file, $!]);
                            $ok = 0;
                        }
                    }
                }
            }
        }
    }

    if ($ok)
    {
        DPOLog::report_msg(DPOEvents::FETCH_RUNTIME_OK, []);
    }
    else
    {
        DPOLog::report_msg(DPOEvents::FETCH_RUNTIME_FAILURE, []);
    }

    return $ok;
}

sub fetch_modules_from_project
{
    my ($self, $project) = @_;

    if (List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        # The project is a workspace project. We don't need to fetch
        # its module since it is available after having built project.
        return 1;
    }

    # The project is either an external module or a project of 'this_product'
    # not in the workspace.
    if ($project->{dpo_compliant}->{value})
    {
        if (!$self->fetch_modules_from_compliant_project($project))
        {
            DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_COMPLIANT_PROJECT_FAILURE, [$project->{name}]);
            return 0;
        }
    }
    else
    {
        if (!$self->fetch_modules_from_non_compliant_project($project))
        {
            DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_NON_COMPLIANT_PROJECT_FAILURE, [$project->{name}]);
            return 0;
        }
    }

    return 1;
}

sub fetch_modules_from_compliant_project
{
    my ($self, $project) = @_;

    if (List::MoreUtils::any {$_ eq $project->{name}} @{$self->{fetch_checked}})
    {
        return 1;
    }

    if (List::MoreUtils::any {$_->{name} eq $project->{name}} @{$self->{panel_product}->{workspace_projects}})
    {
        print "$project->{name} is a workspace project. Don't need to fetch it.\n";
        return 1;
    }

    my $env_var_id = "\$(" . uc($project->{name}) . "_PRJ_ROOT)";
    my $path = $env_var_id;
    if (DPOEnvVars::expand_env_var(\$path))
    {
        $path =~ s/\\/\//g;


        if ($project->is_executable())
        {
            my $found_debug = 0;

            # Debug
            my $module_name = "$project->{name}d.exe";

            my $complete = "$path/bin/$module_name";
            if (-f $complete)
            {
                push(@{$self->{fetch_to_copy}}, $complete);
                $found_debug = 1;
            }
            else
            {
                my $complete = "$path/bin/Debug/$module_name";
                if (-f $complete)
                {
                    push(@{$self->{fetch_to_copy}}, $complete);
                    $found_debug = 1;
                }
                else
                {
                }
            }

            if (!$found_debug)
            {
                DPOLog::report_msg(DPOEvents::MODULE_NOT_FOUND, ["$project->{name}d.exe", "$env_var_id/bin | $env_var_id/bin/Debug"]);
                push(@{$self->{fetch_not_found}}, "$project->{name}d.exe");
            }

            # Release
            my $found_release = 0;

            $module_name = "$project->{name}.exe";

            $complete = "$path/bin/$module_name";
            if (-f $complete)
            {
                push(@{$self->{fetch_to_copy}}, $complete);
                $found_release = 1;
            }
            else
            {
                my $complete = "$path/bin/Release/$module_name";
                if (-f $complete)
                {
                    push(@{$self->{fetch_to_copy}}, $complete);
                    $found_release = 1;
                }
            }

            if (!$found_release)
            {
                DPOLog::report_msg(DPOEvents::MODULE_NOT_FOUND, ["$project->{name}.exe", "$env_var_id/bin | $env_var_id/bin/Release"]);
                push(@{$self->{fetch_not_found}}, "$project->{name}.exe");
            }

            if ($found_debug || $found_release)
            {
                push(@{$self->{fetch_checked}}, $project->{name});
            }

            push(@{$self->{fetch_checked}}, $project->{name});
        }
        else
        {
            if ($project->{type} == 6)
            {
                my $found_debug = 0;

                # Debug
                my $module_name = "$project->{name}d.dll";

                my $complete = "$path/lib/$module_name";
                if (-f $complete)
                {
                    push(@{$self->{fetch_to_copy}}, $complete);
                    $found_debug = 1;
                }
                else
                {
                    my $complete = "$path/lib/Debug/$module_name";
                    if (-f $complete)
                    {
                        push(@{$self->{fetch_to_copy}}, $complete);
                        $found_debug = 1;
                    }
                }

                if (!$found_debug)
                {
                    DPOLog::report_msg(DPOEvents::MODULE_NOT_FOUND, ["$project->{name}d.dll", "$env_var_id/lib | $env_var_id/lib/Debug"]);
                    push(@{$self->{fetch_not_found}}, "$project->{name}d.dll");
                }

                # Release
                my $found_release = 0;

                $module_name = "$project->{name}.dll";

                $complete = "$path/lib/$module_name";
                if (-f $complete)
                {
                    push(@{$self->{fetch_to_copy}}, $complete);
                    $found_release = 1;
                }
                else
                {
                    my $complete = "$path/lib/Release/$module_name";
                    if (-f $complete)
                    {
                        push(@{$self->{fetch_to_copy}}, $complete);
                        $found_release = 1;
                    }
                }

                if (!$found_release)
                {
                    DPOLog::report_msg(DPOEvents::MODULE_NOT_FOUND, ["$project->{name}.dll", "$env_var_id/lib | $env_var_id/lib/Release"]);
                    push(@{$self->{fetch_not_found}}, "$project->{name}.dll");
                }
            }

            push(@{$self->{fetch_checked}}, $project->{name});
        }

        # If the project is in 'this_product', we have to fetch the module
        # of this project only (not those related to runtime dependencies of
        # 'this_product'). But, if product of the project is different of
        # 'this_product', we have to fetch modules from runtime dependencies of
        # the product.
        if ($project->{dpo_compliant}->{product_name} ne $self->{panel_product}->{this_product}->{name})
        {
            if (!$self->fetch_modules_from_product_runtime_dependencies($project, "project"))
            {
                DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PRODUCT_RUNTIME_DEPENDENCIES_FAILURE, [$project->{name}]);
                return 0;
            }
        }

        # Fetch relevant modules from dependencies
        foreach my $dep (@{$project->relevant_deps()})
        {
            my $proj;
            $self->{panel_product}->get_project($dep->{name}, \$proj);

            if (!$self->fetch_modules_from_project($proj))
            {
                DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PROJECT_FAILURE, [$proj->{name}]);
                return 0;
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$path]);
        return 0;
    }

    return 1;
}

sub fetch_modules_from_product_runtime_dependencies
{
    my ($self, $product_or_project, $which_type) = @_;

    my $product_name;

    if ($which_type eq "project")
    {
        $product_name = $product_or_project->{dpo_compliant}->{product_name};
    }
    else
    {
        $product_name = $product_or_project->{name};
    }

    my $product;
    if (!DPOProductConfig::get_product_with_name($product_name, \$product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, [$product_name]);
        return 0;
    }

    foreach my $p (@{$product->{runtime}->{runtime_products_compliant}})
    {
        foreach my $proj (@{$p->{dpo_project_dependencies}})
        {
            my $project;
            if (!$self->{panel_product}->get_project($proj->{name}, \$project))
            {
                DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$proj->{name}]);
                return 0;
            }

            if (!$self->fetch_modules_from_project($project))
            {
                DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PROJECT_FAILURE, [$project->{name}]);
                return 0;
            }
        }
    }

    foreach my $p (@{$product->{runtime}->{runtime_products_non_compliant}})
    {
        my $env_var_id = "\$(" . uc($p->{name}) . "_ROOT)";

        foreach my $mod (@{$p->{modules_names}})
        {
            $self->fetch_non_compliant_with_module_name($env_var_id, $mod);
            push(@{$self->{fetch_checked}}, $mod);
        }
    }

    return 1;
}

sub fetch_modules_from_workspace_runtime_dependencies
{
    my ($self) = @_;

    foreach my $project (@{$self->{panel_product}->{runtime_in_workspace}})
    {
        if (!$self->fetch_modules_from_project($project))
        {
            DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PROJECT_FAILURE, [$project->{name}]);
            return 0;
        }
    }

    return 1;
}

sub fetch_modules_from_non_compliant_project
{
    my ($self, $project) = @_;

    if (List::MoreUtils::any {$_ eq $project->{name}} @{$self->{fetch_checked}})
    {
        return 1;
    }

    my $product;
    if (!DPOProductConfig::get_product_with_name($project->{dpo_compliant}->{product_name}, \$product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, [$project->{dpo_compliant}->{product_name}]);
        push(@{$self->{fetch_checked}}, $project->{name});
        return 0;
    }

    my $env_var_id = "\$(" . uc($project->{dpo_compliant}->{product_name}) . "_ROOT)";
    my $path = $env_var_id;
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$path]);
        push(@{$self->{fetch_checked}}, $project->{dpo_compliant}->{product_name});
        return 0;
    }

    foreach my $non_compliant_lib (@{$product->{dpo_compliant_product}->{non_compliant_lib_seq}})
    {
        if ($non_compliant_lib->{lib_id} eq $project->{name})
        {
            my $module = "";

            if ($non_compliant_lib->{dynamic_debug_dll} ne "")
            {
                $module = $non_compliant_lib->{dynamic_debug_dll};
            }
            else
            {
                if ($non_compliant_lib->{dynamic_debug_lib} ne "")
                {
                    $module = $non_compliant_lib->{dynamic_debug_lib};
                }
            }

            if ($module ne "")
            {
                if (!$self->find_module($module, "$path/lib"))
                {
                    # TO_DO
                    return 0;
                }
            }

            if ($non_compliant_lib->{dynamic_release_dll} ne "")
            {
                $module = $non_compliant_lib->{dynamic_release_dll};
            }
            else
            {
                if ($non_compliant_lib->{dynamic_release_lib} ne "")
                {
                    $module = $non_compliant_lib->{dynamic_release_lib};
                }
            }

            if ($module ne "")
            {
                if (!$self->find_module($module, "$path/lib"))
                {
                    # TO_DO
                    return 0;
                }
            }

            foreach my $dep (@{$project->relevant_deps()})
            {
                my $proj;
                $self->{panel_product}->get_project($dep->{name}, \$proj);

                if (!$self->fetch_modules_from_project($proj))
                {
                    DPOLog::report_msg(DPOEvents::FETCH_MODULES_FROM_PROJECT_FAILURE, [$proj->{name}]);
                    return 0;
                }
            }
        }
    }

    push(@{$self->{fetch_checked}}, $project->{name});

    return 1;
}

sub fetch_non_compliant_with_module_name
{
    my ($self, $env_var_id, $mod) = @_;

    if (List::MoreUtils::any {$_ eq $mod} @{$self->{fetch_checked}})
    {
        return;
    }

    my $path = $env_var_id;
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$path]);
        push(@{$self->{fetch_checked}}, $mod);
        return;
    }

    if (!$self->find_module($mod, "$path/lib"))
    {
        if (!$self->find_module($mod, "$path/bin"))
        {
            my $found = 0;
            my $lib_path;
            if ($self->get_path("lib", $path, \$lib_path))
            {
                if ($self->find_module($mod, $lib_path))
                {
                    $found = 1;
                }
            }
            if (!$found)
            {
                my $bin_path;
                if ($self->get_path("bin", $path, \$bin_path))
                {
                    if ($self->find_module($mod, $bin_path))
                    {
                        $found = 1;
                    }
                }
            }
            if (!$found)
            {
                if ($^O =~ /Win/)
                {
                    my $env_var_id2 = "\$(SYSTEMROOT)/System32";
                    my $env_var_value = $env_var_id2;
                    if (DPOEnvVars::expand_env_var(\$env_var_value))
                    {
                        if (-f "$env_var_value/$mod")
                        {
                            # Don't need to copy. It's a system module.
                        }
                        else
                        {
                            DPOLog::report_msg(DPOEvents::MODULE_NOT_FOUND, [$mod, "$env_var_id | $env_var_id2"]);
                        }
                    }
                    else
                    {
                        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_value]);
                    }
                }
                else
                {
                    # TO_DO: linux
                }
            }
        }
    }

    push(@{$self->{fetch_checked}}, $mod);
}

sub find_module
{
    my ($self, $mod, $path) = @_;

    my @content=();
    if (!DPOUtils::get_dir_content($path, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$path]);
        return 0;
    }

    foreach my $elem (@content)
    {
        my $complete = "$path/$mod";
        if (-f $complete)
        {
            push(@{$self->{fetch_to_copy}}, $complete);
            return 1;
        }
        if (-d "$path/$elem")
        {
            if ($self->find_module($mod, "$path/$elem"))
            {
                return 1;
            }
        }
    }

    my $found = 0;
    foreach my $elem (@content)
    {
        my ($fname, $ext) = $mod =~ /(.*)\.(.*)/;
        if ($elem =~ /$fname/)
        {
            if ($elem =~ /$ext/)
            {
                push(@{$self->{fetch_to_copy}}, "$path/$elem");
                $found = 1;
            }
        }
    }

    if ($found)
    {
        return 1;
    }

    return 0;
}

sub get_path
{
    my ($self, $sub_path, $path, $found_path) = @_;

    if (-d "$path/$sub_path")
    {
        $$found_path = "$path/$sub_path";
        return 1;
    }

    my @content=();
    if (!DPOUtils::get_dir_content($path, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$path]);
        return 0;
    }

    foreach my $elem (@content)
    {
        my $complete = "$path/$elem";

        if (-d $complete && $elem ne "." && $elem ne ".." && $elem ne ".svn")
        {
            if ($self->get_path($sub_path, $complete, $found_path))
            {
                return 1;
            }
        }
    }

    return 0;
}

sub generate
{
    my ($self, $workspace_projects_ref) = @_;

    DPOLog::report_msg(DPOEvents::GENERATION, []);

    if ($self->{panel_product}->{combo_box_toolchain}->GetValue() eq "")
    {
        Wx::MessageBox("Toolchain must be selected.", "", Wx::wxOK | Wx::wxICON_ERROR);
        return 0
    }

    my $ok = 1;

    if ($self->prepare_mwc_mpc_and_mpb_files($workspace_projects_ref))
    {
        if (!$self->call_mwc())
        {
            $ok = 0;
        }
    }
    else
    {
        $ok = 0;
    }

    if ($ok)
    {
        DPOLog::report_msg(DPOEvents::GENERATE_OK, []);
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GENERATE_FAILURE, []);
    }

    return $ok;
}

sub prepare_mwc_mpc_and_mpb_files
{
    my ($self, $workspace_projects_ref) = @_;

    # Prepare mwc file

    # Header
    my @lines = ();
    push(@lines, "workspace {\n\n");

    my @header_impl_or_abstract_class;
    foreach my $project (@$workspace_projects_ref)
    {
        if ($project->is_header_impl_or_abstract_class())
        {
            push(@header_impl_or_abstract_class, $project);
        }
    }

    my $projects_to_include_ref = 0;
    if (scalar(@header_impl_or_abstract_class) != 0)
    {
        my $dlg = DPOHeaderImplOrAbstractClassToIncludeInWorkspaceDlg->new(
                        \@header_impl_or_abstract_class,
                        undef,
                        -1,
                        "",
                        Wx::wxDefaultPosition,
                        Wx::wxDefaultSize,
                        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);

        $dlg->ShowModal();

        $projects_to_include_ref = $dlg->{projects_to_include};

        $dlg->Destroy();
    }

    # MPC includes
    my @processed_mpc_includes=();
    foreach my $project (@$workspace_projects_ref)
    {
        if (!$self->header_impl_or_abstract_class_to_include($project, $projects_to_include_ref, 0))
        {
            next;
        }

        my @mpc_includes=();
        if (!$self->get_mpc_includes_for_mwc($project, \@processed_mpc_includes, \@mpc_includes))
        {
            DPOLog::report_msg(DPOEvents::GET_MPC_INCLUDES_FOR_MWC_FAILURE, [$project->{name}]);
            return 0;
        }
        foreach my $mpc_include (@mpc_includes)
        {
            if (DPOEnvVars::expand_env_var(\$mpc_include))
            {
                push(@lines, "$tab$mpc_include\n");
            }
            else
            {
                DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$mpc_include]);
                return 0;
            }
        }
    }
    push(@lines, "\n");

    # Projects
    foreach my $project (@$workspace_projects_ref)
    {
        if (!$self->header_impl_or_abstract_class_to_include($project, $projects_to_include_ref, 1))
        {
            next;
        }

        my $name_modifier = "-name_modifier *-" .
                                $self->{panel_product}->{combo_box_toolchain}->GetValue() .
                                " -apply_project";

        my $features = "";
        foreach my $feature (@{$project->{features}})
        {
            $features .= "-features $feature ";
        }

        my @done;

        if ($project->is_library())
        {
            if ($project->is_dynamic_library())
            {
                push(@lines, "$tab$project->{name} {\n");
                $self->after_entries($project, \@done, \@lines, $projects_to_include_ref);
                push(@lines, "$tab$tab" . "cmdline += $name_modifier $features\n");
                push(@lines, "$tab$tab\$(" . uc($project->{name}) . "_PRJ_ROOT)/src/$project->{name}.mpc\n");
                push(@lines, "$tab}\n\n");
            }

            if ($project->is_static_library())
            {
                push(@lines, "$tab$project->{name}_static {\n");
                $self->after_entries($project, \@done, \@lines, $projects_to_include_ref);
                push(@lines, "$tab$tab" . "cmdline += -static $name_modifier $features\n");
                push(@lines, "$tab$tab\$(" . uc($project->{name}) . "_PRJ_ROOT)/src/$project->{name}_static.mpc\n");
                push(@lines, "$tab}\n\n");
            }
        }
        else
        {
            if ($project->{type} == 1)
            {
                my $dep;
                if (!$self->{panel_product}->get_project($project->{test_app_of}, \$dep))
                {
                    DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$project->{test_app_of}]);
                    return 0;
                }

                if ($dep->is_executable())
                {
                    if (!$self->add_test_app_project_entry($project, "dynamic", $name_modifier, $features, \@lines, $projects_to_include_ref))
                    {
                        DPOLog::report_msg(DPOEvents::ADD_TEST_APP_PROJECT_ENTRY_FAILURE, [$project->{name}, "dynamic"]);
                        return 0;
                    }
                }
                else
                {
                    if ($dep->is_static_library())
                    {
                        unless ($dep->is_header_impl_or_abstract_class())
                        {
                            if (!$self->add_test_app_project_entry($project, "static", $name_modifier, $features, \@lines, $projects_to_include_ref))
                            {
                                DPOLog::report_msg(DPOEvents::ADD_TEST_APP_PROJECT_ENTRY_FAILURE, [$project->{name}, "static"]);
                                return 0;
                            }
                        }
                    }
                    if ($dep->is_dynamic_library()
                        || $dep->is_header_impl_or_abstract_class())
                    {
                        if (!$self->add_test_app_project_entry($project, "dynamic", $name_modifier, $features, \@lines, $projects_to_include_ref))
                        {
                            DPOLog::report_msg(DPOEvents::ADD_TEST_APP_PROJECT_ENTRY_FAILURE, [$project->{name}, "dynamic"]);
                            return 0;
                        }
                    }
                }
            }
            else
            {
                push(@lines, "$tab$project->{name} {\n");
                $self->after_entries($project, \@done, \@lines, $projects_to_include_ref);
                push(@lines, "$tab$tab" . "cmdline += $name_modifier $features\n");
                push(@lines, "$tab$tab\$(" . uc($project->{name}) . "_PRJ_ROOT)/src\n");
                push(@lines, "$tab}\n\n");
            }
        }
    }

    push(@lines, "}\n");

    # Save mwc file
    my $initial_wd = Cwd::getcwd();
    chdir($self->{panel_product}->{workspace_path});

    my $tmp_file = "mwc.tmp";
    if (!open (OUT, ">$tmp_file"))
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $tmp_file, $!]);
        return 0;
    }

    foreach my $line (@lines)
    {
        print OUT $line;
    }

    close(OUT);

    my $mwc_file = "$self->{panel_product}->{workspace_path}/$self->{panel_product}->{workspace_name}.mwc";
    if (!File::Copy::syscopy($tmp_file, $mwc_file))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$tmp_file, $mwc_file, $!]);
        chdir($initial_wd);
        return 0;
    }

    unlink($tmp_file);

    chdir($initial_wd);


    # Prepare mpc files
    print "Prepare mpc files...\n";
    foreach my $project (@$workspace_projects_ref)
    {
        if (!$self->prepare_mpc_files($project))
        {
            return 0;
        }
    }

    return 1;
}

sub prepare_mpc_files
{
    my ($self, $project) = @_;

    my $static = 0;
    if ($project->is_static_library())
    {
        if (!$self->create_static_mpc_file($project->{name}))
        {
            DPOLog::report_msg(DPOEvents::STATIC_MPC_FILE_CREATION_FAILURE, [$project->{name}]);
            return 0;
        }
    }

    if (!$self->prepare_mpb_dependencies($project))
    {
        DPOLog::report_msg(DPOEvents::PREPARE_MPB_DEPENDENCIES_FAILURE, [$project->{name}]);
        return 0;
    }

    if (!$self->fit($project))
    {
        return 0;
    }

    return 1;
}

sub add_test_app_project_entry
{
    my ($self, $project, $type, $name_modifier, $features, $lines_ref, $projects_to_include_ref) = @_;

    my $static_suffix = "";
    if ($type eq "static")
    {
        $static_suffix = "_static";
    }

    push(@$lines_ref, "$tab$project->{name}" . "$static_suffix {\n");

    my @done;
    $self->after_entries($project, \@done, $lines_ref, $projects_to_include_ref);

    push(@$lines_ref, "$tab$tab" . "cmdline += $name_modifier $features\n");
    push(@$lines_ref, "$tab$tab\$(" . uc($project->{name}) . "_PRJ_ROOT)/src/$project->{name}$static_suffix.mpc\n");
    push(@$lines_ref, "$tab}\n\n");

    my $test_project;
    if ($self->{panel_product}->get_project($project->{name}, \$test_project))
    {
        my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
        my $project_path = "\$($env_var_id)";
        if (!DPOEnvVars::expand_env_var(\$project_path))
        {
            DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$project_path]);
            return 0;
        }

        if (!$self->fit_when($project_path, $test_project, $type))
        {
            DPOLog::report_msg(DPOEvents::FIT_FAILURE, [$test_project->{name}]);
            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, [$project->{name}]);
        return 0;
    }

    return 1;
}

sub call_mwc
{
    my ($self) = @_;

    my $mpc_project_type = $self->{panel_product}->{combo_box_toolchain}->GetValue();

    my $mpc_name_modifier_option = "-name_modifier *-" .
                                    $mpc_project_type .
                                    " -apply_project";

    my $arch = $self->{panel_product}->{combo_box_arch}->GetValue();
    if ($^O =~ /Win/)
    {
        if ($arch eq "i686")
        {
            $arch = "Win32";
        }
        else
        {
            $arch = "x64";
        }
    }

    my $value_template = "-value_template platforms=$arch";

    my $env_var_id = "\$(MPC_ROOT)";
    my $mpc_path = $env_var_id;
    if (DPOEnvVars::expand_env_var(\$mpc_path))
    {
        my $cmd = "$mpc_path/mwc.pl -type".
                            " $mpc_project_type".
                            " -noreldefs".
                            " $mpc_name_modifier_option".
                            " $value_template".
                            " $self->{panel_product}->{workspace_name}.mwc";

        my $cwd = Cwd::getcwd();
        chdir($self->{panel_product}->{workspace_path});

        my $mwc_ok = 1;
        print "\n********** MWC **********\n";
        print "$cmd\n";
        my $output = `$cmd 2>&1`;
        if ($output !~ "Generation Time:"
            || $output =~ /Skipping/)
        {
            print $output;
            $mwc_ok = 0;
        }
        print "*************************\n";

        chdir($cwd);

        if (!$mwc_ok)
        {
            DPOLog::report_msg(DPOEvents::MWC_FAILURE, []);
            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$mpc_path]);
        return 0;
    }

    return 1;
}

sub after_entries
{
    my ($self, $project, $done_ref, $lines_ref, $projects_to_include_ref) = @_;

    my $deps = $project->relevant_deps();

    foreach my $dep (@$deps)
    {
        my $proj;
        $self->{panel_product}->get_project($dep->{name}, \$proj);

        if (!$self->header_impl_or_abstract_class_to_include($proj, $projects_to_include_ref, 0))
        {
            $self->after_entries($proj, $done_ref, $lines_ref, $projects_to_include_ref);

            next;
        }

        foreach my $workspace_project (@{$self->{panel_product}->{workspace_projects}})
        {
            if ($workspace_project->{name} eq $proj->{name}
                && ($workspace_project->{type} & $proj->{type}) == $proj->{type})
            {
                my $static_suffix = "";
                if ($proj->is_static_library())
                {
                    $static_suffix = "_static";
                }

                if (!List::MoreUtils::any {$_ eq "$proj->{name}$static_suffix"} @$done_ref)
                {
                    my $entry = "$tab$tab" . "cmdline += -value_project after+=$proj->{name}$static_suffix";
                    push(@$lines_ref, "$entry\n");
                    push(@$done_ref, "$proj->{name}$static_suffix");
                }

                last;
            }
        }
    }
}

sub create_static_mpc_file
{
    my ($self, $project_name) = @_;

    my $env_var_id = uc($project_name) . "_PRJ_ROOT";
    my $project_path = "\$($env_var_id)";
    if (DPOEnvVars::expand_env_var(\$project_path))
    {
        my $src = "$project_path/src/$project_name.mpc";
        my $target = "$project_path/src/$project_name"."_static.mpc";

        # Add macro:    macros += XYZ_HAS_DLL=0

        my $tmp_file = "$target";
        if (!open (OUT, ">$target"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $target, $!]);
            return 0;
        }

        my @lines;
        if (DPOUtils::get_file_lines($src, \@lines))
        {
            my $line_count = 0;
            foreach my $line (@lines)
            {
                if ($line =~ /project.*{$/)
                {
                    $line =~ s/_fit/_fit_static/;
                }

                if ($line_count == scalar(@lines) - 1)
                {
                    # Add this line just before the last one.
                    print OUT "    macros += " . uc($project_name) . "_HAS_DLL=0\n";
                }
                print OUT $line;
                $line_count++;
            }

            close(OUT);
        }
        else
        {
            DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$src]);
            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$project_path]);
        return 0;
    }

    return 1;
}

sub prepare_mpb_dependencies
{
    my ($self, $project) = @_;

    my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (DPOEnvVars::expand_env_var(\$path))
    {
        my $file = "$path/MPC/$project->{name}_dependencies.mpb";

        my $fh;
        my $bPrintToFile = 1; # set to 0 to not print to file (test)
        if ($bPrintToFile)
        {
            $fh = new FileHandle;
            if (!$fh->open(">$file"))
            {
                DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $file, $!]);
                return 0;
            }
        }

        if (!$bPrintToFile)
        {
            $fh = *STDOUT;
        }

        print $fh   "\n// This file is generated by DPOProduct.pl.\n" .
                    "// Do not write in this file.\n\n";

        # Project inheritance
        my $header = "project";

        my @dependencies;
        foreach my $dep (@{$project->relevant_deps()})
        {
            my $mpb_name = $dep->{name};
            if (!$dep->{dpo_compliant}->{value})
            {
                $mpb_name = $dep->{dpo_compliant}->{mpb};
            }

            if (!List::MoreUtils::any {$_ eq $mpb_name} @dependencies)
            {
                push(@dependencies, $mpb_name);
            }
        }

        if (scalar(@dependencies) != 0)
        {
            $header .= ": ";

            my $sep = "";
            foreach my $mpb_name (@dependencies)
            {
                $header .= $sep . $mpb_name;
                $sep = ", ";
            }
        }

        $header .= " {\n";

        print $fh "$header\n";

        my @confs;
        $self->add_configurationname_to_local_dependencies($project, $fh, \@confs);

        # idlflags
        foreach my $dep (@{$project->relevant_deps()})
        {
            $project->extend_with_idlflags($dep);
        }

        foreach my $idlflag (@{$project->{idlflags}})
        {
            print $fh "    idlflags += -I\$($idlflag)/include\n";
        }

        print $fh "}\n";

        if ($bPrintToFile)
        {
            $fh->close;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$path]);
        return 0;
    }

    return 1;
}

sub fit
{
    my ($self, $project) = @_;

    my $ok = 1;

    my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (DPOEnvVars::expand_env_var(\$path))
    {
        if ($project->{type} == 5)
        {
            if (!$self->fit_when($path, $project, "static"))
            {
                $ok = 0;
            }
        }
        if ($project->{type} == 6
            || $project->{type} == 0)
        {
            if (!$self->fit_when($path, $project, "dynamic"))
            {
                $ok = 0;
            }
        }
        if ($project->{type} == 7)
        {
            if (!$self->fit_when($path, $project, "static"))
            {
                $ok = 0;
            }
            if (!$self->fit_when($path, $project, "dynamic"))
            {
                $ok = 0;
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$path]);
        $ok = 0;
    }

    if (!$ok)
    {
        DPOLog::report_msg(DPOEvents::FIT_FAILURE, [$project->{name}]);
    }

    return $ok;
}

sub fit_when
{
    my ($self, $path, $project, $when) = @_;

    my $suffix = "";
    if ($when eq "static")
    {
        $suffix = "_static";
    }

    my $file = "$path/MPC/$project->{name}_fit$suffix.mpb";

    my $fh;
    my $bPrintToFile = 1; # set to 0 to not print to file (test)
    if ($bPrintToFile)
    {
        $fh = new FileHandle;
        if (!$fh->open(">$file"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $file, $!]);
            return 0;
        }
    }

    if (!$bPrintToFile)
    {
        $fh = *STDOUT;
    }

    print $fh   "\n// This file is generated by DPOProduct.pl.\n" .
                "// Do not write in this file.\n\n";

    print $fh "project {\n";

    # Prepare configuration text
    my $configuration_text = "\$(Configuration)";
    if ($^O =~ /Win/)
    {
        # Before VC10, 'ConfigurationName' was used for
        # configurations (Debug/Release). From VC10, 'ConfigurationName' is
        # still supported but when used for 'Output Directory' and
        # 'Intermediate Directory', it doesn't work anymore.
        # Thus, we use 'ConfigurationName' for versions smaller than VC10.

        # Get selected toolchain
        my $toolchain = $self->{panel_product}->{combo_box_toolchain}->GetValue();
        # Create the vector containing toolchains that use 'ConfigurationName'
        my @toolchain_with_configuration_name = qw(vc9 vc8 vc7 vc6 gnuace make);
        # If the selected toolchain is one using 'ConfigurationName', use it parameter.
        if (List::MoreUtils::any {$_ eq $toolchain} @toolchain_with_configuration_name)
        {
            $configuration_text = "\$(ConfigurationName)";
        }
    }

    # Add dependencies libpaths
    my @added; # Used to prevent addition of the same elements.
    $self->add_lib_paths($project, $configuration_text, $fh, \@added);

    # Update xyz_fit.mpb when project is dynamic with static dependencies

    # MPC generate projects as static only or as dynamic only.
    # If a project is built as static, all dependencies must also
    # be built as static and conversely for projects generated as
    # dynamic.
    # To mix static and dynamic projects we must take actions when the
    # project is dynamic (or executable; ie not explicitly static) and
    # there are dynamic dependencies (direct or indirect).

    if ($project->is_executable()
        || $project->is_dynamic_library())
    {
        # For project generated as non static and containing direct or
        # indirect static dependencies, we must remove 'libs' related to
        # those static dependencies to the benefit of new 'lit_libs' entries
        # and macros ("XYZ_HAS_DLL=0").

        my $text = "dynamic";
        if ($project->is_executable())
        {
            $text = "executable";
        }

        print $fh "\n    // Because $project->{name} is $text...\n\n";

        my $deps = $project->{dependencies_when_dynamic};
        if ($when eq "static")
        {
            $deps = $project->{dependencies_when_static};
        }

        if (!$self->prevent_dynamic_when_static_dep($project, $deps, $configuration_text, $fh))
        {
            DPOLog::report_msg(DPOEvents::PREVENT_DYNAMIC_WHEN_STATIC_DEP_NOT_DONE, []);
            return 0;
        }
    }
    else
    {
        # MPC doesn't generate entries for libs because a static library
        # doesn't need to link with any library. Thus nothing to do here.
    }

    print $fh "}\n";

    if ($bPrintToFile)
    {
        $fh->close;
    }

    return 1;
}

sub add_lib_paths
{
    my ($self, $project, $configuration_text, $fh, $added_ref) = @_;

    foreach my $dep (@{$project->relevant_deps()})
    {
        my $proj;
        $self->{panel_product}->get_project($dep->{name}, \$proj);

        my $dep_name_uc;
        if ($proj->{dpo_compliant}->{value})
        {
            $dep_name_uc = uc($proj->{name});
        }
        else
        {
            $dep_name_uc = uc($proj->{dpo_compliant}->{product_name});
        }

        if (List::MoreUtils::any {$_->{name} eq $proj->{name}} @{$self->{panel_product}->{workspace_projects}})
        {
            if (!List::MoreUtils::any {$_ eq $dep_name_uc} @{$added_ref})
            {
                print $fh "    libpaths += \$($dep_name_uc" . "_PRJ_ROOT)/lib/$configuration_text\n";
                push(@{$added_ref}, $dep_name_uc);
            }
        }
        else
        {
            if (!List::MoreUtils::any {$_ eq $dep_name_uc} @{$added_ref})
            {
                if ($proj->{type} != 2)
                {
                    print $fh "    libpaths += \$($dep_name_uc" . "_ROOT)/lib\n";
                    push(@{$added_ref}, $dep_name_uc);
                }
            }
        }

        $self->add_lib_paths($proj, $configuration_text, $fh, $added_ref);
    }
}

sub prevent_dynamic_when_static_dep
{
    my ($self, $parent, $deps_ref, $configuration_text, $fh) = @_;

    foreach my $dep (@{$deps_ref})
    {
        my $proj;
        $self->{panel_product}->get_project($dep->{name}, \$proj);

        if ($proj->{type} == 5
            && $parent->{type} != 2)
        {
            print $fh "    // ...and $proj->{name} is static (in $parent->{name}):\n";

            my @new_libs_lines;


            if ($proj->{dpo_compliant}->{value})
            {
                print $fh "    libs -= $proj->{name}\n";
            }
            else
            {
                my $found = 0;
                my $mpb_file = "";
                my @mpc_includes = split(/;/, $proj->{dpo_compliant}->{mpc_includes});
                foreach my $mpc_include (@mpc_includes)
                {
                    $mpb_file = "$mpc_include/$proj->{dpo_compliant}->{mpb}.mpb";
                    if (DPOEnvVars::expand_env_var(\$mpb_file))
                    {
                        if (-e $mpb_file)
                        {
                            $found = 1;
                            last;
                        }
                    }
                    else
                    {
                        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$mpb_file]);
                        return 0;
                    }
                }

                if (!$found)
                {
                    DPOLog::report_msg(DPOEvents::MPB_FILE_NOT_FOUND, [$proj->{dpo_compliant}->{mpb}, $proj->{dpo_compliant}->{mpc_includes}]);
                    return 0;
                }

                my @libs_lines;
                my @blocks_containing_libs;
                my @non_block_libs;
                if (!DPOMpb::extract_libs_lines($proj, $mpb_file, \@libs_lines, \@blocks_containing_libs, \@non_block_libs))
                {
                    DPOLog::report_msg(DPOEvents::EXTRACT_LIBS_LINES_FAILURE, [$mpb_file]);
                    return 0;
                }
                else
                {
                    foreach my $block (@blocks_containing_libs)
                    {
                        foreach my $line (@$block)
                        {
                            if ($line =~ /specific/
                                || $line =~ /feature/
                                || $line =~ /libs.*=/)
                            {
                                push(@new_libs_lines, $line);
                            }
                        }
                        print $fh "    }\n";
                    }

                    foreach my $line (@non_block_libs)
                    {
                        push(@new_libs_lines, $line);
                    }
                    print $fh "\n";
                }
            }

            my $debug_static_name;
            my $release_static_name;
            if (!$self->get_module_names($proj, "static", \$debug_static_name, \$release_static_name))
            {
                DPOLog::report_msg(DPOEvents::FAILED_TO_GET_MODULES_NAMES, [$proj->{name}]);
                return 0;
            }

            my $substractions = "";
            foreach my $line (@new_libs_lines)
            {
                DPOUtils::trim(\$line);
                if ($line =~ /\+=/)
                {
                    $line =~ s/\+=/\-=/;
                }
                else
                {
                    $line =~ s/=/\-=/;
                }
                $substractions .= "        Release::$line\n";
                $substractions .= "        Debug::$line\n";
            }

            print $fh
                "    specific {\n" .
                $substractions .
                "        Release::lit_libs += $release_static_name\n" .
                "        Debug::lit_libs += $debug_static_name\n" .
                "    }\n";

            print $fh "    macros += \"" . uc($proj->{name}) . "_HAS_DLL=0\"\n\n";
        }

        if (!$self->prevent_dynamic_when_static_dep($proj, $proj->{dependencies_when_static}, $configuration_text, $fh))
        {
            DPOLog::report_msg(DPOEvents::PREVENT_DYNAMIC_WHEN_STATIC_DEP_NOT_DONE, []);
            return 0;
        }
    }

    return 1;
}

sub get_module_names
{
    my ($self, $project, $type, $debug_name_ref, $release_name_ref) = @_;

    # Compliant by default
    # dpo compliant projects use default MPC modifiers (if MPC modifiers change, we are in trouble here ==> TO_DO)
    if ($type eq "static")
    {
        $$debug_name_ref = "$project->{name}sd";
        $$release_name_ref = "$project->{name}s";
    }
    else
    {
        $$debug_name_ref = "$project->{name}d";
        $$release_name_ref = "$project->{name}";
    }

    if (!$project->{dpo_compliant}->{value})
    {
        my $product;
        if (DPOProductConfig::get_product_with_name($project->{dpo_compliant}->{product_name}, \$product))
        {
            foreach my $non_compliant_lib (@{$product->{dpo_compliant_product}->{non_compliant_lib_seq}})
            {
                if ($non_compliant_lib->{lib_id} eq $project->{name})
                {
                    if ($type eq "static")
                    {
                        $$debug_name_ref = $non_compliant_lib->{static_debug_lib};
                        $$release_name_ref = $non_compliant_lib->{static_release_lib};
                    }
                    else
                    {
                        $$debug_name_ref = $non_compliant_lib->{dynamic_debug_lib};
                        $$release_name_ref = $non_compliant_lib->{dynamic_release_lib};
                    }

                    if ($$debug_name_ref =~ /(.*)\.(.*)/)
                    {
                        $$debug_name_ref = $1;
                    }
                    if ($$release_name_ref =~ /(.*)\.(.*)/)
                    {
                        $$release_name_ref = $1;
                    }
                }
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, [$project->{dpo_compliant}->{product_name}]);
            return 0;
        }
    }

    return 1;
}

sub freeze
{
    my ($self, $workspace_projects_ref) = @_;

    DPOLog::report_msg(DPOEvents::FREEZING, []);

    my $tool_chain = $self->{panel_product}->{combo_box_toolchain}->GetValue();

    my $dlg = DPOProductFreezeDlg->new(
                    $self->{panel_product}->{this_product},
                    $tool_chain,
                    $workspace_projects_ref,
                    undef,
                    -1,
                    "",
                    Wx::wxDefaultPosition,
                    Wx::wxDefaultSize,
                    Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);
    $dlg->Centre();
    my $rc = $dlg->ShowModal();
    if ($rc == Wx::wxID_OK)
    {
        my @projects_to_freeze = @$workspace_projects_ref;

        my $current_version = $dlg->{text_ctrl_product_version}->GetValue();
        my $versions_log = $dlg->{flavour_path} . "/dpo_versions.log";
        my $new_product_version = $dlg->{text_ctrl_product_new_version}->GetValue();
        my $new_product_flavour = $dlg->{text_ctrl_product_new_flavour}->GetValue();
        my $new_product_flavour_path = $dlg->{flavour_path};
        my $modules_target_directory = "$new_product_flavour_path/modules";

        $dlg->Destroy();

        if ($new_product_version eq $current_version
            || $current_version eq "")
        {
            unless (-e $modules_target_directory)
            {
                if (!DPOUtils::make_path($modules_target_directory))
                {
                    DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$modules_target_directory creation failure"]);
                    return 0;
                }
            }

            my @same_version_and_target_version;
            foreach my $project (@projects_to_freeze)
            {
                if ($project->{version} eq $project->{target_version})
                {
                    if ($project->{dpo_compliant}->{product_flavour} eq $new_product_flavour)
                    {
                        # Put in @same_version_and_target_version if it doesn't exist in the pool
                        if (-d "$modules_target_directory/$project->{name}/$project->{target_version}")
                        {
                            push(@same_version_and_target_version, $project);
                        }
                    }
                }
            }

            my $continue = 1;
            if (scalar(@same_version_and_target_version) != 0)
            {
                my $same;
                foreach my $proj (@same_version_and_target_version)
                {
                    $same .= "- $proj->{name}-$proj->{version} VS $proj->{name}-$proj->{target_version}\n";
                }

                my $msg = "There are some projects with the same version and target version.\n$same\n".
                                "These projects won't be frozen.\n\n".
                                "Do you want to continue?";
                my $rc = Wx::MessageBox(
                        $msg,
                        "Freezing",
                        Wx::wxYES_NO);

                if ($rc == Wx::wxNO)
                {
                    DPOLog::report_msg(DPOEvents::FREEZING_CANCELLED, []);
                    return 0;
                }
            }
        }

        my $wait = Wx::BusyCursor->new();

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        my $timestamp = sprintf ( "%04d-%02d-%02d %02d:%02d:%02d",
                                        $year+1900,
                                        $mon+1,
                                        $mday,
                                        $hour,
                                        $min,
                                        $sec);

        # Update dpo_versions.log
        my @last_product_version_block;
        if (!$self->extract_projects_of_the_last_product_version($versions_log, \@last_product_version_block))
        {
            my $msg = "Can't extract last product version from $versions_log";
            Wx::MessageBox($msg, "", Wx::wxOK | Wx::wxICON_ERROR);
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$versions_log (can't extract last product version)"]);
            return 0;
        }

        my @projects_to_keep_with_this_product;
        my $dlg_choice = DPOProductFreezeChoiceDlg->new(
                        \@projects_to_freeze,
                        \@last_product_version_block,
                        $self->{panel_product},
                        $versions_log,
                        $current_version,
                        $new_product_version,
                        $new_product_flavour,
                        undef,
                        -1,
                        "",
                        Wx::wxDefaultPosition,
                        Wx::wxDefaultSize,
                        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);
        $dlg_choice->Centre();
        my $rc = $dlg_choice->ShowModal();
        $dlg_choice->Destroy();
        if ($rc == Wx::wxID_OK)
        {
            # @last_product_version_block has been updated in a way that it
            # contains the projects of the new product version.
            if (!$self->add_new_product_version_entry($versions_log, $new_product_version, \@last_product_version_block, $timestamp))
            {
                my $msg = "Can't add new version entry into $versions_log";
                Wx::MessageBox($msg, "", Wx::wxOK | Wx::wxICON_ERROR);
                DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$versions_log (can't add new version entry)"]);
                return 0;
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::FREEZING_CANCELLED, []);
            return 0;
        }

        my @fails;
        foreach my $project (@projects_to_freeze)
        {
            if (-d "$modules_target_directory/$project->{name}/$project->{target_version}")
            {
                DPOLog::report_msg(DPOEvents::GENERIC_WARNING, ["$project->{name}/$project->{target_version} not frozen. It already exists."]);
                next;
            }

            #~ if ($project->{version} ne $project->{target_version}
                #~ || $new_product_flavour ne $self->{panel_product}->{this_product}->{flavour})
            #~ {
                $project->{version} = $project->{target_version};
                if (!$self->{panel_product}->update_workspace_projects($project))
                {
                    DPOLog::report_msg(DPOEvents::UPDATE_WORKSPACE_PROJECTS_FAILURE, [$project->{name}]);
                }

                my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
                my $project_dir = "\$($env_var_id)";
                if (DPOEnvVars::expand_env_var(\$project_dir))
                {
                    my $into = "$modules_target_directory/$project->{name}/$project->{target_version}";

                    if ($self->do_freeze($project, $project_dir, $into))
                    {
                        if (!$self->{panel_product}->save_project($project))
                        {
                            my $msg = "Can't save project $project->{name}";
                            Wx::MessageBox($msg, "", Wx::wxOK | Wx::wxICON_ERROR);
                            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$project->{name} saving"]);
                            return 0;
                        }
                    }
                    else
                    {
                        push(@fails, $project);
                    }
                }
                else
                {
                    DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$project_dir]);
                    return 0;
                }
            #~ }
        }

        $self->{panel_product}->fill_product_projects();

        if (scalar(@fails) != 0)
        {
            my $fails_text = "";
            my $sep = "";
            foreach my $fail (@fails)
            {
                $fails_text .= "$sep$fail->{name}";
                $sep = ", ";
            }
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, [$fails_text]);
            return 0;
        }
        #~ else
        #~ {
            #~ DPOLog::report_msg(DPOEvents::FREEZING_COPY_OK, []);
        #~ }

        # Update version of the product
        $self->{panel_product}->{this_product}->{version} = $new_product_version;

        # Update pool and local product version and flavour
        my $local_dpoproduct_file = "$self->{panel_product}->{this_product}->{path}/DPOProduct.xml";

        my $product;
        my $config_product = DPOProductConfig->new($local_dpoproduct_file);
        if ($config_product)
        {
            $config_product->get_product(\$product);

            $product->{version} = $new_product_version;
            $product->{flavour} = $new_product_flavour;
            my $err;
            if (!$config_product->save($product))
            {
                Wx::MessageBox("Can't update $local_dpoproduct_file: $err", "", Wx::wxOK | Wx::wxICON_ERROR);
                DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$local_dpoproduct_file (can't update: $err)"]);
                return 0;
            }
        }
        else
        {
            Wx::MessageBox("Can't load product from $local_dpoproduct_file", "", Wx::wxOK | Wx::wxICON_ERROR);
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$local_dpoproduct_file (can't update)"]);
            return 0;
        }

        my $runtimes_log_file = $dlg->{flavour_path} . "/dpo_runtimes.log";
        if (!$self->update_product_runtimes_log($runtimes_log_file, $product, $timestamp))
        {
            my $msg = "Can't update runtimes_log";
            Wx::MessageBox($msg, "", Wx::wxOK | Wx::wxICON_ERROR);
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["runtimes_log (can't update)"]);
            return 0;
        }

        if (!File::Copy::copy($local_dpoproduct_file, $new_product_flavour_path))
        {
            Wx::MessageBox("Can't copy $local_dpoproduct_file to $new_product_flavour_path", "", Wx::wxOK | Wx::wxICON_ERROR);
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$local_dpoproduct_file (can't copy to $new_product_flavour_path)"]);
            return 0;
        }

        # templates4dpo
        if (-d "$self->{panel_product}->{this_product}->{path}/templates4dpo")
        {
            if (!DPOUtils::TreeCopy("$self->{panel_product}->{this_product}->{path}/templates4dpo", "$new_product_flavour_path/templates4dpo"))
            {
                Wx::MessageBox("Can't copy $self->{panel_product}->{this_product}->{path}/templates4dpo to $new_product_flavour_path/templates4dpo", "", Wx::wxOK | Wx::wxICON_ERROR);
                DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["$self->{panel_product}->{this_product}->{path}/templates4dpo (can't copy to $new_product_flavour_path/templates4dpo)"]);
                return 0;
            }
        }

        # Set env. vars.
        my @listEnvVarValues;

        # DPOProduct
        my $env_var = DPOEnvVar->new($self->{panel_product}->{this_product}->{name} . "_ROOT", $new_product_flavour_path);
        push(@listEnvVarValues, $env_var);

        # Set env vars of all modules of the product
        foreach my $project_to_freeze (@projects_to_freeze)
        {
            my $env_var = DPOEnvVar->new(uc($project_to_freeze->{name}) . "_PRJ_ROOT", "$modules_target_directory/$project_to_freeze->{name}/$project_to_freeze->{version}");
            push(@listEnvVarValues, $env_var);
        }

        $rc = DPOEnvVars::system_set_env_vars(\@listEnvVarValues);
        if (!$rc)
        {
            Wx::MessageBox(
                    "DPOWorkspace::set_env_vars() - can't set environment variables.",
                    "Setting environment variables",
                    Wx::wxOK | Wx::wxICON_ERROR);
            DPOLog::report_msg(DPOEvents::FREEZE_FAILURE, ["environment settings"]);
            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::FREEZING_CANCELLED, []);
        $dlg->Destroy();
        return 0;
    }

    DPOLog::report_msg(DPOEvents::FREEZING_OK, []);

    $self->{panel_product}->close_workspace();

    $self->{panel_product}->{checkbox_validate}->SetValue(0);
    $self->{panel_product}->{checkbox_freeze}->SetValue(0);

    return 1;
}

sub do_freeze
{
    my ($self, $project, $project_dir, $modules_target_directory) = @_;

    print "do_freeze: $project->{name}: $project_dir --> $modules_target_directory...\n";

    my @to_be_copied;

    # include
    if (!$self->get_includes_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "includes"]);
        return 0;
    }

    # libraries
    if (!$self->get_libs_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "libs"]);
        return 0;
    }

    # executables
    if (!$self->get_execs_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "execs"]);
        return 0;
    }

    # etc
    if (!$self->get_etcs_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "etc"]);
        return 0;
    }

    # var
    if (!$self->get_vars_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "var"]);
        return 0;
    }

    # doc
    if (!$self->get_docs_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "doc"]);
        return 0;
    }

    # mpc
    if (!$self->get_mpcs_to_copy($project, $project_dir, $modules_target_directory, \@to_be_copied))
    {
        DPOLog::report_msg(DPOEvents::GET_STUFF_TO_COPY, [$project_dir, "mpc"]);
        return 0;
    }

    # DPOProject.xml
    my $source_target = ToFreezeSourceTarget->new("$project_dir/DPOProject.xml", $modules_target_directory);
    push(@to_be_copied, $source_target);

    # features
    $source_target = ToFreezeSourceTarget->new("$project_dir/features", $modules_target_directory);
    push(@to_be_copied, $source_target);

    # Actually copy the files
    foreach my $source_target (@to_be_copied)
    {
        my $src = $source_target->{source};
        my $target = $source_target->{target};

        my $dir = File::Basename::dirname($target);

        unless (-e $dir)
        {
            if (!DPOUtils::make_path($dir))
            {
                return 0;
            }
        }

        if (!File::Copy::copy($src, $target))
        {
            DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$src, $target, $!]);
            return 0;
        }
    }

    # Set permissions on linux
    #~ if (!DPOUtils::set_permissions($actual_directory))
    #~ {
        #~ $$errors_ref = "Error: can not set permissions for \"$actual_directory\".";
        #~ return 0;
    #~ }

    return 1;
}

sub get_includes_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    my $src = "$project_dir/include";
    if (-e $src)
    {
        my $target = "$modules_target_directory/include";
        $self->file_to_copy_on_freeze($src, $target, 0, $files_to_copy_ref);
    }

    return 1;
}

sub get_libs_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    if ($project->is_library())
    {
        my $src_lib_release = "$project_dir/lib/Release";
        my $src_lib_debug = "$project_dir/lib/Debug";
        #~ my $target_lib_release = "$modules_target_directory/lib/Release";
        #~ my $target_lib_debug = "$modules_target_directory/lib/Debug";
        my $target_lib_release = "$modules_target_directory/lib";
        my $target_lib_debug = "$modules_target_directory/lib";

        if ($^O =~ /Win/)
        {
            if (-e $src_lib_release
                && !(-e $src_lib_debug))
            {
                DPOLog::report_msg(DPOEvents::HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE, ["Debug", $project->{name}, $src_lib_debug]);
            }
            if (-e $src_lib_debug
                && !(-e $src_lib_release))
            {
                DPOLog::report_msg(DPOEvents::HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE, ["Release", $project->{name}, $src_lib_release]);
            }
        }

        my $ft = File::Type->new();

        if (-e $src_lib_release)
        {
            # select lib/dll to copy
            my @content=();
            if (!DPOUtils::get_dir_content($src_lib_release, \@content))
            {
                DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_lib_release]);
                return 0;
            }

            foreach my $file (@content)
            {
                my $complete = "$src_lib_release/$file";
                if (-f $complete)
                {
                    my $type_from_file = $ft->checktype_filename($complete);

                    if ($type_from_file =~ /x-ar/
                            || $type_from_file =~ /x.*-executable/)
                        #~ || $file =~ /\.pdb$/)
                    {
                        my $target_file = "$target_lib_release/$file";
                        my $source_target = ToFreezeSourceTarget->new($complete,
                                                                $target_file);
                        push(@$files_to_copy_ref, $source_target);
                    }
                }
            }
        }

        if (-e $src_lib_debug)
        {
            my @content=();
            if (!DPOUtils::get_dir_content($src_lib_debug, \@content))
            {
                DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_lib_debug]);
                return 0;
            }

            foreach my $file (@content)
            {
                my $complete = "$src_lib_debug/$file";

                if (-f $complete)
                {
                    my $type_from_file = $ft->checktype_filename($complete);

                    if ($type_from_file =~ /x-ar/
                        || $type_from_file =~ /x.*-executable/)
                        #~ || $file =~ /\.pdb$/)
                    {
                        my $target_file = "$target_lib_debug/$file";

                        my $source_target = ToFreezeSourceTarget->new($complete,
                                                            $target_file);
                        push(@$files_to_copy_ref, $source_target);
                    }
                }
            }
        }
    }

    return 1;
}

sub get_execs_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    if ($project->is_executable()
        || $project->is_dynamic_library()) # Sometimes, a dll can put executables in bin
    {
        my $src_release = "$project_dir/bin/Release";
        my $src_debug = "$project_dir/bin/Debug";
        #~ my $target_release = "$modules_target_directory/bin/Release";
        #~ my $target_debug = "$modules_target_directory/bin/Debug";
        my $target_release = "$modules_target_directory/bin";
        my $target_debug = "$modules_target_directory/bin";

        if ($^O =~ /Win/)
        {
            if (-e $src_debug
                    && !(-e $src_release))
            {
                DPOLog::report_msg(DPOEvents::HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE, ["Release", $project->{name}, $src_release]);
            }
            if (-e $src_release
                    && !(-e $src_debug))
            {
                DPOLog::report_msg(DPOEvents::HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE, ["Debug", $project->{name}, $src_debug]);
            }
        }

        my $ft = File::Type->new();

        # select exe to copy (release)

        if (-e $src_release)
        {
            my @content=();
            if (!DPOUtils::get_dir_content($src_release, \@content))
            {
                DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_release]);
                return 0;
            }

            foreach my $file (@content)
            {
                my $complete = "$src_release/$file";
                if (-f $complete)
                {
                    my $type_from_file = $ft->checktype_filename($complete);

                    if ($type_from_file =~ /x.*-executable/)
                        #~ || $file =~ /\.pdb$/)
                    {
                        my $target_file = "$target_release/$file";
                        my $source_target = ToFreezeSourceTarget->new($complete,
                                                                $target_file);
                        push(@$files_to_copy_ref, $source_target);
                    }
                }
            }
        }

        if (-e $src_debug)
        {
            # select exe to copy (debug)
            if ($^O =~ /Win/)
            {
                my @content=();
                if (!DPOUtils::get_dir_content($src_debug, \@content))
                {
                    DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$src_debug]);
                    return 0;
                }

                foreach my $file (@content)
                {
                    my $complete = "$src_debug/$file";

                    if (-f $complete)
                    {
                        my $type_from_file = $ft->checktype_filename($complete);

                        if ($type_from_file =~ /x.*-executable/)
                            #~ || $file =~ /\.pdb$/)
                        {
                            my $target_file = "$target_debug/$file";

                            my $source_target = ToFreezeSourceTarget->new($complete,
                                                                $target_file);
                            push(@$files_to_copy_ref, $source_target);
                        }
                    }
                }
            }
        }
    }

    return 1;
}

sub get_etcs_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    my $src = "$project_dir/etc";
    if (-e $src)
    {
        my $target = "$modules_target_directory/etc";
        $self->file_to_copy_on_freeze($src, $target, 0, $files_to_copy_ref);
    }

    return 1;
}

sub get_vars_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    my $src = "$project_dir/var";
    if (-e $src)
    {
        my $target = "$modules_target_directory/var";
        $self->file_to_copy_on_freeze($src, $target, 0, $files_to_copy_ref);
    }

    return 1;
}

sub get_docs_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    my $src = "$project_dir/doc";
    if (-e $src)
    {
        my $target = "$modules_target_directory/doc";
        $self->file_to_copy_on_freeze($src, $target, 0, $files_to_copy_ref);
    }

    return 1;
}

sub get_mpcs_to_copy
{
    my ($self, $project, $project_dir, $modules_target_directory, $files_to_copy_ref) = @_;

    my $src = "$project_dir/MPC";
    if (-e $src)
    {
        my $target = "$modules_target_directory/MPC";
        $self->file_to_copy_on_freeze($src, $target, 0, $files_to_copy_ref);
    }

    return 1;
}

sub file_to_copy_on_freeze
{
    my ($self, $src, $target, $bSub, $to_be_copied) = @_;

    my @out;
    if (!DPOUtils::TreeScan($src, \@out))
    {
        DPOLog::report_msg(DPOEvents::TREE_SCAN_FAILURE, [$src]);
        return 0;
    }

    foreach my $entry (@out)
    {
        my ($file) = $entry =~ /$src\/(.*)/;
        my $target_file = "$target/$file";

        #~ print "to copy: $src/$file --> $target_file\n";

        my $source_target = ToFreezeSourceTarget->new("$src/$file",
                                                        $target_file);
        push(@$to_be_copied, $source_target);
    }

    return 1;
}

sub extract_projects_of_the_last_product_version
{
    my ($self, $versions_log, $last_version_projects_ref) = @_;

    my @lines;
    if (!DPOUtils::get_file_lines($versions_log, \@lines))
    {
        return 1;
    }

    my @last_block;
    foreach my $line (reverse @lines)
    {
        chomp $line;

        if ($line =~ /^$/) # not an empty line
        {
            next;
        }

        push(@last_block, $line);
        if ($line =~ /\[.*\]/)
        {
            last;
        }
    }

    foreach my $line (reverse @last_block)
    {
        push(@$last_version_projects_ref, $line);
    }

    return 1;
}

sub add_new_product_version_entry
{
    my ($self, $versions_log, $new_product_version, $last_version_projects_ref, $timestamp) = @_;

    my $bPrintToFile = 1;  #  1: to file,  0: to console

    my $fh;
    if ($bPrintToFile)
    {
        $fh = new FileHandle();
        if (!$fh->open(">>$versions_log"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, [$versions_log, $!]);
            return 0;
        }
    }
    else
    {
        $fh = *STDOUT;
    }

    print $fh "[$new_product_version] $timestamp\n";

    foreach my $line (sort @{$last_version_projects_ref})
    {
        if ($line =~ /\[.*\]/)
        {
            next;
        }

        print $fh "$line\n";
    }

    print $fh "\n";

    if ($bPrintToFile)
    {
        $fh->close;
    }

    return 1;
}

sub update_product_runtimes_log
{
    my ($self, $runtimes_log_file, $product, $timestamp) = @_;

    my @freeze_runtimes;
    foreach my $runtime (@{$product->{runtime}->{runtime_products_non_compliant}})
    {
        foreach my $module_name (@{$runtime->{modules_names}})
        {
            push(@freeze_runtimes, "$runtime->{name}/$runtime->{flavour}/$runtime->{version}/$module_name");
        }
    }

    foreach my $runtime (@{$product->{runtime}->{runtime_products_compliant}})
    {
        foreach my $dep (@{$runtime->{dpo_project_dependencies}})
        {
            my $ext = "";
            if ($^O =~ /Win/)
            {
                if ($dep->{type} == 6)
                {
                    $ext = ".dll";
                }
                else
                {
                    if ($dep->{type} == 0
                        || $dep->{type} == 1)
                    {
                        $ext = ".exe";
                    }
                    else
                    {
                        # TO_DO aviser mauvais type.
                    }
                }
            }
            push(@freeze_runtimes, "$runtime->{name}/$runtime->{flavour}/modules/$dep->{name}/$runtime->{version}/$dep->{name}$ext");
        }
    }

    my @new_log;
    foreach my $r (@freeze_runtimes)
    {
        my $log_entry = "    $r";
        push(@new_log, $log_entry);
    }

    my $fh = new FileHandle();

    my $bPrintToFile = 0;  #  1: to file,  0: to console

    if (!$bPrintToFile)
    {
        if (!$fh->open(">> $runtimes_log_file"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, [$runtimes_log_file, $!]);
            return 0;
        }
    }
    else
    {
        $fh = *STDOUT;
    }

    print $fh "[$product->{version}] $timestamp\n";
    foreach my $new_log_entry (@new_log)
    {
        print $fh "$new_log_entry\n";
    }

    print $fh "\n";

    if ($bPrintToFile)
    {
        $fh->close;
    }

    return 1;
}

sub header_impl_or_abstract_class_to_include
{
    my ($self, $project, $projects_to_include_ref, $tracing) =  @_;

    if ($project->is_header_impl_or_abstract_class())
    {
        if ($projects_to_include_ref != 0)
        {
            if (!List::MoreUtils::any {$_->{name} eq $project->{name}} @{$projects_to_include_ref})
            {
                if ($tracing)
                {
                    print "$project->{name} - not included\n";
                }
                return 0;
            }
        }
    }

    if ($tracing)
    {
        print "$project->{name} - included\n";
    }

    return 1;
}

sub add_configurationname_to_local_dependencies
{
    my ($self, $project, $fh, $confs_ref) = @_;

    foreach my $dep (@{$project->relevant_deps()})
    {
        my $proj;
        $self->{panel_product}->get_project($dep->{name}, \$proj);

        my $env_var_id = uc($proj->{name}) . "_PRJ_ROOT";
        my $path = "\$($env_var_id)";
        if (DPOEnvVars::expand_env_var(\$path))
        {
            if (!DPOUtils::in_dpo_pool($path))
            {
                if (!List::MoreUtils::any {$_ eq $env_var_id} @$confs_ref)
                {
                    print $fh "    libpaths += \$($env_var_id)/lib/\$(ConfigurationName)\n";
                    push(@$confs_ref, $env_var_id);
                }
            }
        }
        else
        {
            # Local dependencies are dpo compliant. If $dep is non dpo compliant,
            # it is necessary in the pool.
        }

        $self->add_configurationname_to_local_dependencies($proj, $fh, $confs_ref);
    }
}

sub get_mpc_includes_for_mwc
{
    my ($self, $project, $processed_mpc_includes_ref, $mpc_includes_ref) = @_;

    my $project_name;
    my $mpc_inc_ref;
    if ($project->{dpo_compliant}->{value})
    {
        # MPC includes is not provided with DPO compliant project but
        # we know it is $XYZ/MPC.
        $project_name = $project->{name};

        my $env_var_id = uc($project_name) . "_PRJ_ROOT";
        my $path = "\$($env_var_id)";
        if (DPOEnvVars::expand_env_var(\$path))
        {
            $mpc_inc_ref = "$path/MPC";
        }
        else
        {
            DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
            return 0;
        }
    }
    else
    {
        $project_name = $project->{dpo_compliant}->{product_name};
        $mpc_inc_ref = $project->{dpo_compliant}->{mpc_includes};
    }

    my @mpc_includes = split(/;/, $mpc_inc_ref);
    foreach my $mpc_includes_value (@mpc_includes)
    {
        my $mpc_includes = "cmdline += -include \"$mpc_includes_value\"";

        if (!List::MoreUtils::any {$_ eq $mpc_includes_value} @$processed_mpc_includes_ref)
        {
            push(@$mpc_includes_ref, $mpc_includes);
            push(@$processed_mpc_includes_ref, $mpc_includes_value);
        }
    }

    foreach my $dep (@{$project->relevant_deps()})
    {
        my $proj;
        $self->{panel_product}->get_project($dep->{name}, \$proj);
        if (!$self->get_mpc_includes_for_mwc($proj, $processed_mpc_includes_ref, $mpc_includes_ref))
        {
            return 0;
        }
    }

    return 1;
}


1;
