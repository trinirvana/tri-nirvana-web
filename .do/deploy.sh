#!/bin/bash

# DigitalOcean App Platform Deployment Script for Tri-Nirvana

# Set PATH to include doctl
export PATH="$HOME/.local/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Deploying Tri-Nirvana Web to DigitalOcean App Platform${NC}"

# Check if we're in the right directory
if [ ! -f ".do/app.yaml" ]; then
    echo -e "${RED}❌ Error: .do/app.yaml not found. Run this script from the project root.${NC}"
    exit 1
fi

# Verify doctl authentication
if ! doctl account get > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: DigitalOcean CLI not authenticated. Run 'doctl auth init' first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Checking existing apps...${NC}"
EXISTING_APP=$(doctl apps list --format ID,Spec.Name --no-header | grep "tri-nirvana-web" | awk '{print $1}')

if [ -n "$EXISTING_APP" ]; then
    echo -e "${YELLOW}🔄 Updating existing app (ID: $EXISTING_APP)...${NC}"
    doctl apps update $EXISTING_APP --spec .do/app.yaml
    
    echo -e "${YELLOW}⏳ Waiting for deployment to complete...${NC}"
    doctl apps create-deployment $EXISTING_APP --wait
else
    echo -e "${YELLOW}🆕 Creating new app...${NC}"
    doctl apps create --spec .do/app.yaml --wait
fi

echo -e "${GREEN}✅ Deployment complete!${NC}"

# Get app info
APP_ID=$(doctl apps list --format ID,Spec.Name --no-header | grep "tri-nirvana-web" | awk '{print $1}')
if [ -n "$APP_ID" ]; then
    echo -e "${GREEN}📱 App ID: $APP_ID${NC}"
    APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)
    echo -e "${GREEN}🌐 App URL: https://$APP_URL${NC}"
fi

# Show logs
echo -e "${YELLOW}📝 Recent deployment logs:${NC}"
doctl apps logs $APP_ID --type deploy --tail 20