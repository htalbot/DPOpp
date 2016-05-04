use lib $ENV{DPO_CORE_ROOT} . "/scripts";

use strict;
use Wx qw[:everything];
use File::Path;
use DPOEvents;

package NewLayerBase;

sub new
{
    my ($class, $layer_path, $project_path, $project, $panel_product) = @_;

    my $self = {
    };

    $layer_path =~ s/\\/\//g;
    $project_path =~ s/\\/\//g;

    $self->{layer_path} = $layer_path;
    $self->{project_path} = $project_path;
    $self->{project} = $project;
    $self->{panel_product} = $panel_product;

    bless($self, $class);

    return $self;
}

sub pre_validate
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub post_validate
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub import
{
    my ($self) = @_;

    if (!$self->pre_import_())
    {
        return 0;
    }

    if (!$self->import_())
    {
        return 0;
    }

    if (!$self->post_import_())
    {
        return 0;
    }

    my $wait = Wx::BusyCursor->new();

    my $propagate_msg="";
    if (!DPOUtils::propagate_changes($self->{project_path}, $self->{project}->{name}, \$propagate_msg))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can not propagate with $self->{project}->{name}"]);
        return 0;
    }

    if (!DPOUtils::replace_string_in_file($self->{project_path}, "xyz", $self->{project}->{name}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't replace 'xyz' with $self->{project}->{name}"]);
        return 0;
    }

    return 1;
}

sub pre_import_
{
    my ($self) = @_;

    if (!$self->pre_validate())
    {
        return 0;
    }

    # ...

    return 1;
}

# Base implementation of import
sub import_
{
    my ($self) = @_;

    my $wait = Wx::BusyCursor->new();

    my %files_to_copy;
    my $err_msg;
    if (!$self->get_files_to_copy(\%files_to_copy, \$err_msg))
    {
        Wx::MessageBox(
                $err_msg,
                "Importing",
                Wx::wxOK | Wx::wxICON_ERROR);
        return 0;
    }

    $self->filter(\%files_to_copy);

    # Actually copy files
    if (!$self->copy_the_files(\%files_to_copy))
    {
        return 0;
    }

    $self->{panel_product}->load_projects_in_product($self->{panel_product}->{this_product}->{path});

    return 1;
}

sub post_import_
{
    my ($self) = @_;

    # ...

    if (!$self->post_validate())
    {
        return 0;
    }

    return 1;
}

sub get_files_to_copy
{
    my ($self, $files_out, $err_msg_ref) = @_;

    my $src_path = $self->{layer_path};

    unless (-e $src_path)
    {
        return 1;
    }

    my @out;
    if (!DPOUtils::TreeScan($src_path, \@out))
    {
        DPOLog::report_msg(DPOEvents::TREE_SCAN_FAILURE, [$src_path]);
        return 0;
    }

    foreach my $entry (@out)
    {
        $entry =~ s/\\/\//g;

        my ($file) = $entry =~ /$src_path\/(.*)/;
        if ($file =~ /\//)
        {
            $file =~ s/xyz/$self->{project}->{name}/g;

            my $target_file = "$self->{project_path}/$file";

            #~ print "to copy: $src_path/$file --> $target_file\n";

            $files_out->{$entry} = $target_file;
        }
    }

    return 1;
}

sub copy_the_files
{
    my ($self, $files_to_copy) = @_;

    my @files_to_update;
    foreach my $key (keys %$files_to_copy)
    {
        my $file = $files_to_copy->{$key};

        unless (-e $file)
        {
            my ($path, $fname) = $file =~ /(.*)\/(.*)/;

            if (!DPOUtils::make_path($path))
            {
                return 0;
            }

            if (!File::Copy::copy($key, $file))
            {
                DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$key, $file, $!]);
                return 0;
            }
            push(@files_to_update, $file);
        }
    }

    if (!DPOUtils::replace_in_file("dummy", $self->{project}->{name}, \@files_to_update))
    {
        Wx::MessageBox(
                "Can not replace text with $self->{project}->{name}.",
                "Importing",
                Wx::wxOK | Wx::wxICON_ERROR);
        return 0;
    }

    return 1;
}

sub filter
{
    my ($self, $files_to_copy) = @_;

    print "NewLayerBase::filter()...\n";
}


1;
