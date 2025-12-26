import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'getting-started/installation',
        'getting-started/quick-start',
        'getting-started/configuration',
        'getting-started/code-generation',
      ],
    },
    {
      type: 'category',
      label: 'Models',
      items: [
        'models/defining-models',
        'models/attributes',
        'models/casting',
        'models/driver-overrides',
        'models/relationships',
        'models/timestamps',
        'models/soft-deletes',
        'models/scopes',
        'models/events',
        'models/model-methods',
        'models/factories',
      ],
    },
    {
      type: 'category',
      label: 'Queries',
      items: [
        'queries/query-builder',
        'queries/repository',
        'queries/relations',
        'queries/data-source',
        'queries/caching',
        'queries/json',
      ],
    },
    {
      type: 'category',
      label: 'Migrations',
      items: [
        'migrations/overview',
        'migrations/schema-builder',
        'migrations/running-migrations',
        'migrations/events',
        'migrations/squashing',
      ],
    },
    {
      type: 'category',
      label: 'Drivers',
      items: [
        'drivers/overview',
        {
          type: 'category',
          label: 'Internals',
          items: [
            'drivers/internals/overview',
            'drivers/internals/plans',
            'drivers/internals/schema',
          ],
        },
        'drivers/sqlite',
        'drivers/postgres',
        'drivers/mysql',
      ],
    },
    {
      type: 'category',
      label: 'CLI',
      items: [
        'cli/overview',
        'cli/migrations',
        'cli/seeding',
        'cli/schema',
        'cli/commands',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: [
        {
          type: 'category',
          label: 'Fullstack',
          items: [
            'guides/fullstack/setup',
            'guides/fullstack/models',
            'guides/fullstack/server-routes',
            'guides/fullstack/templates-storage',
            'guides/fullstack/migrations-seeds',
            'guides/fullstack/cli-runbook',
            'guides/fullstack/api',
            'guides/fullstack/testing',
            'guides/fullstack/ormed-shelf-tutorial',
          ],
        },
        'guides/testing',
        'guides/best-practices',
        'guides/date-time',
        'guides/observability',
        'guides/multi-database',
        'guides/examples',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: [
        'reference/driver-capabilities',
      ],
    },
  ],
};

export default sidebars;
