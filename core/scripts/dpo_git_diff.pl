use lib $ENV{DPO_CORE_ROOT} . "/scripts";

use strict;
use Cwd;
use Getopt::Long;
use Wx qw[:everything];

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


git_diff($source);

sub git_diff
{
    my ($dir) = @_;

    my @content;
    if (get_dir_content($dir, \@content))
    {
        foreach my $elem (@content)
        {
            my $complete = "$dir/$elem";

            if (-d $complete)
            {
                if ($elem eq ".git")
                {
                    print ".git: $complete\n";
                    my $cwd = getcwd();
                    chdir($complete);
                    system("\"C:\Program Files (x86)\Git\bin\sh.exe\" --login -i");
                    #~ system("dir");
                    chdir($cwd);
                }
                else
                {
                    git_diff($complete);
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

sub get_dir_content
{
    my ($dir, $content_ref) = @_;

    my $initial_wd = Cwd::getcwd();

    if (!chdir($dir))
    {
        print "Can't change directory to $dir\n";
        return 0;
    }
    my $cwd = Cwd::getcwd();

    opendir(DIR, $cwd);
    @$content_ref = readdir(DIR);
    closedir(DIR);

    my @purified=();
    foreach(@$content_ref)
    {
        if (($_ ne "." && $_ ne ".." ))
        {
            if (!/.svn$/
                #~ && !/.git/
                && !/.bzr/)
            {
                push(@purified, $_);
            }
        }
    }

    @$content_ref = @purified;

    chdir($initial_wd);

    return 1;
}


