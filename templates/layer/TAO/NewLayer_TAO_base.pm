# LayerID=TAO_base

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

package NewLayer_TAO_base;

use strict;
use DPOUtils;
use DPOObjAndItfNamesDlg;
use Wx qw[:everything];

# TO_DO ???
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

require NewLayerBase;

use vars qw(@ISA);
@ISA = qw(NewLayerBase);

# TO_DO ???
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts/GUI");

sub new
{
    my ($class, $layer_path, $project_path, $project, $panel_product) = @_;

    my $self = $class->SUPER::new($layer_path, $project_path, $project, $panel_product);

    $self->{interface_project_name} = "";
    $self->{interface_name} = "";
    $self->{object_host_name} = "";
    $self->{object_file_name} = "";

    return $self;
}

sub obj_itf_to_select
{
    my ($self, $dlg_obj_itf) = @_;

    # No selection: 0
    # Implement a Corba interface: 1
    # Use a Corba object (client): 2
    # Activate a Corba object (server): 3
    $dlg_obj_itf->{radio_box_choice}->SetSelection(0);
}

sub set_corba_parameters
{
    my ($self) = @_;

    if (!$ENV{TAO_ROOT})
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, ["TAO_ROOT"]);
        return 0;
    }

    my @available_tao_interfaces=();
    DPOUtils::get_available_corba_interfaces(\@available_tao_interfaces);

    my $dlg = DPOObjAndItfNamesDlg->new(undef,
                                        -1,
                                        "",
                                        Wx::wxDefaultPosition,
                                        Wx::wxDefaultSize,
                                        Wx::wxDEFAULT_FRAME_STYLE
                                            |Wx::wxTAB_TRAVERSAL );

    $dlg->fill_TAO_interfaces(\@available_tao_interfaces);
    $dlg->set_project_name($self->{project}->{name});
    $self->obj_itf_to_select($dlg);

    my $rc = 1;
    my $bLoop = 1;
    while (1)
    {
        if ($dlg->ShowModal() == Wx::wxID_OK)
        {
            my $interface = $dlg->{combo_box_interfaces}->GetValue();
            $self->{object_host_name} = $dlg->{text_ctrl_host_file}->GetValue();
            $self->{object_file_name} = $dlg->{text_ctrl_object_file}->GetValue();

            ($self->{interface_project_name}) = $interface =~ /(.*):.*/;
            $self->{panel_product}->add_a_recall("Don't forget to include '$self->{interface_project_name}' into '$self->{project}->{name}'.");

            ($self->{interface_name}) = $interface =~ /.*:(.*)/;
            $self->update_names(
                        $dlg->{target},
                        $self->{interface_name},
                        $self->{object_host_name},
                        $self->{object_file_name});

            last;
        }
        else
        {
            $rc = 0;
            last;
        }
    }

    $dlg->Destroy();

    return $rc;
}


sub update_names
{
    my ($self, $target, $itf_name, $obj_host, $obj_name) = @_;

    my $wait = Wx::BusyCursor->new(); # Doesn't work

    if ($obj_host)
    {
        if (!DPOUtils::replace_string_in_file($self->{project_path},
                                    "related_object_host",
                                    $obj_host))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'related_object_host' in $self->{project_path} files failed"]);
            return 0;
        }
    }

    if ($obj_name)
    {
        my ($first_letter, $remaining) = $obj_name =~ /(.{1})(.*)/;
        if (!$self->rename_files($self->{project_path}, "related_object", lc($first_letter) . $remaining))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'related_object' in $self->{project_path} files failed"]);
            return 0;
        }

        if (!DPOUtils::replace_string_in_file($self->{project_path},
                                    "related_object",
                                    $obj_name))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'related_object' in $self->{project_path} files failed"]);
            return 0;
        }
    }

    if ($itf_name)
    {
        if (!DPOUtils::replace_string_in_file($self->{project_path},
                                    "relatedinterface",
                                    $itf_name))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'relatedinterface' in $self->{project_path} files failed"]);
            return 0;
        }

        if (!DPOUtils::replace_string_in_file($self->{project_path},
                                    "Relatedinterface",
                                    $itf_name))
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Replacing 'Relatedinterface' in $self->{project_path} files failed"]);
            return 0;
        }
    }

    return 1;
}

sub rename_files
{
    my ($self, $dir, $value, $new_value) = @_;

    my @content=();
    if (!DPOUtils::get_dir_content($dir, \@content))
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$dir]);
        return 0;
    }

    foreach my $file (@content)
    {
        my $complete = "$dir/$file";

        if (-f $complete)
        {
            (my $n=$file) =~ s/$value/$new_value/;
            rename "$dir/$file", "$dir/$n";
        }

        if (-d $complete && $file ne "." && $file ne ".." )
        {
            if (!$self->rename_files($complete, $value, $new_value))
            {
                return 0;
            }

            (my $n=$file) =~ s/$value/$new_value/;
            rename "$dir/$file", "$dir/$n";
        }
    }

    return 1;
}

1;
