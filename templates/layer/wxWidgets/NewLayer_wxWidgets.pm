# LayerID=wxWidgets

use lib $ENV{DPO_CORE_ROOT} . "/scripts";

package NewLayer_wxWidgets;

use strict;
use List::MoreUtils;
use File::Copy;
use DPOUtils;
use DPOEnvVars;

use Wx 0.15 qw[:allclasses];
use Wx qw[:everything];

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

    if (!$self->update_features_file())
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Updating features file for wxWidgets failed"]);
        return 0;
    }

    if (!$self->update_app_path_wxg($self->{project_path}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Failed to update project path in .wxg file"]);
        return 0;
    }

    my $rc = Wx::MessageBox(
                "Is ACE part of the project $self->{project}->{name} ?",
                "Importing wxWidgets",
                Wx::wxYES_NO | Wx::wxICON_QUESTION);
    if ($rc == Wx::wxYES)
    {
        if (!$self->append__wxHAS_MODE_T__in_mpc())
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't append wxHAS_MODE_T in mpc file"]);
            return 0;
        }
    }

    $rc = Wx::MessageBox(
                "Is wxWidgets unicode?",
                "Importing wxWidgets",
                Wx::wxYES_NO | Wx::wxICON_QUESTION);
    if ($rc == Wx::wxYES)
    {
        if (!$self->append__UNICODE__in_mpc())
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't append wxHAS_MODE_T in mpc file"]);
            return 0;
        }
    }

    $self->{panel_product}->add_a_recall("Don't forget to include required wxWidgets dependencies into '$self->{project}->{name}'.");

    return 1;
}


sub update_features_file
{
    my ($self) = @_;

    my $file = "$self->{project_path}/features";

    my @lines;
    if (!DPOUtils::get_file_lines($file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
        return 0;
    }

    my $entry = "wxwindows";
    if (!List::MoreUtils::any {$_ =~ /$entry/} @lines)
    {
        push(@lines, "$entry=1");
    }
    else
    {
        foreach my $line(@lines)
        {
            my $line2 = $line;

            DPOUtils::trim(\$line2);
            if ($line =~ /$entry/)
            {
                $line =~ s/=(.*)/= 1/;
                $line =~ s/\/\///; # remove comment
                $line =~ s/\s*(.*)/$1/; # remove leading spaces
            }
        }
    }

    my $tmp_file = $self->{project_path} . "/tmp";
    if (!open (OUT, ">$tmp_file"))
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $tmp_file, $!]);
        return 0;
    }

    foreach(@lines)
    {
        print OUT $_;
    }

    close(OUT);

    if (!File::Copy::copy($tmp_file, $file))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$tmp_file, $file, $!]);
        return 0;
    }

    unlink($tmp_file);

    $self->{project}->load_features();

    return 1;
}

sub update_app_path_wxg
{
    my ($self, $project_path) = @_;

    my @dir_content=();
    if (DPOUtils::get_dir_content($project_path, \@dir_content))
    {
        foreach my $elem (@dir_content)
        {
            if ($elem =~ /\.wxg$/)
            {
                if (!$self->update_app_path_wxg_($project_path))
                {
                    return 0;
                }
            }

            if (-d "$project_path/$elem")
            {
                if (!$self->update_app_path_wxg("$project_path/$elem"))
                {
                    return 0;
                }
            }
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::GET_DIR_CONTENT_FAILURE, [$project_path]);
        return 0;
    }

    return 1;
}

sub update_app_path_wxg_
{
    my ($self, $project_path) = @_;

    my $file = "$project_path/$self->{project}->{name}.wxg";

    unless (-e $file)
    {
        return 1;
    }

    my @lines;
    if (!DPOUtils::get_file_lines($file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
        return 0;
    }

    foreach my $line(@lines)
    {
        my $new = "application path=\"$project_path";
        $line =~ s/application path=\"(.*) (name.*)/$new\" $2/;

        $line =~ s/overwrite=\"1\"/overwrite=\"0\"/;

        if ($line =~ /$new/)
        {
            last;
        }
    }

    my $tmp_file = "$project_path/tmp";
    if (!open (OUT, ">$tmp_file"))
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $tmp_file, $!]);
        return 0;
    }

    foreach(@lines)
    {
        print OUT $_;
    }

    close(OUT);

    if (!File::Copy::copy($tmp_file, $file))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$tmp_file, $file, $!]);
        return 0;
    }

    unlink($tmp_file);

    return 1;
}

sub append__wxHAS_MODE_T__in_mpc
{
    my ($self) = @_;

    my $file = "$self->{project_path}/src/$self->{project}->{name}.mpc";

    my @lines;
    if (!DPOUtils::get_file_lines($file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
        return 0;
    }

    my $tmp_file = $self->{project_path} . "/tmp";
    if (!open (OUT, ">$tmp_file"))
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $tmp_file, $!]);
        return 0;
    }

    my $first = 1;
    foreach(@lines)
    {
        print OUT $_;
        if ($first
            && ($_ =~ /\{/))
        {
            $first = 0;
            print OUT "\n    macros += wxHAS_MODE_T\n";
        }
    }

    close(OUT);

    if (!File::Copy::copy($tmp_file, $file))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$tmp_file, $file, $!]);
        return 0;
    }

    unlink($tmp_file);

    return 1;
}

sub append__UNICODE__in_mpc
{
    my ($self) = @_;

    my $file = "$self->{project_path}/src/$self->{project}->{name}.mpc";

    my @lines;
    if (!DPOUtils::get_file_lines($file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$file]);
        return 0;
    }

    my $tmp_file = $self->{project_path} . "/tmp";
    if (!open (OUT, ">$tmp_file"))
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["open", $tmp_file, $!]);
        return 0;
    }

    # TO_DO: don't insert lines if they already exist.
    my $first = 1;
    foreach(@lines)
    {
        print OUT $_;
        if ($first
            && ($_ =~ /\{/))
        {
            $first = 0;

            print OUT "\n    specific(prop:microsoft) {\n";
            print OUT "        unicode = 1\n";
            print OUT "    }\n";

            # TO_DO: linux
        }
    }

    close(OUT);

    if (!File::Copy::copy($tmp_file, $file))
    {
        DPOLog::report_msg(DPOEvents::FILE_COPY_FAILURE, [$tmp_file, $file, $!]);
        return 0;
    }

    unlink($tmp_file);

    return 1;
}

1;
