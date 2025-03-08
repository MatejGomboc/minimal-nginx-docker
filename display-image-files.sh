#!/bin/bash
# Script to display the file structure of the minimal-nginx Docker image

echo "Generating tree view of files in minimal-nginx Docker image..."
echo

# Create a container from the minimal-nginx image
CONTAINER_ID=$(docker create minimal-nginx)

# Create a temporary script to generate the tree structure
cat > /tmp/tree-script.sh << 'EOF'
#!/bin/sh

# Function to display directory tree
print_tree() {
    local dir=$1
    local prefix=$2
    local first_prefix=$3
    local files=$(find "$dir" -maxdepth 1 -mindepth 1 | sort)
    
    local count=0
    local total=$(echo "$files" | wc -l)
    
    for file in $files; do
        count=$((count + 1))
        
        # Skip if parent directory or current directory
        if [ "$file" = "." ] || [ "$file" = ".." ]; then
            continue
        fi
        
        # Prepare the correct prefix for current item
        if [ "$count" = "$total" ]; then
            new_prefix="$prefix└── "
            next_prefix="$prefix    "
        else
            new_prefix="$prefix├── "
            next_prefix="$prefix│   "
        fi
        
        # Get the base filename
        base=$(basename "$file")
        
        # Display the file/directory
        echo "$first_prefix$new_prefix$base"
        
        # If it's a directory, recursively print its contents
        if [ -d "$file" ]; then
            print_tree "$file" "$next_prefix" ""
        fi
    done
}

# Start the tree view from root (/)
echo "/"
print_tree "/" "" ""
EOF

# Make the script executable
chmod +x /tmp/tree-script.sh

# Run Alpine container with the filesystem from minimal-nginx
docker run --rm -it --volumes-from $CONTAINER_ID -v /tmp/tree-script.sh:/tree-script.sh alpine:latest /tree-script.sh

# Clean up
docker rm $CONTAINER_ID
rm /tmp/tree-script.sh

echo
echo "Tree view generation complete!"