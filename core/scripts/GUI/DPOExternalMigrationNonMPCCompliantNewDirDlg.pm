# generated by wxGlade 0.6.8 on Fri Oct 30 12:58:11 2015
#
# To get wxPerl visit http://wxPerl.sourceforge.net/
#

use Wx 0.15 qw[:allclasses];
use strict;
# begin wxGlade: dependencies
# end wxGlade

# begin wxGlade: extracode
# end wxGlade

package DPOExternalMigrationNonMPCCompliantNewDirDlg;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;
use Wx::Locale 'gettext' => '_T', 'gettext_noop' => 'gettext_noop';


sub new {
    my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $title  = ""                 unless defined $title;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    # begin wxGlade: DPOExternalMigrationNonMPCCompliantNewDirDlg::new
    $style = wxDEFAULT_DIALOG_STYLE 
        unless defined $style;

    $self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{text_ctrl_new_dir} = Wx::TextCtrl->new($self, wxID_ANY, "", wxDefaultPosition, wxDefaultSize, );
    $self->{sizer_23_staticbox} = Wx::StaticBox->new($self, wxID_ANY, _T("New subdirectory") );
    $self->{button_ok} = Wx::Button->new($self, wxID_ANY, _T("Ok"));
    $self->{button_cancel} = Wx::Button->new($self, wxID_ANY, _T("Cancel"));

    $self->__set_properties();
    $self->__do_layout();

    Wx::Event::EVT_BUTTON($self, $self->{button_ok}->GetId, \&on_button_ok);
    Wx::Event::EVT_BUTTON($self, $self->{button_cancel}->GetId, \&on_button_cancel);

    # end wxGlade

    $self->{button_ok}->SetDefault();

    return $self;
}


sub __set_properties {
    my $self = shift;
    # begin wxGlade: DPOExternalMigrationNonMPCCompliantNewDirDlg::__set_properties
    $self->SetTitle(_T("New subdirectory"));
    # end wxGlade
}

sub __do_layout {
    my $self = shift;
    # begin wxGlade: DPOExternalMigrationNonMPCCompliantNewDirDlg::__do_layout
    $self->{sizer_22} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sizer_112} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sizer_23_staticbox}->Lower();
    $self->{sizer_23} = Wx::StaticBoxSizer->new($self->{sizer_23_staticbox}, wxHORIZONTAL);
    $self->{sizer_23}->Add($self->{text_ctrl_new_dir}, 0, 0, 0);
    $self->{sizer_22}->Add($self->{sizer_23}, 0, wxALIGN_CENTER_HORIZONTAL, 0);
    $self->{sizer_112}->Add($self->{button_ok}, 0, wxLEFT, 3);
    $self->{sizer_112}->Add($self->{button_cancel}, 0, wxLEFT, 3);
    $self->{sizer_22}->Add($self->{sizer_112}, 0, wxALL|wxALIGN_CENTER_HORIZONTAL, 5);
    $self->SetSizer($self->{sizer_22});
    $self->{sizer_22}->Fit($self);
    $self->Layout();
    # end wxGlade
}

sub on_button_ok
{
    my ($self, $event) = @_;

    $self->EndModal(Wx::wxID_OK);

    return;

    # wxGlade: DPOExternalMigrationNonMPCCompliantNewDirDlg::on_button_ok <event_handler>
    warn "Event handler (on_button_ok) not implemented";
    $event->Skip;
    # end wxGlade
}


sub on_button_cancel
{
    my ($self, $event) = @_;

    $self->EndModal(Wx::wxID_CANCEL);

    return;

    # wxGlade: DPOExternalMigrationNonMPCCompliantNewDirDlg::on_button_cancel <event_handler>
    warn "Event handler (on_button_cancel) not implemented";
    $event->Skip;
    # end wxGlade
}


# end of class DPOExternalMigrationNonMPCCompliantNewDirDlg

1;

