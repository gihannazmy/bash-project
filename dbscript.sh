#!/bin/bash

# Function to check if the name follows database naming rules
is_valid_name() {
    local name=$1
    # Check if the name starts with a letter, contains only alphanumeric characters and underscores, and is up to 30 characters long
    if [[ $name =~ ^[a-zA-Z][a-zA-Z0-9_]{0,29}$ ]]; then
        return 0  # Valid name
    else
        return 1  # Invalid name
    fi
}

# Check if 'db' directory exists, create it if it doesn't
if [ ! -d "db" ]; then
    mkdir "db" || { echo "Failed to create directory 'db'"; exit 1; }
    echo "Directory 'db' created."
fi

# Change to 'db' directory
cd "db" || { echo "Failed to change directory to 'db'"; exit 1; }

select choice in create drop show connect exit
do 
    case $choice in 
        "create")
            read -p "Enter the database name that you wish to create: " db_name
            if is_valid_name "$db_name"; then
                if [ -d "$db_name" ]; then
                    echo "Database '$db_name' already exists."
                else
                    mkdir "$db_name" || { echo "Failed to create directory '$db_name'"; exit 1; }
                    echo "Database '$db_name' created successfully."
                fi
            else
                echo "Invalid database name. The name must start with a letter, contain only alphanumeric characters and underscores, and be up to 30 characters long."
            fi
            ;;
        "drop")
            read -p "Enter the database name that you wish to drop: " db_name
            if is_valid_name "$db_name"; then
                if [ -d "$db_name" ]; then
                    read -p "Are you sure you want to drop '$db_name'? This action cannot be undone. (y/n): " confirm
                    if [ "$confirm" = "y" ]; then
                        rm -r "$db_name" || { echo "Failed to drop database '$db_name'"; exit 1; }
                        echo "The database '$db_name' has been dropped successfully."
                    else
                        echo "Database deletion aborted."
                    fi
                else
                    echo "The database '$db_name' does not exist."
                fi
            else
                echo "Invalid database name. The name must start with a letter, contain only alphanumeric characters and underscores, and be up to 30 characters long."
            fi
            ;;
        "show")
            # List all directories ending with "/"
            echo "Existing databases:"
            ls -F | grep '/$'
            ;;
        "connect")
            read -p "Enter the database name that you want to connect to: " db_name
            if is_valid_name "$db_name"; then
                if [ -d "$db_name" ]; then
                    cd "$db_name" || { echo "Failed to connect to '$db_name'"; exit 1; }
                    echo "Connected to '$db_name'"
                    
                    # Call another script here
                    ./tablescript.sh
                else
                    echo "The database '$db_name' does not exist."
                fi
            else
                echo "Invalid database name. The name must start with a letter, contain only alphanumeric characters and underscores, and be up to 30 characters long."
            fi
            ;;
        "exit")
            break
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac
    read -p "Press Enter to continue..."
done

