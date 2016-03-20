package NewProjectTemplate;

sub new
{
    my ($class, $parent_dir, $project_name, $panel_product) = @_;

    my $self = {
    };

    $parent_dir =~ s/\\/\//g;

    $self->{parent_dir} = $parent_dir;
    $self->{project_name} = $project_name;
    $self->{panel_product} = $panel_product;

    bless($self, $class);

    return $self;
}

sub validate
{
    my ($self, $msg_ref) = @_;

    return 1;
}

sub get_right_project_type
{
    my ($self, $path, $project_type_ref) = @_;

    my ($type) = $path =~ /.*\/(.*)/;

    $$project_type_ref = $type;

    return 1;
}

sub post_create
{
    my ($self, $project, $parent, $msg_ref) = @_;

    return 1;
}

sub require_ace
{
    my ($self) = @_;

    return 0;
}

1;
