import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import clsx from 'clsx';
import styles from './index.module.css';

const features = [
  {
    title: 'TUI Runtime',
    description:
      'A full The Elm Architecture runtime for terminal apps — models, commands, subscriptions, and a hot-reloadable widget tree.',
    link: '/docs/tui',
  },
  {
    title: 'UV (Ultraviolet)',
    description:
      'Cell-based canvas with diff rendering, Sixel/Kitty graphics, color matrix post-processing, and dirty-tracking buffers.',
    link: '/docs/uv',
  },
  {
    title: 'Widget Catalog',
    description:
      'Scroll views, virtual lists, animations, slot registries, charts, sequence diagrams, and more — all composable.',
    link: '/docs/widgets',
  },
  {
    title: 'Style System',
    description:
      'Adaptive colors, borders, padding, themes, and WCAG contrast checking — from simple ANSI to full truecolor.',
    link: '/docs/style',
  },
  {
    title: 'Testing Infrastructure',
    description:
      'WidgetTester, gauntlet stress-testing, widget storms, flicker analysis, and deterministic replay harness.',
    link: '/docs/testing',
  },
  {
    title: 'Remote Plugins',
    description:
      'Out-of-process plugin surfaces over stdin/stdout with surface composition, RPC services, and multi-plugin workspaces.',
    link: '/docs/plugins',
  },
];

function Feature({
  title,
  description,
  link,
}: {
  title: string;
  description: string;
  link: string;
}) {
  return (
    <div className={clsx('col col--4', styles.feature)}>
      <h3>
        <Link to={link}>{title} →</Link>
      </h3>
      <p>{description}</p>
    </div>
  );
}

export default function Home(): React.JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout description={siteConfig.tagline}>
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <h1 className="hero__title">{siteConfig.title}</h1>
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className={styles.buttons}>
            <Link
              className="button button--secondary button--lg"
              to="/docs/docs_index"
            >
              Browse Docs →
            </Link>
            <Link
              className="button button--outline button--secondary button--lg"
              to="/docs/tui"
            >
              Quick Start
            </Link>
          </div>
        </div>
      </header>

      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              {features.map((f) => (
                <Feature key={f.title} {...f} />
              ))}
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
