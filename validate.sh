#!/bin/bash
#
# NetBox Terraform Module - Pre-Deployment Validation Script
#
# This script performs basic validation of your terraform.tfvars configuration
# before you run terraform apply.
#
# Usage: ./validate.sh [path/to/terraform.tfvars]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

echo "=================================================="
echo "NetBox Terraform Module Validation"
echo "=================================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}ERROR: terraform is not installed${NC}"
    ((ERRORS++))
else
    echo -e "${GREEN}✓${NC} Terraform is installed"
fi

# Check if jq is installed (for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}WARNING: jq is not installed (optional, for enhanced validation)${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓${NC} jq is installed"
fi

echo ""
echo "Validating Terraform configuration..."
echo ""

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
    echo ""
fi

# Validate Terraform syntax
if terraform validate > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Terraform syntax is valid"
else
    echo -e "${RED}✗ Terraform syntax validation failed${NC}"
    terraform validate
    ((ERRORS++))
fi

# Check for required files
echo ""
echo "Checking required files..."
REQUIRED_FILES=("provider.tf" "variables.tf" "dcim.tf" "ipam.tf" "data.tf" "outputs.tf")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Found $file"
    else
        echo -e "${RED}✗ Missing required file: $file${NC}"
        ((ERRORS++))
    fi
done

# Check for tfvars file
echo ""
echo "Checking for variable definitions..."
if [ -f "terraform.tfvars" ]; then
    echo -e "${GREEN}✓${NC} Found terraform.tfvars"
    TFVARS_FILE="terraform.tfvars"
elif [ -f "terraform.tfvars.json" ]; then
    echo -e "${GREEN}✓${NC} Found terraform.tfvars.json"
    TFVARS_FILE="terraform.tfvars.json"
elif [ ! -z "$1" ] && [ -f "$1" ]; then
    echo -e "${GREEN}✓${NC} Using provided tfvars file: $1"
    TFVARS_FILE="$1"
else
    echo -e "${YELLOW}WARNING: No terraform.tfvars file found${NC}"
    echo "  You can create one from terraform.tfvars.example"
    ((WARNINGS++))
    TFVARS_FILE=""
fi

# Check if NetBox environment variables are set
echo ""
echo "Checking NetBox connection..."
if [ -n "$TFVARS_FILE" ]; then
    if grep -q "netbox_url" "$TFVARS_FILE" && grep -q "netbox_token" "$TFVARS_FILE"; then
        echo -e "${GREEN}✓${NC} NetBox credentials found in tfvars"
        
        # Extract NetBox URL (basic extraction, might not work for complex formats)
        NETBOX_URL=$(grep "netbox_url" "$TFVARS_FILE" | cut -d'"' -f2 | head -1)
        if [ -n "$NETBOX_URL" ] && [ "$NETBOX_URL" != "https://netbox.example.com" ]; then
            echo "  Testing connectivity to: $NETBOX_URL"
            if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$NETBOX_URL" | grep -q "^[23]"; then
                echo -e "${GREEN}✓${NC} NetBox is reachable"
            else
                echo -e "${YELLOW}WARNING: Unable to reach NetBox at $NETBOX_URL${NC}"
                ((WARNINGS++))
            fi
        fi
    else
        echo -e "${YELLOW}WARNING: NetBox credentials not found in tfvars${NC}"
        ((WARNINGS++))
    fi
fi

# Run terraform plan in check mode if possible
echo ""
echo "Running terraform plan (validation mode)..."
if terraform plan -input=false > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Terraform plan succeeded"
else
    echo -e "${RED}✗ Terraform plan failed${NC}"
    echo ""
    echo "Common issues:"
    echo "  1. NetBox device types don't exist"
    echo "  2. Site keys don't match between maps"
    echo "  3. Location names don't match site definitions"
    echo ""
    echo "Run 'terraform plan' for detailed error information"
    ((ERRORS++))
fi

# Summary
echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You can now run: terraform apply"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation completed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Review warnings above. You may proceed with: terraform apply"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before running terraform apply"
    exit 1
fi
