# Testing with Your AWX Instance

This document shows how we tested the AWX inventory fetcher against your AWX instance at `192.168.252.5`.

## Test Environment

- **AWX Host**: http://192.168.252.5
- **Username**: admin
- **Password**: (configured)
- **SSL Verification**: Disabled (self-signed cert)

## Test Setup

We created 4 test inventories with different sizes to verify the script handles various scenarios:

| Inventory | ID | Hosts | Groups | Purpose |
|-----------|-----|-------|--------|---------|
| Test Inventory - Small | 13 | 3 | 2 | Basic functionality test |
| Test Inventory - Medium | 14 | 10 | 2 | Medium-sized inventory |
| Test Inventory - Large | 15 | 25 | 3 | Large inventory with pagination |
| Test Inventory - Empty | 16 | 0 | 0 | Edge case: empty inventory |

## Running Tests

### 1. Setup and Connection Test

```bash
make setup
```

Expected output:
- ✓ Dependencies installed (curl, jq)
- ✓ Connection successful
- List of existing organizations
- List of existing inventories

### 2. Create Test Data

```bash
make create-test-data
```

This creates the 4 test inventories listed above.

### 3. Test Individual Inventory

```bash
make test-basic INVENTORY_ID=13
```

Expected output:
- Fetches inventory metadata
- Retrieves all hosts (3 hosts)
- Retrieves all groups (2 groups)
- Displays complete JSON structure
- Shows summary: "Total Hosts: 3, Total Groups: 2"

### 4. Test All Inventories

```bash
make test-all
```

Fetches and displays summaries for all inventories in the AWX instance.

### 5. Test with Output File

```bash
make test-output INVENTORY_ID=13
```

Saves the complete JSON output to `test_output.json`.

## Verified Features

✅ **Authentication**: Both token and username/password authentication work  
✅ **Pagination**: Successfully handles paginated API responses  
✅ **SSL Handling**: Works with self-signed certificates using `-k` flag  
✅ **Error Handling**: Gracefully handles API errors and missing data  
✅ **Multiple Inventories**: Can fetch any inventory by ID  
✅ **Complete Data**: Returns inventory metadata, hosts, and groups  
✅ **Host Variables**: Correctly parses and includes host variables  
✅ **JSON Output**: Clean, well-formatted JSON structure  

## Example Output Structure

```json
{
  "inventory": {
    "id": 13,
    "name": "Test Inventory - Small",
    "description": "Small test inventory",
    "total_hosts": 3,
    "total_groups": 2,
    ...
  },
  "hosts": [
    {
      "id": 54,
      "name": "web-01.example.com",
      "description": "Web server 1",
      "variables": "{\"ansible_host\": \"192.168.1.10\", \"environment\": \"production\"}",
      "enabled": true,
      ...
    }
  ],
  "groups": [
    {
      "id": 33,
      "name": "webservers",
      "description": "Web servers",
      ...
    }
  ],
  "summary": {
    "total_hosts": 3,
    "total_groups": 2,
    "host_names": [
      "db-01.example.com",
      "web-01.example.com",
      "web-02.example.com"
    ]
  }
}
```

## Cleanup

To remove test inventories:

```bash
make delete-test-data
```

⚠️ **Warning**: This will delete ALL inventories with "Test" in the name.

## Using with Real Inventories

Once testing is complete, you can use the script with your real inventories:

```bash
# List all inventories
make list-inventories

# Fetch a specific inventory
./awx_inventory_fetch.sh \
  -h http://192.168.252.5 \
  -u admin \
  -p YOUR_PASSWORD \
  -i INVENTORY_ID \
  -k

# Save to file
./awx_inventory_fetch.sh \
  -h http://192.168.252.5 \
  -u admin \
  -p YOUR_PASSWORD \
  -i INVENTORY_ID \
  -k \
  -o my_inventory.json
```

## Next Steps

Now that the basic functionality is working, we can add:

1. **--limit Support**: Filter hosts based on patterns (like `ansible-playbook --limit`)
2. **Group Membership**: Show which hosts belong to which groups
3. **Host Variables**: Optionally fetch detailed host variables
4. **Export Formats**: Export to Ansible inventory format (INI/YAML)
5. **Caching**: Cache results to reduce API calls
6. **Filtering**: Filter by enabled status, groups, etc.

## Troubleshooting

### Connection Issues

If you get connection errors:
```bash
# Test the API directly
curl -k -u admin:PASSWORD http://192.168.252.5/api/v2/
```

### Authentication Errors

If you get 401 errors:
```bash
# Verify credentials work
curl -k -u admin:PASSWORD http://192.168.252.5/api/v2/me/
```

### Empty Results

If you get 0 hosts:
```bash
# Verify the inventory exists and has hosts
make list-inventories
```
