# TemplateID=header:AbstractClass

package NewProject_header_abstract_class_dll;

use strict;

unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

require NewProjectTemplate;

use vars qw(@ISA);
@ISA = qw(NewProjectTemplate);


1;
