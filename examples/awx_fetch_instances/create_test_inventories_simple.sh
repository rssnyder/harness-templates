#!/usr/bin/env bash

set -euo pipefail

AWX_HOST="${1:-}"
AWX_USERNAME="${2:-}"
AWX_PASSWORD="${3:-}"

if [ -z "$AWX_HOST" ] || [ -z "$AWX_USERNAME" ] || [ -z "$AWX_PASSWORD" ]; then
    echo "Usage: $0 <AWX_HOST> <AWX_USERNAME> <AWX_PASSWORD>"
    exit 1
fi

echo "Creating test inventories in AWX..."

# Get organization ID
ORG_ID=$(curl -sS -k -u "$AWX_USERNAME:$AWX_PASSWORD" \
    "$AWX_HOST/api/v2/organizations/" | jq -r '.results[0].id')

echo "Using organization ID: $ORG_ID"

# Create Small Inventory
echo "Creating Small Inventory..."
INV_SMALL=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"Test Inventory - Small\", \"description\": \"Small test inventory\", \"organization\": $ORG_ID}" \
    "$AWX_HOST/api/v2/inventories/" | jq -r '.id')

echo "  Created inventory $INV_SMALL"

# Create groups
GRP_WEB=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "webservers", "description": "Web servers"}' \
    "$AWX_HOST/api/v2/inventories/$INV_SMALL/groups/" | jq -r '.id')

GRP_DB=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "databases", "description": "Database servers"}' \
    "$AWX_HOST/api/v2/inventories/$INV_SMALL/groups/" | jq -r '.id')

# Create hosts with proper JSON string encoding
curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"web-01.example.com\", \"description\": \"Web server 1\", \"variables\": \"{\\\"ansible_host\\\": \\\"192.168.1.10\\\", \\\"environment\\\": \\\"production\\\"}\"}" \
    "$AWX_HOST/api/v2/inventories/$INV_SMALL/hosts/" > /dev/null

curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"web-02.example.com\", \"description\": \"Web server 2\", \"variables\": \"{\\\"ansible_host\\\": \\\"192.168.1.11\\\", \\\"environment\\\": \\\"production\\\"}\"}" \
    "$AWX_HOST/api/v2/inventories/$INV_SMALL/hosts/" > /dev/null

curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"db-01.example.com\", \"description\": \"Database server 1\", \"variables\": \"{\\\"ansible_host\\\": \\\"192.168.1.20\\\", \\\"db_type\\\": \\\"postgresql\\\"}\"}" \
    "$AWX_HOST/api/v2/inventories/$INV_SMALL/hosts/" > /dev/null

echo "  Created 3 hosts"

# Create Medium Inventory
echo "Creating Medium Inventory..."
INV_MEDIUM=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"Test Inventory - Medium\", \"description\": \"Medium test inventory\", \"organization\": $ORG_ID}" \
    "$AWX_HOST/api/v2/inventories/" | jq -r '.id')

echo "  Created inventory $INV_MEDIUM"

# Create groups
curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "production", "description": "Production environment"}' \
    "$AWX_HOST/api/v2/inventories/$INV_MEDIUM/groups/" > /dev/null

curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "webservers", "description": "Web servers"}' \
    "$AWX_HOST/api/v2/inventories/$INV_MEDIUM/groups/" > /dev/null

# Create 10 hosts
for i in {1..10}; do
    curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"web-$(printf "%02d" $i).prod.example.com\", \"description\": \"Web server $i\"}" \
        "$AWX_HOST/api/v2/inventories/$INV_MEDIUM/hosts/" > /dev/null
done

echo "  Created 10 hosts"

# Create Large Inventory
echo "Creating Large Inventory..."
INV_LARGE=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"Test Inventory - Large\", \"description\": \"Large test inventory\", \"organization\": $ORG_ID}" \
    "$AWX_HOST/api/v2/inventories/" | jq -r '.id')

echo "  Created inventory $INV_LARGE"

# Create groups
curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "us-east", "description": "US East region"}' \
    "$AWX_HOST/api/v2/inventories/$INV_LARGE/groups/" > /dev/null

curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "us-west", "description": "US West region"}' \
    "$AWX_HOST/api/v2/inventories/$INV_LARGE/groups/" > /dev/null

curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d '{"name": "webservers", "description": "Web servers"}' \
    "$AWX_HOST/api/v2/inventories/$INV_LARGE/groups/" > /dev/null

# Create 25 hosts
for i in {1..25}; do
    curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"server-$(printf "%02d" $i).prod.example.com\", \"description\": \"Server $i\"}" \
        "$AWX_HOST/api/v2/inventories/$INV_LARGE/hosts/" > /dev/null
done

echo "  Created 25 hosts"

# Create Empty Inventory
echo "Creating Empty Inventory..."
INV_EMPTY=$(curl -sS -k -X POST -u "$AWX_USERNAME:$AWX_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"Test Inventory - Empty\", \"description\": \"Empty test inventory\", \"organization\": $ORG_ID}" \
    "$AWX_HOST/api/v2/inventories/" | jq -r '.id')

echo "  Created inventory $INV_EMPTY (no hosts)"

echo ""
echo "================================"
echo "Test Data Creation Complete!"
echo "================================"
echo ""
echo "Created inventories:"
echo "  - Small:  ID $INV_SMALL (3 hosts, 2 groups)"
echo "  - Medium: ID $INV_MEDIUM (10 hosts, 2 groups)"
echo "  - Large:  ID $INV_LARGE (25 hosts, 3 groups)"
echo "  - Empty:  ID $INV_EMPTY (0 hosts, 0 groups)"
echo ""
echo "Test commands:"
echo "  make test-basic INVENTORY_ID=$INV_SMALL"
echo "  make test-basic INVENTORY_ID=$INV_MEDIUM"
echo "  make test-basic INVENTORY_ID=$INV_LARGE"
echo "  make test-basic INVENTORY_ID=$INV_EMPTY"
echo "  make test-all"
