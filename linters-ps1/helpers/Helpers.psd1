@{
    ModuleVersion = "1.0"

    NestedModules = @(
        "./ps1-linters/helpers/Helpers.psm1"
    )

    FunctionsToExport = @(
        "Assert-ExternalCommandError",
        "Test-CodeUsingAllLinters",
        "Test-CodeUsingClang",
        "Test-CodeUsingCSpell",
        "Test-CodeUsingPrettier",
        "Test-CodeUsingPSScriptAnalyzer",
        "Test-CSpellConfigurationFile",
        "Test-GitAttributesFile",
        "Test-GitIgnoreFile",
        "Test-PrettierIgnoreFile"
    )
}