# LayerID=TAO_client

use lib $ENV{DPO_CORE_ROOT} . "/scripts";
use lib $ENV{DPO_CORE_ROOT} . "/scripts/GUI";

package NewLayer_TAO_client;

use strict;
use DPOEvents;
use DPOUtils;

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

    print "pre_import_: TAO_server\n";

    if (!$self->{project}->is_executable())
    {
        DPOLog::report_msg(
                    DPOEvents::GENERIC_ERROR,
                    ["A TAO client can be executable only ($self->{project}->{name} is not executable)."]);
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

    print "post_import_: TAO_client\n";

    if (!$self->SUPER::set_corba_parameters())
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["set_corba_parameters failed"]);
        return 0;
    }

    # Add additional dependencies
    my $ace_product;
    if (!DPOProductConfig::get_product_with_name("ACE", \$ace_product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["ACE"]);
        return 0;
    }

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
    if (!$self->{panel_product}->save_workspace($self->{panel_product}->{workspace_projects}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't save workspace"]);
        return 0;
    }

    $self->{panel_product}->fill_tree_workspace();
    $self->{panel_product}->fill_product_projects();
    $self->{panel_product}->validate();

    return 1;
}

sub obj_itf_to_select
{
    my ($self, $dlg_obj_itf) = @_;

    # No selection: 0
    # Implement a Corba interface: 1
    # Use a Corba object (client): 2
    # Activate a Corba object (server): 3

    my $index = 2;

    for (my $i = 0; $i != 4; $i++)
    {
        if ($i != $index)
        {
            $dlg_obj_itf->{radio_box_choice}->Enable($i, 0);
        }
    }
}


1;
