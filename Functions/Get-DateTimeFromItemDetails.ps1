#Requires -Version 5.1

<#
.SYNOPSIS
PSMediaFileRenaming Helper function.

.NOTES
Author: nekrassov01
#>

function Get-DateTimeFromItemDetails
{
    [CmdletBinding()]
    [OutputType([System.DateTime])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$FilePath,

        [Parameter(Position = 1, Mandatory = $true)]
        [int[]]$DatePropertyId,

        [Parameter(Position = 2, Mandatory = $false)]
        [switch]$Inspect
    )

    begin
    {
        try
        {
            $resultDateTime = $null

            if ($null -eq (Get-Variable -Name objShell -ErrorAction Ignore))
            {
                $objShell = New-Object -COMObject Shell.Application -ErrorAction Stop
            }

            $targetFolder = Split-Path -Path $filePath -Parent
            $targetFile = Split-Path -Path $filePath -Leaf

            $objShellFolder = $objShell.NameSpace($targetFolder)
            $objShellFile = $objShellFolder.ParseName($targetFile)

            $datePropertyId.ForEach{

                $propertyName  = $objShellFolder.GetDetailsOf($Null, $_)
                $propertyValue = $objShellFolder.GetDetailsOf($objShellFile, $_)

                if ($PSBoundParameters.ContainsKey('Inspect'))
                {
                    return [PSCustomObject]@{
                        Index = $_
                        Name  = $propertyName 
                        Value = $propertyValue
                    }
                }

                # Combine strings and cast them to DateTime
                if (-not [System.String]::IsNullOrEmpty($propertyValue))
                {
                    $splitedValue = $propertyValue.Split(' ')
        
                    $yyyy = $splitedValue[0].Substring(1,4)
                    $MM   = $splitedValue[0].Substring(7,2)
                    $dd   = $splitedValue[0].Substring(11,2)
        
                    if ($splitedValue[1].Length -eq 6)
                    {
                        $HH = '0' + $splitedValue[1].Substring(2,1)
                        $mi = $splitedValue[1].Substring(4,2)
                    }
        
                    if ($splitedValue[1].Length -eq 7)
                    {
                        $HH = $splitedValue[1].Substring(2,2)
                        $mi = $splitedValue[1].Substring(5,2)
                    }
        
                    $ss = '00'

                    if ($null -eq $resultDateTime)
                    {
                        $resultDateTime = [System.DateTime]::ParseExact($yyyy+$MM+$dd+$HH+$mi+$ss, 'yyyyMMddHHmmss', $null)
                        
                        if ($null -ne $resultDateTime)
                        {
                            return $resultDateTime
                        }
                    } 
                }
            }
        }
        catch
        {
            return $null
        }
        finally
        {
            # Clear the variable referring to __ComObject.
            Get-Variable | Where-Object -FilterScript { $_.Value -is [__ComObject]} | Clear-Variable -WhatIf:$false

            # Release __ComObject.
            if ($null -ne $objShell)
            {
                [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($objShell)
            }

            # When called by the parent, memory is not collected by this function. It will be collected by the parent.
            if ([system.string]::IsNullOrEmpty($MyInvocation.ScriptName))
            {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                1 | ForEach-Object -Process { $_ } | Out-Null
                [System.GC]::Collect()
            }
        }
    }
}