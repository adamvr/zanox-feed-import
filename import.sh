#!/bin/bash

# Here
cwd="$(dirname $0)"

# Locations
feedUrl="$2"
zip="$cwd/feed.xml.gz"
feed="$cwd/feed.xml"
clean="$cwd/clean.xml"
json="$cwd/data.json"
queries="$cwd/queries.js"

# Database
db="feeds"
collection="$1"

# Awk script
awk="$cwd/lazada.awk"

# JSONify script
jsonify="$cwd/zanox-stream.js"

# Fetch feed
echo "Fetching feed"
curl "$feedUrl" > "$zip" 2>/dev/null

# Extracting
echo "Extracting feed"
gunzip -f "$zip"

# Jsonify
echo "Converting to json"
node "$jsonify" < "$feed" > "$json"

# Querify
echo "Converting to queries"
sed "s/^.*/db.$collection.insert(&)/" < "$json" > "$queries" 2>/dev/null

# Removing old data
echo "Flushing old data"
echo "db.$collection.drop()" | mongo "$db" 2>&1 >/dev/null

# Run queries
echo "Running queries"
mongo "$db" "$queries" 2>/dev/null

# Setting up indicies
echo "Setting up indices"
echo "db.$collection.ensureIndex({product_name: 1}); db.$collection.ensureIndex({product_name: -1});" | mongo "$db" 2>&1 >/dev/null
