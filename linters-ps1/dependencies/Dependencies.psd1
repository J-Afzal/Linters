@{
    ModuleVersion = "1.0"

    NestedModules = @(
        "./linters-ps1/dependencies/Dependencies.psm1"
    )

    FunctionsToExport = @(
        "Install-LintingDependencies"
    )
}
