import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Artisanal',
  tagline: 'A Dart toolkit for building beautiful terminal applications',
  favicon: 'img/favicon.svg',

  url: 'https://artisanal.dev',
  baseUrl: '/',

  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Read directly from the repo's docs/ folder — no copying needed.
          path: '../docs',
          routeBasePath: 'docs',
          // Don't show an "Edit this page" link (internal repo).
          editUrl: undefined,
          // Show breadcrumbs at the top of each page.
          breadcrumbs: true,
          // Exclude internal files from the site.
          exclude: [
            // Internal planning doc, not user-facing
            'documentation_checklist.md',
          ],
        },
        // No blog needed.
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Artisanal',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Docs',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Overview', to: '/docs/docs_index' },
            { label: 'TUI Runtime', to: '/docs/tui' },
            { label: 'Widget Catalog', to: '/docs/widgets' },
            { label: 'UV System', to: '/docs/uv' },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Artisanal. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'bash', 'json', 'yaml'],
    },
    // Enable doc search sidebar.
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
