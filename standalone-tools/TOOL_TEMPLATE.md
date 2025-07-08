# Standalone Tool Template

## Structure for Individual Tools

Each standalone tool follows this consistent structure:

```
standalone-tools/[tool-name]/
├── index.html              # Main tool page
├── manifest.json           # PWA manifest
├── sw.js                  # Service worker for PWA
├── css/
│   └── tool-specific.css  # Tool-specific styles
├── js/
│   ├── app.js            # Main tool logic
│   └── calculations.js   # Tool calculations
├── assets/
│   ├── icons/            # Tool-specific icons
│   └── images/           # Tool images
├── api/
│   ├── save.php          # Save tool data
│   └── load.php          # Load tool data
└── README.md             # Tool documentation
```

## Base HTML Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[Tool Name] - Tri Nirvana AI</title>
    
    <!-- PWA Meta -->
    <meta name="theme-color" content="#667eea">
    <meta name="description" content="[Tool description]">
    <link rel="manifest" href="manifest.json">
    <link rel="icon" type="image/png" href="../shared/assets/favicon.png">
    
    <!-- Shared Brand System -->
    <link rel="stylesheet" href="../shared/branding/brand-system.css">
    <link rel="stylesheet" href="../shared/components/ui-components.css">
    
    <!-- Tool-specific styles -->
    <link rel="stylesheet" href="css/tool-specific.css">
</head>
<body>
    <!-- Tool Header -->
    <header class="tool-header">
        <div class="container">
            <div class="flex items-center justify-between">
                <div class="tool-brand">
                    <h1 class="text-2xl font-bold text-primary">[Tool Name]</h1>
                    <p class="text-sm text-gray-600">Tri Nirvana AI</p>
                </div>
                <button class="btn btn-ghost" id="menuBtn">
                    <i class="icon-menu"></i>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Tool Content -->
    <main class="tool-main">
        <div class="container">
            <!-- Tool content goes here -->
        </div>
    </main>

    <!-- Tool Footer -->
    <footer class="tool-footer">
        <div class="container">
            <div class="text-center text-sm text-gray-500">
                <p>&copy; 2024 Tri Nirvana AI. All rights reserved.</p>
                <div class="flex justify-center gap-4 mt-2">
                    <a href="#" class="text-primary">Privacy</a>
                    <a href="#" class="text-primary">Terms</a>
                    <a href="#" class="text-primary">Support</a>
                </div>
            </div>
        </div>
    </footer>

    <!-- Shared utilities -->
    <script src="../shared/js/utils.js"></script>
    <!-- Tool-specific scripts -->
    <script src="js/app.js"></script>
</body>
</html>
```

## PWA Manifest Template

```json
{
  "name": "[Tool Name] - Tri Nirvana AI",
  "short_name": "[Tool Name]",
  "description": "[Tool description]",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#667eea",
  "categories": ["health", "fitness", "sports"],
  "icons": [
    {
      "src": "assets/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "assets/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

## Service Worker Template

```javascript
const CACHE_NAME = '[tool-name]-v1';
const urlsToCache = [
  '/',
  '/css/tool-specific.css',
  '/js/app.js',
  '/js/calculations.js',
  '../shared/branding/brand-system.css',
  '../shared/components/ui-components.css',
  '../shared/js/utils.js'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => {
        if (response) {
          return response;
        }
        return fetch(event.request);
      }
    )
  );
});
```

## JavaScript Structure

```javascript
// app.js - Main tool logic
class ToolName {
  constructor() {
    this.initializeElements();
    this.bindEvents();
    this.loadUserData();
  }

  initializeElements() {
    // Get DOM elements
  }

  bindEvents() {
    // Add event listeners
  }

  loadUserData() {
    // Load saved user data
  }

  calculate() {
    // Main calculation logic
  }

  saveData() {
    // Save user data
  }

  displayResults() {
    // Show results
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new ToolName();
});
```

## Tool Development Checklist

### Setup
- [ ] Create tool directory structure
- [ ] Copy base HTML template
- [ ] Update manifest.json with tool details
- [ ] Create service worker
- [ ] Add tool-specific icons

### Development
- [ ] Implement core functionality
- [ ] Add form validation
- [ ] Create calculation logic
- [ ] Implement data persistence
- [ ] Add responsive design
- [ ] Test PWA functionality

### Integration
- [ ] Add to main platform
- [ ] Create API endpoints
- [ ] Implement user authentication
- [ ] Add analytics tracking
- [ ] Test across devices

### Deployment
- [ ] Test in production environment
- [ ] Configure subdomain
- [ ] Set up SSL certificate
- [ ] Submit to app stores (if native wrapper)
- [ ] Create marketing materials

## Monetization Integration

### Free Tier Features
```javascript
const FREE_FEATURES = {
  calculations: 5, // per day
  save_results: false,
  export_data: false,
  advanced_options: false
};
```

### Pro Tier Features
```javascript
const PRO_FEATURES = {
  calculations: -1, // unlimited
  save_results: true,
  export_data: true,
  advanced_options: true,
  custom_branding: false
};
```

### Payment Integration
```javascript
// Stripe integration for pro upgrades
const upgradeModal = {
  show: () => {
    // Show upgrade modal
  },
  hide: () => {
    // Hide upgrade modal
  }
};
```

## Analytics Integration

```javascript
// Track tool usage
TriNirvana.analytics.track('tool_used', {
  tool_name: '[tool-name]',
  user_tier: 'free|pro',
  calculation_type: 'basic|advanced'
});
```

## SEO Optimization

```html
<!-- Tool-specific meta tags -->
<meta name="keywords" content="triathlon, [tool-specific-keywords]">
<meta property="og:title" content="[Tool Name] - Tri Nirvana AI">
<meta property="og:description" content="[Tool description]">
<meta property="og:image" content="assets/images/tool-preview.jpg">
<meta property="og:type" content="website">
```

## Performance Requirements

- First Contentful Paint: < 1.5s
- Largest Contentful Paint: < 2.5s
- Cumulative Layout Shift: < 0.1
- First Input Delay: < 100ms
- PWA Score: > 90

## Browser Support

- Chrome 80+
- Firefox 75+
- Safari 13+
- Edge 80+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Testing Checklist

- [ ] Desktop responsiveness
- [ ] Mobile responsiveness
- [ ] Tablet responsiveness
- [ ] PWA installation
- [ ] Offline functionality
- [ ] Form validation
- [ ] Calculation accuracy
- [ ] Data persistence
- [ ] Performance metrics
- [ ] Accessibility compliance