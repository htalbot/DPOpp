#!/usr/bin/perl

use strict;
use DPOUtils;
use DPOEnvVars;
use List::MoreUtils;

package DPOTabulator;

my $tab = 0;

sub print_tabs
{
    print ' ' x $tab;
}

sub inc_tabs
{
    $tab += 4;
}

sub dec_tabs
{
    $tab -= 4;
}

1;



package DPOCompliant;
use parent 'Clone';

sub new
{
    my ($class,
        $value,
        $product_name,
        $product_flavour,
        $mpb,
        $mpc_includes) = @_;

    my $self =
    {
        value => $value,
        product_name => $product_name,
        product_flavour => $product_flavour,
        mpb => $mpb,
        mpc_includes => $mpc_includes
    };

    bless($self, $class);

    return $self;
}

sub show
{
    my ($self) = @_;

    DPOTabulator::print_tabs();
    print "    value => ", $self->{value}, "\n";
    DPOTabulator::print_tabs();
    print "    mpb => ", $self->{mpb}, "\n";
    DPOTabulator::print_tabs();
    print "    product_name => ", $self->{product_name}, "\n";
    DPOTabulator::print_tabs();
    print "    product_flavour => ", $self->{product_flavour}, "\n";
    DPOTabulator::print_tabs();
    print "    mpc_includes => ", $self->{mpc_includes}, "\n";
}


1;


package DPOProjectDependency;
use parent 'Clone';

sub new
{
    my ($class,
        $name,
        $version,
        $target_version,
        $type,
        $dpo_compliant) = @_;

    my $self =
    {
        name => $name,
        version => $version,
        target_version => $target_version,
        type => $type,
        dpo_compliant => $dpo_compliant
    };

    bless($self, $class);

    return $self;
}

sub new_from_xml_node
{
    my ($class, $node) = @_;

    my $name = $node->findnodes('./Name')->to_literal->value();
    my $version = $node->findnodes('./Version')->to_literal->value();
    my $target_version = $node->findnodes('./TargetVersion')->to_literal->value();
    my $type = $node->findnodes('./Type')->to_literal->value();
    my $dpo_compliant_value = int($node->findnodes('./DPOCompliant/Value'));
    my $dpo_compliant_product_name = $node->findnodes('./DPOCompliant/ProductName')->to_literal->value();
    my $dpo_compliant_product_flavour = $node->findnodes('./DPOCompliant/ProductFlavour')->to_literal->value();
    my $dpo_compliant_mpb = $node->findnodes('./DPOCompliant/MPB')->to_literal->value();
    my $dpo_compliant_mpc_includes = $node->findnodes('./DPOCompliant/MPCIncludes')->to_literal->value();
    my $dpo_compliant = DPOCompliant->new($dpo_compliant_value, $dpo_compliant_product_name, $dpo_compliant_product_flavour, $dpo_compliant_mpb, $dpo_compliant_mpc_includes);

    my $self =
    {
        name => $name,
        version => $version,
        target_version => $target_version,
        type => $type,
        dpo_compliant => $dpo_compliant
    };

    bless($self, $class);

    return $self;
}

sub show
{
    my ($self) = @_;

    DPOTabulator::print_tabs();
    print "    name(DEP) => ", $self->{name}, "\n";
    DPOTabulator::print_tabs();
    print "    version => ", $self->{version}, "\n";
    DPOTabulator::print_tabs();
    print "    target_version => ", $self->{target_version}, "\n";
    DPOTabulator::print_tabs();
    print "    type => ", $self->{type}, "\n";
    DPOTabulator::print_tabs();
    print "  dpo_compliant: \n";
        $self->{dpo_compliant}->show();
}

sub get_manifest
{
    my ($self, $manifest_ref) =  @_;


}

1;


package DPOProject;
use parent 'Clone';

sub new
{
    my ($class,
        $name,
        $version,
        $target_version,
        $type,
        $dpo_compliant) = @_;

    my $self =
    {
        name => $name,
        version => $version,
        target_version => $target_version,
        type => $type,
        test_app_of => "",
        dpo_compliant => $dpo_compliant,
        dependencies_when_dynamic => [],
        dependencies_when_static => []
    };

    bless($self, $class);

    return $self;
};

sub new_from_xml_node
{
    my ($class, $node) = @_;

    # name
    my $name = $node->findnodes('Project/Name')->to_literal->value();

    # version
    my $version = $node->findnodes('Project/Version')->to_literal->value();

    # target_version
    my $target_version = $node->findnodes('Project/TargetVersion')->to_literal->value();

    # type
    my $type = int($node->findnodes('Project/Type'));

    # test_app_of
    my $test_app_of = $node->findnodes('Project/TestAppOf')->to_literal->value();

    # Compliant
    my $dpo_compliant_value = int($node->findnodes('Project/DPOCompliant/Value'));
    my $dpo_compliant_product_name = $node->findnodes('Project/DPOCompliant/ProductName')->to_literal->value();
    my $dpo_compliant_product_flavour = $node->findnodes('Project/DPOCompliant/ProductFlavour')->to_literal->value();
    my $dpo_compliant_mpb = $node->findnodes('Project/DPOCompliant/MPB')->to_literal->value();
    my $dpo_compliant_mpc_includes = $node->findnodes('Project/DPOCompliant/MPCIncludes')->to_literal->value();
    my $dpo_compliant = DPOCompliant->new($dpo_compliant_value, $dpo_compliant_product_name, $dpo_compliant_product_flavour, $dpo_compliant_mpb, $dpo_compliant_mpc_includes);

    # dependencies
    my @dependencies_when_dynamic;
    my @dependencies_when_dynamic_nodes = $node->findnodes("Project/Dependencies_when_dynamic");
    foreach my $dependency_node (@dependencies_when_dynamic_nodes)
    {
        my $project_node = $dependency_node->findnodes('./ProjectDependency');

        foreach my $x (@{$project_node})
        {
            my $dependency = DPOProjectDependency->new_from_xml_node($x);

            push(@dependencies_when_dynamic, $dependency);
        }
    }

    my @dependencies_when_static;
    my @dependencies_when_static_nodes = $node->findnodes("Project/Dependencies_when_static");
    foreach my $dependency_node (@dependencies_when_static_nodes)
    {
        my $project_node = $dependency_node->findnodes('./ProjectDependency');

        foreach my $x (@{$project_node})
        {
            my $dependency = DPOProjectDependency->new_from_xml_node($x);

            push(@dependencies_when_static, $dependency);
        }
    }

    my $self =
    {
        name => $name,
        version => $version,
        target_version => $target_version,
        type => $type,
        test_app_of => $test_app_of,
        dpo_compliant => $dpo_compliant,
        dependencies_when_dynamic => \@dependencies_when_dynamic,
        dependencies_when_static => \@dependencies_when_static
    };

    bless($self, $class);
}

sub show
{
    my ($self) = @_;

    DPOTabulator::print_tabs();
    print "Project:\n";
    DPOTabulator::print_tabs();
    print "  name => ", $self->{name}, "\n";
    DPOTabulator::print_tabs();
    print "  version => ", $self->{version}, "\n";
    DPOTabulator::print_tabs();
    print "  target_version => ", $self->{target_version}, "\n";
    DPOTabulator::print_tabs();
    print "  type => ", $self->{type}, "\n";
    DPOTabulator::print_tabs();
    print "  test_app_of => ", $self->{test_app_of}, "\n";
    DPOTabulator::print_tabs();
    print "  dpo_compliant: \n";
        $self->{dpo_compliant}->show();
    DPOTabulator::print_tabs();
    print "  dependencies_when_dynamic:\n";
        $self->show_dependencies("when_dynamic");
    DPOTabulator::print_tabs();
    print "  dependencies_when_static:\n";
        $self->show_dependencies("when_static"), "\n";
}

sub show_dependencies
{
    my ($self, $when) = @_;

    my $ref = $self->{dependencies_when_dynamic};
    if ($when eq "when_static")
    {
        $ref = $self->{dependencies_when_static};
    }

    DPOTabulator::inc_tabs();

    foreach my $dep (@{$ref})
    {
        $dep->show($when);
    }

    DPOTabulator::dec_tabs();
}

sub is_library
{
    my ($self) = @_;

    if (($self->{type} & 0b100) == 0b100)
    {
        return 1;
    }

    return 0;
}

sub is_dynamic_library
{
    my ($self) = @_;

    if (($self->{type} & 0b110) == 0b110)
    {
        return 1;
    }

    return 0;
}

sub is_static_library
{
    my ($self) = @_;

    if (($self->{type} & 0b101) == 0b101)
    {
        return 1;
    }

    return 0;
}

sub is_executable
{
    my ($self) = @_;

    return !$self->is_library() && !$self->is_header_impl_or_abstract_class();
}

sub is_header_impl_or_abstract_class
{
    my ($self) = @_;

    if ($self->{type} == 2)
    {
        return 1;
    }

    return 0;
}

sub get_actual_version
{
    my ($self) = @_;

    my $env_var_id;
    if ($self->{dpo_compliant}->{value})
    {
        $env_var_id = uc($self->{name}) . "_PRJ_ROOT";
    }
    else
    {
        $env_var_id = uc($self->{dpo_compliant}->{product_name}) . "_ROOT";
    }

    my $path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        return "";
    }
    my $major;
    my $minor;
    my $patch;
    if (read_project_version($path, \$major, \$minor, \$patch))
    {
        return "$major.$minor.$patch";
    }
    else
    {
        return "";
    }
}

sub read_project_version
{
    my ($dir, $major, $minor, $patch) = @_;

    $dir =~ s/\\/\//g;

    my $pre;
    my $version;
    my $project_name;
    if (DPOUtils::in_dpo_pool($dir))
    {
        ($pre, $project_name, $version) = $dir =~ /(.*)\/(.*)\/(.*)$/;
        ($$major, $$minor, $$patch) = $version =~ /(\d+)\.(\d+)\.(\d+)/;
        return 1;
    }
    else
    {
        ($pre, $project_name) = $dir =~ /(.*)\/(.*)$/;
    }

    my $version_file = "$dir/include/$project_name/version.h";
    my @lines=();
    if (!DPOUtils::get_file_lines($version_file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$version_file]);
        return 0;
    }

    my $major_version_string = uc($project_name) . "_MAJOR";
    my $minor_version_string = uc($project_name) . "_MINOR";
    my $patch_version_string = uc($project_name) . "_PATCH";

    foreach (@lines)
    {
        chomp($_);

        DPOUtils::trim(\$_);

        if (!/^$/)
        {
            if (/\Q$major_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$major = $tokens[$#tokens];
            }

            if (/\Q$minor_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$minor = $tokens[$#tokens];
            }

            if (/\Q$patch_version_string\E/)
            {
                my @tokens = split(/([ \t])/, $_);
                $$patch = $tokens[$#tokens];
            }
        }
    }

    my $major_version_missing=0;
    my $minor_version_missing=0;
    my $patch_version_missing=0;
    if (length($major)==0)
    {
        $major_version_missing = 1;
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["major version is missing in $version_file"]);
    }

    if (length($minor)==0)
    {
        $minor_version_missing = 1;
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["minor version is missing in $version_file"]);
    }

    if (length($patch)==0)
    {
        $patch_version_missing = 1;
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["patch version is missing in $version_file"]);
    }

    if ($major_version_missing
        || $minor_version_missing
        || $patch_version_missing)
    {
        return 0;
    }

    return 1;
}

sub load_features
{
    my ($self) = @_;

    if ($self->{dpo_compliant}->{value} == 0)
    {
        # Non compliant projects have not features file in their root.
        # Few are using features files (ACE)
        $self->{features} = [];
        return 1;
    }

    my $env_var_id = uc($self->{name}) . "_PRJ_ROOT";
    my $path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
        return 0;
    }

    my $feature_file = "$path/features";
    if (-f $feature_file)
    {
        my @features;
        if (!DPOUtils::read_feature_file($feature_file, \@features))
        {
            DPOLog::report_msg(DPOEvents::READ_FEATURES_FILE_FAILURE, [$feature_file]);
            return 0;
        }

        @{$self->{features}} = @features;
    }
    else
    {
        #~ DPOLog::report_msg(DPOEvents::FEATURES_DOESNT_EXIST, [$feature_file]);
        #~ return 0;
        # By default, if a feature is not defined, it's enabled.
        # To disable a feature, a file (features) must be created in
        # uc($project->{name}) . "_ROOT" and the feature must be assigned to 0.
        # For example: wxwindows = 0
    }

    return 1;
}

sub get_manifest
{
    my ($self, $manifest_ref) =  @_;


}

sub relevant_deps
{
    my ($self) = @_;

    if ($self->{type} == 5)
    {
        return $self->{dependencies_when_static};
    }
    else
    {
        if ($self->{type} == 6
            || $self->{type} == 0
            || $self->{type} == 1
            || $self->{type} == 2)
        {
            return $self->{dependencies_when_dynamic};
        }
        else
        {
            if ($self->{type} == 7)
            {
                my @array = (@{$self->{dependencies_when_dynamic}}, @{$self->{dependencies_when_dynamic}});
                return \@array;
            }
            else
            {
                return [];
            }
        }
    }
}

sub extend_with_idlflags
{
    my ($self, $dep) = @_;

    if (!$dep->{dpo_compliant}->{value})
    {
        # Process dpo compliant only
        return 1;
    }

    my $project_name = $dep->{name};

    # Check if $self is an idl project
    my $self_is_idl = 0;

    my $env_var_id =  uc($project_name) . "_PRJ_ROOT";

    my $path = "\$($env_var_id)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        return 0;
    }

    my @content;
    if (!DPOUtils::get_dir_content("$path/include/$project_name", \@content))
    {
        return 0;
    }

    if (!DPOUtils::in_dpo_pool($path))
    {
        my @content_src;
        if (!DPOUtils::get_dir_content("$path/src", \@content_src))
        {
            return 0;
        }

        foreach my $src (@content_src)
        {
            push(@content, $src);
        }
    }

    foreach my $elem (@content)
    {
        if ($elem =~ /.*\.idl$/)
        {
            $self_is_idl = 1;
            last;
        }
    }

    if ($self_is_idl)
    {
        # Check if $env_var_id stands for an idl project too.

        my $project_name;

        if (DPOUtils::in_dpo_pool($path))
        {
            (my $pre, $project_name) =
                    $path =~ /(.*)\/(.*)\/\d+?\.\d+?\.\d+?/;
        }
        else # local
        {
            ($project_name) = $path =~ /.*\/(.*)$/;
        }

        my @content;
        if (!DPOUtils::get_dir_content("$path/include/$project_name", \@content))
        {
            return 0;
        }

        foreach my $elem (@content)
        {
            if ($elem =~ /.*\.idl$/)
            {
                $self_is_idl = 1;

                if (!List::MoreUtils::any {$_ eq $env_var_id} @{$self->{idlflags}})
                {
                    push(@{$self->{idlflags}}, $env_var_id);
                }

                last;
            }
        }
    }
}

1; # package DPOProject



package DPOProjectConfig;

use FileHandle;
use XML::LibXML;

sub new
{
    my ($class,
        $file,
        $err_ref) = @_;

    $file =~ s/\\/\//g;

    my $parser = XML::LibXML->new();

    unless (-f $file)
    {
        DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["Test file", $file, "File doesn't exist"]);
        $$err_ref = "$file doesn't exist";
        return 0;
    }

    my $doc = $parser->parse_file($file);
    my $xml_version = $doc->version();
    my $xml_encoding = $doc->encoding();

    if (!$xml_version)
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["No xml version specified in $file"]);
        $$err_ref = "No xml version specified in $file";
        return 0;
    }
    if (!$xml_encoding)
    {
        $xml_encoding = "";
    }

    # XML document root
    my $root = $doc->documentElement();

    my $xmlns_xsi = $root->getAttribute('xmlns:xsi');
    my $xsi_noNamespaceSchemaLocation = $root->getAttribute('xsi:noNamespaceSchemaLocation');

    # XML file validation
    my $path = "\$(DPO_CORE_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        $$err_ref = "DPO_CORE_ROOT env. var. not defined.";
        print $@;
        return 0;
    }
    $path .= "/scripts";
    my $xsd_file = $root->getAttribute('xsi:noNamespaceSchemaLocation');
    my $xml_schema = XML::LibXML::Schema->new(location => "$path/$xsd_file");

    eval { $xml_schema->validate($doc) };
    if ($@)
    {
        DPOLog::report_msg(DPOEvents::XML_SCHEMA_VALIDATION, [$file, $@->{message}]);
        return 0;
    }

    my $project = DPOProject->new_from_xml_node($doc);

    my $self =
    {
        xml_file => $file,
        xml_version => $xml_version,
        xml_encoding => $xml_encoding,
        xml_schema => $xml_schema,
        xmlns_xsi => $xmlns_xsi,
        xsi_noNamespaceSchemaLocation => $xsi_noNamespaceSchemaLocation,
        project => $project
    };

    bless($self, $class);

    return $self;
}

sub get_project
{
    my ($self, $project_ref) = @_;

    $$project_ref = $self->{project};

    return 1;
}

sub show_dependencies
{
    my ($self, $when) = @_;

    my $ref = $self->{dependencies_when_dynamic};

    if ($when eq "when_static")
    {
        $ref = $self->{dependencies_when_static};
    }

    foreach my $mod (@{$ref})
    {
        $mod->show($when);
    }
}

sub show
{
    my ($self) = @_;

    DPOTabulator::print_tabs();
    print "Config: $self->{xml_file}\n";
    DPOTabulator::inc_tabs();
    $self->{project}->show();
}

sub create_dependency_element
{
    my ($doc, $dep) = @_;

    my $text;

    my $dependency = $doc->createElement('ProjectDependency');
    my $dependency_name = $doc->createElement('Name');
    my $dependency_version = $doc->createElement('Version');
    my $dependency_target_version = $doc->createElement('TargetVersion');
    my $dependency_type = $doc->createElement('Type');
    my $dependency_dpo_compliant = $doc->createElement('DPOCompliant');
    my $dependency_dpo_compliant_value = $doc->createElement('Value');
    my $dependency_dpo_compliant_product_name = $doc->createElement('ProductName');
    my $dependency_dpo_compliant_product_flavour = $doc->createElement('ProductFlavour');
    my $dependency_dpo_compliant_mpb = $doc->createElement('MPB');
    my $dependency_dpo_compliant_mpc_includes = $doc->createElement('MPCIncludes');

    $dependency->appendChild($dependency_name);
    $dependency->appendChild($dependency_version);
    $dependency->appendChild($dependency_target_version);
    $dependency->appendChild($dependency_type);
    $dependency_dpo_compliant->appendChild($dependency_dpo_compliant_value);
    $dependency_dpo_compliant->appendChild($dependency_dpo_compliant_product_name);
    $dependency_dpo_compliant->appendChild($dependency_dpo_compliant_product_flavour);
    $dependency_dpo_compliant->appendChild($dependency_dpo_compliant_mpb);
    $dependency_dpo_compliant->appendChild($dependency_dpo_compliant_mpc_includes);
    $dependency->appendChild($dependency_dpo_compliant);

    $text = XML::LibXML::Text->new($dep->{name});
    $dependency_name->appendChild($text);

    $text = XML::LibXML::Text->new($dep->{version});
    $dependency_version->appendChild($text);

    $text = XML::LibXML::Text->new($dep->{target_version});
    $dependency_target_version->appendChild($text);

    $text = XML::LibXML::Text->new($dep->{type});
    $dependency_type->appendChild($text);

    $text = XML::LibXML::Text->new($dep->{dpo_compliant}->{value});
    $dependency_dpo_compliant_value->appendChild($text);

    # compliant product_name
    $text = XML::LibXML::Text->new($dep->{dpo_compliant}->{product_name});
    $dependency_dpo_compliant_product_name->appendChild($text);

    # compliant product_flavour
    $text = XML::LibXML::Text->new($dep->{dpo_compliant}->{product_flavour});
    $dependency_dpo_compliant_product_flavour->appendChild($text);

    # compliant mpb
    $text = XML::LibXML::Text->new($dep->{dpo_compliant}->{mpb});
    $dependency_dpo_compliant_mpb->appendChild($text);

    # compliant mpc_includes
    $text = XML::LibXML::Text->new($dep->{dpo_compliant}->{mpc_includes});
    $dependency_dpo_compliant_mpc_includes->appendChild($text);

    return $dependency;
}

sub save
{
    my ($self, $project, $err_ref) = @_;

    if (DPOUtils::in_dpo_pool($self->{xml_file}))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't overwrite $self->{xml_file} because it's in pool"]);
        return 0;
    }

    my $file = $self->{xml_file};

    my $doc = XML::LibXML::Document->new($self->{xml_version}, $self->{xml_encoding});
    my $root = $doc->createElement('Project');

    $root->setAttribute('xmlns:xsi', $self->{xmlns_xsi});
    $root->setAttribute('xsi:noNamespaceSchemaLocation', $self->{xsi_noNamespaceSchemaLocation});
    $doc->setDocumentElement($root);

    # create doc elements
    my $name = $doc->createElement('Name');
    my $version = $doc->createElement('Version');
    my $target_version = $doc->createElement('TargetVersion');
    my $type = $doc->createElement('Type');
    my $test_app_of = $doc->createElement('TestAppOf');
    my $dpo_compliant = $doc->createElement('DPOCompliant');
    my $dependencies_when_dynamic = $doc->createElement('Dependencies_when_dynamic');
    my $dependencies_when_static = $doc->createElement('Dependencies_when_static');

    # append doc child elements
    $root->appendChild($name);
    $root->appendChild($version);
    $root->appendChild($target_version);
    $root->appendChild($type);
    $root->appendChild($test_app_of);
    $root->appendChild($dpo_compliant);
    $root->appendChild($dependencies_when_dynamic);
    $root->appendChild($dependencies_when_static);

    my $text;

    my $ref;
    if ($project)
    {
        $ref = \$project;
    }
    else
    {
        $ref = \$self;
    }

    # set project name
    $text = XML::LibXML::Text->new($$ref->{name});
    $name->appendChild($text);

    # set version value
    $text = XML::LibXML::Text->new($$ref->{version});
    $version->appendChild($text);

    # set target_version value
    $text = XML::LibXML::Text->new($$ref->{target_version});
    $target_version->appendChild($text);

    # set type value
    $text = XML::LibXML::Text->new($$ref->{type});
    $type->appendChild($text);

    # set test_app_of value
    $text = XML::LibXML::Text->new($$ref->{test_app_of});
    $test_app_of->appendChild($text);

    # dpo_compliant
    my $dpo_compliant_value = $doc->createElement('Value');
    my $dpo_compliant_product_name = $doc->createElement('ProductName');
    my $dpo_compliant_product_flavour = $doc->createElement('ProductFlavour');
    my $dpo_compliant_mpb = $doc->createElement('MPB');
    my $dpo_compliant_mpc_includes = $doc->createElement('MPCIncludes');

    $dpo_compliant->appendChild($dpo_compliant_value);
    $dpo_compliant->appendChild($dpo_compliant_product_name);
    $dpo_compliant->appendChild($dpo_compliant_product_flavour);
    $dpo_compliant->appendChild($dpo_compliant_mpb);
    $dpo_compliant->appendChild($dpo_compliant_mpc_includes);

    # compliant value
    $text = XML::LibXML::Text->new($$ref->{dpo_compliant}->{value});
    $dpo_compliant_value->appendChild($text);

    # compliant product_name
    $text = XML::LibXML::Text->new($$ref->{dpo_compliant}->{product_name});
    $dpo_compliant_product_name->appendChild($text);

    # compliant product_flavour
    $text = XML::LibXML::Text->new($$ref->{dpo_compliant}->{product_flavour});
    $dpo_compliant_product_flavour->appendChild($text);

    # compliant mpb
    $text = XML::LibXML::Text->new($$ref->{dpo_compliant}->{mpb});
    $dpo_compliant_mpb->appendChild($text);

    # compliant mpc_includes
    $text = XML::LibXML::Text->new($$ref->{dpo_compliant}->{mpc_includes});
    $dpo_compliant_mpc_includes->appendChild($text);

    # Dependencies values
    foreach my $dep (@{$$ref->{dependencies_when_dynamic}})
    {
        my $dependency = create_dependency_element($doc, $dep);

        $dependencies_when_dynamic->appendChild($dependency);
    }

    foreach my $dep (@{$$ref->{dependencies_when_static}})
    {
        my $dependency = create_dependency_element($doc, $dep);

        $dependencies_when_static->appendChild($dependency);
    }

    # validate
    eval { $self->{xml_schema}->validate($doc) };
    if ($@)
    {
        DPOLog::report_msg(DPOEvents::XML_SCHEMA_VALIDATION, [$self->{xml_file}, $@->{message}]);
        return 0;
    }

    # write to file
    return $self->stream($doc, $file);
}

sub stream
{
    my ($self, $doc, $file) = @_;

    my $fh;
    my $bPrintToFile = 1;  #  1: to file,  0: to console

    if ($bPrintToFile)
    {
        $fh = new FileHandle();
        if (!$fh->open(">$file"))
        {
            DPOLog::report_msg(DPOEvents::FILE_OPERATION_FAILURE, ["Open", $file, $!]);
            return 0;
        }
    }
    else
    {
        $fh = *STDOUT;
    }

    print $fh $doc->toString(1);

    return 1;
}


1; # package DPOProjectConfig
