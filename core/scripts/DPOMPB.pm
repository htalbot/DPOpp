#!/usr/bin/perl

use List::MoreUtils;

use DPOUtils;
use DPOMPC;
use DPOEvents;
use DPOEnvVars;

package DPOMpb;

my %loaded_libs_lines;
my @mpc_features;
my @contain_no_libs;

sub new
{
    my ($class,
        $product_name,
        $product_flavour,
        $lib_id,
        $name,
        $mpc_includes) = @_;

    my $self =
    {
        product_name => $product_name,
        product_flavour => $product_flavour,
        lib_id => $lib_id,
        name => $name,
        mpc_includes => $mpc_includes
    };

    bless($self, $class);

    return $self;
}

sub load_non_compliant_dependencies
{
    my ($self, $product, $project, $loaded_projects_ref, $mpbs_scanned_ref) = @_;

    if (!List::MoreUtils::any {$_->{name} eq $self->{name}} @$mpbs_scanned_ref)
    {
        # Get associated mpbs (those from product's mpbs inherit)
        my @associated_libs;
        if ($self->get_non_compliant_associated_libs(\@associated_libs))
        {
            # Make projects with the associated mpbs and make them dependencies of $project
            foreach my $associated_lib (@associated_libs)
            {
                my ($lib_id, $mpb_name) = %$associated_lib;

                if ($lib_id ne $project->{name}
                    && $lib_id ne "TAO_IDL_BE") # TO_DO
                {
                    my $dpo_compliant = DPOCompliant->new(0, # not compliant
                                                            $self->{product_name},
                                                            $self->{product_flavour},
                                                            $mpb_name,
                                                            $self->{mpc_includes});

                    my $type;
                    if (!$product->get_lib_type($lib_id, \$type))
                    {
                        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't get type of $lib_id"]);
                        return 0;
                    }

                    my $new_project = DPOProject->new($lib_id, $product->{version}, $product->{version}, $type, $dpo_compliant);

                    my $dpo_mpb = DPOMpb->new($self->{product_name}, $self->{product_flavour}, $lib_id, $mpb_name, $self->{mpc_includes});

                    # Get dependencies of $dep and put them into loaded_projects
                    if (!$dpo_mpb->load_non_compliant_dependencies($product, $new_project, $loaded_projects_ref, $mpbs_scanned_ref))
                    {
                        DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't get non compliant dependencies for $new_project->{name}"]);
                        return 0;
                    }

                    my $dep = DPOProjectDependency->new($new_project->{name},
                                                        $new_project->{version},
                                                        $new_project->{target_version},
                                                        $new_project->{type},
                                                        $new_project->{dpo_compliant});

                    push(@{$project->{dependencies_when_static}}, $dep);
                    push(@{$project->{dependencies_when_dynamic}}, $dep);

                    if (!List::MoreUtils::any {$_->{name} eq $new_project->{name}} @$loaded_projects_ref)
                    {
                        # Non dpo compliant projects have no features file in their root.
                        # Few are using features files (ACE). ACE features can be obtained
                        # by ace itself.
                        #~ if (!$new_project->load_features())
                        #~ {
                            #~ DPOLog::report_msg(DPOEvents::GET_FEATURES_FAILURE, [$new_project->{name}]);
                            #~ return 0;
                        #~ }

                        push(@$loaded_projects_ref, $new_project);
                    }
                }
            }
        }
        else
        {
            DPOLog::report_msg(DPOEvents::GENERIC_ERROR, ["Can't get associated libraries for non compliant dependency from $project->{name}"]);
            return 0;
        }

        push(@$mpbs_scanned_ref, $self);
    }

    return 1;
}


sub get_non_compliant_associated_libs
{
    my ($self, $associated_mpbs_ref) = @_;

    my @mpc_includes = split(/;/, $self->{mpc_includes});

    my @libs_ids;
    my $level = 0;
    if (!DPOMpb::get_libs_ids(0, $self->{name}, \@mpc_includes, \@libs_ids, \$level))
    {
        return 0;
    }

    foreach my $lib_id (@libs_ids)
    {
        if (!List::MoreUtils::any {$_ eq $lib_id->{id}} @$associated_mpbs_ref)
        {
            if ($lib_id->{mpb_name} ne $self->{name})
                #~ && $lib_id->{level} == 1)
            {
                my $project_name = $lib_id->{id};
                if ($lib_id->{mpb_name} =~ /(.*)_dpo$/
                    || $lib_id->{mpb_name} =~ /(.*)_dpo_static$/)
                {
                    $project_name = $1;
                }
                my $lib_id_with_mpb_name = {$project_name => $lib_id->{mpb_name}};

                my $found = 0;
                foreach my $mpb (@$associated_mpbs_ref)
                {
                    foreach my $key (keys %$mpb)
                    {
                        if ($key eq $project_name)
                        {
                            $found = 1;
                            last;
                        }
                    }

                    if ($found)
                    {
                        last;
                    }
                }

                if (!$found)
                {
                    push(@$associated_mpbs_ref, $lib_id_with_mpb_name);
                }
            }
        }
    }

    return 1;
}


sub get_libs_ids
{
    my ($project, $mpb_name, $mpc_includes, $libs_ids_ref, $level_ref) = @_;

    if (scalar(@mpc_features) == 0)
    {
        my $dpo_mpc = DPOMPC->new();
        if (!$dpo_mpc->read_features(\@mpc_features))
        {
            DPOLog::report_msg(DPOEvents::READING_DPO_MPC_FEATURES, []);
            return 0;
        }
    }

    #~ #print "Get dependencies libs from $mpb_name (", scalar(@$mpc_includes), ")\n";
    foreach my $x (@$mpc_includes)
    {
        my $complete = "$x/$mpb_name.mpb";
        my $complete_expanded = $complete;
        DPOEnvVars::expand_env_var(\$complete_expanded);

        if (-e $complete_expanded)
        {
            my @libs_lines;
            if (defined($loaded_libs_lines->{$mpb_name}))
            {
                @libs_lines = @{$loaded_libs_lines->{$mpb_name}};
            }
            else
            {
                if (!List::MoreUtils::any {$_ eq $complete} @contain_no_libs)
                {
                    my @blocks_containing_libs_not_used;
                    my @non_block_libs_not_used;
                    if (!extract_libs_lines($project, $complete_expanded, \@libs_lines, \@blocks_containing_libs_not_used, \@non_block_libs_not_used))
                    {
                        push(@contain_no_libs, $complete);
                        next;
                    }
                }
                @{$loaded_libs_lines->{$mpb_name}} = @libs_lines;
            }

            foreach my $line (@libs_lines)
            {
                my ($libs_ids) = $line =~ /=(.*)/;

                #~ #print "******************** Line containing lib: $line";
                #~ #print "$$level_ref =====================> ";
                #~ #print "    " x ($$level_ref * 1);
                #~ #print "$libs_ids\n";

                my @tokens = split(/ /, $libs_ids);
                foreach my $token (@tokens)
                {
                    if (length($token) != 0)
                    {
                        my %lib_id;
                        if ($token =~ /.*\/(.*)/)
                        {
                            $lib_id{id} = $1;
                        }
                        else
                        {
                            $lib_id{id} = $token;
                        }

                        $lib_id{level} = $$level_ref;
                        $lib_id{mpb_name} = $mpb_name;
                        #~ #print "LLLLL = $lib_id{id} - $$level_ref\n";
                        push(@$libs_ids_ref, \%lib_id);
                    }
                }
            }

            if (scalar(@libs_lines) != 0)
            {
                $$level_ref++;
            }

            my @base_projects;
            if (get_base_projects($complete_expanded, \@base_projects))
            {
                foreach my $b (@base_projects)
                {
                    foreach my $x (@$mpc_includes)
                    {
                        my $mpb_name = "$x/$b.mpb";
                        my $mpb_name_expanded = $mpb_name;
                        DPOEnvVars::expand_env_var(\$mpb_name_expanded);
                        if (-e $mpb_name_expanded)
                        {
                            get_libs_ids($project, $b, $mpc_includes, $libs_ids_ref, $level_ref);
                            last;
                        }
                    }
                }
            }
            else
            {
                DPOLog::report_msg(DPOEvents::GET_BASE_PROJECTS_FAILURE, [$complete]);
                return 0;
            }

            if (scalar(@libs_lines) != 0)
            {
                $$level_ref--;
            }

            last;
        }
    }

    return 1;
}

sub extract_libs_lines
{
    my ($project, $mpb_file, $new_lines, $blocks_containing_libs_ref, $non_block_libs_ref) = @_;

    my $libs_pattern = "(xerceslib|libs)\\s*\\+*\\=";
    my $feature_keyword = "feature";
    my $specific_keyword = "specific|verbatim|Define_Custom";
    # When lines are included in a scope of keywords,
    # keep only those that are relevant.

    # Get mpc features
    my @all_features;
    if ($project)
    {
        if (defined($project->{features}))
        {
            @all_features = (@{$project->{features}});
        }
    }

    @all_features = (@mpc_features, @all_features);

    # Read lines from file
    my @lines;
    if (!DPOUtils::get_file_lines($mpb_file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$mpb_file]);
        return 0;
    }

    # Extract blocks
    my @feature_blocks=();
    my @file_remaining_lines=();
    extract_blocks(\@lines,
                    $feature_keyword,
                    \@feature_blocks,
                    \@file_remaining_lines);

    foreach my $feature_block (@feature_blocks)
    {
        # Extract specific blocks from feature blocks
        my @specific_blocks=();
        my @feature_remaining_lines=();
        extract_blocks($feature_block,
                        $specific_keyword,
                        \@specific_blocks,
                        \@feature_remaining_lines);

        my @candidate_lines=(); # libs contained in the feature blocks
                                # are not necessary to be considered.
                                # If feature is not defined or disabled,
                                # libs lines won't be kept.

        # If we find libs in specific blocks, we will have to check
        # if the feature is defined. If feature is not defined, the user
        # will have to define it in $project_ROOT/features file. If feature
        # is defined but not enabled, we won't have to keep this libs.
        foreach my $specific_block (@specific_blocks)
        {
            foreach my $line (@$specific_block)
            {
                if ($line =~ /($specific_keyword)\s*\((.*)\)\s+\{/)
                {
                    next; # Ok, check for libs in the remaining
                }
                else
                {
                    if ($line =~ /$libs_pattern/)
                    {
                        push(@candidate_lines, $line);
                    }
                }
            }
        }

        # Extract libs from remaining lines of feature block
        foreach my $line (@feature_remaining_lines)
        {
            if ($line =~ /$libs_pattern/)
            {
                push(@candidate_lines, $line);
            }
        }

        # Get the features
        my @features;
        foreach my $line (@$feature_block)
        {
            if ($line =~ /feature\s*\((.*)\)\s+\{/)
            {
                @features = split(/,/, $1) if defined($1);
                last;
            }
        }

        if (scalar(@candidate_lines))
        {
            my $enabled = 1; # If not found => enabled

            # Check features
            foreach my $feature (@features)
            {
                DPOUtils::trim(\$feature);

                my ($neg) = $feature =~ /(\!)/;

                my $original = $feature; # to trace (printf(CheckValid...

                $feature =~ s/\!(.*)/\Q$1\E/ if $neg;

                my $count = 0;
                my $bFound = 0;
                foreach my $assignment (@all_features)
                {
                    my ($project_feature, $value) =
                            $assignment =~ /(.*)=(.*)/;

                    DPOUtils::trim(\$project_feature);
                    DPOUtils::trim(\$value);

                    if ($project_feature eq $feature)
                    {
                        $bFound = 1;
                        $count++;
                        if (defined($neg) && $neg)
                        {
                            $value = !$value;
                        }
                        $enabled = $enabled && $value;
                        #~ #printf("CheckValid - $original ($assignment) => %d\n", $valid);
                    }
                }

                if ($count > 1)
                {
                    DPOLog::report_msg(DPOEvents::FEATURE_DEFINED_MULTIPLE_TIMES, [$feature, $mpb_file, $count]);
                }
            }

            if ($enabled)
            {
                foreach my $libs_line (@candidate_lines)
                {
                    push(@$new_lines, $libs_line);
                    if (!List::MoreUtils::any {$_ eq $feature_block} @{$blocks_containing_libs_ref})
                    {
                        push(@{$blocks_containing_libs_ref}, $feature_block);
                    }
                }
            }
        }
    }

    # Extract specific blocks from file remaining lines (lines not in feature blocks)
    my @new_file_remaining_lines=();
    my @specific_blocks=();
    extract_blocks(\@file_remaining_lines,
                    $specific_keyword,
                    \@specific_blocks,
                    \@new_file_remaining_lines);

    foreach my $specific_block (@specific_blocks)
    {
        foreach my $line (@$specific_block)
        {
            if ($line =~ /($specific_keyword)\s*\((.*)\)\s+\{/)
            {
                next; # Ok, check for libs in the remaining
            }
            else
            {
                if ($line =~ /$libs_pattern/)
                {
                    push(@$new_lines, $line);
                    if (!List::MoreUtils::any {$_ eq $specific_block} @{$blocks_containing_libs_ref})
                    {
                        push(@{$blocks_containing_libs_ref}, $specific_block);
                    }
                }
            }
        }
    }

    # Extract libs from file remaining lines (not in feature/specific blocks)
    foreach my $line (@new_file_remaining_lines)
    {
        if ($line =~ /$libs_pattern/)
        {
            push(@$new_lines, $line);
            if (!List::MoreUtils::any {$_ eq $line} @{$non_block_libs_ref})
            {
                push(@{$non_block_libs_ref}, $line);
            }
        }
    }

    return 1;
}


sub extract_blocks
{
    my ($lines, $keywords, $blocks, $remaining_lines) = @_;

    my $block_begin = 0;
    my @block = ();
    my $curly_braces_count = 0;
    my $relevant = 0;
    foreach my $line (@$lines)
    {
        if ($line =~ /\s*\/\//)
        {
            next;
        }

        if ($block_begin)
        {
            if ($relevant)
            {
                push(@block, $line);
            }

            if ($line =~ /\{/)
            {
                $curly_braces_count += 1;
            }

            if ($line =~ /\}/)
            {
                $curly_braces_count -= 1;

                if ($curly_braces_count == 0)
                {
                    push(@$blocks, [@block]);
                    @block = ();
                    $block_begin = 0;
                    $relevant = 0;
                }
            }
        }
        else
        {
            if ($line =~ /($keywords)\s*\(.*\)\s+\{/)
            {
                $block_begin = 1;
                $curly_braces_count = 1;

                $relevant = relevant_block($line, $keywords);
                if ($relevant)
                {
                    push(@block, $line);
                    next;
                }
            }
            else
            {
                push(@$remaining_lines, $line);
            }
        }
    }
}

sub relevant_block
{
    my ($line, $keywords) = @_;

    # TO_DO: detailler pour chaque specific...
    if ($line =~ /specific/)
    {
        if ($^O =~ /Win/)
        {
            if ($line =~ /cdt6/)
            {
                return 0;
            }
        }
        else # Linux
        {
            if ($line =~ /prop:windows/
                || $line =~ /prop:microsoft/
                || $line =~ /vc\d*/)
            {
                return 0; # irrelevant
            }
        }
    }

    return 1; # relevant
}


sub get_base_projects
{
    my ($mpb_file, $base_projects) = @_;

    my @lines=();
    if (!DPOUtils::get_file_lines($mpb_file, \@lines))
    {
        DPOLog::report_msg(DPOEvents::GET_LINES_FROM_FILE_FAILURE, [$mpb_file]);
        return 0;
    }

    # extract base projects from mpb file
    my @project_lines=();
    DPOUtils::get_complete_lines(\@lines, "project", \@project_lines);
    foreach(@project_lines)
    {
        my $line = $_;

        if (/:/)
        {
            my @new_base_projects = $_ =~ /:(.*)\{/;
            foreach(@new_base_projects)
            {
                my @tokens = split(/,/, $_);
                foreach(@tokens)
                {
                    DPOUtils::trim(\$_);
                    if ($_)
                    {
                        my $bFound = 0;
                        my $current = $_;
                        foreach(@$base_projects)
                        {
                            if ($_ eq $current)
                            {
                                $bFound = 1;
                                last;
                            }
                        }
                        if (!$bFound)
                        {
                            push(@$base_projects, $_);
                        }
                    }
                }
            }
        }
        last;
    }

    return 1;
}


1;


