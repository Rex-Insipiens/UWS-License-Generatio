import os
import xml.etree.ElementTree as ET
import glob
import shutil
import subprocess
import tkinter as tk
from tkinter import filedialog, messagebox

def select_input_files():
    """Open a file dialog to select CSV files."""
    files = filedialog.askopenfilenames(title="Select CSV files", filetypes=[("CSV Files", "*.csv")])
    return files

def select_output_directory():
    """Open a file dialog to select an output directory."""
    directory = filedialog.askdirectory(title="Select Output Directory")
    return directory

def process_files(csv_files, output_directory):
    """Process the selected CSV files and generate XML files."""
    # Define the path to the License_Template.xml
    template_path = os.path.join(os.path.dirname(__file__), "License_Template_UWS_6_0.xml")

    # Check if the template file exists
    if not os.path.exists(template_path):
        messagebox.showerror("Error", f"Template file 'License_Template.xml' not found.")
        return

    # Loop through each CSV file
    for csv_file in csv_files:
        print(f"Processing file: {csv_file}")

        # Load the XML template
        tree = ET.parse(template_path)
        xml_document = tree.getroot()

        # Initialize a list to store Server Identifiers
        server_identifiers = []

        # Import the CSV file
        with open(csv_file, 'r') as file:
            csv_data = file.readlines()

        # Skip the first row (header) and process the remaining rows
        for row in csv_data[1:]:
            # Split the row by semicolon and trim whitespace
            values = [value.strip() for value in row.split(';')]

            # Check if there are enough columns to extract the Server Identifier
            if len(values) > 1:
                # Get the last column (Server Identifier)
                server_identifier = values[-1].strip('"')

                # Add to the list if it's not null or empty
                if server_identifier:
                    server_identifiers.append(server_identifier)

        # Join the Server Identifiers with a comma and a space
        joined_identifiers = ', '.join(server_identifiers)

        # Find the "Server" element and update the "Identifier" attribute
        server_element = xml_document.find(".//Server")  # Adjust the XPath if necessary
        if server_element is not None:
            server_element.set("Identifier", joined_identifiers)
        else:
            print("Could not find the 'Server' element in the template XML.")

        # Define your desired prefix for the final license file
        prefix = "License"

        # Extract everything after the first underscore in the original CSV file name
        csv_file_parts = os.path.splitext(os.path.basename(csv_file))[0].split('_')
        csv_file_part = '_'.join(csv_file_parts[1:])  # Join all parts after the first underscore

        # Construct the output XML path using the prefix and the selected part of the CSV file name
        output_xml_path = os.path.join(output_directory, f"{prefix}_{csv_file_part}.xml")

        # Save the XML document to the specified path
        tree.write(output_xml_path)

        print(f"Updated results saved to: {output_xml_path}")

        # Execute the GenerateChecksum.ps1 script
        subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", os.path.join(os.path.dirname(__file__), "GenerateChecksum.ps1")])

        # Create a new folder named after csv_file_part
        new_folder_path = os.path.join(output_directory, csv_file_part)
        os.makedirs(new_folder_path, exist_ok=True)

        # Copy the original CSV file to the new folder
        csv_copy_path = os.path.join(new_folder_path, os.path.basename(csv_file))
        shutil.copy(csv_file, csv_copy_path)

        # Copy the created XML file to the new folder
        xml_copy_path = os.path.join(new_folder_path, f"{prefix}_{csv_file_part}.xml")
        shutil.copy(output_xml_path, xml_copy_path)

        # Check if both files were copied successfully
        csv_copied = os.path.exists(csv_copy_path)
        xml_copied = os.path.exists(xml_copy_path)

        if csv_copied and xml_copied:
            # Delete the original CSV file
            os.remove(csv_file)

            # Delete the created XML file
            os.remove(output_xml_path)

    messagebox.showinfo("Success", "Processing completed successfully!")

def main():
    """Main function to run the UI."""
    root = tk.Tk()
    root.title("CSV to XML Converter")

    # Hide the main window
    #root.withdraw()

    # Select input CSV files
    csv_files = select_input_files()
    if not csv_files:
        messagebox.showwarning("Warning", "No CSV files selected!")
        return

    # Select output directory
    output_directory = select_output_directory()
    if not output_directory:
        messagebox.showwarning("Warning", "No output directory selected!")
        return

    # Process the selected files
    process_files(csv_files, output_directory)

if __name__ == "__main__":
    main()
