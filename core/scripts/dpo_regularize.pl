use lib $ENV{DPO_CORE_ROOT} . "/scripts";

use strict;
use Getopt::Long;
use Wx qw[:everything];

use DPOUtils;
use DPOProject;

my $source;
my $msg;
if (!GetParam(\$source, \$msg))
{
    Wx::MessageBox(
            $msg,
            "Program arguments",
            Wx::wxOK | Wx::wxICON_ERROR,
            undef);
    exit -1;
}


regul($source);

sub regul
{
    my ($dir) = @_;

    my @content;
    if (DPOUtils::get_dir_content($dir, \@content))
    {
        foreach my $elem (@content)
        {
            my $complete = "$dir/$elem";
            if (-d $complete)
            {
                regul($complete);
            }
            else
            {
                if ($elem eq "DPOProject.xml")
                {
                    if (-f $complete)
                    {
                        my $err;
                        my $config = DPOProjectConfig->new($complete, \$err);
                        if ($config)
                        {
                            my $project;
                            if ($config->get_project(\$project))
                            {
                                foreach my $dep (@{$project->{dependencies_when_dynamic}}, @{$project->{dependencies_when_static}})
                                {
                                    if ($dep->{version} ne $dep->{target_version})
                                    {
                                        print "Diff in dep $dep->{name} ($dep->{version} ne $dep->{target_version}) of project $project->{name}-$project->{version}\n";
                                    }
                                }
                            }
                        }
                    }

                    #~ print "check for versions in $complete\n";
                }
            }
        }
    }
}


sub GetParam
{
    my ($source, $msg) = @_;

    # Syntax string
    my $syntax = "\nusage: $0 --source <project directory>\n";

    # read options
    GetOptions("source:s" => $source);

    if (!defined($$source))
    {
        $$msg = $syntax;
        return 0;
    }
    else
    {
        return 1;
    }
}



