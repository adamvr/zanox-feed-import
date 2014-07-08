#!/bin/bash

# Here
cwd="$(dirname $0)"

# Locations
feedUrl="$2"
zip="$cwd/feed.tsv.gz"
feed="$cwd/feed.tsv"

# Database
db="feeds"
collection="$1"

# Fetch feed
echo "Fetching feed"
curl "$feedUrl" > "$zip" 2>/dev/null

# Extracting
echo "Extracting feed"
gunzip -f "$zip"

# Import data
echo "Importing data"
mongoimport --host "localhost" --collection "$collection" --db "$db" --headerline --drop --type tsv < "$feed"

# Set up indicies
echo "Setting up indices"
echo "db.$collection.ensureIndex({product_name: 1})" | mongo "$db" 2>&1 >/dev/null
echo "db.$collection.ensureIndex({product_name: -1})" | mongo "$db" 2>&1 >/dev/null
