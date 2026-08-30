import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'docs_index',
      label: 'Start here',
    },
    { type: 'doc', id: 'architecture', label: 'How it fits together' },
    {
      type: 'category',
      label: 'Build a command-line tool',
      items: [
        { type: 'doc', id: 'console', label: 'Print and prompt' },
        { type: 'doc', id: 'args', label: 'Commands and arguments' },
        { type: 'doc', id: 'terminal', label: 'Work with the terminal' },
        { type: 'doc', id: 'renderer', label: 'Choose a renderer' },
      ],
    },
    {
      type: 'category',
      label: 'Style text and layouts',
      items: [
        { type: 'doc', id: 'style', label: 'Style terminal output' },
        { type: 'doc', id: 'layout', label: 'Arrange content' },
        { type: 'doc', id: 'unicode', label: 'Measure terminal text' },
        { type: 'doc', id: 'colorprofile', label: 'Adapt terminal colors' },
      ],
    },
    {
      type: 'category',
      label: 'Build an interactive app',
      items: [
        { type: 'doc', id: 'tui', label: 'Use the TEA runtime' },
        { type: 'doc', id: 'inline_tui', label: 'Share the terminal screen' },
        { type: 'doc', id: 'widgets', label: 'Build with widgets' },
        { type: 'doc', id: 'animation', label: 'Add animation' },
        { type: 'doc', id: 'bubbles', label: 'Add interactive components' },
        { type: 'doc', id: 'io_components', label: 'Use console components' },
        { type: 'doc', id: 'replay', label: 'Replay and trace sessions' },
      ],
    },
    {
      type: 'category',
      label: 'Render custom content',
      items: [
        { type: 'doc', id: 'uv', label: 'Draw with Ultraviolet' },
        { type: 'doc', id: 'terminal_graphics', label: 'Show terminal images' },
        { type: 'doc', id: 'markdown', label: 'Render Markdown' },
        { type: 'doc', id: 'charting', label: 'Draw charts' },
      ],
    },
    {
      type: 'category',
      label: 'Test and debug',
      items: [
        { type: 'doc', id: 'testing', label: 'Test widget apps' },
      ],
    },
    {
      type: 'category',
      label: 'Try experimental APIs',
      collapsed: true,
      items: [
        { type: 'doc', id: 'liquid', label: 'Build with Liquid' },
      ],
    },
  ],
};

export default sidebars;
