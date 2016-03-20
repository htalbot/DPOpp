# LayerID=ACE_plugin

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

package NewLayer_ACE_plugin;

use strict;
use DPOUtils;
use DPOEnvVars;
use DPOACEPluginAbstractBaseNameDlg;

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

    return $self;
}

sub pre_validate
{
    my ($self, $msg_ref) = @_;

    if (!$self->{project}->is_dynamic_library())
    {
        DPOLog::report_msg(
                    DPOEvents::GENERIC_ERROR,
                    ["$self->{project}->{name} is not a dynamic library."]);
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

    # Get available plugin interfaces

    # Get environment variables currently defined (*_ROOT)
    my $env_vars = DPOEnvVars->new();
    $env_vars->load();

    # Find relevant CPP abstract classes
    my @cpp_abstract_classes = ();
    foreach my $key (keys %$env_vars)
    {
        my $env_var = $env_vars->{$key};
        my $path = $env_var->{value};

        # What is the project?
        my $project_name = "";
        if ($path =~ /\d+\.\d+\.\d+$/)
        {
            ($project_name) = $path =~ /.*\/(.*)\/\d+\.\d+\.\d+/;
        }
        else
        {
            ($project_name) = $path =~ /.*\/(.*)?$/;
        }

        my $include_path = "$path/include/$project_name";

        # Check existence of the mandatory files to be an ace plugin interface
        if (-e $include_path) # must be in dpo format (ACE is an exception)
        {
            if (-f "$include_path/CPPAbstractClass.track")
            {
                push(@cpp_abstract_classes, $project_name);
            }
        }
    }

    my $rc = 1;

    my $dlg = DPOACEPluginAbstractBaseNameDlg->new(
        \@cpp_abstract_classes,
        undef,
        -1,
        "",
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL);

    if ($dlg->ShowModal() == Wx::wxID_OK)
    {
        my $name = $dlg->{selection};

        if (!DPOUtils::replace_string_in_file($self->{project_path}, "cpp_abstract_class", $name))
        {
            Wx::MessageBox(
                    "Can not replace 'cpp_abstract_class' with $name.",
                    "Importing",
                    Wx::wxOK | Wx::wxICON_ERROR);
            $rc = 0;
        }

        $self->{panel_product}->add_a_recall("Don't forget to include '$name' into '$self->{project}->{name}'.");
    }
    else
    {
        $rc = 0;
    }

    $dlg->Destroy();

    return $rc;
}


1;
