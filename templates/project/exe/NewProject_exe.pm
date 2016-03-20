# TemplateID=executable

package NewProject_exe;

use strict;

unshift(@INC, $ENV{DPO_CORE_ROOT} . "/scripts");

require NewProjectTemplate;

use vars qw(@ISA);
@ISA = qw(NewProjectTemplate);


1;
