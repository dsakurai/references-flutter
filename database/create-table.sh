#!/usr/bin/env bash
set -e

# Create the table in the database
mariadb -h db -u appuser -pdevpass appdb < ./create-table.sql || true # Ignore errors if the table already exists

# Verify the table was created
mariadb -h db -u appuser -pdevpass appdb -e "SHOW TABLES;"

# Describe the table structure
mariadb -h db -u appuser -pdevpass appdb -e "DESCRIBE \`References\`;"

# View the first 10 rows of the table
mariadb -h db -u appuser -pdevpass appdb -e "SELECT * FROM \`References\` LIMIT 10;"