import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'docs_index',
      label: 'Overview',
    },
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: [
        { type: 'doc', id: 'architecture', label: 'Architecture Overview' },
      ],
    },
    {
      type: 'category',
      label: 'Core Toolkit',
      items: [
        { type: 'doc', id: 'console', label: 'Console I/O' },
        { type: 'doc', id: 'args', label: 'Args & Command Runner' },
        { type: 'doc', id: 'terminal', label: 'Terminal Abstraction' },
        { type: 'doc', id: 'renderer', label: 'Renderer Abstraction' },
      ],
    },
    {
      type: 'category',
      label: 'Styling & Layout',
      items: [
        { type: 'doc', id: 'style', label: 'Style System' },
        { type: 'doc', id: 'layout', label: 'Layout Utilities' },
        { type: 'doc', id: 'unicode', label: 'Unicode Utilities' },
        { type: 'doc', id: 'colorprofile', label: 'Color Profiles' },
      ],
    },
    {
      type: 'category',
      label: 'TUI & Components',
      items: [
        { type: 'doc', id: 'tui', label: 'TUI Runtime' },
        { type: 'doc', id: 'widgets', label: 'Widget Catalog' },
        { type: 'doc', id: 'animation', label: 'Animation System' },
        { type: 'doc', id: 'bubbles', label: 'Bubbles Components' },
        { type: 'doc', id: 'io_components', label: 'Console Components' },
        { type: 'doc', id: 'plugins', label: 'Remote Plugin Surfaces' },
        { type: 'doc', id: 'replay', label: 'Replay Automation' },
      ],
    },
    {
      type: 'category',
      label: 'Rendering & Content',
      items: [
        { type: 'doc', id: 'uv', label: 'UV System (Ultraviolet)' },
        { type: 'doc', id: 'terminal_graphics', label: 'Terminal Graphics' },
        { type: 'doc', id: 'markdown', label: 'Markdown Rendering' },
        { type: 'doc', id: 'charting', label: 'Charting Primitives' },
      ],
    },
    {
      type: 'category',
      label: 'Testing & Debugging',
      items: [
        { type: 'doc', id: 'testing', label: 'Widget Testing' },
      ],
    },
    {
      type: 'category',
      label: 'Experimental',
      collapsed: true,
      items: [
        { type: 'doc', id: 'liquid', label: 'Liquid Templates' },
        { type: 'doc', id: 'physics', label: 'Physics Helpers' },
      ],
    },
  ],
};

export default sidebars;
