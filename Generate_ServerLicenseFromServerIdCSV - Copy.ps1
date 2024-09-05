# Get the directory of the script
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the path to the License_Template.xml
$templatePath = Join-Path -Path $scriptDirectory -ChildPath "License_Template_UWS_6_0.xml"

# Check if the template file exists
if (-Not (Test-Path -Path $templatePath)) {
    Write-Host "Template file 'License_Template.xml' not found in the directory: $scriptDirectory"
    exit
}

# Get all CSV files in the script's directory
$csvFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.csv"

# Check if any CSV files were found
if ($csvFiles.Count -eq 0) {
    Write-Host "No CSV files found in the directory: $scriptDirectory"
    exit
}

# Loop through each CSV file
foreach ($csvFile in $csvFiles) {
    Write-Host "Processing file: $($csvFile.FullName)"

    # Load the XML template
    [xml]$xmlDocument = Get-Content -Path $templatePath

    # Initialize a list to store Server Identifiers
    $serverIdentifiers = @()

    # Import the CSV file
    $csvData = Get-Content -Path $csvFile.FullName

    # Skip the first row (header) and process the remaining rows
    for ($i = 1; $i -lt $csvData.Count; $i++) {
        $row = $csvData[$i]

        # Split the row by semicolon
        $values = $row -split ';' | ForEach-Object { $_.Trim() }

        # Check if there are enough columns to extract the Server Identifier
        if ($values.Length -gt 1) {
            # Get the last column (Server Identifier)
            $serverIdentifier = $values[-1]  # Get the last column

            # Remove quotes if present
            $serverIdentifier = $serverIdentifier -replace '^"|"$', ''

            # Add to the list if it's not null or empty
            if (![string]::IsNullOrEmpty($serverIdentifier)) {
                $serverIdentifiers += $serverIdentifier
            }
        }
    }

    # Join the Server Identifiers with a comma and a space
    $joinedIdentifiers = $serverIdentifiers -join ', '

    # Find the "Server" element and update the "Identifier" attribute
    $serverElement = $xmlDocument.SelectSingleNode("//Server") # Adjust the XPath if necessary
    if ($serverElement -ne $null) {
        $serverElement.SetAttribute("Identifier", $joinedIdentifiers)
    } else {
        Write-Host "Could not find the 'Server' element in the template XML."
    }

	
	# Define your desired prefix for the final license file
	$prefix = "License"

	# Extract everything after the first underscore in the original CSV file name
	$csvFileParts = [System.IO.Path]::GetFileNameWithoutExtension($csvFile.Name).Split('_')
	$csvFilePart = $csvFileParts[1..($csvFileParts.Length - 1)] -join '_'  # Join all parts after the first underscore	

	# Construct the output XML path using the prefix and the selected part of the CSV file name
	$outputXmlPath = Join-Path -Path $scriptDirectory -ChildPath ("{0}_{1}.xml" -f $prefix, $csvFilePart)

	# Save the XML document to the specified path
	$xmlDocument.Save($outputXmlPath)
	
	Write-Host "Updated results saved to: $outputXmlPath"
		
	# Assuming both scripts are in the same folder
	& ".\GenerateChecksum.ps1"
		
	# Create a new folder named after $csvFilePart
	$newFolderPath = Join-Path -Path $scriptDirectory -ChildPath $csvFilePart
	New-Item -ItemType Directory -Path $newFolderPath -Force

	# Copy the original CSV file to the new folder
	$csvCopyPath = Join-Path -Path $newFolderPath -ChildPath $csvFile.Name
	Copy-Item -Path $csvFile.FullName -Destination $csvCopyPath

	# Copy the created XML file to the new folder
	$xmlCopyPath = Join-Path -Path $newFolderPath -ChildPath ("{0}_{1}.xml" -f $prefix, $csvFilePart)
	Copy-Item -Path $outputXmlPath -Destination $xmlCopyPath

	# Check if both files were copied successfully
	$csvCopied = Test-Path $csvCopyPath
	$xmlCopied = Test-Path $xmlCopyPath

	if ($csvCopied -and $xmlCopied) {
		# Delete the original CSV file
		Remove-Item -Path $csvFile.FullName -Force

		# Delete the created XML file
		Remove-Item -Path $outputXmlPath -Force
	}

Pause
   
}
