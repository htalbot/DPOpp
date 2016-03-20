# TemplateID=Corba:TAO:Interface

package NewProject_tao_interface_dll;

use strict;
use DPOEvents;

unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

require NewProjectTemplate;

use vars qw(@ISA);
@ISA = qw(NewProjectTemplate);

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

sub require_ace
{
    my ($self) = @_;

    return 1;
}

sub post_create
{
    my ($self, $project, $parent, $msg_ref) = @_;

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

    return 1;
}


1;
