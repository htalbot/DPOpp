Files in this directory:

- xyz.mpb

    Files that can be included as a base project in a
    project using xyz.

- xyz_dependencies.mpb

    This base project file contains the dependencies of xyz.
    This file should not be updated manually except for the
    first line (project).

- xyz_ex.mpb

    This file contains the specific project MPC definitions.
    This is the common definitions for the type of the project.

- xyz_test_app_dependencies.mpb

    This base project file contains the dependencies of the
    test application of xyz.
    This file should not be updated manually except for the
    first line (project).

If it is needed to define this project so that it
can be used as a base project, please refer
to $DPO_CORE_ROOT/doc/MPC/base_project_definition.txt.
