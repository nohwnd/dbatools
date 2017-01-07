$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = $here | Split-Path

$ManifestPath   = "$ModulePath\dbatools.psd1"

# test the module manifest - exports the right functions, processes the right formats, and is generally correct
Describe "Manifest" {
    BeforeAll {
        $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    It "passes through Test-ModuleManifest" { 
        Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue
    }

    ## Should be fixed now - Until the issue with requiring full paths for required assemblies is resolved need to keep this commented out RMS 01112016
    It "has a valid name" {
        $Manifest.Name | Should Be 'dbatools'
    }

    It "has a valid root module" {
        $Manifest.RootModule | Should Be "dbatools.psm1"
    }

    It "has a valid Description" {
        $Manifest.Description | Should Be 'Provides extra functionality for SQL Server Database admins and enables SQL Server instance migrations.'
    }

    It "has a valid Author" {
        $Manifest.Author | Should Be 'Chrissy LeMaire'
    }

    It "has a valid Company Name" {
        $Manifest.CompanyName | Should Be 'dbatools.io'
    }

    It "has a valid guid" {
        $Manifest.Guid | Should Be '9d139310-ce45-41ce-8e8b-d76335aa1789'
    }

    It "has valid PowerShell version" {
        $Manifest.PowerShellVersion | Should Be '3.0'
    }

    It "has valid  required assemblies" {
        $Manifest.RequiredAssemblies | Should Be @()
    }

    It "has a valid copyright" {
        $Manifest.CopyRight | Should Be '2016 Chrissy LeMaire'
    }


<#
 # Don't want this just yet

    It 'exports all public functions' {

        $FunctionFiles = Get-ChildItem "$ModulePath\functions" -Filter *.ps1 | Select -ExpandProperty BaseName

        $FunctionNames = $FunctionFiles

        $ExFunctions = $Manifest.ExportedFunctions.Values.Name
        $ExFunctions
        foreach ($FunctionName in $FunctionNames)

        {

            $ExFunctions -contains $FunctionName | Should Be $true

        }

    }
#>
}
