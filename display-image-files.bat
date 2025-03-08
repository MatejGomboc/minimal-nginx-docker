@echo off
setlocal enabledelayedexpansion

echo Generating tree view of files in minimal-nginx Docker image...
echo.

REM Create a container from the minimal-nginx image
for /f "tokens=*" %%a in ('docker create minimal-nginx') do set CONTAINER_ID=%%a

REM Create a temporary script file
echo #!/bin/sh > %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo # Function to display directory tree >> %TEMP%\tree-script.sh
echo print_tree() { >> %TEMP%\tree-script.sh
echo     local dir=$1 >> %TEMP%\tree-script.sh
echo     local prefix=$2 >> %TEMP%\tree-script.sh
echo     local first_prefix=$3 >> %TEMP%\tree-script.sh
echo     local files=$(find "$dir" -maxdepth 1 -mindepth 1 ^| sort) >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo     local count=0 >> %TEMP%\tree-script.sh
echo     local total=$(echo "$files" ^| wc -l) >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo     for file in $files; do >> %TEMP%\tree-script.sh
echo         count=$((count + 1)) >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo         # Skip if parent directory or current directory >> %TEMP%\tree-script.sh
echo         if [ "$file" = "." ] ^|^| [ "$file" = ".." ]; then >> %TEMP%\tree-script.sh
echo             continue >> %TEMP%\tree-script.sh
echo         fi >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo         # Prepare the correct prefix for current item >> %TEMP%\tree-script.sh
echo         if [ "$count" = "$total" ]; then >> %TEMP%\tree-script.sh
echo             new_prefix="$prefix└── " >> %TEMP%\tree-script.sh
echo             next_prefix="$prefix    " >> %TEMP%\tree-script.sh
echo         else >> %TEMP%\tree-script.sh
echo             new_prefix="$prefix├── " >> %TEMP%\tree-script.sh
echo             next_prefix="$prefix│   " >> %TEMP%\tree-script.sh
echo         fi >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo         # Get the base filename >> %TEMP%\tree-script.sh
echo         base=$(basename "$file") >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo         # Display the file/directory >> %TEMP%\tree-script.sh
echo         echo "$first_prefix$new_prefix$base" >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo         # If it's a directory, recursively print its contents >> %TEMP%\tree-script.sh
echo         if [ -d "$file" ]; then >> %TEMP%\tree-script.sh
echo             print_tree "$file" "$next_prefix" "" >> %TEMP%\tree-script.sh
echo         fi >> %TEMP%\tree-script.sh
echo     done >> %TEMP%\tree-script.sh
echo } >> %TEMP%\tree-script.sh
echo. >> %TEMP%\tree-script.sh
echo # Start the tree view from root (/) >> %TEMP%\tree-script.sh
echo echo "/" >> %TEMP%\tree-script.sh
echo print_tree "/" "" "" >> %TEMP%\tree-script.sh

REM Convert line endings to Unix style (optional, but helps ensure script runs correctly)
docker run --rm -v %TEMP%:/work alpine:latest sh -c "tr -d '\r' < /work/tree-script.sh > /work/tree-script-unix.sh && mv /work/tree-script-unix.sh /work/tree-script.sh && chmod +x /work/tree-script.sh"

REM Run Alpine container with the filesystem from minimal-nginx
docker run --rm -it --volumes-from %CONTAINER_ID% -v %TEMP%:/tmp alpine:latest /tmp/tree-script.sh

REM Clean up
docker rm %CONTAINER_ID%
del %TEMP%\tree-script.sh

echo.
echo Tree view generation complete!

endlocal