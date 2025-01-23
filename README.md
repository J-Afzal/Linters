# Linters

Mostly wrappers around existing linters with some custom implementations.

## Getting Started

TODO

## General Information

TODO

## CI / CD

TODO

## Development Setup

TODO

For development a few extra tools are needed to check for linting issues locally. The `Test-CodeUsingAllLinting` function
can be called to locally run all the linting steps in the CI workflow.

```ps1
Import-Module ./modules/TerminalGames.psd1
Test-CodeUsingAllLinting -Verbose
```

The obvious dependencies are:

- Git
- CMake (>= v3.20)
- C++ compiler of your choice

### PowerShell

Install PowerShell to run the `TerminalGames` module and the ScriptAnalyzer:

```ps1
Import-Module ./modules/TerminalGames.psd1
Test-CodeUsingPSScriptAnalyzer -Verbose
```

### Node

Install the Node (>= v22.12.0) dependencies using `npm install` to run the `cspell` and `prettier` linters:

```ps1
Import-Module ./modules/TerminalGames.psd1
Test-CodeUsingCSpell -Verbose
Test-CodeUsingPrettier -Verbose
```

### Generator

Any generator can be used to build the project but to run `clang-tidy`/`clang-format` CMake must be configured using a generator
that creates a `compile_commands.json` file in the build directory before running `clang-tidy`/`clang-format` (e.g.
`-G "Ninja"`, `-G "NMake Makefiles"`, etc)

### Clang

Install `clang-tidy` and `clang-format` (>= version 19.1.6). On windows you can download and run the `LLVM-19.1.6-win64.exe`
binary from the [LLVM release page](https://github.com/llvm/llvm-project/releases/tag/llvmorg-19.1.6) or use
[chocolatey](https://community.chocolatey.org/packages/llvm).

```cmd
clang-tidy [file] -p ./build
```

```cmd
clang-format --Werror --dry-run [file]
```

The `TerminalGames` module can be used to run `clang-tidy` and `clang-format` against the entire repository (with optional
parameters to fix any fixable errors):

```ps1
Import-Module ./modules/TerminalGames.psd1
Test-CodeUsingClang -FixClangTidyErrors -FixClangFormatErrors -Verbose
```

### IDE

On Windows, Visual Studio 2022 can be used by opening the folder as a CMake project and Visual Studio Code can be used by
opening the folder through the `Developer PowerShell for VS` (otherwise you may see errors around cl.exe not being found).
