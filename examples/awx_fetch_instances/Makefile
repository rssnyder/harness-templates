.PHONY: help test test-basic test-all clean check-deps list-inventories create-test-data setup

# Default AWX configuration
AWX_HOST ?= http://192.168.252.5
AWX_USERNAME ?= admin
AWX_PASSWORD ?= PIkLYoqfIakLTrtssoavHYl7qGjdZMGJ
AWX_VERIFY_SSL ?= false

# Test inventory IDs (will be set after creation)
TEST_INVENTORY_SMALL ?=
TEST_INVENTORY_MEDIUM ?=
TEST_INVENTORY_LARGE ?=

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)AWX Inventory Fetcher - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Configuration:$(NC)"
	@echo "  AWX_HOST:     $(AWX_HOST)"
	@echo "  AWX_USERNAME: $(AWX_USERNAME)"
	@echo "  AWX_PASSWORD: [hidden]"

check-deps: ## Check if required dependencies are installed
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@command -v curl >/dev/null 2>&1 || { echo "$(YELLOW)curl is required but not installed$(NC)"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "$(YELLOW)jq is required but not installed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

test-connection: check-deps ## Test connection to AWX server
	@echo "$(BLUE)Testing connection to AWX...$(NC)"
	@curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" \
		"$(AWX_HOST)/api/v2/me/" | jq -e '.results[0].username // .username' > /dev/null || { echo "$(YELLOW)Connection failed$(NC)"; exit 1; }
	@echo "$(GREEN)✓ Connection successful$(NC)"

list-inventories: check-deps ## List all inventories
	@echo "$(BLUE)Fetching all inventories...$(NC)"
	@curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" \
		"$(AWX_HOST)/api/v2/inventories/" | jq -r '.results[] | "\(.id)\t\(.name)\t(\(.total_hosts) hosts, \(.total_groups) groups)"'

list-organizations: check-deps ## List all organizations
	@echo "$(BLUE)Fetching organizations...$(NC)"
	@curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" \
		"$(AWX_HOST)/api/v2/organizations/" | jq -r '.results[] | "\(.id)\t\(.name)"'

create-test-data: check-deps test-connection ## Create test inventories with various configurations
	@echo "$(BLUE)Creating test data...$(NC)"
	@./create_test_inventories_simple.sh "$(AWX_HOST)" "$(AWX_USERNAME)" "$(AWX_PASSWORD)"

test-basic: check-deps ## Test fetching a single inventory (requires INVENTORY_ID)
	@if [ -z "$(INVENTORY_ID)" ]; then \
		echo "$(YELLOW)Error: INVENTORY_ID not set$(NC)"; \
		echo "Usage: make test-basic INVENTORY_ID=<id>"; \
		exit 1; \
	fi
	@echo "$(BLUE)Testing inventory fetch for ID $(INVENTORY_ID)...$(NC)"
	@./awx_inventory_fetch.sh \
		-h "$(AWX_HOST)" \
		-u "$(AWX_USERNAME)" \
		-p "$(AWX_PASSWORD)" \
		-i "$(INVENTORY_ID)" \
		-k -v

test-output: check-deps ## Test with output to file (requires INVENTORY_ID)
	@if [ -z "$(INVENTORY_ID)" ]; then \
		echo "$(YELLOW)Error: INVENTORY_ID not set$(NC)"; \
		echo "Usage: make test-output INVENTORY_ID=<id>"; \
		exit 1; \
	fi
	@echo "$(BLUE)Testing inventory fetch with file output...$(NC)"
	@./awx_inventory_fetch.sh \
		-h "$(AWX_HOST)" \
		-u "$(AWX_USERNAME)" \
		-p "$(AWX_PASSWORD)" \
		-i "$(INVENTORY_ID)" \
		-k -o test_output.json
	@echo "$(GREEN)✓ Output written to test_output.json$(NC)"
	@echo "$(BLUE)Summary:$(NC)"
	@jq -r '"Inventory: \(.inventory.name)\nTotal Hosts: \(.summary.total_hosts)\nTotal Groups: \(.summary.total_groups)"' test_output.json

test-all: check-deps ## Test fetching all inventories
	@echo "$(BLUE)Testing all inventories...$(NC)"
	@for id in $$(curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" "$(AWX_HOST)/api/v2/inventories/" | jq -r '.results[].id'); do \
		echo "$(GREEN)Testing inventory ID: $$id$(NC)"; \
		./awx_inventory_fetch.sh -h "$(AWX_HOST)" -u "$(AWX_USERNAME)" -p "$(AWX_PASSWORD)" -i $$id -k | jq -r '.summary | "  Hosts: \(.total_hosts), Groups: \(.total_groups)"'; \
		echo ""; \
	done

test-env: check-deps ## Test using environment variables from .env file
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Error: .env file not found$(NC)"; \
		echo "Create .env file from .env.example"; \
		exit 1; \
	fi
	@echo "$(BLUE)Testing with .env configuration...$(NC)"
	@bash -c 'source .env && ./awx_inventory_fetch.sh -i $${INVENTORY_ID}'

clean: ## Clean up test output files
	@echo "$(BLUE)Cleaning up test files...$(NC)"
	@rm -f test_output.json test_*.json
	@echo "$(GREEN)✓ Cleaned$(NC)"

delete-test-data: check-deps ## Delete test inventories (WARNING: destructive)
	@echo "$(YELLOW)⚠ This will delete all inventories with 'Test' in the name$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		for id in $$(curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" "$(AWX_HOST)/api/v2/inventories/" | jq -r '.results[] | select(.name | contains("Test")) | .id'); do \
			echo "Deleting inventory ID: $$id"; \
			curl -sS -k -X DELETE -u "$(AWX_USERNAME):$(AWX_PASSWORD)" "$(AWX_HOST)/api/v2/inventories/$$id/"; \
		done; \
		echo "$(GREEN)✓ Test inventories deleted$(NC)"; \
	fi

api-info: check-deps ## Show AWX API information
	@echo "$(BLUE)AWX API Information:$(NC)"
	@curl -sS -k -u "$(AWX_USERNAME):$(AWX_PASSWORD)" \
		"$(AWX_HOST)/api/v2/" | jq '{version: .version, description: .description}'

setup: check-deps test-connection ## Initial setup - test connection and list existing data
	@echo "$(GREEN)Setup complete!$(NC)"
	@echo ""
	@echo "$(BLUE)Existing organizations:$(NC)"
	@make list-organizations
	@echo ""
	@echo "$(BLUE)Existing inventories:$(NC)"
	@make list-inventories
	@echo ""
	@echo "$(GREEN)Next steps:$(NC)"
	@echo "  1. Run 'make create-test-data' to create test inventories"
	@echo "  2. Run 'make test-all' to test fetching all inventories"
	@echo "  3. Run 'make test-basic INVENTORY_ID=<id>' to test a specific inventory"
