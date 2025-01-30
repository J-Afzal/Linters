@{
    ModuleVersion = "1.0"

    NestedModules = @(
        "Helpers.psm1"
    )

    FunctionsToExport = @(
        "Assert-ExternalCommandError",
        "Test-CodeUsingAllLinters",
        "Test-CodeUsingClangTools",
        "Test-CodeUsingCSpell",
        "Test-CodeUsingPrettier",
        "Test-CodeUsingPSScriptAnalyzer",
        "Test-CSpellConfiguration",
        "Test-GitAttributesFile",
        "Test-GitIgnoreFile",
        "Test-PrettierIgnoreFile"
    )
}
