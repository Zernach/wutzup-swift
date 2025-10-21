# Wutzup Website

A simple, modern website for Wutzup built with React and Vite.

## Tech Stack

- **React 18** - Modern React with hooks
- **TypeScript** - Type safety
- **Vite** - Fast build tool and dev server
- **React Router** - Client-side routing
- **CSS** - Vanilla CSS for styling

## Getting Started

### Prerequisites

- Node.js 18+ 
- Yarn 4.9.1+

### Installation

```bash
yarn install
```

### Development

Start the development server:

```bash
yarn dev
```

The site will be available at `http://localhost:5173`

### Build

Build for production:

```bash
yarn build
```

The built files will be in the `dist` directory.

### Preview

Preview the production build locally:

```bash
yarn preview
```

## Project Structure

```
website/
├── src/
│   ├── pages/           # Page components
│   │   ├── HomePage.tsx
│   │   └── PrivacyPolicyPage.tsx
│   ├── App.tsx          # Main app with routes
│   ├── main.tsx         # Entry point
│   └── index.css        # Global styles
├── index.html           # HTML template
├── vite.config.ts       # Vite configuration
└── package.json         # Dependencies
```

## Pages

- `/` - Home page with app introduction
- `/privacy-policy` - Privacy policy page

## SEO

The website includes comprehensive SEO setup:

### Meta Tags
- Page-specific titles and descriptions
- Open Graph tags for social media sharing
- Twitter Card tags
- Theme color for browser UI
- Author and keywords

### Static Files
- `robots.txt` - Search engine crawling instructions
- `sitemap.xml` - Site structure for search engines
- `wutzup-icon.jpg` - Favicon and social sharing image

### SEO Component
The `SEO` component (`src/components/SEO.tsx`) allows dynamic meta tag updates for each page:

```tsx
<SEO 
  title="Your Page Title"
  description="Your page description"
  url="https://wutzup.archlife.org/your-page"
/>
```

All pages use this component to ensure proper SEO metadata.
