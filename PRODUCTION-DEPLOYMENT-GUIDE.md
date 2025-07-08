# 🚀 Production Deployment Guide - Tri Nirvana AI Platform

## Phase 3: Production Deployment to Digital Ocean

Your application is now ready for production deployment with complete CI/CD automation.

## Prerequisites ✅

Before deploying to production, ensure you have:

1. **Digital Ocean Account** with billing enabled
2. **Domain name** purchased and DNS configured
3. **GitHub repository** with all code committed
4. **Supabase database schema** deployed (from Phase 2)

## 🔧 Production Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │────│ GitHub Actions  │────│  Digital Ocean  │
│                 │    │     CI/CD       │    │    Droplet      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                              │
         │              ┌─────────────────┐            │
         └──────────────│   Supabase      │────────────┘
                        │ Auth + Database │
                        └─────────────────┘
```

## Step 1: Create Digital Ocean Droplet

```bash
# Create a new droplet
doctl compute droplet create tri-nirvana-prod \
  --region nyc1 \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --enable-monitoring \
  --enable-backups \
  --ssh-keys YOUR_SSH_KEY_ID

# Get the droplet IP
doctl compute droplet list
```

Or create via the Digital Ocean web interface:
- **Name**: `tri-nirvana-prod`
- **Region**: Choose closest to your users
- **Size**: `2 vCPU, 4GB RAM` (upgradeable)
- **Image**: `Ubuntu 22.04 LTS`
- **Additional options**: Monitoring, Backups

## Step 2: Configure GitHub Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and Variables** → **Actions**

Add these secrets:

### Digital Ocean Secrets
```
DIGITALOCEAN_ACCESS_TOKEN=your_do_token
PRODUCTION_HOST=your_droplet_ip
PRODUCTION_USERNAME=deploy
PRODUCTION_SSH_KEY=your_private_ssh_key
```

### Supabase Production Secrets
```
PRODUCTION_SUPABASE_URL=https://lwjudzphytpjywnzcxlu.supabase.co
PRODUCTION_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3anVkenBoeXRwanl3bnpjeGx1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDMzMjcsImV4cCI6MjA2NTM3OTMyN30.9RFekS9u9KO-eLyLfLQ3uTcELEEKAhz8JSUPR8_wSRw
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3anVkenBoeXRwanl3bnpjeGx1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTgwMzMyNywiZXhwIjoyMDY1Mzc5MzI3fQ.Vt-Z9fFY7S5k0tI3NrxKjybjWUokN8whhvzUNSnaxOU
PRODUCTION_DATABASE_URL=postgresql://postgres:[password]@db.lwjudzphytpjywnzcxlu.supabase.co:5432/postgres
```

### Application Secrets
```
PRODUCTION_JWT_SECRET=your_random_jwt_secret_key_min_32_chars
PRODUCTION_REDIS_PASSWORD=your_secure_redis_password
PRODUCTION_APP_URL=https://your-domain.com
```

### Staging Secrets (for testing)
```
STAGING_HOST=your_staging_droplet_ip
STAGING_USERNAME=deploy
STAGING_SSH_KEY=your_staging_ssh_key
STAGING_SUPABASE_URL=https://lwjudzphytpjywnzcxlu.supabase.co
STAGING_SUPABASE_ANON_KEY=[same as production for now]
STAGING_SUPABASE_SERVICE_ROLE_KEY=[same as production for now]
STAGING_DATABASE_URL=[same as production for now]
STAGING_JWT_SECRET=your_staging_jwt_secret
STAGING_REDIS_PASSWORD=your_staging_redis_password
```

## Step 3: Server Setup

SSH into your droplet and run the setup script:

```bash
ssh root@your_droplet_ip

# Download and run the setup script
curl -sSL https://raw.githubusercontent.com/your-username/tri-nirvana-web/main/scripts/setup-droplet.sh | bash

# Or manually run the commands from setup-droplet.sh
```

The setup script will:
- Install Docker and Docker Compose
- Configure Nginx with SSL
- Set up firewall rules
- Create deploy user
- Configure automatic backups

## Step 4: Domain and SSL Configuration

1. **Point your domain to the droplet**:
   ```
   A Record: @ → your_droplet_ip
   A Record: www → your_droplet_ip
   ```

2. **Configure SSL** (done automatically by setup script):
   ```bash
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   ```

## Step 5: Deploy to Production

### Option A: Automatic Deployment (Recommended)

1. **Push to main branch** (auto-deploys to staging):
   ```bash
   git add .
   git commit -m "Deploy BETA v1.0 🚀"
   git push origin main
   ```

2. **Deploy to production** via GitHub Actions:
   - Go to **Actions** tab in GitHub
   - Select "Deploy to Digital Ocean" workflow
   - Click "Run workflow"
   - Choose "production" environment
   - Click "Run workflow"

### Option B: Manual Deployment

```bash
# SSH into your production server
ssh deploy@your_droplet_ip

# Navigate to the application directory
cd /opt/tri-nirvana

# Pull latest code
git pull origin main

# Update environment variables
cp .env.production .env

# Build and restart containers
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d

# Verify deployment
curl https://your-domain.com/health
```

## Step 6: Verify Production Deployment

### Health Checks
```bash
# Application health
curl https://your-domain.com/health

# Database connectivity  
curl https://your-domain.com/api/race-distances

# SSL certificate
curl -I https://your-domain.com
```

### Supabase Configuration
1. **Update Site URLs** in Supabase Dashboard:
   - Site URL: `https://your-domain.com`
   - Redirect URLs: `https://your-domain.com/**`

2. **Test authentication** at:
   - `https://your-domain.com/test-auth.html`

## 🎯 Production Features

Your deployed application includes:

### ✅ **Core Features**
- Race time prediction calculator
- User authentication and profiles
- Certificate generation
- Responsive design for mobile/desktop

### ✅ **Infrastructure**
- HTTPS/SSL encryption
- Automated deployments via GitHub Actions
- Health monitoring and alerts
- Automatic backups
- Rolling updates with rollback capability

### ✅ **Analytics & Monitoring**
- User behavior tracking
- Performance monitoring
- Error logging
- Feedback collection

### ✅ **Security**
- Row Level Security (RLS) in database
- CSRF protection
- Input validation
- Secure environment variables

## 🚨 Post-Deployment Checklist

- [ ] Domain points to droplet IP
- [ ] SSL certificate is active
- [ ] Application health check passes
- [ ] User registration works
- [ ] Race prediction generation works
- [ ] Analytics tracking works
- [ ] Feedback submission works
- [ ] Mobile interface works
- [ ] GitHub Actions deployment works

## 📊 Monitoring & Maintenance

### Daily Monitoring
```bash
# Check application health
curl https://your-domain.com/health

# Check Docker containers
docker-compose -f docker-compose.production.yml ps

# Check logs
docker-compose -f docker-compose.production.yml logs --tail=100
```

### Weekly Maintenance
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Clean Docker images
docker system prune -f

# Check SSL certificate expiry
sudo certbot renew --dry-run
```

### Analytics Dashboard
Monitor your application through:
- **Supabase Dashboard**: Database metrics and user analytics
- **Digital Ocean Monitoring**: Server performance metrics
- **GitHub Actions**: Deployment success/failure rates

## 🎉 Success! Your Tri Nirvana AI Platform is LIVE!

**Production URL**: `https://your-domain.com`

### 📈 Expected Beta Launch Metrics

**Week 1 Goals:**
- 50+ beta user registrations
- 100+ race predictions generated
- 10+ feedback submissions
- 99.9% uptime

**Month 1 Goals:**
- 500+ active beta users
- 1000+ predictions generated
- 50+ certificates downloaded
- Feature roadmap based on user feedback

### 🚀 Next Steps

1. **User Onboarding**: Share the platform with beta users
2. **Feedback Collection**: Monitor user feedback and feature requests
3. **Performance Optimization**: Based on real usage patterns
4. **Feature Development**: Implement additional tools based on user needs

**Your Tri Nirvana AI Platform is now ready for BETA users!** 🏃‍♂️🚴‍♀️🏊‍♂️