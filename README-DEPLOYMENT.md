# Tri Nirvana AI Platform - Complete Deployment Guide

## 🚀 Overview

This guide provides step-by-step instructions for deploying the Tri Nirvana AI Platform from development to production, including:

- ✅ **Phase 1**: Infrastructure Setup (GitHub + Docker + CI/CD)
- ✅ **Phase 2**: Application Beta Mode Transition  
- ✅ **Phase 3**: Supabase Database & Authentication
- ✅ **Phase 4**: Production Deployment to Digital Ocean
- ✅ **Phase 5**: Monitoring & Security
- ✅ **Phase 6**: Beta User Onboarding

## 📋 Prerequisites Checklist

### Required Accounts & Services
- [ ] GitHub account with repository access
- [ ] Digital Ocean account with billing enabled
- [ ] Supabase account and project created
- [ ] Domain name purchased and configured
- [ ] LINE Official Account (for coaching integration)

### Local Development Setup
- [ ] Docker & Docker Compose installed
- [ ] Node.js 18+ and npm installed
- [ ] Supabase CLI installed
- [ ] Git configured with SSH keys

## 🎯 Architecture Overview

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

## 📱 Phase 1: Infrastructure Setup

### 1.1 GitHub Repository Configuration

```bash
# Clone the repository
git clone https://github.com/your-username/tri-nirvana-web.git
cd tri-nirvana-web

# Create production branch
git checkout -b production
git push -u origin production
```

### 1.2 Configure GitHub Secrets

Navigate to **Settings > Secrets and Variables > Actions** and add:

#### Digital Ocean Secrets
```
DIGITALOCEAN_ACCESS_TOKEN=your_do_token
PRODUCTION_HOST=your_droplet_ip
PRODUCTION_USERNAME=deploy
PRODUCTION_SSH_KEY=your_private_ssh_key
```

#### Supabase Secrets
```
SUPABASE_ACCESS_TOKEN=your_supabase_token
PRODUCTION_SUPABASE_URL=https://your-project.supabase.co
PRODUCTION_SUPABASE_ANON_KEY=your_anon_key
PRODUCTION_SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
PRODUCTION_SUPABASE_PROJECT_REF=your_project_ref
PRODUCTION_DATABASE_URL=postgresql://postgres:password@db.supabase.co:5432/postgres
```

#### Application Secrets
```
PRODUCTION_JWT_SECRET=your_jwt_secret_key
PRODUCTION_REDIS_PASSWORD=your_redis_password
PRODUCTION_APP_URL=https://your-domain.com
```

### 1.3 Digital Ocean Droplet Setup

```bash
# Create droplet
doctl compute droplet create tri-nirvana-prod \
  --region nyc1 \
  --size s-2vcpu-4gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --enable-monitoring \
  --enable-backups

# Get droplet IP
doctl compute droplet list

# Run setup script
ssh root@YOUR_DROPLET_IP
curl -sSL https://raw.githubusercontent.com/your-username/tri-nirvana-web/main/scripts/setup-droplet.sh | bash
```

## 🔧 Phase 2: Supabase Configuration

### 2.1 Initialize Supabase Project

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Initialize project
cd tri-nirvana-web
supabase init

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF
```

### 2.2 Deploy Database Schema

```bash
# Push migrations
supabase db push

# Deploy edge functions
supabase functions deploy

# Verify deployment
supabase functions list
```

### 2.3 Configure Authentication

1. **Enable Auth Providers** in Supabase Dashboard:
   - Email/Password: ✅ Enabled
   - Google OAuth: ✅ Enabled (optional)

2. **Configure Auth Settings**:
   ```
   Site URL: https://your-domain.com
   Redirect URLs: https://your-domain.com/auth/callback
   ```

3. **Set up Auth Webhook**:
   ```
   Webhook URL: https://your-domain.com/supabase/functions/v1/auth-management/webhook
   Events: INSERT, UPDATE, DELETE
   ```

## 🎨 Phase 3: Application Beta Mode

### 3.1 Environment Configuration

Create `.env.production`:

```bash
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com
APP_VERSION=1.0.0-beta

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Features
FEATURE_BETA_MODE=true
FEATURE_ANALYTICS=true
FEATURE_FEEDBACK=true
FEATURE_REALTIME=true
```

### 3.2 Deploy Beta Application

```bash
# Build and test locally
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d

# Test application
curl http://localhost/health

# Push to production via GitHub Actions
git add .
git commit -m "Deploy BETA v1.0"
git push origin main
```

## 🌐 Phase 4: Production Deployment

### 4.1 Domain & SSL Setup

```bash
# On your droplet
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Test SSL renewal
sudo certbot renew --dry-run
```

### 4.2 Deploy to Production

1. **Trigger Production Deployment**:
   - Go to GitHub Actions
   - Select "Deploy to Digital Ocean"
   - Click "Run workflow"
   - Choose "production" environment

2. **Verify Deployment**:
   ```bash
   curl https://your-domain.com/health
   curl https://your-domain.com/api/race-distances
   ```

### 4.3 Database Verification

```bash
# Check Supabase connection
curl -H "apikey: YOUR_ANON_KEY" \
     "https://your-project.supabase.co/rest/v1/race_distances"

# Verify edge functions
curl "https://your-project.supabase.co/functions/v1/race-prediction" \
     -H "Content-Type: application/json" \
     -d '{"data":{"distance":"olympic","swimPace":"2:00","bikeSpeed":35,"runPace":"5:00","experience":"intermediate"}}'
```

## 📊 Phase 5: Monitoring & Analytics

### 5.1 Health Monitoring

```bash
# Set up monitoring cron job
echo "*/5 * * * * curl -f https://your-domain.com/health || echo 'Health check failed' | mail -s 'Site Down' admin@your-domain.com" | crontab -
```

### 5.2 Log Monitoring

```bash
# View application logs
docker-compose -f docker-compose.production.yml logs -f app

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 5.3 Analytics Verification

Check Supabase Analytics Dashboard:
- User signups and authentication events
- Prediction generation events
- Page view tracking
- Error monitoring

## 👥 Phase 6: Beta User Management

### 6.1 Beta Testing Program

1. **Invite Beta Users**:
   - Share registration link: `https://your-domain.com`
   - All new users automatically become beta testers

2. **Monitor Beta Metrics**:
   ```sql
   -- Check beta user stats
   SELECT 
     COUNT(*) as total_users,
     COUNT(CASE WHEN beta_tester THEN 1 END) as beta_users,
     COUNT(CASE WHEN created_at > NOW() - INTERVAL '7 days' THEN 1 END) as new_this_week
   FROM profiles;
   ```

### 6.2 Feedback Collection

1. **In-App Feedback**: Automatic feedback widget
2. **LINE Integration**: Direct coaching feedback
3. **Analytics Dashboard**: User behavior insights

## 🔒 Security & Maintenance

### 6.1 Regular Updates

```bash
# Update system packages (monthly)
sudo apt update && sudo apt upgrade -y

# Update Docker images (weekly)
docker-compose -f docker-compose.production.yml pull
docker-compose -f docker-compose.production.yml up -d

# Backup database (automated via Supabase)
# Backup uploaded files
/opt/tri-nirvana/backup.sh
```

### 6.2 Security Monitoring

- Monitor failed login attempts in Supabase
- Check SSL certificate expiration
- Review firewall logs for suspicious activity
- Monitor resource usage and performance

## 🚨 Troubleshooting

### Common Issues

1. **Application Won't Start**:
   ```bash
   docker-compose -f docker-compose.production.yml logs app
   docker system prune -f
   ```

2. **Database Connection Issues**:
   ```bash
   # Test Supabase connection
   curl -H "apikey: YOUR_ANON_KEY" "https://your-project.supabase.co/rest/v1/"
   ```

3. **SSL Certificate Issues**:
   ```bash
   sudo certbot renew
   sudo nginx -t
   sudo systemctl reload nginx
   ```

4. **High Memory Usage**:
   ```bash
   free -h
   docker stats
   docker-compose -f docker-compose.production.yml restart
   ```

## 📈 Performance Optimization

### 6.3 Optimization Checklist

- [ ] CDN configured for static assets
- [ ] Redis caching implemented
- [ ] Database queries optimized
- [ ] Image compression enabled
- [ ] Gzip compression active
- [ ] HTTP/2 enabled

## ✅ Go-Live Checklist

### Pre-Launch
- [ ] All environment variables configured
- [ ] SSL certificates active
- [ ] Database migrations applied
- [ ] Edge functions deployed
- [ ] Authentication working
- [ ] Analytics tracking active
- [ ] Backup systems functional
- [ ] Monitoring alerts configured

### Post-Launch
- [ ] User registration tested
- [ ] Prediction generation tested
- [ ] Certificate download tested
- [ ] Feedback submission tested
- [ ] Mobile responsiveness verified
- [ ] Performance metrics recorded
- [ ] Beta user onboarding active

## 🎉 Success Metrics

### Week 1 Goals
- 50+ beta user registrations
- 100+ race predictions generated
- 10+ feedback submissions
- 99.9% uptime

### Month 1 Goals
- 500+ active beta users
- 1000+ predictions generated
- 50+ certificates downloaded
- Feature request roadmap established

---

## 📞 Support

For deployment support:
- Check logs: `docker-compose logs`
- Review monitoring: `https://your-domain.com/health`
- Database issues: Supabase Dashboard
- Infrastructure: Digital Ocean Console

**🚀 Your Tri Nirvana AI Platform is now ready for BETA launch!**