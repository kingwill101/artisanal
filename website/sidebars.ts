import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  docsSidebar: [
    {
      type: 'doc',
      id: 'DOCS_INDEX',
      label: 'Overview',
    },
    {
      type: 'category',
      label: 'Getting Started',
      collapsed: false,
      items: [
        { type: 'doc', id: 'ARCHITECTURE', label: 'Architecture Overview' },
      ],
    },
    {
      type: 'category',
      label: 'Core Toolkit',
      items: [
        { type: 'doc', id: 'CONSOLE', label: 'Console I/O' },
        { type: 'doc', id: 'ARGS', label: 'Args & Command Runner' },
        { type: 'doc', id: 'TERMINAL', label: 'Terminal Abstraction' },
        { type: 'doc', id: 'RENDERER', label: 'Renderer Abstraction' },
      ],
    },
    {
      type: 'category',
      label: 'Styling & Layout',
      items: [
        { type: 'doc', id: 'STYLE', label: 'Style System' },
        { type: 'doc', id: 'LAYOUT', label: 'Layout Utilities' },
        { type: 'doc', id: 'UNICODE', label: 'Unicode Utilities' },
        { type: 'doc', id: 'COLORPROFILE', label: 'Color Profiles' },
      ],
    },
    {
      type: 'category',
      label: 'TUI & Components',
      items: [
        { type: 'doc', id: 'TUI', label: 'TUI Runtime' },
        { type: 'doc', id: 'WIDGETS', label: 'Widget Catalog' },
        { type: 'doc', id: 'ANIMATION', label: 'Animation System' },
        { type: 'doc', id: 'BUBBLES', label: 'Bubbles Components' },
        { type: 'doc', id: 'IO_COMPONENTS', label: 'Console Components' },
        { type: 'doc', id: 'PLUGINS', label: 'Remote Plugin Surfaces' },
        { type: 'doc', id: 'REPLAY', label: 'Replay Automation' },
      ],
    },
    {
      type: 'category',
      label: 'Rendering & Content',
      items: [
        { type: 'doc', id: 'UV', label: 'UV System (Ultraviolet)' },
        { type: 'doc', id: 'TERMINAL_GRAPHICS', label: 'Terminal Graphics' },
        { type: 'doc', id: 'MARKDOWN', label: 'Markdown Rendering' },
        { type: 'doc', id: 'CHARTING', label: 'Charting Primitives' },
      ],
    },
    {
      type: 'category',
      label: 'Testing & Debugging',
      items: [
        { type: 'doc', id: 'TESTING', label: 'Widget Testing' },
      ],
    },
    {
      type: 'category',
      label: 'Experimental',
      collapsed: true,
      items: [
        { type: 'doc', id: 'LIQUID', label: 'Liquid Templates' },
        { type: 'doc', id: 'PHYSICS', label: 'Physics Helpers' },
      ],
    },
  ],
};

export default sidebars;
