@{
    ModuleVersion = "1.0"

    NestedModules = @(
        "./linters-ps1/helpers/Helpers.psm1"
    )

    FunctionsToExport = @(
        "Assert-ExternalCommandError",
        "Test-CodeUsingAllLinters",
        "Test-CodeUsingClangTools",
        "Test-CodeUsingCSpell",
        "Test-CodeUsingPrettier",
        "Test-CodeUsingPSScriptAnalyzer",
        "Test-CSpellConfigurationFile",
        "Test-GitAttributesFile",
        "Test-GitIgnoreFile",
        "Test-PrettierIgnoreFile"
    )
}