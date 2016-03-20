#!/usr/bin/perl -w

use strict;

unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");
unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts/GUI");

use DPOUtils;

require DPOFrame;

use Wx qw[:everything];


package DPOApp;

use base 'Wx::App';

sub OnInit
{
    my $msg;
    if (!DPOUtils::check_essentials(\$msg))
    {
        Wx::MessageBox($msg);
        exit -1;
    }

    my $frame = DPOFrame->new(undef, -1, "", Wx::wxDefaultPosition, Wx::wxDefaultSize, Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL );

    if ($frame)
    {
        $frame->Show( 1 );
    }
    else
    {
        exit -1;
    }
}

1;


package main;

my $app = DPOApp->new;
$app->MainLoop;

1;
