#!/usr/bin/perl

use strict;
use DPOUtils;
use DPOProject;
use DPOEnvVars;
use DPOEvents;

package DPORuntimeModule;

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    # name
    my $name = $node->to_literal;

    my $self =
    {
        name => $name,
    };

    bless($self, $class);

    return $self;
}

sub save
{
    my ($self) = @_;


}

1;

package DPORuntimeProduct;

sub new
{
    my ($class,
        $name,
        $version,
        $flavour) = @_;

    my $self =
    {
        name => $name,
        version => $version,
        flavour => $flavour
    };

    bless($self, $class);

    return $self;
}

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    # name
    my $name = $node->findnodes('Name')->to_literal->value();

    # version
    my $version = $node->findnodes('Version')->to_literal->value();

    # flavour
    my $flavour = $node->findnodes('Flavour')->to_literal->value();

    my $self =
    {
        name => $name,
        version => $version,
        flavour => $flavour
    };

    bless($self, $class);

    return $self;
}

1;

package DPORuntimeProductCompliant;

use vars qw(@ISA);
@ISA = qw(DPORuntimeProduct);

sub new
{
    my ($class, $name, $version, $flavour) = @_;

    my $self = $class->SUPER::new($name, $version, $flavour);

    $self->{dpo_project_dependencies} = [];

    return $self;
}

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    my $self = $class->SUPER::new_from_xml_node($node);

    $self->{dpo_project_dependencies} = [];

    # Fill dpo_project_dependencies
    my @project_dependency_nodes = $node->findnodes("ProjectDependencies/ProjectDependency");
    foreach my $project_dependency_node (@project_dependency_nodes)
    {
        my $project_dependency = DPOProjectDependency->new_from_xml_node($project_dependency_node);
        push(@{$self->{dpo_project_dependencies}}, $project_dependency);
    }

    return $self;
}

1;


package DPORuntimeProductNonCompliant;

use vars qw(@ISA);
@ISA = qw(DPORuntimeProduct);

sub new
{
    my ($class, $name, $version, $flavour) = @_;

    my $self = $class->SUPER::new($name, $version, $flavour);

    $self->{modules_names} = [];

    return $self;
}

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    my $self = $class->SUPER::new_from_xml_node($node);

    $self->{modules_names} = [];

    # Fill modules_names
    my @modules_names_nodes = $node->findnodes("Modules/ModuleName");
    foreach my $module_name_node (@modules_names_nodes)
    {
        my $dpo_module = DPORuntimeModule->new_from_xml_node($module_name_node);
        push(@{$self->{modules_names}}, $dpo_module->{name});
    }

    return $self;
}

1;


package DPORuntime;

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    my @runtime_product_compliants;
    my @runtime_product_compliant_nodes = $node->findnodes('RuntimeProductCompliantSeq/ProductCompliant');
    foreach my $runtime_product_compliant_node (@runtime_product_compliant_nodes)
    {
        my $runtime_product_compliant = DPORuntimeProductCompliant->new_from_xml_node($runtime_product_compliant_node);
        push(@runtime_product_compliants, $runtime_product_compliant);
    }

    my @runtime_product_non_compliants;
    my @runtime_product_non_compliant_nodes = $node->findnodes('RuntimeProductNonCompliantSeq/ProductNonCompliant');
    foreach my $runtime_product_non_compliant_node (@runtime_product_non_compliant_nodes)
    {
        my $runtime_product_non_compliant = DPORuntimeProductNonCompliant->new_from_xml_node($runtime_product_non_compliant_node);
        push(@runtime_product_non_compliants, $runtime_product_non_compliant);
    }


    my $self =
    {
        runtime_products_compliant => \@runtime_product_compliants,
        runtime_products_non_compliant => \@runtime_product_non_compliants
    };

    bless($self, $class);

    return $self;
}

sub save
{
    my ($self) = @_;

}

1;


package DPONonCompliantLib;

sub new
{
    my ($class,
        $lib_id,
        $mpb_name) = @_;

    my $self =
    {
        lib_id => $lib_id,
        mpb_name => $mpb_name,
        static_debug_lib => "",
        static_release_lib => "",
        dynamic_debug_lib => "",
        dynamic_release_lib => "",
        dynamic_debug_dll => "",
        dynamic_release_dll => "",
        plugin => 0
    };

    bless($self, $class);

    return $self;
}

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    # Lib_id
    my $lib_id = $node->findnodes('Lib_id')->to_literal->value();

    # MPB
    my $mpb_name = $node->findnodes('MPB')->to_literal->value();

    # StaticDebugLib
    my $static_debug_lib = $node->findnodes('StaticDebugLib')->to_literal->value();

    # StaticReleaseLib
    my $static_release_lib = $node->findnodes('StaticReleaseLib')->to_literal->value();

    # DynamicDebugLib
    my $dynamic_debug_lib = $node->findnodes('DynamicDebugLib')->to_literal->value();

    # DynamicReleaseLib
    my $dynamic_release_lib = $node->findnodes('DynamicReleaseLib')->to_literal->value();

    # DynamicDebugDLL
    my $dynamic_debug_dll = $node->findnodes('DynamicDebugDLL')->to_literal->value();

    # DynamicReleaseDLL
    my $dynamic_release_dll = $node->findnodes('DynamicReleaseDLL')->to_literal->value();

    # Plugin
    my $plugin = $node->findnodes('Plugin')->to_literal->value();

    my $self =
    {
        lib_id => $lib_id,
        mpb_name => $mpb_name,
        static_debug_lib => $static_debug_lib,
        static_release_lib => $static_release_lib,
        dynamic_debug_lib => $dynamic_debug_lib,
        dynamic_release_lib => $dynamic_release_lib,
        dynamic_debug_dll => $dynamic_debug_dll,
        dynamic_release_dll => $dynamic_release_dll,
        plugin => $plugin
    };

    bless($self, $class);

    return $self;
};

sub create_non_compliant_lib_element
{
    my ($doc, $mpc_non_compliant_lib) = @_;

    my $mpc_non_compliant_lib_element = $doc->createElement('NonCompliantLib');

    my $lib_id_element = $doc->createElement('Lib_id');
    my $mpb_element = $doc->createElement('MPB');
    my $static_debug_lib_element = $doc->createElement('StaticDebugLib');
    my $static_release_lib_element = $doc->createElement('StaticReleaseLib');
    my $dynamic_debug_lib_element = $doc->createElement('DynamicDebugLib');
    my $dynamic_release_lib_element = $doc->createElement('DynamicReleaseLib');
    my $dynamic_debug_dll_element = $doc->createElement('DynamicDebugDLL');
    my $dynamic_release_dll_element = $doc->createElement('DynamicReleaseDLL');
    my $plugin_element = $doc->createElement('Plugin');

    $mpc_non_compliant_lib_element->appendChild($lib_id_element);
    $mpc_non_compliant_lib_element->appendChild($mpb_element);
    $mpc_non_compliant_lib_element->appendChild($static_debug_lib_element);
    $mpc_non_compliant_lib_element->appendChild($static_release_lib_element);
    $mpc_non_compliant_lib_element->appendChild($dynamic_debug_lib_element);
    $mpc_non_compliant_lib_element->appendChild($dynamic_release_lib_element);
    $mpc_non_compliant_lib_element->appendChild($dynamic_debug_dll_element);
    $mpc_non_compliant_lib_element->appendChild($dynamic_release_dll_element);
    $mpc_non_compliant_lib_element->appendChild($plugin_element);

    my $text;

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{lib_id});
    $lib_id_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{mpb_name});
    $mpb_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{static_debug_lib});
    $static_debug_lib_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{static_release_lib});
    $static_release_lib_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{dynamic_debug_lib});
    $dynamic_debug_lib_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{dynamic_release_lib});
    $dynamic_release_lib_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{dynamic_debug_dll});
    $dynamic_debug_dll_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{dynamic_release_dll});
    $dynamic_release_dll_element->appendChild($text);

    $text = XML::LibXML::Text->new($mpc_non_compliant_lib->{plugin});
    $plugin_element->appendChild($text);

    return $mpc_non_compliant_lib_element;
}

1;


package DPOCompliantProduct;

sub new_from_xml_node
{
    my ($class,
        $node) = @_;

    # Value
    my $value = $node->findnodes('Value')->to_literal->value();

    # NonCompliantLibSeq
    my @non_compliant_lib_seq;
    my @non_compliant_lib_nodes = $node->findnodes('NonCompliantLibSeq/NonCompliantLib');
    foreach my $non_compliant_lib_node (@non_compliant_lib_nodes)
    {
        my $non_compliant_lib = DPONonCompliantLib->new_from_xml_node($non_compliant_lib_node);
        push(@non_compliant_lib_seq, $non_compliant_lib);
    }

    my $self =
    {
        value => $value,
        non_compliant_lib_seq => \@non_compliant_lib_seq
    };

    bless($self, $class);

    return $self;
}

1;


package DPOProduct;
use parent 'Clone';

sub new
{
    my ($class,
        $name,
        $version,
        $flavour,
        $dpo_compliant_product # DPOCompliantProduct
        ) = @_;

    my $self =
    {
        name => $name,
        version => $version,
        flavour => $flavour,
        dpo_compliant_product => $dpo_compliant_product, # DPOCompliantProduct
        runtime => undef, # DPORuntime
        mpc_includes => "",
        freeze_directory => ""
    };

    bless($self, $class);

    return $self;
};

sub new_from_xml_node
{
    my ($class, $node) = @_;

    # name
    my $name = $node->findnodes('Name')->to_literal->value();

    # version
    my $version = $node->findnodes('Version')->to_literal->value();

    # flavour
    my $flavour = $node->findnodes('Flavour')->to_literal->value();

    # dpo_compliant_product
    my @dpo_compliant_product_nodes = $node->findnodes('DPOCompliant');
    my $dpo_compliant_product = DPOCompliantProduct->new_from_xml_node($dpo_compliant_product_nodes[0]);

    my @runtime_nodes = $node->findnodes("Runtime");
    my $runtime = DPORuntime->new_from_xml_node($runtime_nodes[0]);

    my $mpc_includes = $node->findnodes('MPCIncludes')->to_literal->value();

    my $freeze_directory = $node->findnodes('FreezeDirectory')->to_literal->value();

    my $self =
    {
        name => $name,
        version => $version,
        flavour => $flavour,
        dpo_compliant_product => $dpo_compliant_product,
        runtime => $runtime,
        mpc_includes => $mpc_includes,
        freeze_directory => $freeze_directory
    };

    bless($self, $class);

    return $self;
}

sub get_exec
{
    my ($self, $path, $execs_ref, $ft) =  @_;

    if (!defined($ft))
    {
        $ft = File::Type->new();
    }

    if (-d $path)
    {
        my @content = ();
        DPOUtils::get_dir_content($path, \@content);
        foreach(@content)
        {
            chomp $_;

            my $complete = "$path/$_";

            if (-d $complete)
            {
                $self->get_exec($complete, $execs_ref, $ft);
            }
            else
            {
                if ($complete =~ /\/lib\//
                    || $complete =~ /\/bin\//)
                {
                    if (DPOUtils::is_executable($complete, $ft)
                        || DPOUtils::is_dynamic_lib($complete, $ft))
                    {
                        push(@$execs_ref, $complete);
                    }
                }
            }
        }
    }
}

sub params_from_id
{
    my ($id, $name_ref, $version_ref, $flavour_ref) = @_;

    my $flavour;
    ($$name_ref, $$version_ref, $flavour) = $id =~ /(.*)-(\d+.\d+.\d+)(.*)/;
    $$flavour_ref = "";
    if (defined($flavour) && $flavour ne "")
    {
        ($$flavour_ref) = $flavour =~ /^-(.*)/;
    }
}

sub get_lib_type
{
    my ($self, $lib_id, $type_ref) = @_;

    my $dynamic = 0;
    my $static = 0;
    my $found = 0;
    foreach my $non_compliant_lib (@{$self->{dpo_compliant_product}->{non_compliant_lib_seq}})
    {
        if ($non_compliant_lib->{lib_id} eq $lib_id)
        {
            $found = 1;
            if ($non_compliant_lib->{dynamic_debug_lib} ne "" && $non_compliant_lib->{dynamic_release_lib} ne "")
            {
                $dynamic = 1;
            }

            if ($non_compliant_lib->{static_debug_lib} ne "" && $non_compliant_lib->{static_release_lib} ne "")
            {
                $static = 1;
            }
        }
    }

    if (!$found)
    {
        if ($^O =~ /Win/)
        {
            my $env_var_id = "\$(SYSTEMROOT)/System32";
            my $env_var_value = $env_var_id;
            if (DPOEnvVars::expand_env_var(\$env_var_value))
            {
                if (-f "$env_var_value/$lib_id.dll")
                {
                    $dynamic = 1;
                }
                else
                {
                    return 0;
                }
            }
        }
        else
        {
            return 0;
        }
    }

    if ($static)
    {
        if ($dynamic)
        {
            $$type_ref = 7;
        }
        else
        {
            $$type_ref = 5;
        }
    }
    if ($dynamic)
    {
        if ($static)
        {
            $$type_ref = 7;
        }
        else
        {
            $$type_ref = 6;
        }
    }

    return 1;
}

1;


package DPOProductConfig;

use FileHandle;
use XML::LibXML;

sub new
{
    my ($class,
        $file) = @_;

    $file =~ s/\\/\//g;

    my $parser = XML::LibXML->new();

    unless (-f $file)
    {
        DPOLog::report_msg(DPOEvents::FILE_DOESNT_EXIST, [$file]);
        return 0;
    }

    my $doc = $parser->parse_file($file);
    my $xml_version = $doc->version();
    my $xml_encoding = $doc->encoding();

    if (!$xml_version)
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["No version specified in $file"]);
        return 0;
    }
    if (!$xml_encoding)
    {
        $xml_encoding = "";
    }

    # XML document root
    my $product = $doc->documentElement();

    my $xmlns_xsi = $product->getAttribute('xmlns:xsi');
    my $xsi_noNamespaceSchemaLocation = $product->getAttribute('xsi:noNamespaceSchemaLocation');

    # XML file validation
    my $path = "\$(DPO_CORE_ROOT)";
    if (!DPOEnvVars::expand_env_var(\$path))
    {
        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["DPO_CORE_ROOT env. var. not defined"]);
        return 0;
    }
    $path .= "/scripts";
    my $xsd_file = $product->getAttribute('xsi:noNamespaceSchemaLocation');
    my $xml_schema = XML::LibXML::Schema->new(location => "$path/$xsd_file");

    eval { $xml_schema->validate($doc) };
    if ($@)
    {
        DPOLog::report_msg(DPOEvents::XML_SCHEMA_VALIDATION, [$file, $@->{message}]);
        return 0;
    }

    my $dpo_product;
    my @products_nodes = $doc->findnodes('Product');
    # XML file is valid and there is only one product element.
    $dpo_product = DPOProduct->new_from_xml_node($products_nodes[0]);

    my $self =
    {
        xml_file => $file,
        xml_version => $xml_version,
        xml_encoding => $xml_encoding,
        xml_schema => $xml_schema,
        xmlns_xsi => $xmlns_xsi,
        xsi_noNamespaceSchemaLocation => $xsi_noNamespaceSchemaLocation,
        product => $dpo_product,
    };

    bless($self, $class);

    return $self;
}

sub get_product
{
    my ($self, $product_ref) = @_;

    $$product_ref= $self->{product};

    return 1;
}

sub create_dpo_compliant_product_element
{
    my ($doc, $dpo_compliant_product) = @_;

    my $dpo_compliant_product_element = $doc->createElement('DPOCompliant');

    my $value_element = $doc->createElement('Value');
    my $non_compliant_lib_seq_element = $doc->createElement('NonCompliantLibSeq');

    $dpo_compliant_product_element->appendChild($value_element);
    $dpo_compliant_product_element->appendChild($non_compliant_lib_seq_element);

    my $text;

    $text = XML::LibXML::Text->new($dpo_compliant_product->{value});
    $value_element->appendChild($text);

    foreach my $non_compliant_lib (@{$dpo_compliant_product->{non_compliant_lib_seq}})
    {
        my $non_compliant_lib_element = DPONonCompliantLib::create_non_compliant_lib_element($doc, $non_compliant_lib);
        $non_compliant_lib_seq_element->appendChild($non_compliant_lib_element);
    }

    return $dpo_compliant_product_element;
}

sub create_runtime_product_compliant_element
{
    my ($doc, $runtime_product_compliant) = @_;

    my $runtime_product_compliant_element = $doc->createElement('ProductCompliant');

    my $name_element = $doc->createElement('Name');
    my $version_element = $doc->createElement('Version');
    my $flavour_element = $doc->createElement('Flavour');
    my $project_dependencies_element = $doc->createElement('ProjectDependencies');

    $runtime_product_compliant_element->appendChild($name_element);
    $runtime_product_compliant_element->appendChild($version_element);
    $runtime_product_compliant_element->appendChild($flavour_element);
    $runtime_product_compliant_element->appendChild($project_dependencies_element);

    my $text;

    $text = XML::LibXML::Text->new($runtime_product_compliant->{name});
    $name_element->appendChild($text);

    $text = XML::LibXML::Text->new($runtime_product_compliant->{version});
    $version_element->appendChild($text);

    $text = XML::LibXML::Text->new($runtime_product_compliant->{flavour});
    $flavour_element->appendChild($text);

    foreach my $dpo_project_dependency (@{$runtime_product_compliant->{dpo_project_dependencies}})
    {
        my $project_dependency = DPOProjectConfig::create_dependency_element($doc, $dpo_project_dependency);
        $project_dependencies_element->appendChild($project_dependency);
    }

    return $runtime_product_compliant_element;
}

sub create_runtime_product_non_compliant_element
{
    my ($doc, $runtime_product_non_compliant) = @_;

    my $runtime_product_non_compliant_element = $doc->createElement('ProductNonCompliant');

    my $name_element = $doc->createElement('Name');
    my $version_element = $doc->createElement('Version');
    my $flavour_element = $doc->createElement('Flavour');
    my $modules_element = $doc->createElement('Modules');

    $runtime_product_non_compliant_element->appendChild($name_element);
    $runtime_product_non_compliant_element->appendChild($version_element);
    $runtime_product_non_compliant_element->appendChild($flavour_element);
    $runtime_product_non_compliant_element->appendChild($modules_element);

    my $text;

    $text = XML::LibXML::Text->new($runtime_product_non_compliant->{name});
    $name_element->appendChild($text);

    $text = XML::LibXML::Text->new($runtime_product_non_compliant->{version});
    $version_element->appendChild($text);

    $text = XML::LibXML::Text->new($runtime_product_non_compliant->{flavour});
    $flavour_element->appendChild($text);

    foreach my $module_name (@{$runtime_product_non_compliant->{modules_names}})
    {
        my $module_name_element = $doc->createElement('ModuleName');
        $modules_element->appendChild($module_name_element);

        $text = XML::LibXML::Text->new($module_name);
        $module_name_element->appendChild($text);
    }

    return $runtime_product_non_compliant_element;
}


sub save
{
    my ($self, $dpo_product, $pool) = @_;

    if (DPOUtils::in_dpo_pool($self->{xml_file}))
    {
        if (!defined($pool) || !$pool)
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't overwrite $self->{xml_file} because it's in pool"]);
            return 0;
        }
    }

    my $text;

    my $ref;
    if ($dpo_product)
    {
        $ref = \$dpo_product;
    }
    else
    {
        $ref = \$self;
    }

    my $file = $self->{xml_file};

    my $doc = XML::LibXML::Document->new($self->{xml_version}, $self->{xml_encoding});
    my $product = $doc->createElement('Product');

    $product->setAttribute('xmlns:xsi', $self->{xmlns_xsi});
    $product->setAttribute('xsi:noNamespaceSchemaLocation', $self->{xsi_noNamespaceSchemaLocation});
    $doc->setDocumentElement($product);

    # create product elements
    my $name = $doc->createElement('Name');
    my $version = $doc->createElement('Version');
    my $flavour = $doc->createElement('Flavour');
    my $runtime = $doc->createElement('Runtime');
    my $runtime_product_compliant_seq = $doc->createElement('RuntimeProductCompliantSeq');
    my $runtime_product_non_compliant_seq = $doc->createElement('RuntimeProductNonCompliantSeq');
    my $mpc_includes = $doc->createElement('MPCIncludes');
    my $freeze_directory = $doc->createElement('FreezeDirectory');

    # set product name
    $text = XML::LibXML::Text->new($$ref->{name});
    $name->appendChild($text);
    $product->appendChild($name);

    # set version value
    $text = XML::LibXML::Text->new($$ref->{version});
    $version->appendChild($text);
    $product->appendChild($version);

    # set flavour value
    $text = XML::LibXML::Text->new($$ref->{flavour});
    $flavour->appendChild($text);
    $product->appendChild($flavour);

    # set dpo compliant
    my $dpo_compliant_product_element = create_dpo_compliant_product_element($doc, $$ref->{dpo_compliant_product});
    $product->appendChild($dpo_compliant_product_element);

    # set runtime
    foreach my $runtime_product_compliant (@{$dpo_product->{runtime}->{runtime_products_compliant}})
    {
        my $runtime_product_compliant_element = create_runtime_product_compliant_element($doc, $runtime_product_compliant);
        $runtime_product_compliant_seq->appendChild($runtime_product_compliant_element);
    }

    foreach my $runtime_product_non_compliant (@{$dpo_product->{runtime}->{runtime_products_non_compliant}})
    {
        my $runtime_product_non_compliant_element = create_runtime_product_non_compliant_element($doc, $runtime_product_non_compliant);
        $runtime_product_non_compliant_seq->appendChild($runtime_product_non_compliant_element);
    }
    $product->appendChild($runtime);
    $runtime->appendChild($runtime_product_compliant_seq);
    $runtime->appendChild($runtime_product_non_compliant_seq);

    # set mpc_includes value
    $text = XML::LibXML::Text->new($$ref->{mpc_includes});
    $mpc_includes->appendChild($text);
    $product->appendChild($mpc_includes);

    # set freeze_directory value
    $text = XML::LibXML::Text->new($$ref->{freeze_directory});
    $freeze_directory->appendChild($text);
    $product->appendChild($freeze_directory);

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


sub get_product_with_name
{
    my ($product_name, $product_ref, $hide_log) = @_;

    my $env_var_id =  uc($product_name) . "_ROOT";
    my $path = "\$($env_var_id)";
    if (DPOEnvVars::expand_env_var(\$path))
    {
        my $file = "$path/DPOProduct.xml";
        if (-f $file)
        {
            my $config_product = DPOProductConfig->new($file);
            if ($config_product)
            {
                if (!$config_product->get_product($product_ref))
                {
                    DPOLog::report_msg(DPOEvents::GET_PRODUCT_FAILURE, [$product_name]);
                    return 0;
                }
            }
            else
            {
                return 0;
            }
        }
        else
        {
            # Not a dpo product.

            my $log = 1;

            if (defined($hide_log)
                && $hide_log == 1)
            {
                $log = 0; # Don't log for non dpo projects (those defined as <XYZ>_ROOT)
            }

            if ($log)
            {
                DPOLog::report_msg(DPOEvents::FILE_DOESNT_EXIST, [$file, $!]);
            }

            return 0;
        }
    }
    else
    {
        DPOLog::report_msg(DPOEvents::ENV_VAR_NOT_DEFINED, [$env_var_id]);
        return 0;
    }

    return 1;
}

1;


