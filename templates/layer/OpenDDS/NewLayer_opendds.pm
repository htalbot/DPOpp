# LayerID=OpenDDS

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

package NewLayer_OpenDDS;

use strict;
use Wx qw[:everything];
use DPOUtils;
use DPOEvents;
use DPOTopicNamesDlg;

require NewLayerBase;

use vars qw(@ISA);
@ISA = qw(NewLayerBase);

# TO_DO ???
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts/GUI");

sub new
{
    my ($class, $layer_path, $project_path, $project, $panel_product) = @_;

    my $self = $class->SUPER::new($layer_path, $project_path, $project, $panel_product);

    return $self;
}

sub pre_validate
{
    my ($self, $msg_ref) = @_;

    if (!$self->{project}->is_executable())
    {
        DPOLog::report_msg(
                    DPOEvents::GENERIC_ERROR,
                    ["$self->{project}->{name} is not executable."]);
        return 0;
    }

    return 1;
}

sub post_validate
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub pre_import_
{
    my ($self) = @_;

    if (!$self->SUPER::pre_import_())
    {
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

    if (!$self->SUPER::post_import_())
    {
        return 0;
    }

    # Get available OpenDDS Topics

    $self->set_opendds_parameters();

    # Add additional dependencies
    my $ace_product;
    if (!DPOProductConfig::get_product_with_name("ACE", \$ace_product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["ACE"]);
        return 0;
    }

    if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{workspace_project}, $ace_product, "TAO", "taolib"))
    {
        DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["ACE", "TAO"]);
        return 0;
    }

    my $dds_product;
    if (!DPOProductConfig::get_product_with_name("DDS", \$dds_product))
    {
        DPOLog::report_msg(DPOEvents::CANT_GET_PRODUCT, ["DDS"]);
        return 0;
    }

    if (!$self->{panel_product}->add_non_compliant_dep($self->{panel_product}->{workspace_project}, $dds_product, "OpenDDS_Rtps_Udp", "dcps_rtps_udp"))
    {
        DPOLog::report_msg(DPOEvents::CANT_ADD_NON_COMPLIANT_DEP, ["DDS", "OpenDDS_Rtps_Udp"]);
        return 0;
    }

    # Save workspace
    if (!$self->{panel_product}->save_workspace($self->{panel_product}->{workspace_projects}))
    {
        return 0;
    }

    return 1;
}

sub set_opendds_parameters
{
    my ($self) = @_;

    my $retcode = 1;

    if (!$ENV{DDS_ROOT})
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, ["DDS_ROOT"]);
        return 0;
    }

    my @available_topics=();
    DPOUtils::get_available_opendds_topics(\@available_topics);

    # Select topic
    my $dlg = DPOTopicNamesDlg->new(undef,
                                        -1,
                                        "",
                                        Wx::wxDefaultPosition,
                                        Wx::wxDefaultSize,
                                        Wx::wxDEFAULT_FRAME_STYLE
                                            |Wx::wxTAB_TRAVERSAL );

    $dlg->set_topics(\@available_topics);

    my $rc = $dlg->ShowModal();
    if ($rc == Wx::wxID_OK)
    {
        my $module_and_topic = $dlg->{list_box_topics}->GetStringSelection();
        my ($module, $namespace, $topic_name) = $module_and_topic =~ /(.*):(.*)::(.*)/;

        DPOUtils::trim(\$topic_name);
        DPOUtils::trim(\$namespace);

        my $rc = $self->update_topic_names($module, $namespace, $topic_name);
        if (!$rc)
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["update_topic_names failed"]);
            $retcode = 0;
        }
        else
        {
            $self->{panel_product}->add_a_recall("Don't forget to include '$module' into '$self->{project}->{name}'.");
        }
    }
    else
    {
        $retcode = 0;
    }

    $dlg->Destroy();

    return $retcode;
}


sub update_topic_names
{
    my ($self, $topic_host, $topic_namespace, $topic_id) = @_;

    if (!DPOUtils::replace_string_in_file($self->{project_path},
                                "related_topic_host",
                                $topic_host))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'related_topic_host' in $self->{project_path} files failed"]);
        return 0;
    }

    my $sep = "::";

    if (!DPOUtils::replace_string_in_file($self->{project_path},
                                "TOPIC_NAMESPACE",
                                "$topic_namespace"))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'TOPIC_NAMESPACE' in $self->{project_path} files failed"]);
        return 0;
    }

    if (!DPOUtils::replace_string_in_file($self->{project_path},
                                "related_topic_obj",
                                $topic_id))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'related_topic_obj' in $self->{project_path} files failed"]);
        return 0;
    }

    return 1;
}


1;
