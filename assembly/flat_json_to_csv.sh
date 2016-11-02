# This converts the flat JSON files into csvs in the same directory.
# Dependencies: jq.

# Strip the extension.
file="${1%.*}"

# Get the header.
cat "$1" | \
jq --raw-output '.[]' | \
head -n 1 | \
jq --raw-output 'keys_unsorted | @csv' > "$file.csv"

# Get the contents of the file.
cat "$1" | \
jq --raw-output '.[]' | \
jq --raw-output '[.[]] | @csv' >> "$file.csv"