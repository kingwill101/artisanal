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
      ],
    },
    {
      type: 'category',
      label: 'CLI & Console',
      items: [
        'cli-console/console-io',
        'cli-console/argument-parsing',
        'cli-console/verbosity',
      ],
    },
    {
      type: 'category',
      label: 'Styling & Layout',
      items: [
        'styling-layout/style',
        'styling-layout/colors',
        'styling-layout/themes',
        'styling-layout/borders-boxes',
        'styling-layout/lists-tables',
        'styling-layout/layout-primitives',
        'styling-layout/writer-api',
      ],
    },
    {
      type: 'category',
      label: 'Interactive TUIs (TEA)',
      items: [
        'core-concepts/model',
        'core-concepts/update',
        'core-concepts/view',
        'core-concepts/messages',
        'core-concepts/commands',
        'core-concepts/program',
        'core-concepts/rendering',
      ],
    },
    {
      type: 'category',
      label: 'Components (Bubbles)',
      items: [
        'components/overview',
        'components/text-input',
        'components/text-area',
        'components/viewport',
        'components/progress-spinner',
        'components/table',
        'components/list',
        'components/file-picker',
      ],
    },
    {
      type: 'category',
      label: 'Advanced Rendering (UV)',
      items: [
        'advanced-rendering/overview',
        'advanced-rendering/buffers-cells',
        'advanced-rendering/compositor-layers',
        'advanced-rendering/terminal-graphics',
        'advanced-rendering/optimizations',
      ],
    },
    {
      type: 'category',
      label: 'Low-level Terminal',
      items: [
        'terminal/terminal-abstraction',
        'terminal/ansi-sequences',
        'terminal/input-decoding',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: [
        'reference/examples',
      ],
    },
  ],
};

export default sidebars;
