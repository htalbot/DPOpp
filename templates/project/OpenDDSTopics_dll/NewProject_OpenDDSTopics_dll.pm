# TemplateID=DDS:OpenDDS:Topic

package NewProject_OpenDDSTopics_dll;

use strict;

unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

require NewProjectTemplate;

use vars qw(@ISA);
@ISA = qw(NewProjectTemplate);

sub validate
{
    my ($self, $msg_ref) = @_;

    if (!$ENV{DDS_ROOT})
    {
        $$msg_ref = "DDS_ROOT not defined.";
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
    if (!DPOProductConfig::get_product_with_name("DDS", \$ace_product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["DDS"]);
        return 0;
    }

    if (!$self->{panel_product}->add_non_compliant_dep($project, $ace_product, "OpenDDS_Dcps", "dcps"))
    {
        DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["DDS", "OpenDDS_Dcps"]);
        return 0;
    }

    return 1;
}


1;
