# Tri Nirvana AI Platform - Deployment Guide

This guide covers the complete deployment process for the Tri Nirvana AI Platform using GitHub Actions, Digital Ocean, and Supabase.

## Architecture Overview

```
GitHub Repository → GitHub Actions → DigitalOcean Container Registry → DigitalOcean Droplet
                                  ↘ Supabase Database & Auth
```

## Prerequisites

### 1. Digital Ocean Setup
- Digital Ocean account with billing enabled
- Container Registry enabled
- Droplet with Ubuntu 22.04 LTS (minimum 2GB RAM)
- Domain name configured with DNS pointing to droplet IP

### 2. Supabase Setup
- Supabase account and project created
- Database schema configured
- Authentication providers enabled
- API keys generated

### 3. GitHub Repository
- Repository with code pushed
- GitHub Secrets configured (see below)

## Step-by-Step Deployment

### 1. Create Digital Ocean Droplet

```bash
# Create a new droplet
doctl compute droplet create tri-nirvana-prod \
  --region nyc1 \
  --size s-2vcpu-2gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --enable-monitoring \
  --enable-backups
```

### 2. Set Up Droplet

```bash
# Connect to your droplet
ssh root@YOUR_DROPLET_IP

# Run the setup script
curl -sSL https://raw.githubusercontent.com/your-username/tri-nirvana-web/main/scripts/setup-droplet.sh | bash
```

### 3. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

#### Digital Ocean Secrets
- `DIGITALOCEAN_ACCESS_TOKEN`: Your DO API token
- `PRODUCTION_HOST`: Your droplet IP address
- `PRODUCTION_USERNAME`: SSH username (usually 'deploy')
- `PRODUCTION_SSH_KEY`: Private SSH key for droplet access
- `STAGING_HOST`, `STAGING_USERNAME`, `STAGING_SSH_KEY`: For staging environment

#### Supabase Secrets
- `SUPABASE_ACCESS_TOKEN`: Your Supabase access token
- `PRODUCTION_SUPABASE_URL`: Production Supabase project URL
- `PRODUCTION_SUPABASE_ANON_KEY`: Production anon key
- `PRODUCTION_SUPABASE_SERVICE_ROLE_KEY`: Production service role key
- `PRODUCTION_SUPABASE_PROJECT_REF`: Production project reference
- `PRODUCTION_SUPABASE_DB_PASSWORD`: Production database password
- `PRODUCTION_DATABASE_URL`: PostgreSQL connection string

#### Application Secrets
- `PRODUCTION_JWT_SECRET`: JWT signing secret
- `PRODUCTION_REDIS_PASSWORD`: Redis password
- `PRODUCTION_APP_URL`: Your production domain (https://your-domain.com)

#### Staging Environment (Optional)
- Duplicate all production secrets with `STAGING_` prefix

#### Notification Secrets (Optional)
- `TELEGRAM_BOT_TOKEN`: For deployment notifications
- `TELEGRAM_CHAT_ID`: Your Telegram chat ID

### 4. Set Up Supabase Project

1. Create a new Supabase project
2. Configure authentication providers:
   ```sql
   -- Enable email/password auth
   -- Enable Google OAuth (optional)
   -- Configure redirect URLs
   ```

3. Set up database schema:
   ```sql
   -- Create tables for user data, predictions, etc.
   -- Set up Row Level Security (RLS) policies
   -- Create necessary indexes
   ```

### 5. Configure Domain and SSL

```bash
# On your droplet, configure SSL with Let's Encrypt
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Verify SSL configuration
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Initial Deployment

1. Push code to `main` branch to trigger staging deployment
2. Manually trigger production deployment via GitHub Actions:
   - Go to Actions tab in GitHub
   - Select "Deploy to Digital Ocean" workflow
   - Click "Run workflow"
   - Select "production" environment

### 7. Verify Deployment

```bash
# Check application health
curl https://your-domain.com/health

# Check Docker containers
docker ps

# Check logs
docker-compose -f docker-compose.production.yml logs -f
```

## Environment Configuration

### Production Environment Variables

Create `.env` file on production server:

```bash
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com
APP_VERSION=1.0.0-beta

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:password@db.supabase.co:5432/postgres

# Security
JWT_SECRET=your-secure-jwt-secret
REDIS_PASSWORD=your-secure-redis-password

# Features
FEATURE_BETA_MODE=true
FEATURE_ANALYTICS=true
FEATURE_FEEDBACK=true
```

## Monitoring and Maintenance

### Health Checks
- Application health: `https://your-domain.com/health`
- Container status: `docker ps`
- Nginx status: `sudo systemctl status nginx`

### Log Monitoring
```bash
# Application logs
docker-compose -f docker-compose.production.yml logs -f app

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u tri-nirvana.service -f
```

### Backup and Recovery
```bash
# Manual backup
/opt/tri-nirvana/backup.sh

# Restore from backup
tar -xzf backups/uploads-YYYYMMDD-HHMMSS.tar.gz -C /opt/tri-nirvana/
```

### Updates and Rollbacks
```bash
# Check for updates
docker-compose -f docker-compose.production.yml pull

# Rollback to previous version
docker-compose -f docker-compose.production.yml down
docker tag tri-nirvana-app:previous tri-nirvana-app:latest
docker-compose -f docker-compose.production.yml up -d
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   sudo certbot renew --dry-run
   sudo nginx -t
   ```

2. **Container Won't Start**
   ```bash
   docker-compose -f docker-compose.production.yml logs app
   docker system prune -f
   ```

3. **Database Connection Issues**
   ```bash
   # Check Supabase connection
   curl -H "apikey: YOUR_ANON_KEY" "https://your-project.supabase.co/rest/v1/"
   ```

4. **High Memory Usage**
   ```bash
   # Check memory usage
   free -h
   docker stats
   
   # Restart containers
   docker-compose -f docker-compose.production.yml restart
   ```

### Performance Optimization

1. **Enable Redis Caching**
   - Configure Redis for session storage
   - Implement caching for prediction results

2. **CDN Configuration**
   - Set up CloudFlare or DigitalOcean Spaces CDN
   - Configure static asset caching

3. **Database Optimization**
   - Monitor query performance in Supabase
   - Add indexes for frequently queried data
   - Implement connection pooling

## Security Considerations

1. **Regular Updates**
   ```bash
   # Update system packages
   sudo apt update && sudo apt upgrade -y
   
   # Update Docker images
   docker-compose -f docker-compose.production.yml pull
   ```

2. **Firewall Configuration**
   ```bash
   # Check firewall status
   sudo ufw status
   
   # Block suspicious IPs
   sudo ufw deny from SUSPICIOUS_IP
   ```

3. **SSL Certificate Renewal**
   ```bash
   # Certificates auto-renew via cron
   sudo certbot renew --quiet
   ```

## Support and Monitoring

### Metrics to Monitor
- Application uptime and response time
- Memory and CPU usage
- Disk space utilization
- SSL certificate expiration
- Database connection status

### Alerts to Set Up
- Application health check failures
- High resource usage (>80%)
- SSL certificate expiration (30 days before)
- Failed deployment notifications

## Scaling Considerations

### Horizontal Scaling
- Set up load balancer with multiple droplets
- Configure session storage in Redis
- Use DigitalOcean Managed Databases

### Vertical Scaling
- Monitor resource usage
- Upgrade droplet size as needed
- Optimize Docker resource limits

---

For additional support, check the logs and monitoring endpoints, or contact the development team.