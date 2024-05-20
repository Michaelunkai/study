#!/bin/bash

prompt_for_path() {
    local path

    read -p "Enter the name of the file or folder in the current path: " path

    if [[ -z $path ]]; then
        printf "No path provided.\n" >&2
        return 1
    fi

    if [[ ! -e $path ]]; then
        printf "File or folder does not exist.\n" >&2
        return 1
    fi

    if [[ -d $path ]]; then
        delete_and_remake_folder "$path"
    elif [[ -f $path ]]; then
        delete_and_remake_file "$path"
    else
        printf "Path is neither a file nor a folder.\n" >&2
        return 1
    fi
}

delete_and_remake_file() {
    local file_path=$1

    local file_content
    if ! file_content=$(cat "$file_path"); then
        printf "Failed to read the file content.\n" >&2
        return 1
    fi

    if ! rm -f "$file_path"; then
        printf "Failed to delete the file.\n" >&2
        return 1
    fi

    sleep 10

    if ! printf "%s" "$file_content" > "$file_path"; then
        printf "Failed to recreate the file.\n" >&2
        return 1
    fi

    printf "File %s has been successfully recreated.\n" "$file_path"
}

delete_and_remake_folder() {
    local folder_path=$1

    local folder_content
    if ! folder_content=$(tar -cf - -C "$folder_path" .); then
        printf "Failed to read the folder content.\n" >&2
        return 1
    fi

    if ! rm -rf "$folder_path"; then
        printf "Failed to delete the folder.\n" >&2
        return 1
    fi

    sleep 10

    if ! mkdir -p "$folder_path"; then
        printf "Failed to recreate the folder.\n" >&2
        return 1
    fi

    if ! tar -xf - -C "$folder_path" <<< "$folder_content"; then
        printf "Failed to restore the folder content.\n" >&2
        return 1
    fi

    printf "Folder %s has been successfully recreated.\n" "$folder_path"
}

main() {
    prompt_for_path
}

main "$@"
