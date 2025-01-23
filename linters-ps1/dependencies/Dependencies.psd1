@{
    ModuleVersion = "1.0"

    NestedModules = @(
        "./ps1-linters/dependencies/Dependencies.psm1"
    )

    FunctionsToExport = @(
        "Install-BuildDependencies",
        "Install-LintingDependencies"
    )
}
