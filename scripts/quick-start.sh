#!/bin/bash

# Tri Nirvana AI Platform - Quick Start Script
# This script helps you get started with the deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Tri Nirvana AI Platform - Quick Start Setup${NC}"
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.production.yml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the tri-nirvana-web directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Prerequisites Check${NC}"
echo "------------------------"

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is installed${NC}"
else
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose is installed${NC}"
else
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Node.js is installed ($(node --version))${NC}"
else
    echo -e "${YELLOW}⚠️  Node.js is not installed. You'll need it for Supabase CLI.${NC}"
fi

# Check Supabase CLI
if command -v supabase &> /dev/null; then
    echo -e "${GREEN}✅ Supabase CLI is installed${NC}"
else
    echo -e "${YELLOW}⚠️  Supabase CLI is not installed. Installing now...${NC}"
    npm install -g supabase
fi

echo ""
echo -e "${BLUE}🔧 Environment Setup${NC}"
echo "--------------------"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}📝 Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env file created. Please update it with your actual values.${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Create directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p logs backups uploads
echo -e "${GREEN}✅ Directories created${NC}"

echo ""
echo -e "${BLUE}🏗️  Development Setup${NC}"
echo "---------------------"

# Install dependencies if package.json exists
if [ -f "package.json" ]; then
    echo -e "${YELLOW}📦 Installing Node.js dependencies...${NC}"
    npm install
    echo -e "${GREEN}✅ Node.js dependencies installed${NC}"
fi

# Build Docker images for development
echo -e "${YELLOW}🐳 Building Docker images...${NC}"
docker-compose build
echo -e "${GREEN}✅ Docker images built${NC}"

echo ""
echo -e "${BLUE}🧪 Testing Setup${NC}"
echo "----------------"

# Test Docker setup
echo -e "${YELLOW}🔍 Testing Docker setup...${NC}"
if docker-compose up -d; then
    echo -e "${GREEN}✅ Docker containers started successfully${NC}"
    
    # Wait a moment for services to start
    sleep 5
    
    # Test health endpoint
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Application health check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Health check failed - this is normal if Supabase is not configured yet${NC}"
    fi
    
    # Stop containers
    docker-compose down
    echo -e "${GREEN}✅ Docker test completed${NC}"
else
    echo -e "${RED}❌ Docker setup failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================="
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Update .env file with your actual configuration values"
echo "2. Set up your Supabase project:"
echo "   - Create account at https://supabase.com"
echo "   - Create new project"
echo "   - Update SUPABASE_* variables in .env"
echo ""
echo "3. Set up Digital Ocean:"
echo "   - Create account and get API token"
echo "   - Create droplet using scripts/setup-droplet.sh"
echo "   - Configure DNS for your domain"
echo ""
echo "4. Configure GitHub Secrets:"
echo "   - Add all required secrets from README-DEPLOYMENT.md"
echo "   - Set up SSH keys for deployment"
echo ""
echo "5. Deploy to Supabase:"
echo "   supabase login"
echo "   supabase link --project-ref YOUR_PROJECT_REF"
echo "   supabase db push"
echo "   supabase functions deploy"
echo ""
echo "6. Test locally:"
echo "   docker-compose up -d"
echo "   # Visit http://localhost:8080"
echo ""
echo "7. Deploy to production:"
echo "   git push origin main"
echo "   # Trigger GitHub Actions workflow"
echo ""
echo -e "${YELLOW}📚 For detailed instructions, see README-DEPLOYMENT.md${NC}"
echo -e "${GREEN}🚀 Your Tri Nirvana AI Platform is ready for deployment!${NC}"