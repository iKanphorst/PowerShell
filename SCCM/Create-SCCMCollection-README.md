# SCCM Collection Creator from CSV

This PowerShell script creates an SCCM device collection and adds computers from a CSV file as direct members to that collection.

## Features

- Creates a new SCCM device collection with specified parameters
- Adds computers from a CSV file as direct members to the collection
- Supports file dialog selection for the CSV file
- Validates computer existence in SCCM before adding to collection
- Provides detailed summary of the operation

## Prerequisites

- SCCM Console installed on the machine running the script
- PowerShell 5.1 or higher
- Appropriate permissions to create collections and add members in SCCM
- CSV file containing computer names

## Installation

1. Download the `Create-SCCMCollectionFromCSV.ps1` script
2. Place it in a directory of your choice
3. Ensure you have a CSV file with computer names ready (see sample format below)

## Usage

### Basic Usage

```powershell
.\Create-SCCMCollectionFromCSV.ps1 -SiteCode "P01" -SiteServer "sccm.contoso.com" -CollectionName "Computers from CSV" -LimitingCollectionName "All Systems" -ComputerNameColumn "ComputerName"
```

This will open a file dialog to select the CSV file.

### Specifying CSV File Path

```powershell
.\Create-SCCMCollectionFromCSV.ps1 -SiteCode "P01" -SiteServer "sccm.contoso.com" -CollectionName "Computers from CSV" -LimitingCollectionName "All Systems" -CSVPath "C:\Temp\Computers.csv" -ComputerNameColumn "ComputerName"
```

### Full Example with All Parameters

```powershell
.\Create-SCCMCollectionFromCSV.ps1 -SiteCode "P01" -SiteServer "sccm.contoso.com" -CollectionName "Finance Computers" -CollectionFolderPath "DeviceCollection\Finance" -LimitingCollectionName "All Windows Workstations" -CSVPath "C:\Temp\FinanceComputers.csv" -ComputerNameColumn "ComputerName" -RefreshType "Periodic" -RefreshSchedule "Weekly"
```

## Parameters

| Parameter | Description | Required |
|-----------|-------------|----------|
| SiteCode | The site code of the SCCM site | Yes |
| SiteServer | The FQDN of the SCCM site server | Yes |
| CollectionName | The name for the new collection to be created | Yes |
| CollectionFolderPath | The folder path where the collection should be created (e.g., "DeviceCollection\MyFolder") | No |
| LimitingCollectionName | The name of the limiting collection for the new collection | Yes |
| CSVPath | The path to the CSV file containing the computer names. If not provided, a file dialog will open to select the file | No |
| ComputerNameColumn | The column name in the CSV file that contains the computer names | Yes |
| RefreshType | The refresh type for the collection. Valid values are "Manual", "Periodic", "Continuous", or "Both" | No (Default: "Manual") |
| RefreshSchedule | The schedule for periodic refresh (only used if RefreshType is "Periodic" or "Both"). Valid values are "Daily", "Weekly", or "Monthly" | No (Default: "Weekly") |

## Sample CSV Format

The script expects a CSV file with at least one column containing computer names. The column name should match the value provided in the `-ComputerNameColumn` parameter.

Example CSV format:

```csv
ComputerName,Description,Department
DESKTOP-001,Primary workstation,IT
DESKTOP-002,Developer workstation,Development
DESKTOP-003,Finance workstation,Finance
LAPTOP-001,IT Admin laptop,IT
LAPTOP-002,Executive laptop,Executive
```

A sample CSV file (`SampleComputers.csv`) is included with this script.

## Notes

- The script will check if computers exist in SCCM before adding them to the collection
- If a collection with the specified name already exists, the script will use that collection instead of creating a new one
- The script provides a summary of the operation, including the number of computers successfully added, already in the collection, and failed to add

## Troubleshooting

- Ensure the SCCM console is installed on the machine running the script
- Verify you have appropriate permissions in SCCM
- Check that the limiting collection exists
- Ensure the CSV file is properly formatted and contains the specified column name
- If using a file path, make sure the path is accessible
