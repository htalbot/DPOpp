use strict;

package DPOMPC;
use parent 'Clone';
use DPOUtils;
use DPOEnvVars;

sub new
{
    my ($class) = @_;

    my $self =
    {
        mpc_features => []
    };

    bless($self, $class);

    return $self;
}

sub init
{
    my ($self) = @_;

    $self->read_mpc_features();
}

sub read_features
{
    my ($self, $features_ref) = @_;

    if (scalar(@{$self->{mpc_features}}) == 0)
    {
        my $mpc_path = "\$(MPC_ROOT)";
        if (!DPOEnvVars::expand_env_var(\$mpc_path))
        {
            return 0;
        }
        if (defined($mpc_path) && length($mpc_path) != 0)
        {
            if (!DPOUtils::read_features_from($mpc_path, \@{$self->{mpc_features}}))
            {
                return 0;
            }
        }

        my $ace_path = "\$(ACE_ROOT)";
        if (!DPOEnvVars::expand_env_var(\$ace_path))
        {
            return 0;
        }
        if (defined($ace_path) && length($ace_path) != 0)
        {
            if (!DPOUtils::read_features_from("$ace_path/bin/MakeProjectCreator", \@{$self->{mpc_features}}))
            {
                return 0;
            }
        }
    }

    @$features_ref = @{$self->{mpc_features}};

    return 1;
}

1;
