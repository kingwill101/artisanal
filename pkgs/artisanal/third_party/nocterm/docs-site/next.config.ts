import { createMDX } from 'fumadocs-mdx/next';
import type { NextConfig } from 'next';

const withMDX = createMDX();

const config: NextConfig = {
  reactStrictMode: true,
  output: 'export' as const,
  images: {
    unoptimized: true,
  },
};

export default withMDX(config);
