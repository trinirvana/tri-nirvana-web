# DigitalOcean Deployment Configuration

## Quick Deploy

```bash
cd /home/trinirvana/tri-nirvana-web
./.do/deploy.sh
```

## Manual Commands

### Create new app:
```bash
doctl apps create --spec .do/app.yaml --wait
```

### Update existing app:
```bash
# Get app ID first
doctl apps list

# Update with new spec
doctl apps update YOUR_APP_ID --spec .do/app.yaml
```

### Monitor deployment:
```bash
doctl apps list
doctl apps get YOUR_APP_ID
doctl apps logs YOUR_APP_ID --type deploy
```

### Useful Commands:
```bash
# List all apps
doctl apps list

# Get app details
doctl apps get YOUR_APP_ID

# View logs
doctl apps logs YOUR_APP_ID --type run
doctl apps logs YOUR_APP_ID --type deploy

# Scale app
doctl apps update YOUR_APP_ID --spec .do/app.yaml
```

## Configuration Notes

- **App Spec**: `.do/app.yaml` - Defines the application configuration
- **Database**: PostgreSQL 14 (development size)
- **Runtime**: PHP with built-in server
- **Domain**: Auto-assigned DigitalOcean App Platform URL
- **Scaling**: Basic tier (can be upgraded in app.yaml)

## Cost Estimate
- **Web Service**: $5/month (Basic tier)
- **Database**: $15/month (Development tier)
- **Total**: ~$20/month

## Custom Domain Setup
1. Add domain in app.yaml under `domains:` section
2. Update DNS records as shown in DigitalOcean dashboard
3. Redeploy with updated spec