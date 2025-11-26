#!/bin/bash

# Best practice script to verify all Bicep API versions against Azure providers
# This is the most effective way to ensure templates use up-to-date APIs

set -e

echo "🔍 Azure Bicep API Version Checker"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

updates_available=0
up_to_date=0
preview_versions=0

# List of resource types and their current versions (pipe-delimited)
# Note: Only parent resources are checked; child resources inherit parent API versions
resources=(
    "Microsoft.Storage/storageAccounts|2025-06-01"
    "Microsoft.KeyVault/vaults|2025-05-01"
    "Microsoft.DocumentDB/databaseAccounts|2024-05-15"
    "Microsoft.CognitiveServices/accounts|2024-10-01"
    "Microsoft.MachineLearningServices/workspaces|2025-09-01"
    "Microsoft.OperationalInsights/workspaces|2025-07-01"
    "Microsoft.Insights/components|2020-02-02"
    "Microsoft.Resources/resourceGroups|2023-07-01"
    "Microsoft.Authorization/roleAssignments|2022-04-01"
)

for item in "${resources[@]}"; do
    resource_type="${item%%|*}"
    current_version="${item##*|}"
    namespace=$(echo "$resource_type" | cut -d'/' -f1)
    resource_path=$(echo "$resource_type" | cut -d'/' -f2-)
    
    echo -e "${BLUE}📦 $resource_type${NC}"
    echo "   Current version: $current_version"
    
    # Query Azure for latest version
    latest_version=$(az provider show --namespace "$namespace" 2>/dev/null | \
        jq -r ".resourceTypes[] | select(.resourceType == \"$resource_path\") | .apiVersions[0]" 2>/dev/null || echo "")
    
    if [ -n "$latest_version" ] && [ "$latest_version" != "null" ]; then
        echo "   Latest version:  $latest_version"
        
        # Check if current version is preview
        if [[ "$current_version" =~ -preview ]]; then
            echo -e "   ${YELLOW}⚠️  USING PREVIEW VERSION${NC}"
            ((preview_versions++))
        # Check if latest version is preview but current is stable
        elif [[ "$latest_version" =~ -preview ]]; then
            echo -e "   ${GREEN}✅ USING LATEST STABLE${NC}"
            ((up_to_date++))
        # Check if versions match
        elif [ "$current_version" = "$latest_version" ]; then
            echo -e "   ${GREEN}✅ UP TO DATE${NC}"
            ((up_to_date++))
        else
            echo -e "   ${YELLOW}⚠️  STABLE UPDATE AVAILABLE${NC}"
            ((updates_available++))
        fi
    fi
    echo ""
done

echo "===================================="
echo "Summary:"
echo -e "${GREEN}✅ Up to date: $up_to_date${NC}"
echo -e "${RED}⚠️  Updates available: $updates_available${NC}"
echo -e "${YELLOW}⚠️  Preview versions: $preview_versions${NC}"
echo ""

if [ $updates_available -gt 0 ]; then
    echo "💡 Tip: Run this command to check a specific resource:"
    echo "   az provider show --namespace <NAMESPACE> --query \"resourceTypes[?resourceType=='<TYPE>'].apiVersions[0:5]\" -o table"
fi
