#Requires -Version 5.1

<#
.SYNOPSIS
Get the ExifCreationTime and MediaCreationTime of the media file.

.NOTES
Author: nekrassov01
#>

function Get-MediaFileDateTime
{
    [CmdletBinding()]
    [OutputType([psobject[]])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo[]]$Path,

        [Parameter(Position = 1, Mandatory = $false)]
        [int[]]$BitMapPropertyId = $PSMediaFileRenamingBitMapPropertyId,

        [Parameter(Position = 2, Mandatory = $false)]
        [int[]]$ExifPropertyId = $PSMediaFileRenamingItemDetailsPropertyIdExif,

        [Parameter(Position = 3, Mandatory = $false)]
        [int[]]$MediaPropertyId = $PSMediaFileRenamingItemDetailsPropertyIdMedia,

        [Parameter(Position = 4, Mandatory = $false)]
        [switch]$Recurse
    )

    begin
    {
        Set-StrictMode -Version Latest

        $exifCreationTime  = $null
        $mediaCreationTime = $null
    }

    process
    {
        try
        {
            foreach ($p in $path)
            {
                $target = switch ($PSBoundParameters.ContainsKey('Recurse'))
                {
                    $true  { Get-ChildItem -LiteralPath $p -File -Recurse }
                    $false { Get-ChildItem -LiteralPath $p -File }
                }

                foreach ($t in $target)
                {
                    # Try to get the 'ExifCreationTime' using 'Get-DateTimeFromBitmap'
                    $exifCreationTime = Get-DateTimeFromBitmap -FilePath $t.FullName -DatePropertyId $bitMapPropertyId

                    # If 'Get-DateTimeFromBitmap' fails to get the 'ExifCreationTime', 'Get-DateTimeFromItemDetails' will try to get it.
                    if ($null -eq $exifCreationTime)
                    {
                        $exifCreationTime = Get-DateTimeFromItemDetails -FilePath $t.FullName -DatePropertyId $exifPropertyId
                    }

                    # Use 'Get-DateTimeFromItemDetails' to get 'MediaCreationTime'
                    $mediaCreationTime = Get-DateTimeFromItemDetails -FilePath $t.FullName -DatePropertyId $mediaPropertyId

                    $obj = [PSCustomObject]@{
                        FileInfo          = $t
                        ExifCreationTime  = $exifCreationTime
                        MediaCreationTime = $mediaCreationTime
                        CreationTime      = $t | Get-ItempropertyValue -Name 'CreationTime'
                        LastWriteTime     = $t | Get-ItempropertyValue -Name 'LastWriteTime'
                        LastAccessTime    = $t | Get-ItempropertyValue -Name 'LastAccessTime'
                    }

                    $PSCmdlet.WriteObject($obj)

                    $exifCreationTime =$null
                    $mediaCreationTime = $null
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }

    end
    {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        1 | ForEach-Object -Process { $_ } | Out-Null
        [System.GC]::Collect()
    }
}
