#Requires -Version 5.1

<#
.SYNOPSIS
PSMediaFileRenaming Helper function.

.NOTES
Author: nekrassov01
#>

function Get-DateTimeFromBitmap
{
    [CmdletBinding()]
    [OutputType([System.DateTime])]
    param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$FilePath,

        [Parameter(Position = 1, Mandatory = $false)]
        [int[]]$DatePropertyId = @(36867, 36868)
    )

    begin
    {
        try
        {
            $resultDateTime = $null

            $objImg = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $filePath -ErrorAction Stop

            if ($null -eq $objImg)
            {
                return $null
            }

            # Specify the Property ID. Probably, 36867 or 36868 is appropriate
            ($objImg.PropertyItems).Where{ $_.Id -in $datePropertyId }.ForEach{

                # If $resultDateTime is already set, do not execute it.
                # If it cannot be cast to DateTime, return null
                if ($null -eq $resultDateTime)
                {
                    # Convert ':' to '/'
                    $_.Value[4] = 47
                    $_.Value[7] = 47

                    $resultDateTime = [System.Text.Encoding]::ASCII.GetString($_.Value) -as [System.DateTime]
                    return $resultDateTime
                }
            }
        }
        catch
        {
            return $null
        }
        finally
        {
            if ($null -ne $objImg)
            {
                $objImg.Dispose()
            }
        }
    }
}
