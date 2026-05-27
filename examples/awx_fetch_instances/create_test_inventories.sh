#!/usr/bin/env bash

set -euo pipefail

# Script to create test inventories in AWX for testing purposes

AWX_HOST="${1:-}"
AWX_USERNAME="${2:-}"
AWX_PASSWORD="${3:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

if [ -z "$AWX_HOST" ] || [ -z "$AWX_USERNAME" ] || [ -z "$AWX_PASSWORD" ]; then
    log_error "Usage: $0 <AWX_HOST> <AWX_USERNAME> <AWX_PASSWORD>"
    exit 1
fi

# Make API request
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="${AWX_HOST}/api/v2/${endpoint}"

    if [ -n "$data" ]; then
        curl -sS -k -X "$method" \
            -u "$AWX_USERNAME:$AWX_PASSWORD" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$url"
    else
        curl -sS -k -X "$method" \
            -u "$AWX_USERNAME:$AWX_PASSWORD" \
            -H "Content-Type: application/json" \
            "$url"
    fi
}

# Get default organization ID
get_default_org() {
    log_info "Getting default organization..."
    local org_id
    org_id=$(api_request GET "organizations/" | jq -r '.results[0].id')
    if [ -z "$org_id" ] || [ "$org_id" = "null" ]; then
        log_error "No organization found. Creating 'Default' organization..."
        org_id=$(api_request POST "organizations/" '{
            "name": "Default",
            "description": "Default organization for testing"
        }' | jq -r '.id')
    fi
    # Output just the ID, no color codes
    printf "%s" "$org_id"
}

# Create inventory
create_inventory() {
    local name="$1"
    local description="$2"
    local org_id="$3"

    log_info "Creating inventory: $name" >&2

    local response
    response=$(api_request POST "inventories/" "$(jq -n \
        --arg name "$name" \
        --arg desc "$description" \
        --arg org "$org_id" \
        '{
            name: $name,
            description: $desc,
            organization: ($org | tonumber)
        }')")

    local inv_id
    inv_id=$(echo "$response" | jq -r '.id')

    if [ "$inv_id" = "null" ]; then
        log_error "Failed to create inventory: $name" >&2
        echo "$response" | jq '.' >&2
        return 1
    fi

    log_success "Created inventory: $name (ID: $inv_id)" >&2
    printf "%s" "$inv_id"
}

# Create group in inventory
create_group() {
    local inventory_id="$1"
    local group_name="$2"
    local description="${3:-}"

    log_info "  Creating group: $group_name" >&2

    local response
    response=$(api_request POST "inventories/${inventory_id}/groups/" "$(jq -n \
        --arg name "$group_name" \
        --arg desc "$description" \
        '{
            name: $name,
            description: $desc
        }')")

    local group_id
    group_id=$(echo "$response" | jq -r '.id')

    if [ "$group_id" = "null" ]; then
        log_error "Failed to create group: $group_name" >&2
        return 1
    fi

    printf "%s" "$group_id"
}

# Create host in inventory
create_host() {
    local inventory_id="$1"
    local host_name="$2"
    local description="${3:-}"
    local variables="${4:-{}}"

    log_info "  Creating host: $host_name" >&2

    # Debug: show what we received
    [ "${DEBUG:-false}" = "true" ] && echo "DEBUG: variables=$variables" >&2

    # Build the request payload with variables as a JSON string
    local payload
    payload=$(jq -n \
        --arg name "$host_name" \
        --arg desc "$description" \
        --arg vars "$variables" \
        '{
            name: $name,
            description: $desc,
            variables: $vars
        }')

    local response
    response=$(api_request POST "inventories/${inventory_id}/hosts/" "$payload")

    local host_id
    host_id=$(echo "$response" | jq -r '.id')

    if [ "$host_id" = "null" ] || [ -z "$host_id" ]; then
        log_error "Failed to create host: $host_name" >&2
        echo "$response" | jq '.' >&2
        return 1
    fi

    printf "%s" "$host_id"
}

# Add host to group
add_host_to_group() {
    local group_id="$1"
    local host_id="$2"

    api_request POST "groups/${group_id}/hosts/" "{\"id\": $host_id}" > /dev/null
}

# Main script
main() {
    log_info "Starting AWX test data creation..."
    log_info "Target: $AWX_HOST"

    # Get organization
    log_info "Getting default organization..." >&2
    ORG_ID=$(api_request GET "organizations/" | jq -r '.results[0].id')
    log_success "Using organization ID: $ORG_ID"

    echo ""
    log_info "================================"
    log_info "Creating Test Inventory: Small"
    log_info "================================"

    # Test Inventory 1: Small (3 hosts, 2 groups)
    INV_SMALL=$(create_inventory \
        "Test Inventory - Small" \
        "Small test inventory with 3 hosts and 2 groups" \
        "$ORG_ID")

    GROUP_WEB=$(create_group "$INV_SMALL" "webservers" "Web server group")
    GROUP_DB=$(create_group "$INV_SMALL" "databases" "Database server group")

    HOST1=$(create_host "$INV_SMALL" "web-01.example.com" "Web server 1" "{\"ansible_host\": \"192.168.1.10\", \"environment\": \"production\"}")
    HOST2=$(create_host "$INV_SMALL" "web-02.example.com" "Web server 2" "{\"ansible_host\": \"192.168.1.11\", \"environment\": \"production\"}")
    HOST3=$(create_host "$INV_SMALL" "db-01.example.com" "Database server 1" "{\"ansible_host\": \"192.168.1.20\", \"environment\": \"production\"}")

    add_host_to_group "$GROUP_WEB" "$HOST1"
    add_host_to_group "$GROUP_WEB" "$HOST2"
    add_host_to_group "$GROUP_DB" "$HOST3"

    log_success "Small inventory created (ID: $INV_SMALL)"

    echo ""
    log_info "================================"
    log_info "Creating Test Inventory: Medium"
    log_info "================================"

    # Test Inventory 2: Medium (10 hosts, 4 groups with nested structure)
    INV_MEDIUM=$(create_inventory \
        "Test Inventory - Medium" \
        "Medium test inventory with 10 hosts and 4 groups" \
        "$ORG_ID")

    GROUP_PROD=$(create_group "$INV_MEDIUM" "production" "Production environment")
    GROUP_STAGING=$(create_group "$INV_MEDIUM" "staging" "Staging environment")
    GROUP_WEB_MED=$(create_group "$INV_MEDIUM" "webservers" "All web servers")
    GROUP_APP=$(create_group "$INV_MEDIUM" "appservers" "Application servers")

    # Create hosts and assign to groups
    for i in {1..4}; do
        host_id=$(create_host "$INV_MEDIUM" "web-prod-0${i}.example.com" "Production web server $i" "{\"ansible_host\": \"10.0.1.$((10+i))\", \"environment\": \"production\"}")
        add_host_to_group "$GROUP_PROD" "$host_id"
        add_host_to_group "$GROUP_WEB_MED" "$host_id"
    done

    for i in {1..3}; do
        host_id=$(create_host "$INV_MEDIUM" "app-prod-0${i}.example.com" "Production app server $i" "{\"ansible_host\": \"10.0.2.$((10+i))\", \"environment\": \"production\"}")
        add_host_to_group "$GROUP_PROD" "$host_id"
        add_host_to_group "$GROUP_APP" "$host_id"
    done

    for i in {1..3}; do
        host_id=$(create_host "$INV_MEDIUM" "web-staging-0${i}.example.com" "Staging web server $i" "{\"ansible_host\": \"10.0.3.$((10+i))\", \"environment\": \"staging\"}")
        add_host_to_group "$GROUP_STAGING" "$host_id"
        add_host_to_group "$GROUP_WEB_MED" "$host_id"
    done

    log_success "Medium inventory created (ID: $INV_MEDIUM)"

    echo ""
    log_info "================================"
    log_info "Creating Test Inventory: Large"
    log_info "================================"

    # Test Inventory 3: Large (25 hosts, 6 groups)
    INV_LARGE=$(create_inventory \
        "Test Inventory - Large" \
        "Large test inventory with 25 hosts across multiple groups" \
        "$ORG_ID")

    GROUP_EAST=$(create_group "$INV_LARGE" "us-east" "US East region")
    GROUP_WEST=$(create_group "$INV_LARGE" "us-west" "US West region")
    GROUP_WEB_LARGE=$(create_group "$INV_LARGE" "webservers" "Web servers")
    GROUP_APP_LARGE=$(create_group "$INV_LARGE" "appservers" "App servers")
    GROUP_DB_LARGE=$(create_group "$INV_LARGE" "databases" "Database servers")
    GROUP_CACHE=$(create_group "$INV_LARGE" "cache" "Cache servers")

    # Create web servers (10 hosts)
    for i in {1..10}; do
        region=$( [ $((i % 2)) -eq 0 ] && echo "east" || echo "west" )
        region_group=$( [ $((i % 2)) -eq 0 ] && echo "$GROUP_EAST" || echo "$GROUP_WEST" )
        host_id=$(create_host "$INV_LARGE" "web-${region}-$(printf "%02d" $i).prod.example.com" "Web server $i in $region" "{\"ansible_host\": \"172.16.1.$((10+i))\", \"region\": \"$region\"}")
        add_host_to_group "$GROUP_WEB_LARGE" "$host_id"
        add_host_to_group "$region_group" "$host_id"
    done

    # Create app servers (8 hosts)
    for i in {1..8}; do
        region=$( [ $((i % 2)) -eq 0 ] && echo "east" || echo "west" )
        region_group=$( [ $((i % 2)) -eq 0 ] && echo "$GROUP_EAST" || echo "$GROUP_WEST" )
        host_id=$(create_host "$INV_LARGE" "app-${region}-$(printf "%02d" $i).prod.example.com" "App server $i in $region" "{\"ansible_host\": \"172.16.2.$((10+i))\", \"region\": \"$region\"}")
        add_host_to_group "$GROUP_APP_LARGE" "$host_id"
        add_host_to_group "$region_group" "$host_id"
    done

    # Create database servers (4 hosts)
    for i in {1..4}; do
        region=$( [ $((i % 2)) -eq 0 ] && echo "east" || echo "west" )
        region_group=$( [ $((i % 2)) -eq 0 ] && echo "$GROUP_EAST" || echo "$GROUP_WEST" )
        host_id=$(create_host "$INV_LARGE" "db-${region}-$(printf "%02d" $i).prod.example.com" "Database server $i in $region" "{\"ansible_host\": \"172.16.3.$((10+i))\", \"region\": \"$region\", \"db_type\": \"postgresql\"}")
        add_host_to_group "$GROUP_DB_LARGE" "$host_id"
        add_host_to_group "$region_group" "$host_id"
    done

    # Create cache servers (3 hosts)
    for i in {1..3}; do
        region=$( [ $((i % 2)) -eq 0 ] && echo "east" || echo "west" )
        region_group=$( [ $((i % 2)) -eq 0 ] && echo "$GROUP_EAST" || echo "$GROUP_WEST" )
        host_id=$(create_host "$INV_LARGE" "cache-${region}-$(printf "%02d" $i).prod.example.com" "Cache server $i in $region" "{\"ansible_host\": \"172.16.4.$((10+i))\", \"region\": \"$region\", \"cache_type\": \"redis\"}")
        add_host_to_group "$GROUP_CACHE" "$host_id"
        add_host_to_group "$region_group" "$host_id"
    done

    log_success "Large inventory created (ID: $INV_LARGE)"

    echo ""
    log_info "================================"
    log_info "Creating Test Inventory: Empty"
    log_info "================================"

    # Test Inventory 4: Empty (no hosts, just structure)
    INV_EMPTY=$(create_inventory \
        "Test Inventory - Empty" \
        "Empty inventory with groups but no hosts" \
        "$ORG_ID")

    create_group "$INV_EMPTY" "prepared-webservers" "Future web servers" > /dev/null
    create_group "$INV_EMPTY" "prepared-databases" "Future database servers" > /dev/null

    log_success "Empty inventory created (ID: $INV_EMPTY)"

    echo ""
    log_success "================================"
    log_success "Test Data Creation Complete!"
    log_success "================================"
    echo ""
    echo "Created inventories:"
    echo "  - Small:  ID $INV_SMALL (3 hosts, 2 groups)"
    echo "  - Medium: ID $INV_MEDIUM (10 hosts, 4 groups)"
    echo "  - Large:  ID $INV_LARGE (25 hosts, 6 groups)"
    echo "  - Empty:  ID $INV_EMPTY (0 hosts, 2 groups)"
    echo ""
    echo "Test commands:"
    echo "  make test-basic INVENTORY_ID=$INV_SMALL"
    echo "  make test-basic INVENTORY_ID=$INV_MEDIUM"
    echo "  make test-basic INVENTORY_ID=$INV_LARGE"
    echo "  make test-basic INVENTORY_ID=$INV_EMPTY"
    echo "  make test-all"
}

main
