# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

##
# Build: Install given packages in given environments
##
param (
  [string[]] $PackageDirs,
  [string[]] $EnvNames
)

Import-Module (Join-Path $PSScriptRoot "conda-utils.psm1");

if ($null -eq $PackageDirs) {
  $ParentPath = Split-Path -parent $PSScriptRoot
  $PackageDirs = Get-ChildItem -Path $ParentPath -Recurse -Filter "environment.yml" | Select-Object -ExpandProperty Directory | Split-Path -Leaf
  Write-Host "##[info]No PackageDir. Setting to default '$PackageDirs'"
}

if ($null -eq $EnvNames) {
  $EnvNames = $PackageDirs | ForEach-Object {$_.replace("-", "")}
  Write-Host "##[info]No EnvNames. Setting to default '$EnvNames'"
}

# Check that input is valid
if ($EnvNames.length -ne $PackageDirs.length) {
  throw "Cannot run build script: '$EnvNames' and '$PackageDirs' lengths don't match"
}

function Install-Package() {
  param(
    [string] $EnvName,
    [string] $PackageDir
  )
  $ParentPath = Split-Path -parent $PSScriptRoot
  $AbsPackageDir = Join-Path $ParentPath $PackageDir
  Write-Host "##[info]Install package $AbsPackageDir in development mode for env $EnvName"
  # Set environment vars to be able to run conda activate.
  Enable-Conda
  # Activate env
  conda activate $EnvName
  Get-PythonConfiguration | Write-Verbose
  # Install package
  pip install -e $AbsPackageDir
}


for ($i=0; $i -le $PackageDirs.length-1; $i++) {
  Install-Package -EnvName $EnvNames[$i] -PackageDir $PackageDirs[$i]
}
