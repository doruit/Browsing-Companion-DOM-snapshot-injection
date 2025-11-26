#!/bin/bash

# Best practice script to verify all Bicep API versions, kinds, and SKUs against Azure providers
# This is the most effective way to ensure templates use up-to-date and valid configurations

set -e

echo "🔍 Azure Bicep API Version, Kind & SKU Checker"
echo "==============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

updates_available=0
up_to_date=0
preview_versions=0
kind_checks=0
sku_checks=0

# List of resource types with their current versions, kinds, and SKUs (pipe-delimited)
# Format: "ResourceType|ApiVersion|Kind|SKU"
# Note: Only parent resources are checked; child resources inherit parent API versions
resources=(
    "Microsoft.Storage/storageAccounts|2025-06-01|StorageV2|Standard_LRS"
    "Microsoft.KeyVault/vaults|2025-05-01||standard"
    "Microsoft.DocumentDB/databaseAccounts|2024-05-15|GlobalDocumentDB|"
    "Microsoft.CognitiveServices/accounts|2024-10-01|OpenAI|S0"
    "Microsoft.MachineLearningServices/workspaces|2025-09-01|AIServices,Project|"
    "Microsoft.OperationalInsights/workspaces|2025-07-01||PerGB2018"
    "Microsoft.Insights/components|2020-02-02|web|"
    "Microsoft.Resources/resourceGroups|2023-07-01||"
    "Microsoft.Authorization/roleAssignments|2022-04-01||"
)

# Deployment-specific configurations to check
deployments=(
    "gpt-4o-mini|2024-07-18|GlobalStandard"
)

for item in "${resources[@]}"; do
    IFS='|' read -r resource_type current_version current_kind current_sku <<< "$item"
    namespace=$(echo "$resource_type" | cut -d'/' -f1)
    resource_path=$(echo "$resource_type" | cut -d'/' -f2-)
    
    echo -e "${BLUE}📦 $resource_type${NC}"
    echo "   Current version: $current_version"
    
    # Query Azure for resource type details
    resource_info=$(az provider show --namespace "$namespace" 2>/dev/null | \
        jq -r ".resourceTypes[] | select(.resourceType == \"$resource_path\")" 2>/dev/null || echo "")
    
    if [ -n "$resource_info" ] && [ "$resource_info" != "null" ]; then
        # Check API Version
        latest_version=$(echo "$resource_info" | jq -r '.apiVersions[0]' 2>/dev/null || echo "")
        
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
        
        # Check Kind (if specified)
        if [ -n "$current_kind" ]; then
            echo ""
            echo -e "   ${CYAN}🏷️  Kind Validation:${NC}"
            
            # Get available capabilities/kinds from the resource type
            capabilities=$(echo "$resource_info" | jq -r '.capabilities' 2>/dev/null || echo "")
            
            # For resources with multiple kinds (comma-separated)
            IFS=',' read -ra KINDS <<< "$current_kind"
            for kind in "${KINDS[@]}"; do
                echo "      Checking kind: $kind"
                
                # Special handling for different resource types
                case "$namespace" in
                    "Microsoft.Storage")
                        # Storage kinds are well-known and documented
                        if [[ "$kind" =~ ^(Storage|StorageV2|BlobStorage|FileStorage|BlockBlobStorage)$ ]]; then
                            echo -e "         ${GREEN}✅ Valid kind${NC}"
                        else
                            echo -e "         ${RED}❌ Unknown kind${NC}"
                        fi
                        ;;
                    "Microsoft.CognitiveServices")
                        # Cognitive Services has specific kinds
                        if [[ "$kind" =~ ^(OpenAI|CognitiveServices|TextAnalytics)$ ]]; then
                            echo -e "         ${GREEN}✅ Valid kind${NC}"
                        else
                            echo -e "         ${YELLOW}⚠️  Uncommon kind (verify manually)${NC}"
                        fi
                        ;;
                    "Microsoft.MachineLearningServices")
                        # AI Foundry workspace kinds
                        if [[ "$kind" =~ ^(Default|Hub|Project|AIServices)$ ]]; then
                            echo -e "         ${GREEN}✅ Valid kind${NC}"
                        else
                            echo -e "         ${RED}❌ Unknown kind${NC}"
                        fi
                        ;;
                    "Microsoft.DocumentDB")
                        # Cosmos DB kinds
                        if [[ "$kind" =~ ^(GlobalDocumentDB|MongoDB|Parse)$ ]]; then
                            echo -e "         ${GREEN}✅ Valid kind${NC}"
                        else
                            echo -e "         ${RED}❌ Unknown kind${NC}"
                        fi
                        ;;
                    "Microsoft.Insights")
                        # Application Insights kinds
                        if [[ "$kind" =~ ^(web|ios|java|store|phone|other)$ ]]; then
                            echo -e "         ${GREEN}✅ Valid kind${NC}"
                        else
                            echo -e "         ${YELLOW}⚠️  Uncommon kind${NC}"
                        fi
                        ;;
                    *)
                        echo -e "         ${CYAN}ℹ️  Kind validation not implemented for this resource type${NC}"
                        ;;
                esac
                ((kind_checks++))
            done
        fi
        
        # Check SKU (if specified)
        if [ -n "$current_sku" ]; then
            echo ""
            echo -e "   ${CYAN}💎 SKU Validation:${NC}"
            echo "      Current SKU: $current_sku"
            
            # Special handling for different resource types
            case "$namespace" in
                "Microsoft.Storage")
                    if [[ "$current_sku" =~ ^(Standard_LRS|Standard_GRS|Standard_RAGRS|Standard_ZRS|Premium_LRS|Premium_ZRS)$ ]]; then
                        echo -e "         ${GREEN}✅ Valid SKU${NC}"
                    else
                        echo -e "         ${RED}❌ Unknown SKU${NC}"
                    fi
                    ;;
                "Microsoft.CognitiveServices")
                    if [[ "$current_sku" =~ ^(F0|S0|S|S1|S2|S3|S4)$ ]]; then
                        echo -e "         ${GREEN}✅ Valid account SKU${NC}"
                    else
                        echo -e "         ${YELLOW}⚠️  Uncommon SKU (verify manually)${NC}"
                    fi
                    ;;
                "Microsoft.KeyVault")
                    if [[ "$current_sku" =~ ^(standard|premium)$ ]]; then
                        echo -e "         ${GREEN}✅ Valid SKU${NC}"
                    else
                        echo -e "         ${RED}❌ Unknown SKU${NC}"
                    fi
                    ;;
                "Microsoft.OperationalInsights")
                    if [[ "$current_sku" =~ ^(Free|PerNode|PerGB2018|Standalone|Standard|Premium)$ ]]; then
                        echo -e "         ${GREEN}✅ Valid SKU${NC}"
                    else
                        echo -e "         ${RED}❌ Unknown SKU${NC}"
                    fi
                    ;;
                *)
                    echo -e "         ${CYAN}ℹ️  SKU validation not implemented for this resource type${NC}"
                    ;;
            esac
            ((sku_checks++))
        fi
    fi
    echo ""
done

# Check deployment SKUs (for model deployments like OpenAI)
if [ ${#deployments[@]} -gt 0 ]; then
    echo -e "${BLUE}🚀 Deployment Configurations${NC}"
    echo "===================================="
    echo ""
    
    for deployment in "${deployments[@]}"; do
        IFS='|' read -r model_name model_version deployment_sku <<< "$deployment"
        
        echo -e "${CYAN}Model: $model_name${NC}"
        echo "   Version: $model_version"
        echo "   Deployment SKU: $deployment_sku"
        
        # Query available SKUs for the model
        echo "   Checking SKU availability..."
        
        model_info=$(az cognitiveservices model list --location eastus 2>/dev/null | \
            jq -r ".[] | select(.model.name == \"$model_name\" and .model.version == \"$model_version\") | .model.skus[]? | .name" 2>/dev/null || echo "")
        
        if [ -n "$model_info" ]; then
            available_skus=$(echo "$model_info" | tr '\n' ', ' | sed 's/,$//')
            echo "   Available SKUs: $available_skus"
            
            if echo "$model_info" | grep -q "^${deployment_sku}$"; then
                echo -e "   ${GREEN}✅ SKU is valid for this model${NC}"
            else
                echo -e "   ${RED}❌ SKU not available for this model${NC}"
                echo -e "   ${YELLOW}💡 Use one of: $available_skus${NC}"
            fi
        else
            echo -e "   ${YELLOW}⚠️  Could not verify model SKUs (model may not be available in eastus)${NC}"
        fi
        ((sku_checks++))
        echo ""
    done
fi

echo "===================================="
echo "Summary:"
echo -e "${GREEN}✅ Up to date: $up_to_date${NC}"
echo -e "${RED}⚠️  Updates available: $updates_available${NC}"
echo -e "${YELLOW}⚠️  Preview versions: $preview_versions${NC}"
echo -e "${CYAN}🏷️  Kind validations: $kind_checks${NC}"
echo -e "${CYAN}💎 SKU validations: $sku_checks${NC}"
echo ""

if [ $updates_available -gt 0 ]; then
    echo "💡 Tip: Run this command to check a specific resource:"
    echo "   az provider show --namespace <NAMESPACE> --query \"resourceTypes[?resourceType=='<TYPE>'].apiVersions[0:5]\" -o table"
fi

echo ""
echo "💡 To check SKUs for a specific model:"
echo "   az cognitiveservices model list --location <LOCATION> --query \"[?model.name=='<MODEL>']\" -o json | jq '.[] | {name: .model.name, version: .model.version, skus: .model.skus}'"
