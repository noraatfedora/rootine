import os

def rename_files_in_folders(base_directory):
    # Get a list of all folders in the base directory
    for folder_name in sorted(os.listdir(base_directory)):
        folder_path = os.path.join(base_directory, folder_name)

        # Ensure it's a folder
        if os.path.isdir(folder_path):
            # Get all files in the folder and sort them alphabetically
            files = sorted(os.listdir(folder_path))

            # Rename files to 1.png, 2.png, etc.
            for index, file_name in enumerate(files, start=1):
                old_file_path = os.path.join(folder_path, file_name)
                new_file_name = f"{index}.png"
                new_file_path = os.path.join(folder_path, new_file_name)

                # Rename the file
                os.rename(old_file_path, new_file_path)
                print(f"Renamed: {old_file_path} -> {new_file_path}")

# Base directory containing the folders
base_directory = "."

# Call the function
rename_files_in_folders(base_directory)