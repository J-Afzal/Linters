BeforeAll {
    Import-Module ./linters-powershell/modules/Helpers.psm1 -Force
    Import-Module ./linters-powershell/modules/Doxygen.psm1 -Force
}

Describe 'Test-DoxygenDocumentation' {
    It 'Given no Doxyfile, it should return -1' {
        Mock -ModuleName Doxygen -CommandName Test-Path -MockWith { return $false } -ParameterFilter {"./Doxyfile"}
        Test-DoxygenDocumentation | Should -BeExactly -1
    }

    It 'Given a Doxyfile, it should return 0' {
        Mock -ModuleName Doxygen -CommandName Test-Path -MockWith { return $true } -ParameterFilter {"./Doxyfile"}
        Test-DoxygenDocumentation | Should -BeExactly 0
    }

    It 'Given a Doxyfile and ResetLocalGitChanges parameter passed, it should invoke git clean and return 0' {
        Mock -ModuleName Doxygen -CommandName Test-Path -MockWith { return $true } -ParameterFilter { -LiteralPath "./Doxyfile" }

        Mock -ModuleName Doxygen -CommandName Invoke-ExternalCommand -MockWith { throw } -ParameterFilter { -ExternalCommand "git" }

        Test-DoxygenDocumentation -ResetLocalGitChanges | Should -BeExactly 0
    }


    # It 'Given a Doxyfile, it should call all external commands and return null' {
    #     Mock Test-Path { }
    #     Mock Invoke-ExternalCommand { return }

    #     Test-DoxygenDocumentation | Should -BeNullOrEmpty
    # }


    # Context 'When there is a DoxyFile' {
    #     BeforeAll {
    #         Mock Test-Path { return $true }
    #     }

    #     It 'Given no DoxyFile, it should return null' {
    #         Test-DoxygenDocumentation | Should -BeNullOrEmpty
    #     }
    # }
}
