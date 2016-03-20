xyz
=========================================================

    There is an issue when we use wxWidgets along ACE. Both define 'mode_t'
    and this causes an error. So, to be able to use ACE and wxWidgets in the
    same module, we apply this patch to wxWidgets:

        --- filefn.h    2014-06-15 03:55:58 +0000
        +++ filefn.h.new    2014-09-08 15:44:26 +0000
        @@ -77,7 +77,7 @@
         // constants
         // ----------------------------------------------------------------------------

        -#if defined(__VISUALC__) || defined(__DIGITALMARS__)
        +#if (defined(__VISUALC__) || defined(__DIGITALMARS__)) && !defined(WX_HIDE_MODE_T)
             typedef int mode_t;
         #endif

        )

    In ACE, 'mode_t' is defined in file "ace/os_include/sys/os_types.h". So, to
    build the project using ACE and wxWidgets, we have to include
    "ace/os_include/sys/os_types.h" or another ACE header file that refers to it
    before including wxWidgets include file.

    To include wxWidgets in xyz project, merge the content of
    src/xyz.cpp_wx_to_merge to xyz.cpp. As always with templates and layers in
    DPO, they are used as guideline only.

    Don't forget to include dependencies from wxWidgets into the projet.
    wxWidgets dependencies can be included from external tab in dpo.pl.

    wxGlade issue
    -------------
    When using wxGlade with 'Overwriting existing sources' checkbox unchecked,
    some issues can happen.

    When importing the wxWidgets layer with dpo, the frame contains a button
    with an event handler. There are chances that you're going to get rid of it.
    Always with 'Overwriting existing sources' option unchecked, if you generate
    source code with no event handler along any other widget, you will have this
    message:

        wxGlade XyzFrame::event_table block not found, relative code NOT generated
        wxGlade XyzFrame::event_handlers markers not found, relative code NOT generated

        where Xyz is the name of the project where the wxWidgets layer was
        imported.

    Before you delete the button, the source code looks like this:

        BEGIN_EVENT_TABLE(XyzFrame, wxFrame)
            // begin wxGlade: XyzFrame::event_table
            EVT_BUTTON(wxID_ANY, XyzFrame::on_button_1)
            // end wxGlade
        END_EVENT_TABLE();

        void XyzFrame::on_button_1(wxCommandEvent &event)
        {
            event.Skip();
            // notify the user that he hasn't implemented the event handler yet
            wxLogDebug(wxT("Event handler (XyzFrame::on_button_1) not implemented yet"));
        }

        // wxGlade: add XyzFrame event handlers

    And after having deleted the button, it looks like this:

        BEGIN_EVENT_TABLE(XyzFrame, wxFrame)
        END_EVENT_TABLE();

        void XyzFrame::on_button_1(wxCommandEvent &event)
        {
            event.Skip();
            // notify the user that he hasn't implemented the event handler yet
            wxLogDebug(wxT("Event handler (XyzFrame::on_button_1) not implemented yet"));
        }

    As soon as there is no event handler attached to any widgets, the same
    behaviour happens.

    Two things are missing:

        1- the comments in the macro BEGIN_EVENT_TABLE/END_EVENT_TABLE

            BEGIN_EVENT_TABLE(XyzFrame, wxFrame)
    --->        // begin wxGlade: XyzFrame::event_table
    --->        // end wxGlade
            END_EVENT_TABLE();

        2- the comment:

    --->    // wxGlade: add XyzFrame event handlers

    Thus, before generating the source code from wxGlade, you should
    insert these lines of code:

        BEGIN_EVENT_TABLE(XyzFrame, wxFrame)
            // begin wxGlade: XyzFrame::event_table
            // end wxGlade
        END_EVENT_TABLE();

        // wxGlade: add XyzFrame event handlers


    Also, C++ code generation doesn't produce code for event handlers when
    'Overwriting existing sources' option unchecked. To do so, we must check
    'Overwriting existing sources'. But in this case, be sure to make a copy of
    your precious existing code.

    It's often faster to copy an existing event handler instead of having the
    dangerous 'Overwriting existing sources' option checked.




