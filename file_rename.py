import os
import argparse

def rename_files(folder_path):
    # Get a list of all files in the folder
    files = os.listdir(folder_path)

    # Sort the files to ensure they are processed in order
    files.sort()

    # Iterate through the files and rename them
    for index, file_name in enumerate(files):
        # Split the file name and extension
        name, ext = os.path.splitext(file_name)

        # Create the new file name with the incremented number
        new_name = f'{index + 1}{ext}'

        # Construct the full paths for the old and new names
        old_path = os.path.join(folder_path, file_name)
        new_path = os.path.join(folder_path, new_name)

        # Rename the file
        os.rename(old_path, new_path)

    print('Files renamed successfully.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Rename files in a folder.')
    parser.add_argument('folder_path', help='Path to the folder containing files to be renamed.')

    args = parser.parse_args()

    rename_files(args.folder_path)

