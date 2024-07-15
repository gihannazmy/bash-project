#!/bin/bash

# Function to check if the name follows table naming rules
is_valid_name() {
    local name=$1
    # Check if the name starts with a letter, contains only alphanumeric characters and underscores, and is up to 30 characters long
    if [[ $name =~ ^[a-zA-Z][a-zA-Z0-9_]{0,29}$ ]]; then
        return 0  # Valid name
    else
        return 1  # Invalid name
    fi
}

# Function to create the table file with specified fields
create_table() {
    local table_name=$1
    local num_fields=$2
    local fields=()

    for ((i=1; i<=num_fields; i++)); do
        read -p "Enter name for field $i: " field_name
        read -p "Enter data type for field $i (e.g., int, varchar, etc.): " field_type
        read -p "Is this field a primary key? (yes/no): " is_primary_key

        if [[ $is_primary_key == "yes" ]]; then
            fields+=("$field_name $field_type PRIMARY KEY")
        else
            fields+=("$field_name $field_type")
        fi
    done

    # Create the table file with the fields as header
    echo "${fields[*]}" > "${table_name}"  # Assuming .tbl extension for table files
    if [ $? -eq 0 ]; then
        echo "The table '$table_name' with $num_fields fields has been created successfully."
    else
        echo "Failed to create the table '$table_name'."
    fi
}
# Function to read the table's field definitions
get_table_fields() {
    local table_name=$1
    head -n 1 "$table_name"
}

# Function to insert values into the table
insert_into_table() {
    local table_name=$1
    local fields=($(get_table_fields "$table_name"))
    local values=()

    for field in "${fields[@]}"; do
        read -p "Enter value for $field: " value
        values+=("$value")
    done

    # Append the values to the table file
    echo "${values[*]}" >> "$table_name"
    echo "Values have been inserted into the table '$table_name' successfully."
}

# Function to select data from the table
select_from_table() {
    local table_name=$1
    local fields=($(get_table_fields "$table_name"))
    local criteria
    read -p "Enter selection criteria (e.g., field_name=value): " criteria

    # Extract field and value from criteria
    local field=$(echo "$criteria" | cut -d '=' -f 1)
    local value=$(echo "$criteria" | cut -d '=' -f 2)

    if [[ " ${fields[*]} " =~ " $field " ]]; then
        # Print header
        echo "${fields[*]}"
        # Print rows matching the criteria
        while IFS= read -r line; do
            if [[ "$line" == *"$value"* ]]; then
                echo "$line"
            fi
        done < "$table_name"
    else
        echo "Invalid field name in criteria."
    fi
}

# Function to delete data from the table
delete_from_table() {
    local table_name=$1
    local fields=($(get_table_fields "$table_name"))
    local criteria
    read -p "Enter deletion criteria (e.g., field_name=value): " criteria

    # Extract field and value from criteria
    local field=$(echo "$criteria" | cut -d '=' -f 1)
    local value=$(echo "$criteria" | cut -d '=' -f 2)

    if [[ " ${fields[*]} " =~ " $field " ]]; then
        # Create a temporary file to store the new data
        local temp_file="${table_name}.tmp"
        # Print header to the temporary file
        echo "${fields[*]}" > "$temp_file"
        # Copy rows that do not match the criteria to the temporary file
        while IFS= read -r line; do
            if [[ "$line" != *"$value"* ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$table_name"
        # Replace the original file with the temporary file
        mv "$temp_file" "$table_name"
        echo "Rows matching the criteria have been deleted from '$table_name'."
    else
        echo "Invalid field name in criteria."
    fi
}

# Function to update data in the table
update_table() {
    local table_name=$1
    local fields=($(get_table_fields "$table_name"))
    local criteria
    read -p "Enter update criteria (e.g., field_name=value): " criteria
    local update_field
    read -p "Enter the field to update: " update_field
    local update_value
    read -p "Enter the new value: " update_value

    # Extract field and value from criteria
    local field=$(echo "$criteria" | cut -d '=' -f 1)
    local value=$(echo "$criteria" | cut -d '=' -f 2)

    if [[ " ${fields[*]} " =~ " $field " && " ${fields[*]} " =~ " $update_field " ]]; then
        # Create a temporary file to store the new data
        local temp_file="${table_name}.tmp"
        # Print header to the temporary file
        echo "${fields[*]}" > "$temp_file"
        # Update rows that match the criteria
        while IFS= read -r line; do
            if [[ "$line" == *"$value"* ]]; then
                local new_line=$(echo "$line" | sed "s/.*$field.*/$update_value/")
                echo "$new_line" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$table_name"
        # Replace the original file with the temporary file
        mv "$temp_file" "$table_name"
        echo "Rows matching the criteria have been updated in '$table_name'."
    else
        echo "Invalid field name in criteria or update field."
    fi
}

# Main menu loop
select choice in create list drop insert-into select-from delete-from update exit
do
    case $choice in
        "create")
            read -p "Enter the table name that you wish to create: " table_name
            if is_valid_name "$table_name"; then
                read -p "Enter the number of fields in the table: " num_fields
                if [[ $num_fields =~ ^[0-9]+$ && $num_fields -gt 0 ]]; then
                    create_table "$table_name" "$num_fields"
                    read -p "Do you want to continue? (y/n): " continue_choice
                    if [[ "$continue_choice" != "y" ]]; then
                        break
                       
                    fi
                else
                    echo "Invalid number of fields. Please enter a positive integer."
                fi
            else
                echo "Invalid table name. The name must start with a letter, contain only alphanumeric characters and underscores, and be up to 30 characters long."
            fi
            ;;
        "list")
            ls
            read -p "Press any key to continue..."
            ;;
	"drop")
	    read -p "Enter the table name that you wish to drop: " table_name
	    if is_valid_name "$table_name"; then
		if [ -d "$table_name" ]; then
		    read -p "The name '$table_name' is a directory. Do you want to delete it? (y/n): " confirm
		    if [ "$confirm" = "y" ]; then
		        rm -r "$table_name"
		        echo "The directory '$table_name' has been deleted successfully."
		    else
		        echo "Directory deletion aborted."
		    fi
		elif [ -e "$table_name" ]; then
		    rm "$table_name"
		    echo "The table '$table_name' has been dropped successfully."
		else
		    echo "The table '$table_name' does not exist."
		fi
                read -p "Do you want to continue? (y/n): " continue_choice
                if [[ "$continue_choice" != "y" ]]; then
                    break
                fi
	    else
		echo "Invalid table name. The name must start with a letter, contain only alphanumeric characters and underscores, and be up to 30 characters long."
	    fi
	    ;;

        "insert-into")
            read -p "Enter the table name that you wish to insert into: " table_name
            if is_valid_name "$table_name" && [ -e "$table_name" ]; then
                insert_into_table "$table_name"
                read -p "Do you want to continue? (y/n): " continue_choice
                if [[ "$continue_choice" != "y" ]]; then
                    break
                fi
            else
                echo "Invalid table name or the table does not exist."
            fi
            ;;
        "select-from")
            read -p "Enter the table name that you wish to select from: " table_name
            if is_valid_name "$table_name" && [ -e "$table_name" ]; then
                select_from_table "$table_name"
                read -p "Press any key to continue..."
            else
                echo "Invalid table name or the table does not exist."
            fi
            ;;
        "delete-from")
            read -p "Enter the table name that you wish to delete from: " table_name
            if is_valid_name "$table_name" && [ -e "$table_name" ]; then
                delete_from_table "$table_name"
                read -p "Do you want to continue? (y/n): " continue_choice
                if [[ "$continue_choice" != "y" ]]; then
                    break
                fi
            else
                echo "Invalid table name or the table does not exist."
            fi
            ;;
        "update")
            read -p "Enter the table name that you wish to update: " table_name
            if is_valid_name "$table_name" && [ -e "$table_name" ]; then
                update_table "$table_name"
                read -p "Do you want to continue? (y/n): " continue_choice
                if [[ "$continue_choice" != "y" ]]; then
                    break
                fi
            else
                echo "Invalid table name or the table does not exist."
            fi
            ;;
        "exit")
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done

