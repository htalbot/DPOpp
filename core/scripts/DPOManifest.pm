#!/usr/bin/perl

package QualifiedManifestFile;

sub new
{
    my ($class, $name) = @_;

    my $self =
    {
        name => $name,
        status => "include"
    };

    bless($self, $class);

    return $self;
}

1;


package DPOManifest;

sub new
{
    my ($class) = @_;

    my $self =
    {
        lib => [],
        bin => [],
        etc => [],
        var => [],
        doc => [],
        others => []
    };

    bless($self, $class);

    return $self;
}

1;
