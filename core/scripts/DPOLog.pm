#!/usr/bin/perl

use strict;
use DPOEvents;

package DPOLog;

my $g_frame = 0;

sub set_frame
{
    my ($frame) = @_;

    $g_frame = $frame;
}

sub report_msg
{
    my ($event_id, $params_ref) = @_;

    my $events = DPOEvents->new();
    my $msg = $events->get_text($event_id, $params_ref);
    print "$msg\n";

    if ($g_frame)
    {
        $g_frame->report_msg($event_id, $params_ref, (caller(1))[3]);
    }
}

1;
