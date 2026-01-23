# Documentation Site

This directory contains the Ormed documentation site built with [Docusaurus](https://docusaurus.io/).

## Local Development

```bash
cd .site
npm install
npm start
```

This starts a local development server at `http://localhost:3000`.

## Build

```bash
npm run build
```

Build output is in the `build/` directory.

## Deployment

### GitHub Pages (Production)

The site automatically deploys to GitHub Pages when changes are pushed to `main`.

**Setup:**
1. Go to repository Settings → Pages
2. Set Source to "GitHub Actions"

### Deploy Previews (PRs)

PR previews use Netlify. To enable:

1. Create a [Netlify](https://netlify.com) account
2. Create a new site (can be blank)
3. Get your Site ID from Site settings → General
4. Generate a Personal Access Token from User settings → Applications
5. Add secrets to your GitHub repository:
   - `NETLIFY_SITE_ID` - Your Netlify site ID
   - `NETLIFY_AUTH_TOKEN` - Your Netlify personal access token

Once configured, every PR that modifies `.site/**` will get a preview URL posted as a comment.

### Alternative: Vercel Previews

If you prefer Vercel:

1. Import the repository in [Vercel](https://vercel.com)
2. Set the Root Directory to `.site`
3. Vercel automatically creates preview deployments for PRs

No GitHub secrets needed - Vercel handles everything via its GitHub integration.

## Project Structure

```
.site/
├── docs/                 # Documentation pages (Markdown)
│   ├── getting-started/
│   ├── models/
│   ├── queries/
│   ├── migrations/
│   ├── cli/
│   ├── guides/
│   └── reference/
├── src/
│   ├── components/       # React components
│   ├── css/              # Custom styles
│   └── pages/            # Custom pages
├── static/               # Static assets
├── docusaurus.config.ts  # Site configuration
└── sidebars.ts           # Sidebar navigation
```

## Writing Documentation

- Use standard Markdown with [MDX](https://mdxjs.com/) support
- Add frontmatter for page metadata:
  ```md
  ---
  sidebar_position: 1
  title: Page Title
  ---
  ```
- Code blocks support syntax highlighting for `dart`, `yaml`, `bash`, etc.
- Use admonitions for callouts:
  ```md
  :::tip
  This is a tip
  :::
  
  :::caution
  This is a warning
  :::
  ```
