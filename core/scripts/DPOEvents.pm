
package DPOEvents;

use constant EVENT_TYPE_INFO => 0;
use constant EVENT_TYPE_WARNING => 1;
use constant EVENT_TYPE_ERROR => 2;

use constant NEW_ACTIONS => 0;
use constant GENERIC_INFO => 1;
use constant GENERIC_WARNING => 2;
use constant GENERIC_ERROR => 3;
use constant GET_PROJECT_FAILURE => 4;
use constant GET_LINES_FROM_FILE_FAILURE => 5;
use constant GET_VERSION_FAILURE => 6;
use constant GET_PATH_FAILURE => 7;
use constant ENV_VAR_NOT_DEFINED => 8;
use constant ENV_VAR_SETTING_FAILURE => 9;
use constant GET_FEATURES_FAILURE => 10;
use constant LOAD_DYN_DEP_FAILURE => 11;
use constant LOAD_STAT_DEP_FAILURE => 12;
use constant FILE_DOESNT_EXIST => 13;
use constant READ_FEATURES_FILE_FAILURE => 14;
use constant FEATURES_DOESNT_EXIST => 15;
use constant GET_DIR_CONTENT_FAILURE => 16;
use constant GET_BASE_PROJECTS_FAILURE => 17;
use constant FEATURE_DEFINED_MULTIPLE_TIMES => 18;
use constant VALIDATE_PROJECTS => 19;
use constant PROJECTS_NOT_VALID => 20;
use constant VALIDATE_RUNTIME => 21;
use constant RUNTIME_NOT_VALID => 22;
use constant GENERATE_FAILURE => 23;
use constant LOAD_PROJECT_FAILURE => 24;
use constant FETCH_RUNTIME_FAILURE => 25;
use constant FREEZE_FAILURE => 26;
use constant NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL => 27;
use constant DIFFERENT_VERSION => 28;
use constant DIFFERENT_VERSION_PARENT_DEPENDS_ON => 29;
use constant INCOMPATIBLE_CONFIG_VERSION_PARENT_DEFINES => 30;
use constant PROJECTS_VALID => 31;
use constant PATH_DPO_SETTING_OK => 32;
use constant ENV_VAR_SETTING_OK => 33;
use constant FETCH_RUNTIME_OK => 34;
use constant GENERATION_OK => 35;
use constant FREEZING_OK => 36;
use constant INVALID_VERSION_FORMAT => 37;
use constant SMALLER_VERSION => 38;
use constant WRONG_ARCH_OS_TOOLCHAIN_VS_POOL => 39;
use constant WRONG_ARCH_OS_TOOLCHAIN_VS_WORKSPACE => 40;
use constant WRONG_ARCH_OS_TOOLCHAIN_FILE => 41;
use constant INCOHERENT_DPO_POOL => 42;
use constant RUNTIME_COMPLIANT_SUB_DEP_CANT_BE_REMOVED=> 43;
use constant NO_LIBS_WITH_MPB => 44;
use constant FIXING => 45;
use constant FIXING_DONE => 46;
use constant FIXING_CANCELED => 47;
use constant NO_ACTIONS => 48;
use constant DEPENDENCY_OF_NON_PRODUCT_MODULE => 49;
use constant REPLACING_MODULE => 50;
use constant PATH_IS_NOT_DEFINED => 51;
use constant PATH_DPO_IS_NOT_DEFINED => 52;
use constant PATH_DPO_MUST_BE_DEFINED_BEFORE_PATH => 53;
use constant GETTING_MPC_INCLUDES_FROM_MPC_ROOT => 54;
use constant GETTING_MPBS_FROM_NON_COMPLIANT_MODULES => 55;
use constant READING_DPO_MPC_FEATURES => 56;
use constant DEPENDENCY_OF_NON_WORKSPACE_PROJECT => 57;
use constant SAME_ACTUAL_AND_TARGET_VERSIONS => 58;
use constant CASTING_NOT_POSSIBLE => 59;
use constant MPC_INCLUDES_PATH_ABSENT => 60;
use constant GETTING_NON_DPO_COMPLIANT_DEPENDENCIES => 61;
use constant UPDATE_WORKSPACE_PROJECTS_FAILURE => 62;
use constant PROJECTS_THAT_SHOULD_BE_UPGRADED => 63;
use constant GET_ONLY_PROJECTS_MODULES_CAN_BE_IMPORTED => 64;
use constant GET_PRODUCT_FAILURE => 65;
use constant LOAD_PRODUCT_FAILURE => 66;
use constant MODULE_NOT_FOUND => 67;
use constant FETCH_RUNTIME => 68;
use constant FILE_COPY_FAILURE => 69;
use constant DIRECTORY_CREATION_FAILURE => 70;
use constant FILE_OPERATION_FAILURE => 71;
use constant STATIC_MPC_FILE_CREATION_FAILURE => 72;
use constant ENV_VAR_SETTING => 73;
use constant GENERATION => 74;
use constant PROJECT_DIR_NOT_FOUND => 75;
use constant GENERATE_OK => 76;
use constant MWC_FAILURE => 77;
use constant PREPARE_MPB_FILE_FAILURE => 78;
use constant DEPENDENCY_CONFIG_NOT_PLANNED_TO_BE_PART_OF_WORKSPACE => 79;
use constant PREPARE_MPB_DEPENDENCIES_FAILURE => 80;
use constant FIT_FAILURE => 81;
use constant OPERATION_CANCELLED => 82;
use constant FAILED_TO_GET_MODULES_NAMES => 83;
use constant PREVENT_DYNAMIC_WHEN_STATIC_DEP_NOT_DONE => 84;
use constant CANT_GET_PRODUCT => 85;
use constant NOT_A_DPO_PRODUCT => 86;
use constant RUNTIME_SAVING_FAILURE => 87;
use constant EXTRACT_LIBS_LINES_FAILURE => 88;
use constant GETTING_LIBS_IDS_FAILURE => 89;
use constant FREEZING => 90;
use constant FREEZING_CANCELLED => 91;
use constant GET_MPC_INCLUDES_FOR_MWC_FAILURE => 92;
use constant GET_DEEP_DIR_FAILURE => 93;
use constant HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE => 94;
use constant FREEZING_COPY_OK => 95;
use constant FETCH_MODULES_FROM_PRODUCT_RUNTIME_DEPENDENCIES_FAILURE => 96;
use constant FETCH_MODULES_FROM_WORKSPACE_RUNTIME_DEPENDENCIES_FAILURE => 97;
use constant FETCH_MODULES_FROM_PROJECT_FAILURE => 98;
use constant FETCH_MODULES_FROM_COMPLIANT_PROJECT_FAILURE => 99;
use constant FETCH_MODULES_FROM_NON_COMPLIANT_PROJECT_FAILURE => 100;
use constant ADD_TEST_APP_PROJECT_ENTRY_FAILURE => 101;
use constant GET_STUFF_TO_COPY => 102;
use constant TREE_SCAN_FAILURE => 103;
use constant UNDETERMINED_PROJECT_TYPE => 104;
use constant MPB_FILE_NOT_FOUND => 105;
use constant HEADER_NOT_INWORKSPACE_TO_BUILD => 106;
use constant MKPATH_FAILURE => 107;
use constant XML_SCHEMA_VALIDATION => 108;
use constant CANT_ADD_NON_COMPLIANT_DEP => 109;
use constant MAKE_PATH_FAILURE => 110;
use constant NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL_ON_FREEZE => 111;
use constant MPC_FAILURE => 112;
use constant WRONG_ARCH => 113;
use constant PRODUCT_RUNTIME_DEPENDENCY_BAD_VERSION => 114;

sub new
{
    my ($class) = @_;

    my $self =
    {
    };

    bless($self, $class);

    $self->{+NEW_ACTIONS} = DPOEvent->new(
                                    +NEW_ACTIONS,
                                    EVENT_TYPE_INFO,
                                    "---------- Actions... ----------",
                                    0); # number of parameters

    $self->{+GENERIC_INFO} = DPOEvent->new(
                                    +GENERIC_INFO,
                                    EVENT_TYPE_INFO,
                                    "%s.",
                                    1); # number of parameters

    $self->{+GENERIC_WARNING} = DPOEvent->new(
                                    +GENERIC_WARNING,
                                    EVENT_TYPE_WARNING,
                                    "%s.",
                                    1); # number of parameters

    $self->{+GENERIC_ERROR} = DPOEvent->new(
                                    +GENERIC_ERROR,
                                    EVENT_TYPE_ERROR,
                                    "%s",
                                    1); # number of parameters

    $self->{+GET_PROJECT_FAILURE} = DPOEvent->new(
                                    GET_PROJECT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get project %s.",
                                    1); # number of parameters

    $self->{+GET_LINES_FROM_FILE_FAILURE} = DPOEvent->new(
                                    GET_LINES_FROM_FILE_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Can't get file lines from %s.",
                                    1); # number of parameters

    $self->{+GET_VERSION_FAILURE} = DPOEvent->new(
                                    GET_VERSION_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Can't get version from %s.",
                                    1); # number of parameters

    $self->{+GET_PATH_FAILURE} = DPOEvent->new(
                                    GET_PATH_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get project path (%s) from %s.",
                                    2); # number of parameters

    $self->{+ENV_VAR_NOT_DEFINED} = DPOEvent->new(
                                    ENV_VAR_NOT_DEFINED,
                                    EVENT_TYPE_ERROR,
                                    "Value not defined for %s environment variable.",
                                    1); # number of parameters

    $self->{+ENV_VAR_SETTING_FAILURE} = DPOEvent->new(
                                    ENV_VAR_SETTING_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Environment variables setting failure.",
                                    0); # number of parameters

    $self->{+GET_FEATURES_FAILURE} = DPOEvent->new(
                                    GET_FEATURES_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get features for %s.",
                                    1); # number of parameters

    $self->{+LOAD_DYN_DEP_FAILURE} = DPOEvent->new(
                                    LOAD_DYN_DEP_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to load dynamic dependencies for %s.",
                                    1); # number of parameters

    $self->{+LOAD_STAT_DEP_FAILURE} = DPOEvent->new(
                                    LOAD_STAT_DEP_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to load static dependencies for %s.",
                                    1); # number of parameters

    $self->{+FILE_DOESNT_EXIST} = DPOEvent->new(
                                    FILE_DOESNT_EXIST,
                                    EVENT_TYPE_ERROR,
                                    "File doesn't exist %s.",
                                    1); # number of parameters

    $self->{+READ_FEATURES_FILE_FAILURE} = DPOEvent->new(
                                    READ_FEATURES_FILE_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Can't read %s.",
                                    1); # number of parameters

    $self->{+FEATURES_DOESNT_EXIST} = DPOEvent->new(
                                    FEATURES_DOESNT_EXIST,
                                    EVENT_TYPE_ERROR,
                                    "Feature seems to not exist: %s.",
                                    1); # number of parameters

    $self->{+GET_DIR_CONTENT_FAILURE} = DPOEvent->new(
                                    GET_DIR_CONTENT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get content of %s.",
                                    1); # number of parameters

    $self->{+GET_BASE_PROJECTS_FAILURE} = DPOEvent->new(
                                    GET_BASE_PROJECTS_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get base projects for %s.",
                                    1); # number of parameters

    $self->{+FEATURE_DEFINED_MULTIPLE_TIMES} = DPOEvent->new(
                                    FEATURE_DEFINED_MULTIPLE_TIMES,
                                    EVENT_TYPE_WARNING,
                                    "Feature '%s' defined multiple times ".
                                        "in %s (%s times)",
                                    3); # number of parameters

    $self->{+VALIDATE_PROJECTS} = DPOEvent->new(
                                    VALIDATE_PROJECTS,
                                    EVENT_TYPE_INFO,
                                    "Projects validation...",
                                    0); # number of parameters

    $self->{+PROJECTS_NOT_VALID} = DPOEvent->new(
                                    PROJECTS_NOT_VALID,
                                    EVENT_TYPE_ERROR,
                                    "Projects: not valid.",
                                    0); # number of parameters

    $self->{+VALIDATE_RUNTIME} = DPOEvent->new(
                                    VALIDATE_RUNTIME,
                                    EVENT_TYPE_INFO,
                                    "Validate runtime...",
                                    0); # number of parameters

    $self->{+RUNTIME_NOT_VALID} = DPOEvent->new(
                                    RUNTIME_NOT_VALID,
                                    EVENT_TYPE_ERROR,
                                    "Runtime: not valid.",
                                    0); # number of parameters

    $self->{+GENERATE_FAILURE} = DPOEvent->new(
                                    GENERATE_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Generation failure.",
                                    0); # number of parameters

    $self->{+LOAD_PROJECT_FAILURE} = DPOEvent->new(
                                    LOAD_PROJECT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to load project from %s: %s.",
                                    2); # number of parameters

    $self->{+FETCH_RUNTIME_FAILURE} = DPOEvent->new(
                                    FETCH_RUNTIME_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Runtime fetch failure.",
                                    0); # number of parameters

    $self->{+FREEZE_FAILURE} = DPOEvent->new(
                                    FREEZE_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Freezing failure with %s.",
                                    1); # number of parameters

    $self->{+NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL} = DPOEvent->new(
                                    NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL,
                                    EVENT_TYPE_WARNING,
                                    "%s (non workspace project) is defined as local. You can work with local dependency (%s) but before freezing %s you need to freeze the dependency and rebuild workspace.",
                                    1); # number of parameters

    $self->{+DIFFERENT_VERSION} = DPOEvent->new(
                                    DIFFERENT_VERSION,
                                    EVENT_TYPE_ERROR,
                                    "Different versions: %s is a dependency of different modules with different versions...",
                                    1); # number of parameters

    $self->{+DIFFERENT_VERSION_PARENT_DEPENDS_ON} = DPOEvent->new(
                                    DIFFERENT_VERSION_PARENT_DEPENDS_ON,
                                    EVENT_TYPE_ERROR,
                                    "     ...%s depends on %s.",
                                    2); # number of parameters

    $self->{+INCOMPATIBLE_CONFIG_VERSION_PARENT_DEFINES} = DPOEvent->new(
                                    INCOMPATIBLE_CONFIG_VERSION_PARENT_DEFINES,
                                    EVENT_TYPE_ERROR,
                                    "Incompatible version: %s expects %s-%s as dependency while version of %s is %s.",
                                    5); # number of parameters

    $self->{+PROJECTS_VALID} = DPOEvent->new(
                                    PROJECTS_VALID,
                                    EVENT_TYPE_INFO,
                                    "Projects validation: OK.",
                                    0); # number of parameters

    $self->{+PATH_DPO_SETTING_OK} = DPOEvent->new(
                                    PATH_DPO_SETTING_OK,
                                    EVENT_TYPE_INFO,
                                    "   PATH_DPO set to '%s'.",
                                    1); # number of parameters

    $self->{+ENV_VAR_SETTING_OK} = DPOEvent->new(
                                    ENV_VAR_SETTING_OK,
                                    EVENT_TYPE_INFO,
                                    "Environment variables setting: OK.",
                                    0); # number of parameters

    $self->{+FETCH_RUNTIME_OK} = DPOEvent->new(
                                    FETCH_RUNTIME_OK,
                                    EVENT_TYPE_INFO,
                                    "Runtime fetch: OK.",
                                    0); # number of parameters

    $self->{+GENERATION_OK} = DPOEvent->new(
                                    GENERATION_OK,
                                    EVENT_TYPE_INFO,
                                    "Generation: OK.",
                                    0); # number of parameters

    $self->{+FREEZING_OK} = DPOEvent->new(
                                    FREEZING_OK,
                                    EVENT_TYPE_INFO,
                                    "Freezing: OK.",
                                    0); # number of parameters

    $self->{+INVALID_VERSION_FORMAT} = DPOEvent->new(
                                    INVALID_VERSION_FORMAT,
                                    EVENT_TYPE_ERROR,
                                    "Version number (%s) is not in \"digit.digit.digit\" format.",
                                    1); # number of parameters

    $self->{+SMALLER_VERSION} = DPOEvent->new(
                                    SMALLER_VERSION,
                                    EVENT_TYPE_ERROR,
                                    "Version (%s) is smaller than previous version (%s).",
                                    2); # number of parameters

    $self->{+WRONG_ARCH_OS_TOOLCHAIN_VS_POOL} = DPOEvent->new(
                                    WRONG_ARCH_OS_TOOLCHAIN_VS_POOL,
                                    EVENT_TYPE_ERROR,
                                    "Wrong arch|os|toolchain (%s) for project %s-%s (pool: %s). Please, use the right pool or the right project version (in both cases: exit, set env. var. and relaunch dpo.pl).",
                                    4); # number of parameters

    $self->{+WRONG_ARCH_OS_TOOLCHAIN_FILE} = DPOEvent->new(
                                    WRONG_ARCH_OS_TOOLCHAIN_FILE,
                                    EVENT_TYPE_ERROR,
                                    "Wrong arch|os|toolchain file: %s (%s).",
                                    2); # number of parameters

    $self->{+WRONG_ARCH_OS_TOOLCHAIN_VS_WORKSPACE} = DPOEvent->new(
                                    WRONG_ARCH_OS_TOOLCHAIN_VS_WORKSPACE,
                                    EVENT_TYPE_ERROR,
                                    "Wrong project arch|os|toolchain (%s|%s|%s) for project %s-%s VS workspace (%s|%s|%s). Please, use the right arch/os/toolchain or the right project version (in the last case: exit, set env. var. and relaunch dpo.pl).",
                                    8); # number of parameters

    $self->{+INCOHERENT_DPO_POOL} = DPOEvent->new(
                                    INCOHERENT_DPO_POOL,
                                    EVENT_TYPE_ERROR,
                                    "Incoherent DPO_POOL (%s) while workspace arch|os|toolchain are %s|%s|%s.",
                                    4); # number of parameters

    $self->{+RUNTIME_COMPLIANT_SUB_DEP_CANT_BE_REMOVED} = DPOEvent->new(
                                    RUNTIME_COMPLIANT_SUB_DEP_CANT_BE_REMOVED,
                                    EVENT_TYPE_WARNING,
                                    "A sub-dependency (%s) of product (%s) can't be removed.",
                                    0); # number of parameters

    $self->{+NO_LIBS_WITH_MPB} = DPOEvent->new(
                                    NO_LIBS_WITH_MPB,
                                    EVENT_TYPE_WARNING,
                                    "There is no library associated with mpb file (%s).",
                                    1); # number of parameters

    $self->{+FIXING} = DPOEvent->new(
                                    FIXING,
                                    EVENT_TYPE_INFO,
                                    "Fixing...",
                                    0); # number of parameters

    $self->{+FIXING_DONE} = DPOEvent->new(
                                    FIXING_DONE,
                                    EVENT_TYPE_INFO,
                                    "Fixing done.",
                                    0); # number of parameters

    $self->{+FIXING_CANCELED} = DPOEvent->new(
                                    FIXING_CANCELED,
                                    EVENT_TYPE_INFO,
                                    "Fixing canceled.",
                                    0); # number of parameters

    $self->{+NO_ACTIONS} = DPOEvent->new(
                                    NO_ACTIONS,
                                    EVENT_TYPE_INFO,
                                    "No actions.",
                                    0); # number of parameters

    $self->{+DEPENDENCY_OF_NON_PRODUCT_MODULE} = DPOEvent->new(
                                    DEPENDENCY_OF_NON_PRODUCT_MODULE,
                                    EVENT_TYPE_WARNING,
                                    "%s is a dependency of non product module %s (not replaced).",
                                    2); # number of parameters

    $self->{+REPLACING_MODULE} = DPOEvent->new(
                                    REPLACING_MODULE,
                                    EVENT_TYPE_INFO,
                                    "Replacing module %s with version %s...",
                                    2); # number of parameters

    $self->{+PATH_IS_NOT_DEFINED} = DPOEvent->new(
                                    PATH_IS_NOT_DEFINED,
                                    EVENT_TYPE_ERROR,
                                    "Environment variables PATH is not defined.",
                                    0); # number of parameters

    $self->{+PATH_DPO_IS_NOT_DEFINED} = DPOEvent->new(
                                    PATH_DPO_IS_NOT_DEFINED,
                                    EVENT_TYPE_ERROR,
                                    "Environment variables PATH_DPO is not defined.",
                                    0); # number of parameters

    $self->{+PATH_DPO_MUST_BE_DEFINED_BEFORE_PATH} = DPOEvent->new(
                                    PATH_DPO_MUST_BE_DEFINED_BEFORE_PATH,
                                    EVENT_TYPE_ERROR,
                                    "Environment variables PATH_DPO must be defined before PATH.",
                                    0); # number of parameters

    $self->{+GETTING_MPC_INCLUDES_FROM_MPC_ROOT} = DPOEvent->new(
                                    GETTING_MPC_INCLUDES_FROM_MPC_ROOT,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get MPC includes from MPC_ROOT. Error: %s",
                                    1); # number of parameters

    $self->{+GETTING_MPBS_FROM_NON_COMPLIANT_MODULES} = DPOEvent->new(
                                    GETTING_MPBS_FROM_NON_COMPLIANT_MODULES,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get mpbs from non compliant module %s",
                                    1); # number of parameters

    $self->{+READING_DPO_MPC_FEATURES} = DPOEvent->new(
                                    READING_DPO_MPC_FEATURES,
                                    EVENT_TYPE_ERROR,
                                    "Failed to read DPO features",
                                    0); # number of parameters

    $self->{+DEPENDENCY_OF_NON_WORKSPACE_PROJECT} = DPOEvent->new(
                                    DEPENDENCY_OF_NON_WORKSPACE_PROJECT,
                                    EVENT_TYPE_WARNING,
                                    "%s is a dependency of non workspace project %s (not replaced).",
                                    2); # number of parameters

    $self->{+SAME_ACTUAL_AND_TARGET_VERSIONS} = DPOEvent->new(
                                    SAME_ACTUAL_AND_TARGET_VERSIONS,
                                    EVENT_TYPE_WARNING,
                                    "%s: actual and target versions are the same (%s).",
                                    2); # number of parameters

    $self->{+CASTING_NOT_POSSIBLE} = DPOEvent->new(
                                    CASTING_NOT_POSSIBLE,
                                    EVENT_TYPE_ERROR,
                                    "Casting from %s to %s not possible for %s.",
                                    3); # number of parameters

    $self->{+MPC_INCLUDES_PATH_ABSENT} = DPOEvent->new(
                                    MPC_INCLUDES_PATH_ABSENT,
                                    EVENT_TYPE_ERROR,
                                    "MPC includes path absent for %s (%s).",
                                    2); # number of parameters

    $self->{+GETTING_NON_DPO_COMPLIANT_DEPENDENCIES} = DPOEvent->new(
                                    GETTING_NON_DPO_COMPLIANT_DEPENDENCIES,
                                    EVENT_TYPE_ERROR,
                                    "Can't get non dpo compliant dependencies for %s.",
                                    1); # number of parameters

    $self->{+UPDATE_WORKSPACE_PROJECTS_FAILURE} = DPOEvent->new(
                                    UPDATE_WORKSPACE_PROJECTS_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Can't update workspace projects with %s.",
                                    1); # number of parameters

    $self->{+PROJECTS_THAT_SHOULD_BE_UPGRADED} = DPOEvent->new(
                                    PROJECTS_THAT_SHOULD_BE_UPGRADED,
                                    EVENT_TYPE_WARNING,
                                    "%s should be upgraded because its dependencies have been upgraded: %s.",
                                    2); # number of parameters

    $self->{+GET_ONLY_PROJECTS_MODULES_CAN_BE_IMPORTED} = DPOEvent->new(
                                    GET_ONLY_PROJECTS_MODULES_CAN_BE_IMPORTED,
                                    EVENT_TYPE_WARNING,
                                    "Only projects/modules can be imported, not product (%s).",
                                    1); # number of parameters

    $self->{+GET_PRODUCT_FAILURE} = DPOEvent->new(
                                    GET_PRODUCT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get product %s.",
                                    1); # number of parameters

    $self->{+LOAD_PRODUCT_FAILURE} = DPOEvent->new(
                                    LOAD_PRODUCT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to load product from %s.",
                                    1); # number of parameters

    $self->{+MODULE_NOT_FOUND} = DPOEvent->new(
                                    MODULE_NOT_FOUND,
                                    EVENT_TYPE_WARNING,
                                    "%s not found in %s.",
                                    1); # number of parameters

    $self->{+FETCH_RUNTIME} = DPOEvent->new(
                                    FETCH_RUNTIME,
                                    EVENT_TYPE_INFO,
                                    "Runtime fetch...",
                                    0); # number of parameters

    $self->{+FILE_COPY_FAILURE} = DPOEvent->new(
                                    FILE_COPY_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "File copy failure: from %s to %s (error: %d)",
                                    3); # number of parameters

    $self->{+DIRECTORY_CREATION_FAILURE} = DPOEvent->new(
                                    DIRECTORY_CREATION_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Directory creation failure: %s",
                                    1); # number of parameters

    $self->{+FILE_OPERATION_FAILURE} = DPOEvent->new(
                                    FILE_OPERATION_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "File operation (%s) failure on %s: %s",
                                    3); # number of parameters

    $self->{+STATIC_MPC_FILE_CREATION_FAILURE} = DPOEvent->new(
                                    STATIC_MPC_FILE_CREATION_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Creation of %s_static.mpc file failed.",
                                    1); # number of parameters

    $self->{+ENV_VAR_SETTING} = DPOEvent->new(
                                    ENV_VAR_SETTING,
                                    EVENT_TYPE_INFO,
                                    "Environment variables setting...",
                                    0); # number of parameters

    $self->{+GENERATION} = DPOEvent->new(
                                    GENERATION,
                                    EVENT_TYPE_INFO,
                                    "Generation...",
                                    0); # number of parameters

    $self->{+PROJECT_DIR_NOT_FOUND} = DPOEvent->new(
                                    PROJECT_DIR_NOT_FOUND,
                                    EVENT_TYPE_ERROR,
                                    "%s directory not found",
                                    1); # number of parameters

    $self->{+GENERATE_OK} = DPOEvent->new(
                                    GENERATE_OK,
                                    EVENT_TYPE_INFO,
                                    "Generation: OK",
                                    0); # number of parameters

    $self->{+MWC_FAILURE} = DPOEvent->new(
                                    MWC_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "MWC failure. Please see console output",
                                    0); # number of parameters

    $self->{+PREPARE_MPB_FILE_FAILURE} = DPOEvent->new(
                                    PREPARE_MPB_FILE_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "MPB preparation failure for project %s",
                                    1); # number of parameters

    $self->{+DEPENDENCY_CONFIG_NOT_PLANNED_TO_BE_PART_OF_WORKSPACE} = DPOEvent->new(
                                    DEPENDENCY_CONFIG_NOT_PLANNED_TO_BE_PART_OF_WORKSPACE,
                                    EVENT_TYPE_ERROR,
                                    "%s uses %s as %s while %s is planned to be built as %s",
                                    5); # number of parameters

    $self->{+PREPARE_MPB_DEPENDENCIES_FAILURE} = DPOEvent->new(
                                    PREPARE_MPB_DEPENDENCIES_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to prepare mpb dependencies files for project %s",
                                    1); # number of parameters

    $self->{+FIT_FAILURE} = DPOEvent->new(
                                    FIT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fit for project %s",
                                    1); # number of parameters

    $self->{+FAILED_TO_GET_MODULES_NAMES} = DPOEvent->new(
                                    FAILED_TO_GET_MODULES_NAMES,
                                    EVENT_TYPE_INFO,
                                    "Failed to get modules names for %s",
                                    1); # number of parameters

    $self->{+PREVENT_DYNAMIC_WHEN_STATIC_DEP_NOT_DONE} = DPOEvent->new(
                                    PREVENT_DYNAMIC_WHEN_STATIC_DEP_NOT_DONE,
                                    EVENT_TYPE_INFO,
                                    "Preventing dynamic definition whith static dependency not done",
                                    0); # number of parameters

    $self->{+CANT_GET_PRODUCT} = DPOEvent->new(
                                    CANT_GET_PRODUCT,
                                    EVENT_TYPE_ERROR,
                                    "Can't get product %s",
                                    1); # number of parameters

    $self->{+NOT_A_DPO_PRODUCT} = DPOEvent->new(
                                    NOT_A_DPO_PRODUCT,
                                    EVENT_TYPE_WARNING,
                                    "%s is not a DPO product. Is it relevant to set %s as env. var. ?",
                                    2); # number of parameters

    $self->{+RUNTIME_SAVING_FAILURE} = DPOEvent->new(
                                    RUNTIME_SAVING_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to save runtime for %s: %s",
                                    2); # number of parameters

    $self->{+EXTRACT_LIBS_LINES_FAILURE} = DPOEvent->new(
                                    EXTRACT_LIBS_LINES_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get libs lines from %s",
                                    1); # number of parameters

    $self->{+GETTING_LIBS_IDS_FAILURE} = DPOEvent->new(
                                    GETTING_LIBS_IDS_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get libs ids from project %s",
                                    1); # number of parameters

    $self->{+FREEZING} = DPOEvent->new(
                                    FREEZING,
                                    EVENT_TYPE_INFO,
                                    "Freezing...",
                                    0); # number of parameters

    $self->{+FREEZING_CANCELLED} = DPOEvent->new(
                                    FREEZING_CANCELLED,
                                    EVENT_TYPE_INFO,
                                    "Freeze cancelled...",
                                    0); # number of parameters

    $self->{+GET_MPC_INCLUDES_FOR_MWC_FAILURE} = DPOEvent->new(
                                    GET_MPC_INCLUDES_FOR_MWC_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get mpc includes for MWC with %s",
                                    1); # number of parameters

    $self->{+GET_DEEP_DIR_FAILURE} = DPOEvent->new(
                                    GET_DEEP_DIR_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get deep content of directory %s",
                                    1); # number of parameters

    $self->{+HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE} = DPOEvent->new(
                                    HAZARDOUS_MIX_OF_DEBUG_AND_RELEASE,
                                    EVENT_TYPE_WARNING,
                                    "%s version has not been built for %s (%s doesn't exist). ".
                                    "Remember that it is hazardous to mix debug and ".
                                    "release versions in Windows (http://msdn.microsoft.com/en-us/library/ms235460.aspx).",
                                    1); # number of parameters

    $self->{+FREEZING_COPY_OK} = DPOEvent->new(
                                    FREEZING_COPY_OK,
                                    EVENT_TYPE_INFO,
                                    "Freezeing - the step of copying files succeeded",
                                    0); # number of parameters

    $self->{+FETCH_MODULES_FROM_PRODUCT_RUNTIME_DEPENDENCIES_FAILURE} = DPOEvent->new(
                                    FETCH_MODULES_FROM_PRODUCT_RUNTIME_DEPENDENCIES_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fetch modules from runtime dependencies in %s",
                                    1); # number of parameters

    $self->{+FETCH_MODULES_FROM_WORKSPACE_RUNTIME_DEPENDENCIES_FAILURE} = DPOEvent->new(
                                    FETCH_MODULES_FROM_WORKSPACE_RUNTIME_DEPENDENCIES_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fetch modules from workspace dependencies",
                                    0); # number of parameters

    $self->{+FETCH_MODULES_FROM_PROJECT_FAILURE} = DPOEvent->new(
                                    FETCH_MODULES_FROM_PROJECT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fetch modules from project %s",
                                    1); # number of parameters

    $self->{+FETCH_MODULES_FROM_COMPLIANT_PROJECT_FAILURE} = DPOEvent->new(
                                    FETCH_MODULES_FROM_COMPLIANT_PROJECT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fetch modules from compliant project %s",
                                    1); # number of parameters

    $self->{+FETCH_MODULES_FROM_NON_COMPLIANT_PROJECT_FAILURE} = DPOEvent->new(
                                    FETCH_MODULES_FROM_NON_COMPLIANT_PROJECT_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to fetch modules from non compliant project %s",
                                    1); # number of parameters

    $self->{+ADD_TEST_APP_PROJECT_ENTRY_FAILURE} = DPOEvent->new(
                                    ADD_TEST_APP_PROJECT_ENTRY_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to add (in mwc file) test app project entry for project %s (%s)",
                                    2); # number of parameters

    $self->{+GET_STUFF_TO_COPY} = DPOEvent->new(
                                    GET_STUFF_TO_COPY,
                                    EVENT_TYPE_ERROR,
                                    "Failed to get stuff to copy from %s (%s)",
                                    2); # number of parameters

    $self->{+TREE_SCAN_FAILURE} = DPOEvent->new(
                                    TREE_SCAN_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Failed to scan directory %s",
                                    1); # number of parameters

    $self->{+UNDETERMINED_PROJECT_TYPE} = DPOEvent->new(
                                    UNDETERMINED_PROJECT_TYPE,
                                    EVENT_TYPE_ERROR,
                                    "Undetermined project type (static/dynamic) for %s",
                                    1); # number of parameters

    $self->{+MPB_FILE_NOT_FOUND} = DPOEvent->new(
                                    MPB_FILE_NOT_FOUND,
                                    EVENT_TYPE_ERROR,
                                    "MPB file %s not found in %s",
                                    2); # number of parameters

    $self->{+HEADER_NOT_INWORKSPACE_TO_BUILD} = DPOEvent->new(
                                    HEADER_NOT_INWORKSPACE_TO_BUILD,
                                    EVENT_TYPE_INFO,
                                    "%s is not included in workspace and won't be built",
                                    1); # number of parameters

    $self->{+MKPATH_FAILURE} = DPOEvent->new(
                                    MKPATH_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "File::Path::mkpath(%s) failure: %s",
                                    2); # number of parameters

    $self->{+XML_SCHEMA_VALIDATION} = DPOEvent->new(
                                    XML_SCHEMA_VALIDATION,
                                    EVENT_TYPE_ERROR,
                                    "XML schema validation failure for %s: %s",
                                    2); # number of parameters

    $self->{+CANT_ADD_NON_COMPLIANT_DEP} = DPOEvent->new(
                                    CANT_ADD_NON_COMPLIANT_DEP,
                                    EVENT_TYPE_ERROR,
                                    "Can't add non compliant dependencies in %s: %s",
                                    2); # number of parameters

    $self->{+MAKE_PATH_FAILURE} = DPOEvent->new(
                                    MAKE_PATH_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "Making path failure: %s (file: %s)",
                                    2); # number of parameters

    $self->{+NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL_ON_FREEZE} = DPOEvent->new(
                                    NONWORKSPACE_PROJECT_DEFINED_AS_LOCAL_ON_FREEZE,
                                    EVENT_TYPE_ERROR,
                                    "Can't freeze with local depedency (%s). You have to use (build with) non local (pool) dependencies.",
                                    1); # number of parameters

    $self->{+MPC_FAILURE} = DPOEvent->new(
                                    MPC_FAILURE,
                                    EVENT_TYPE_ERROR,
                                    "MPC failure. Please see console output",
                                    0); # number of parameters

    $self->{+WRONG_ARCH} = DPOEvent->new(
                                    WRONG_ARCH,
                                    EVENT_TYPE_ERROR,
                                    "Wrong architecture for %s.",
                                    1); # number of parameters

    $self->{+PRODUCT_RUNTIME_DEPENDENCY_BAD_VERSION} = DPOEvent->new(
                                    PRODUCT_RUNTIME_DEPENDENCY_BAD_VERSION,
                                    EVENT_TYPE_ERROR,
                                    "Wrong runtime version for %s (current: %s, registered: %s).",
                                    3); # number of parameters

    return $self;
}

# Get a copy of the event
sub instance
{
    my ($self, $id, $params_ref, $src) = @_;

    my $event = $self->{$id}->clone;

    $event->set_params($params_ref, $src);

    return $event;
}

# Get event text only (no need to copy the event)
sub get_text
{
    my ($self, $id, $params_ref) = @_;

    if (!defined($params_ref))
    {
        print "Absent parameters for event $id\n";
        return "";
    }

    return sprintf($self->{$id}->{def}, @$params_ref);
}

sub get_level
{
    my ($self, $id) = @_;

    return $self->{$id}->{level};
}

sub get_def
{
    my ($self, $id) = @_;

    return $self->{$id}->{def};
}

1;


package DPOEvent;
use parent 'Clone';

sub new
{
    my ($class,
        $id,
        $level,
        $def,
        $nb_params) = @_;

    my $self =
    {
        id => $id,
        level => $level,
        def => $def,
        nb_params => $nb_params,
        params => [],
        src => ""
    };

    bless($self, $class);

    return $self;
}

sub set_params
{
    my ($self, $params_ref, $src) = @_;

    if (!defined($params_ref))
    {
        print "Missing parameters for event number $self->{id}\n";
        return;
    }

    if (scalar(@$params_ref) != $self->{nb_params})
    {
        print "Incoherent message/parameters for event number $self->{id}\n";
    }

    $self->{params} = $params_ref;
    $self->{src} = $src;
}

sub text
{
    my ($self) = @_;

    if (scalar(@{$self->{params}}) != 0)
    {
        return sprintf($self->{def}, @{$self->{params}});
    }
    else
    {
        return $self->{def};
    }
}

1;


