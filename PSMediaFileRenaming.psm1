Add-Type @'
public enum PSMediaFileRenamingDateProperty
{
    ExifCreationTime,
    MediaCreationTime,
    CreationTime,
    LastWriteTime,
    LastAccessTime
}
'@

$variables = @{
    'PSMediaFileRenamingBitMapPropertyId'           = @(36867, 36868)
    'PSMediaFileRenamingItemDetailsPropertyId'      = @(12, 208)
    'PSMediaFileRenamingItemDetailsPropertyIdExif'  = 12
    'PSMediaFileRenamingItemDetailsPropertyIdMedia' = 208
}

foreach ($var in $variables.GetEnumerator())
{
    New-Variable -Name $var.Key -Value $var.Value -Scope Script -Force
}

$functionsDir = Join-Path -Path $PSScriptRoot -ChildPath 'Functions'
Get-ChildItem -LiteralPath $functionsDir -Filter '*.ps1' -Recurse | ForEach-Object -Process { . $_.PSPath }
Export-ModuleMember -Function * -Cmdlet * -Alias * -Variable @($variables.Keys)