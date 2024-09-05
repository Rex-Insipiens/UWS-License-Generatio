# Define the folder containing the files to process
$sourceFolder = Split-Path -Parent $MyInvocation.MyCommand.Path  # Change this to your source folder path

# Define the folder containing the executable
$exeFolder = "C:\Users\mdjelassi\OneDrive - Philips\TOOLS\LicenseFileSignature_2_2_0_398333"  # Change this to your executable folder path

# Define the prefix that the files must start with
$filePrefix = "License"  # Change this to the desired prefix

# Get the path of the executable
$exePath = Join-Path -Path $exeFolder -ChildPath "LicenseFileSignature.exe"  # Change this to your executable name

# Check if the executable exists
if (-Not (Test-Path -Path $exePath)) {
    Write-Host "Executable not found at: $exePath"
    exit 1  # Exit the script with an error code
}

# Get all XML files in the source folder that start with the specified prefix
$xmlFiles = Get-ChildItem -Path $sourceFolder -Filter "$filePrefix*.xml"  # Get XML files starting with the prefix

# Check if any XML files were found
if ($xmlFiles.Count -eq 0) {
    Write-Host "No XML files found starting with '$filePrefix' in the folder: $sourceFolder"
    exit 0  # Exit the script gracefully
}

# Loop through each XML file found
foreach ($file in $xmlFiles) {
    Write-Host "Processing file: $($file.FullName)"  # Output the name of the file being processed

    # Run the executable with the current XML file as an argument
    & $exePath $file.FullName  # Use the call operator '&' to run the executable with the XML file as an argument

    # Check if the executable ran successfully
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully processed: $($file.Name)"  # Output success message
    } else {
        Write-Host "Failed to process: $($file.Name)"  # Output failure message
    }
}
