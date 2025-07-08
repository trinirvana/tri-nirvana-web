#!/bin/bash

# Tri Nirvana AI Platform - Digital Ocean Droplet Setup Script
# This script sets up a fresh Ubuntu 22.04 droplet for production deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Tri Nirvana AI Platform Droplet Setup...${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo -e "${YELLOW}📦 Installing essential packages...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    tree \
    nano

# Install Docker
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
echo -e "${YELLOW}👤 Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Install Docker Compose
echo -e "${YELLOW}🐳 Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# Configure fail2ban
echo -e "${YELLOW}🛡️ Configuring fail2ban...${NC}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create application directory
echo -e "${YELLOW}📁 Creating application directory...${NC}"
sudo mkdir -p /opt/tri-nirvana
sudo chown $USER:$USER /opt/tri-nirvana

# Install Nginx (for reverse proxy)
echo -e "${YELLOW}🌐 Installing Nginx...${NC}"
sudo apt install -y nginx
sudo systemctl enable nginx

# Configure Nginx reverse proxy
echo -e "${YELLOW}🌐 Configuring Nginx reverse proxy...${NC}"
sudo tee /etc/nginx/sites-available/tri-nirvana > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        proxy_pass http://localhost:8080/health;
        access_log off;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/tri-nirvana /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# Install Certbot for SSL
echo -e "${YELLOW}🔒 Installing Certbot for SSL...${NC}"
sudo apt install -y certbot python3-certbot-nginx

# Create swap file (if not exists)
echo -e "${YELLOW}💾 Creating swap file...${NC}"
if ! sudo swapon --show | grep -q "/swapfile"; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# Install monitoring tools
echo -e "${YELLOW}📊 Installing monitoring tools...${NC}"
sudo apt install -y netdata

# Create deployment user
echo -e "${YELLOW}👤 Creating deployment user...${NC}"
if ! id "deploy" &>/dev/null; then
    sudo useradd -m -s /bin/bash deploy
    sudo usermod -aG docker deploy
    sudo mkdir -p /home/deploy/.ssh
    sudo chown deploy:deploy /home/deploy/.ssh
    sudo chmod 700 /home/deploy/.ssh
fi

# Set up log rotation
echo -e "${YELLOW}📝 Setting up log rotation...${NC}"
sudo tee /etc/logrotate.d/tri-nirvana > /dev/null <<EOF
/opt/tri-nirvana/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 deploy deploy
    postrotate
        docker-compose -f /opt/tri-nirvana/docker-compose.production.yml restart app
    endscript
}
EOF

# Create systemd service for auto-start
echo -e "${YELLOW}⚙️ Creating systemd service...${NC}"
sudo tee /etc/systemd/system/tri-nirvana.service > /dev/null <<EOF
[Unit]
Description=Tri Nirvana AI Platform
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/tri-nirvana
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0
User=deploy
Group=deploy

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable tri-nirvana.service

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"
sudo tee /opt/tri-nirvana/backup.sh > /dev/null <<'EOF'
#!/bin/bash

# Backup script for Tri Nirvana AI Platform
BACKUP_DIR="/opt/tri-nirvana/backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Backup uploaded files
if [ -d "/opt/tri-nirvana/uploads" ]; then
    tar -czf $BACKUP_DIR/uploads-$DATE.tar.gz -C /opt/tri-nirvana uploads/
fi

# Backup environment files
cp /opt/tri-nirvana/.env $BACKUP_DIR/env-$DATE.backup

# Remove backups older than 30 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.backup" -mtime +30 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/tri-nirvana/backup.sh

# Set up cron job for backups
echo -e "${YELLOW}⏰ Setting up backup cron job...${NC}"
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/tri-nirvana/backup.sh >> /var/log/tri-nirvana-backup.log 2>&1") | crontab -

# Install DigitalOcean CLI
echo -e "${YELLOW}🌊 Installing DigitalOcean CLI...${NC}"
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.102.0/doctl-1.102.0-linux-amd64.tar.gz
tar xf doctl-1.102.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin
rm doctl-1.102.0-linux-amd64.tar.gz

# Create monitoring script
echo -e "${YELLOW}📊 Creating monitoring script...${NC}"
sudo tee /opt/tri-nirvana/monitor.sh > /dev/null <<'EOF'
#!/bin/bash

# Monitoring script for Tri Nirvana AI Platform
LOG_FILE="/var/log/tri-nirvana-monitor.log"

# Check if application is running
if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "$(date): Application health check failed" >> $LOG_FILE
    
    # Try to restart the application
    cd /opt/tri-nirvana
    docker-compose -f docker-compose.production.yml restart app
    
    # Wait and check again
    sleep 30
    if ! curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "$(date): Application restart failed" >> $LOG_FILE
        # Send notification (implement your notification method here)
    else
        echo "$(date): Application restarted successfully" >> $LOG_FILE
    fi
else
    echo "$(date): Application health check passed" >> $LOG_FILE
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Disk usage high: ${DISK_USAGE}%" >> $LOG_FILE
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
if (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
    echo "$(date): Memory usage high: ${MEMORY_USAGE}%" >> $LOG_FILE
fi
EOF

chmod +x /opt/tri-nirvana/monitor.sh

# Set up monitoring cron job
echo -e "${YELLOW}⏰ Setting up monitoring cron job...${NC}"
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/tri-nirvana/monitor.sh") | crontab -

echo -e "${GREEN}✅ Droplet setup completed successfully!${NC}"
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Configure your domain DNS to point to this droplet's IP"
echo "2. Run: sudo certbot --nginx -d your-domain.com -d www.your-domain.com"
echo "3. Clone your repository to /opt/tri-nirvana"
echo "4. Set up your .env file with production values"
echo "5. Run: docker-compose -f docker-compose.production.yml up -d"
echo ""
echo -e "${GREEN}🎉 Your droplet is ready for deployment!${NC}"