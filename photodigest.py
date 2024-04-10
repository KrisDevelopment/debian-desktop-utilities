import os
import sys
import hashlib

# -----------------------------------------------------
# This tool deletes duplicates of images in a directory
# -----------------------------------------------------

def collect_files(directory):
    # Check if the directory exists
    if not os.path.exists(directory):
        print(f"The directory '{directory}' does not exist.")
        return

    # Check if the directory is readable
    if not os.access(directory, os.R_OK):
        print(f"You do not have permission to access the directory '{directory}'.")
        return

    # Create an empty dictionary to store the hash values of the files
    hash_dict = {}

    # Use os.walk to traverse the directory and its subdirectories
    for root, dirs, files in os.walk(directory):
        for file in files:
            # Calculate the hash value of the file
            file_path = os.path.join(root, file)
            with open(file_path, "rb") as f:
                file_content = f.read()
                hash_value = hashlib.sha1(file_content).hexdigest()

            # Add the hash value and the file path to the hash_dict
            if hash_value in hash_dict:
                hash_dict[hash_value].append(file_path)
            else:
                hash_dict[hash_value] = [file_path]

    # Create a list of duplicate files
    duplicate_files = [files for files in hash_dict.values() if len(files) > 1]

    return duplicate_files

if len(sys.argv) < 2:
    print('Please provide the path to the directory containing the files.')
    sys.exit(1)

print(f'running for {sys.argv[1]}')

# Call the collect_files function with the path to the directory containing the files
duplicate_files = collect_files(sys.argv[1])

duplicates_count = 0
# Print the list of duplicate files
if duplicate_files:
    for files in duplicate_files:
        os.remove(files[1])
        print(f'removed {files[1]}')
        duplicates_count = duplicates_count + 1
else:
    print("No duplicate files were found.")

print(f'duplicates processed {duplicates_count}')