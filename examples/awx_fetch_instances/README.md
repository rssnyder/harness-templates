# AWX Inventory Fetcher

A bash script to fetch inventory details and resolve hosts from AWX (Ansible Tower) API.

## Quick Start

```bash
# Run setup to test connection
make setup

# Create test data (optional - for testing)
make create-test-data

# Fetch an inventory
make test-basic INVENTORY_ID=1

# Or use the script directly
./awx_inventory_fetch.sh -h http://your-awx-server -u admin -p password -i 1 -k
```

## Prerequisites

- `bash` 4.0+
- `curl`
- `jq` (for JSON parsing)

Install `jq`:
```bash
# macOS
brew install jq

# Ubuntu/Debian
apt-get install jq

# RHEL/CentOS
yum install jq
```

## Features

- ✅ Token-based or username/password authentication
- ✅ Automatic pagination handling for large inventories
- ✅ Fetches inventory metadata, hosts, and groups
- ✅ SSL verification (can be disabled for self-signed certs)
- ✅ JSON output with summary statistics
- ✅ Verbose mode for debugging
- ✅ Export results to file

## Usage

### Basic Usage

```bash
# Make script executable
chmod +x awx_inventory_fetch.sh

# Using token authentication
./awx_inventory_fetch.sh \
  --host https://awx.example.com \
  --token YOUR_TOKEN \
  --inventory 5

# Using username/password
./awx_inventory_fetch.sh \
  --host https://awx.example.com \
  --username admin \
  --password secretpass \
  --inventory 5
```

### Using Environment Variables

```bash
export AWX_HOST=https://awx.example.com
export AWX_TOKEN=your_api_token_here
export INVENTORY_ID=5

./awx_inventory_fetch.sh
```

### Advanced Options

```bash
# Skip SSL verification (for self-signed certs)
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 --insecure

# Save output to file
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 -o inventory.json

# Verbose mode
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 -v
```

## Configuration

### Option 1: Environment Variables

Create a `.env` file:

```bash
AWX_HOST=https://awx.example.com
AWX_TOKEN=your_token_here
AWX_VERIFY_SSL=true
INVENTORY_ID=5
```

Then source it:
```bash
source .env
./awx_inventory_fetch.sh
```

### Option 2: Configuration Script

Create `awx_config.sh`:

```bash
#!/bin/bash
export AWX_HOST=https://awx.example.com
export AWX_TOKEN=your_token_here
export AWX_VERIFY_SSL=true
```

Use it:
```bash
source awx_config.sh
./awx_inventory_fetch.sh -i 5
```

## Output Format

The script outputs JSON with the following structure:

```json
{
  "inventory": {
    "id": 5,
    "name": "Production Inventory",
    "description": "Production servers",
    "organization": 1,
    ...
  },
  "hosts": [
    {
      "id": 1,
      "name": "web-server-01",
      "description": "",
      "variables": "{}",
      "enabled": true,
      ...
    }
  ],
  "groups": [
    {
      "id": 1,
      "name": "webservers",
      "description": "Web server group",
      ...
    }
  ],
  "summary": {
    "total_hosts": 25,
    "total_groups": 5,
    "host_names": [
      "web-server-01",
      "web-server-02",
      ...
    ]
  }
}
```

## Getting Your AWX Token

### Via AWX Web UI

1. Log into AWX
2. Click on your username (top right)
3. Go to **Tokens**
4. Click **Add** to create a new token
5. Set scope to "Read" if you only need to fetch data
6. Copy the token (it won't be shown again!)

### Via API

```bash
curl -k -X POST https://awx.example.com/api/v2/tokens/ \
  -u username:password \
  -H "Content-Type: application/json" \
  -d '{
    "description": "API Token for Inventory Fetcher",
    "application": null,
    "scope": "read"
  }'
```

## Finding Your Inventory ID

### Via AWX Web UI
1. Go to **Resources** → **Inventories**
2. Click on your inventory
3. The ID is in the URL: `https://awx.example.com/#/inventories/inventory/5`

### Via API

```bash
# List all inventories
curl -k -X GET https://awx.example.com/api/v2/inventories/ \
  -H "Authorization: Bearer YOUR_TOKEN" | jq '.results[] | {id, name}'
```

## Troubleshooting

### SSL Certificate Errors

If you get SSL certificate verification errors with self-signed certificates:

```bash
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 --insecure
```

Or set:
```bash
export AWX_VERIFY_SSL=false
```

### Authentication Errors

If you get "401 Unauthorized":
- Verify your token is correct and not expired
- Ensure your username/password are correct
- Check that your user has permission to view the inventory

### Empty Results

If you get zero hosts:
- Verify the inventory ID is correct
- Check that the inventory actually has hosts
- Ensure your user has permissions to view hosts in this inventory

## Next Steps / TODO

- [ ] Add support for `--limit` parameter to filter hosts (similar to ansible-playbook)
- [ ] Add host variable fetching (currently only fetches host metadata)
- [ ] Add group membership resolution (which hosts are in which groups)
- [ ] Add support for smart inventories
- [ ] Add caching to avoid repeated API calls
- [ ] Add export to Ansible inventory format (INI or YAML)
- [ ] Add filtering options (by enabled status, by group, etc.)

## Examples

### Extract Just Host Names

```bash
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 | \
  jq -r '.summary.host_names[]'
```

### Count Hosts by Group

```bash
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 | \
  jq '.groups[] | {name: .name, host_count: .hosts}'
```

### Get Enabled Hosts Only

```bash
./awx_inventory_fetch.sh -h https://awx.example.com -t TOKEN -i 5 | \
  jq '.hosts[] | select(.enabled == true) | .name'
```

## References

- [AWX API Documentation](https://docs.ansible.com/ansible-tower/latest/html/towerapi/index.html)
- [AWX GitHub Repository](https://github.com/ansible/awx)
