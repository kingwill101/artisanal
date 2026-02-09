import { docs } from '../../.source/server';
import { loader } from 'fumadocs-core/source';
import { createElement } from 'react';
import {
  Home,
  Download,
  Rocket,
  Lightbulb,
  Code,
  AlertTriangle,
  Box,
  Paintbrush,
  Database,
  Flame,
  Columns,
  Type,
  Keyboard,
  ArrowUpDown,
  Layers,
  Terminal,
  Mouse,
  Target,
  CheckCircle,
  Eye,
  Search,
  Star,
  Palette,
} from 'lucide-react';

const icons = {
  home: Home,
  download: Download,
  rocket: Rocket,
  lightbulb: Lightbulb,
  code: Code,
  warning: AlertTriangle,
  cube: Box,
  'paint-brush': Paintbrush,
  database: Database,
  fire: Flame,
  'table-columns': Columns,
  font: Type,
  keyboard: Keyboard,
  'arrows-up-down': ArrowUpDown,
  'layer-group': Layers,
  terminal: Terminal,
  mouse: Mouse,
  bullseye: Target,
  'check-circle': CheckCircle,
  eye: Eye,
  search: Search,
  star: Star,
  palette: Palette,
};

export const source = loader({
  baseUrl: '/docs',
  source: docs.toFumadocsSource(),
  icon(icon) {
    if (!icon || !(icon in icons)) return;
    return createElement(icons[icon as keyof typeof icons]);
  },
});
