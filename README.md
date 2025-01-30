# Linters

Mostly wrappers around existing linters with some custom implementations. Includes a template workflow for running all the
linters.

## CI / CD

[![Continuous Integration](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousIntegration.yml/badge.svg)](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousIntegration.yml)
[![Continuous Deployment](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousDeployment.yml/badge.svg)](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousDeployment.yml)

The continuous integration workflow runs against all commits on pull requests, builds the code, runs unit tests and performs
linting checks.

The continuous deployment workflow runs against all commits to main, builds the code and deploys linter modules as a release.

## Development Setup

The following dependencies need to be installed:

- PowerShell version >= 5
- npm dependencies via `npm install`
- clang-tidy >= 19 and clang-format >= 19
- CMake >= 3.20
- Ninja >= 1.12.1

### IDE

On Windows, Visual Studio 2022 can be used by opening the folder as a CMake project and Visual Studio Code can be used by
opening the folder through the `Developer PowerShell for VS` (otherwise you may see errors around cl.exe not being found when
configuring CMake for the clang-based linters).

<!--
TODO - Linters

Add azure pipeline templates
    # TODO: can matrix os be made in to array like github actions?
    # TODO: check that other jobs skip if this install linting deps step fails
    Add to terminal games to check template works

run pipelines against empty repo

Add logic to prevent multiple cd deployments on a day (and need to turn off azure pipeline cd)


TODO - Terminal Games

Doxygen
    Add build to CI with artifact to check.
    Add build and publish to CD and publish to GH pages (maybe commit to repo but make sure no infinite loop)
    Update readme to link to GH pages docs

-----

zig build system???
Performance profile code to see where performance lost in battleships

------

unit test all the things

change master to main?

-->
