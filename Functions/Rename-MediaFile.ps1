#Requires -Version 5.1

<#
.SYNOPSIS
Using the Bitmap class and ComObject to get the datetime when the image was taken and the datetime when the video file was created.
Combine them with sequential numbers to generate and rename the file names.
A single Cmdlet can be used to batch convert the names of media files.

.NOTES
Author: nekrassov01
#>

function Rename-MediaFile
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([System.IO.FileInfo[]])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo[]]$Path,

        [Parameter(Position = 1, Mandatory = $false)]
        [PSMediaFileRenamingDateProperty]$PrimaryDateProperty = [PSMediaFileRenamingDateProperty]::ExifCreationTime,

        [Parameter(Position = 2, Mandatory = $false)]
        [PSMediaFileRenamingDateProperty]$SecondaryDateProperty = [PSMediaFileRenamingDateProperty]::CreationTime,

        [Parameter(Position = 3, Mandatory = $false)]
        [string]$DateFormat = 'yyyyMMddHHmmss',

        [Parameter(Position = 4, Mandatory = $false)]
        [string]$FileNameFormat = '{0}-{1}',

        [Parameter(Position = 5, Mandatory = $false)]
        [int]$IncrementLimit = 999,

        [Parameter(Position = 6, Mandatory = $false)]
        [int[]]$BitMapPropertyId = $PSMediaFileRenamingBitMapPropertyId,

        [Parameter(Position = 7, Mandatory = $false)]
        [int[]]$ExifPropertyId = $PSMediaFileRenamingItemDetailsPropertyIdExif,

        [Parameter(Position = 8, Mandatory = $false)]
        [int[]]$MediaPropertyId = $PSMediaFileRenamingItemDetailsPropertyIdMedia,

        [Parameter(Position = 9, Mandatory = $false)]
        [switch]$Recurse
    )

    begin
    {
        Set-StrictMode -Version Latest
    }

    process
    {
        try
        {
            foreach ($p in $path)
            {
                $mediaFiles = if ($PSBoundParameters.ContainsKey('Recurse'))
                {
                    (Get-MediaFileDateTime -Path $p -BitMapPropertyId $BitMapPropertyId -ExifPropertyId $ExifPropertyId -MediaPropertyId $MediaPropertyId -Recurse)
                }
                else
                {
                    (Get-MediaFileDateTime -Path $p -BitMapPropertyId $BitMapPropertyId -ExifPropertyId $ExifPropertyId -MediaPropertyId $MediaPropertyId)
                }

                foreach ($m in $mediaFiles)
                {
                    if ($m.$primaryDateProperty -is [System.DateTime])
                    {
                        $dateString = ($m.$primaryDateProperty | Get-Date).ToString($dateFormat)
                    }
                    else
                    {
                        if ($m.$secondaryDateProperty -is [System.DateTime])
                        {
                            $dateString = ($m.$secondaryDateProperty | Get-Date).ToString($dateFormat)
                        }
                        else
                        {
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                [System.Management.Automation.PSArgumentNullException]::new(),
                                'InvalidData',
                                [System.Management.Automation.ErrorCategory]::InvalidData,
                                $m
                            )
                            $PSCmdlet.ThrowTerminatingError($errorRecord)
                        }
                    }

                    $extension = [System.IO.Path]::GetExtension($m.FileInfo.FullName)
                    $format = $FileNameFormat.Replace('{0}', $dateString).Replace('{1}', '{0}')

                    $serialObj = Get-FileNameWithLatestSerialNumber -TargetDirectory $m.FileInfo.Directory.FullName -Limit $IncrementLimit -Format $format -Extension $extension
                    $SerialNumber = $serialObj.SerialNumber

                    $newName = ([System.String]::Format($FileNameFormat, $dateString, $serialNumber)), $extension -join $null
                    
                    if ($PSCmdlet.ShouldProcess($m.FileInfo.FullName, $($PSCmdlet.MyInvocation.MyCommand, $newName) -join ': '))
                    {
                        $obj = Rename-Item -Path $m.FileInfo.FullName -NewName $newName -Force -PassThru -Confirm:$false -WhatIf:$false
                        $PSCmdlet.WriteObject($obj)
                    }
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
