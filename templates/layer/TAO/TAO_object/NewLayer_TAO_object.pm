# LayerID=TAO_object

use lib $ENV{DPO_CORE_ROOT} . "/scripts";
use lib $ENV{DPO_CORE_ROOT} . "/scripts/GUI";

package NewLayer_TAO_object;

use strict;
use List::MoreUtils;
use DPOUtils;
use DPOEnvVars;
use DPOProductNewProjectsToIncludeInWorkspaceDlg;

require NewLayer_TAO_base;

use vars qw(@ISA);
@ISA = qw(NewLayer_TAO_base);

sub new
{
    my ($class, $layer_path, $project_path, $project, $panel_product) = @_;

    my $self = $class->SUPER::new($layer_path, $project_path, $project, $panel_product);

    return $self;
}

sub validate
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub pre_import_
{
    my ($self) = @_;

    print "pre_import_: TAO_object\n";

    if (!$self->{project}->is_library())
    {
        DPOLog::report_msg(
                    DPOEvents::GENERIC_ERROR,
                    ["DPO recommends to implement a Corba object in a library. ".
                     "If you absolutely want to implement it in an executable, ".
                     "please rely on test_xyz_server in templates/layer/TAO/TAO_object."]);
        return 0;
    }

    return 1;
}

sub import_
{
    my ($self) = @_;

    if (!$self->SUPER::import_())
    {
        return 0;
    }

    return 1;
}

sub post_import_
{
    my ($self) = @_;

    print "post_import_: TAO_object\n";

    if (!$self->SUPER::set_corba_parameters())
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["set_corba_parameters failed"]);
        return 0;
    }

    {
        my $wait = Wx::BusyCursor->new(); # TO_DO: marche pas si pas dans scope

        # Saving environment variables
        my @listEnvVarValues;

        my $env_var_id_client = "TEST_" . uc($self->{project}->{name}) . "_CLIENT_PRJ_ROOT";
        my $path = "$self->{project_path}/test_" . $self->{project}->{name} . "_client";
        my $env_var_client = DPOEnvVar->new($env_var_id_client, $path);
        push(@listEnvVarValues, $env_var_client);

        my $env_var_id_server = "TEST_" . uc($self->{project}->{name}) . "_SERVER_PRJ_ROOT";
        $path = "$self->{project_path}/test_" . $self->{project}->{name} . "_server";
        my $env_var_server = DPOEnvVar->new($env_var_id_server, $path);
        push(@listEnvVarValues, $env_var_server);

        DPOEnvVars::system_set_env_vars(\@listEnvVarValues);
    }

    # Update test_xyz_client
    my $project_client;
    if (!$self->{panel_product}->get_project("test_" . $self->{project}->{name} . "_client", \$project_client))
    {
        DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, ["test_" . $self->{project}->{name} . "_client"]);
        return 0;
    }
    if (!DPOUtils::update_deps_version_and_type($project_client, $project_client, $self->{panel_product}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't update version and types of dependencies for $project_client->{name}"]);
        return;
    }

    # Update test_xyz_server
    my $project_server;
    if (!$self->{panel_product}->get_project("test_" . $self->{project}->{name} . "_server", \$project_server))
    {
        DPOLog::report_msg(DPOEvents::GET_PROJECT_FAILURE, ["test_" . $self->{project}->{name} . "_server"]);
        return 0;
    }
    if (!DPOUtils::update_deps_version_and_type($project_server, $project_server, $self->{panel_product}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't update version and types of dependencies for $project_server->{name}"]);
        return;
    }

    # Include subprojects into the current workspace.
    my @sub_projects_names;
    if (DPOUtils::find_sub_projects($self->{project_path}, \@sub_projects_names))
    {
        my $dlg = DPOProductNewProjectsToIncludeInWorkspaceDlg->new(
                        $self->{project}->{name},
                        \@sub_projects_names,
                        undef,
                        -1,
                        "",
                        Wx::wxDefaultPosition,
                        Wx::wxDefaultSize,
                        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);

        $dlg->ShowModal();

        my $wait = Wx::BusyCursor->new();

        foreach my $project_name (@{$dlg->{selected_projects_names}})
        {
            if (!List::MoreUtils::any {$_->{name} eq $project_name} @{$self->{panel_product}->{workspace_projects}})
            {
                my $proj;
                if ($self->{panel_product}->get_project($project_name, \$proj))
                {
                    push(@{$self->{panel_product}->{workspace_projects}}, $proj);
                }
            }
        }

        $dlg->Destroy();

        my $ace_product;
        if (!DPOProductConfig::get_product_with_name("ACE", \$ace_product))
        {
            DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["ACE"]);
            return 0;
        }

        # Add additional dependencies
        if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{working_project}, $ace_product, "TAO_IORTable", "iortable"))
        {
            DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_IORTable"]);
            return 0;
        }

        if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{working_project}, $ace_product, "TAO_Messaging", "messaging"))
        {
            DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Messaging"]);
            return 0;
        }

        if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{working_project}, $ace_product, "TAO_CosNaming", "naming"))
        {
            DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_CosNaming"]);
            return 0;
        }

        if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{working_project}, $ace_product, "TAO_Utils", "utils"))
        {
            DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Utils"]);
            return 0;
        }

        # Save workspace
        if (!$self->{panel_product}->save_workspace($self->{panel_product}->{working_projects}))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't save workspace"]);
            return 0;
        }

        $self->{panel_product}->fill_tree_workspace();
        $self->{panel_product}->fill_product_projects();
        $self->{panel_product}->validate();
    }

    return 1;
}

sub filter
{
    my ($self, $files_to_copy) = @_;

    print "NewLayer_TAO_object::filter()...\n";
    #~ my @to_remove;
    #~ foreach my $key (%$files_to_copy)
    #~ {
        #~ if ($self->{project}->is_library())
        #~ {
            #~ if ($key =~ /test_.*_client/)
            #~ {
                #~ print "exclude $key\n";
                #~ push(@to_remove, $key);
            #~ }
        #~ }
    #~ }

    #~ foreach my $key (@to_remove)
    #~ {
        #~ delete $files_to_copy->{$key};

        #~ my $path = "$self->{layer_path}/test_.*_client";
        #~ if ($key =~ /$path/)
        #~ {
            #~ if (-d $path)
            #~ {
                #~ DPOUtils::remove_dir($path);
            #~ }
        #~ }
    #~ }
}

sub obj_itf_to_select
{
    my ($self, $dlg_obj_itf) = @_;

    # No selection: 0
    # Implement a Corba interface: 1
    # Use a Corba object (client): 2
    # Activate a Corba object (server): 3

    my $index = 1;

    for (my $i = 0; $i != 4; $i++)
    {
        if ($i != $index)
        {
            $dlg_obj_itf->{radio_box_choice}->Enable($i, 0);
        }
    }
}


1;
