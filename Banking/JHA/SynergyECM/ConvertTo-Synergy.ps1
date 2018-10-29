﻿# #############################################################################
# SYNERGY - REPORT CONVERTER
# NAME: ConvertTo-Synergy.ps1
#
# AUTHOR: Joshua Nasiatka
# DATE:   2018/02/05
#
# COMMENT:  This script will convert a text file to a Synergy-Formatted Report file
#
# VERSION HISTORY
# 1.0 2018.02.05 Initial Version.
#
##############################################################################

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [string]$ReportID, # Unique Report Indexing ID

    [Parameter(Mandatory=$false)]
    [string]$ReportDate, # Filing Date

    [Parameter(Mandatory=$false)]
    [int]$DateRow,

    [Parameter(Mandatory=$false)]
    [int]$DateRowStart,

    [Parameter(Mandatory=$false)]
    [int]$DateRowEnd,

    [Parameter(Mandatory=$true)]
    [string]$ReportName, #Report Name

    [Parameter(Mandatory=$true)]
    [string]$Subheading, # Add a second line to the heading of report

    [Parameter(Mandatory=$true)]
    [string]$FilePath, # Specify the path

    [Parameter(Mandatory=$true)]
    [string]$Destination, # Where to put finished repot

    [Parameter(Mandatory=$false)]
    [string]$BackupDir # Where to store backup of report file
)

############################### CONFIG SETTINGS ################################
$TempDir = "C:\Temp"                        # Report File Temp Working Directory
$date = Get-Date -Format "yyyyMMdd-hhmmss"  # Date Format of Report File Name
################################################################################

if (-not (Test-Path -Path $FilePath)) {
    Write-Warning "Report file not found."
    exit
}

if (-not (Test-Path -Path $Destination)) {
    Write-Warning "Unable to access report destination. Please verify location exists and that you have access to it."
    exit
}

# Read Report
$reportContents = Get-Content -Path $FilePath

if (-not $ReportDate) {
    if (-not $DateRow -or -not $DateRowStart -or -not $DateRowEnd) {
        $ReportDate = Get-Date([datetime]$reportContents[0].substring(0,10)) -Format "MM-dd-yy"
    } else {
        try {
            $ReportDate = Get-Date([datetime]$reportContents[$DateRow].substring($DateRowStart,$DateRowEnd)) -Format "MM-dd-yy"
        } catch {
            Write-Warning "Unable to parse date"
            exit
        }
    }
}

# Report Parms
$ReportFile = "$TempDir\REP_$($ReportID)_$($date).txt"
$global:Lines = 10
$global:maxLines = 65
$global:pageNumber = 2

# Add Header to Report File
"`r`n$ReportID`t`t`t`t`t`t`t$($ReportDate)`tPage 1`r`n" >> $ReportFile
"`t`t$ReportName`r`n`t`tGenerated by ConvertTo-Synergy.ps1`r`n`t`t$Subheading`r`n`r`n`r`n" >> $ReportFile

# Report Output
Function AddToReport {
    param([string]$Message)

    if ($global:Lines -eq $global:maxLines) {
        "`f`t" >> $ReportFile
        "$ReportID`t`t`t`t`t`t`t$($ReportDate)`tPage $global:pageNumber`r`n" >> $ReportFile
        $global:Lines = 4
        $global:pageNumber++
    } else { $global:Lines++ }
    $Message >> $ReportFile
}

$reportContents | ForEach-Object {
    AddToReport -Message $_
}

$asciiFile = "$TempDir\$($ReportID)_$($date)_REP.txt"
Get-Content $ReportFile | Out-File -Encoding ASCII -FilePath $asciiFile
Copy-Item -Path $asciiFile -Destination $Destination
if (Test-Path -Path $BackupDir) {
    Copy-Item -Path $asciiFile -Destination $BackupDir
}
Remove-Item -Path $ReportFile
Remove-Item -Path $asciiFile

# .\ConvertTo-Synergy.ps1 -ReportID "L2P-AUD-01" -ReportName "User Activity Log" -Subheading "Last 14 days" -FilePath "\\SERVER01\Share\_Audits\Activity\ActivityLog-01_21__2018-THRU-02_03_2018.txt" -Destination "\\SERVER02\Download"
