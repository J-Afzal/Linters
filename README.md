# Linters

Mostly wrappers around existing linters with some custom implementations.

## CI / CD

[![Continuous Integration](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousIntegration.yml/badge.svg)](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousIntegration.yml)
[![Continuous Deployment](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousDeployment.yml/badge.svg)](https://github.com/J-Afzal/Linters/actions/workflows/ContinuousDeployment.yml)

The continuous integration workflow runs against all commits on pull requests, builds the code, runs unit tests and performs linting checks.

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
TODO

Add ## Getting Started and ## General Information

Add azure pipeline templates (and add to other repos)

Add CD pipeline

Other Languages:
    Lua
    Go
    Python
    Rust

-->
