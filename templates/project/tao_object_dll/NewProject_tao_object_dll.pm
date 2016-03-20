# TemplateID=Corba:TAO:ObjectImplementation

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

package NewProject_tao_object_dll;

use strict;
use DPOProject;
use Wx qw[:everything];

# TO_DO ???
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

use DPOProject;
require NewProjectTemplate;

use vars qw(@ISA);
@ISA = qw(NewProjectTemplate);

# TO_DO ???
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts/GUI");

require TAOInterfaceDlg;
require DPOUtils;

sub validate
{
    my ($self, $msg_ref) = @_;

    if (!$ENV{TAO_ROOT})
    {
        $$msg_ref = "TAO_ROOT not defined.";
        return 0;
    }

    return 1;
}

sub post_create
{
    my ($self, $project, $parent, $msg_ref) = @_;

    my @available_tao_interfaces;
    if (!DPOUtils::get_available_corba_interfaces(\@available_tao_interfaces))
    {
        $$msg_ref = "Error while getting Corba interfaces.";
        return 0;
    }

    if (scalar(@available_tao_interfaces) == 0)
    {
        $$msg_ref = "No Corba interfaces available.";
        return 0;
    }

    # Select interface
    my $dlg = TAOInterfaceDlg->new(undef,
                                        -1,
                                        "",
                                        Wx::wxDefaultPosition,
                                        Wx::wxDefaultSize,
                                        Wx::wxDEFAULT_FRAME_STYLE
                                            |Wx::wxTAB_TRAVERSAL );

    $dlg->set_interfaces(\@available_tao_interfaces);

    my $rc = 1;

    my $button = $dlg->ShowModal();
    if ($button == Wx::wxID_OK)
    {
        my $text = $dlg->{combo_box_interface}->GetStringSelection();
        my ($module, $interface) = $text =~ /(.*):(.*)/;

        if (!$self->update_tao_interface_names(
                $parent,
                $module,
                $interface,
                $msg_ref))
        {
            my $parent_dir = $self->{text_ctrl_parent_dir}->GetValue();

            my $slash = "/";
            if ($^O =~ /Win/)
            {
                $slash = "\\";
            }

            $$msg_ref = "Failed to update names for object and interface.";
            $rc = 0;
        }

        $self->{panel_product}->add_a_recall("Don't forget to include $module into '$self->{project_name}'.");
    }

    if ($button == Wx::wxID_CANCEL)
    {
        $$msg_ref = "Interface not selected.";
        $rc = 0;
    }

    $dlg->Destroy();

    if ($rc == 0)
    {
        return 0;
    }

    my $ace_product;
    if (!DPOProductConfig::get_product_with_name("ACE", \$ace_product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["ACE"]);
        return 0;
    }

    if (!$self->{panel_product}->add_non_compliant_dep($project, $ace_product, "TAO_PortableServer", "portableserver"))
    {
        DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_PortableServer"]);
        return 0;
    }

    # Add dependencies to test_xyz_client and test_xyz_server
    my $env_var_id = uc($project->{name}) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (DPOEnvVars::expand_env_var(\$path))
    {
        my $test_client = "test_" . $project->{name} . "_client";
        my $file = "$path/$test_client/DPOProject.xml";
        my $config = DPOProjectConfig->new($file);
        if ($config)
        {
            my $project_client;
            if ($config->get_project(\$project_client))
            {
                if (!$self->{panel_product}->add_non_compliant_dep($project_client, $ace_product, "TAO_CosNaming", "naming"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_CosNaming"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_client, $ace_product, "TAO_IORTable", "iortable"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_IORTable"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_client, $ace_product, "TAO_Messaging", "messaging"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Messaging"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_client, $ace_product, "TAO_Utils", "utils"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Utils"]);
                    return 0;
                }

                if (!$self->{panel_product}->save_project($project_client))
                {
                    DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't save project $project_client->{name}"]);
                    return 0;
                }
            }
        }

        my $test_server = "test_" . $project->{name} . "_server";
        $file = "$path/$test_server/DPOProject.xml";
        $config = DPOProjectConfig->new($file);
        if ($config)
        {
            my $project_server;
            if ($config->get_project(\$project_server))
            {
                if (!$self->{panel_product}->add_non_compliant_dep($project_server, $ace_product, "TAO_CosNaming", "naming"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_CosNaming"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_server, $ace_product, "TAO_IORTable", "iortable"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_IORTable"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_server, $ace_product, "TAO_Messaging", "messaging"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Messaging"]);
                    return 0;
                }

                if (!$self->{panel_product}->add_non_compliant_dep($project_server, $ace_product, "TAO_Utils", "utils"))
                {
                    DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO_Utils"]);
                    return 0;
                }

                if (!$self->{panel_product}->save_project($project_server))
                {
                    DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't save project $project_server->{name}"]);
                    return 0;
                }
            }
        }
    }

    return $rc;
}


sub update_tao_interface_names
{
    my ($self, $parent, $module, $interface, $msg_ref) = @_;

    my $parent_dir = $parent->{text_ctrl_parent_directory}->GetValue();
    my $project_name = $parent->{text_ctrl_project_name}->GetValue();

    if (!DPOUtils::replace_string_in_file("$parent_dir/$project_name",
                                            "Related_object_i",
                                            "$project_name" . "_i"))
    {
        $$msg_ref = "Failed to rename objects in object ".
                            "implementation files";
        return 0;
    }

    if (!DPOUtils::replace_string_in_file("$parent_dir/$project_name",
                                            "relatedinterface",
                                            $module))
    {
        $$msg_ref = "Failed to rename interface modules in files";
        return 0;
    }

    if (!DPOUtils::replace_string_in_file("$parent_dir/$project_name",
                                            "Relatedinterface",
                                            $interface))
    {
        $$msg_ref = "Failed to rename interfaces in object files";
        return 0;
    }

    return 1;
}


sub require_ace
{
    my ($self) = @_;

    return 1;
}


1;
