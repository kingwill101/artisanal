import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import remarkCodeRegion from './plugins/remark-code-region.mjs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Artisanal',
  tagline: 'A sophisticated TUI framework for Dart',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://artisanal.dev',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'kingwill101', // Usually your GitHub org/user name.
  projectName: 'artisanal', // Usually your repo name.

  onBrokenLinks: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
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
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/kingwill101/ormed/tree/main/packages/artisanal/site/',
          remarkPlugins: [
            [remarkCodeRegion, { rootDir: __dirname }],
          ],
        },
        blog: false, // Disable blog for now
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/artisanal-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Artisanal',
      logo: {
        alt: 'Artisanal Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://pub.dev/packages/artisanal',
          label: 'pub.dev',
          position: 'right',
        },
        {
          href: 'https://github.com/kingwill101/ormed',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Introduction',
              to: '/docs/intro',
            },
            {
              label: 'Quick Start',
              to: '/docs/getting-started/quick-start',
            },
            {
              label: 'Core Concepts',
              to: '/docs/core-concepts/model',
            },
          ],
        },
        {
          title: 'Resources',
          items: [
            {
              label: 'pub.dev',
              href: 'https://pub.dev/packages/artisanal',
            },
            {
              label: 'API Reference',
              href: 'https://pub.dev/documentation/artisanal/latest/',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/kingwill101/ormed',
            },
            {
              label: 'Issues',
              href: 'https://github.com/kingwill101/ormed/issues',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Artisanal. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml', 'bash'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
