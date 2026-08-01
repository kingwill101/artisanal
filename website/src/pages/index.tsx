import React from 'react';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import styles from './index.module.css';

const paths = [
  {
    number: '01',
    eyebrow: 'For scripts and CLIs',
    title: 'Make output worth reading.',
    description:
      'Prompts, progress, tables, errors, and status messages that feel considered—not cobbled together from escape codes.',
    link: '/docs/console',
    linkLabel: 'Explore console tools',
  },
  {
    number: '02',
    eyebrow: 'For interactive apps',
    title: 'Give the terminal a heartbeat.',
    description:
      'Build responsive interfaces with a small Model, update, and view loop that keeps state and side effects understandable.',
    link: '/docs/tui',
    linkLabel: 'Build your first TUI',
  },
  {
    number: '03',
    eyebrow: 'For richer interfaces',
    title: 'Compose, instead of coordinate.',
    description:
      'Reach for screens, forms, lists, editors, and navigation from a widget system that feels familiar to Dart developers.',
    link: '/docs/widgets',
    linkLabel: 'Browse the widgets',
  },
];

const supportingLinks = [
  { label: 'Style text & layouts', link: '/docs/style' },
  { label: 'Draw with Ultraviolet', link: '/docs/uv' },
  { label: 'Test terminal interactions', link: '/docs/testing' },
];

export default function Home(): React.JSX.Element {
  return (
    <Layout description="Build polished command-line tools and terminal apps in Dart">
      <main className={styles.page}>
        <header className={styles.hero}>
          <div className={styles.gridWash} aria-hidden="true" />
          <div className={styles.heroInner}>
            <div className={styles.heroCopy}>
              <div className={styles.eyebrow}>
                <span className={styles.eyebrowMark}>A</span>
                <span>Full-stack terminal tools for Dart</span>
              </div>

              <h1>
                Build for the terminal.
                <span>Enjoy the process.</span>
              </h1>

              <p className={styles.heroLead}>
                Artisanal gives you the pieces for a thoughtful command-line
                experience—from one polished prompt to a complete interactive
                application.
              </p>

              <div className={styles.heroActions}>
                <Link className={styles.primaryAction} to="/docs/docs_index">
                  Start building
                  <span aria-hidden="true">↗</span>
                </Link>
                <Link className={styles.secondaryAction} to="/docs/tui">
                  Take the TUI path
                </Link>
              </div>

              <p className={styles.heroNote}>
                <span aria-hidden="true">✦</span>
                One toolkit. From friendly scripts to full-screen apps.
              </p>
            </div>

            <div className={styles.demoWrap}>
              <div className={styles.demoOffset} aria-hidden="true" />
              <div className={styles.terminal}>
                <div className={styles.terminalBar}>
                  <div className={styles.terminalDots} aria-hidden="true">
                    <span />
                    <span />
                    <span />
                  </div>
                  <span>release.dart</span>
                  <span className={styles.ready}>ready</span>
                </div>

                <div className={styles.codePane}>
                  <pre>
                    <code>
                      <span className={styles.codeBlue}>final</span> console ={' '}
                      <span className={styles.codeGold}>Console</span>();
                      {'\n\n'}
                      <span className={styles.codeBlue}>await</span> console.task(
                      {'\n'}  <span className={styles.codeGreen}>'Preparing release'</span>,
                      {'\n'}  run: build,
                      {'\n'});
                    </code>
                  </pre>
                </div>

                <div className={styles.outputPane}>
                  <div className={styles.outputHeading}>
                    <span className={styles.prompt}>❯</span>
                    dart run release.dart
                  </div>
                  <div className={styles.taskLine}>
                    <span className={styles.success}>✓</span>
                    <span>Preparing release</span>
                    <span className={styles.duration}>1.8s</span>
                  </div>
                  <div className={styles.releaseBox}>
                    <span>ARTISANAL</span>
                    <strong>Ready to ship.</strong>
                    <small>12 checks passed · 0 warnings</small>
                  </div>
                  <span className={styles.cursor} aria-hidden="true" />
                </div>
              </div>
              <div className={styles.demoCaption}>
                <span>01 / OUTPUT</span>
                <span>Small details make useful tools feel good.</span>
              </div>
            </div>
          </div>
        </header>

        <section className={styles.pathsSection}>
          <div className={styles.sectionIntro}>
            <p className={styles.sectionKicker}>Choose your altitude</p>
            <h2>Start where your idea starts.</h2>
            <p>
              You do not need a framework for every script. Pick the layer you
              need today; the rest is there when the project grows.
            </p>
          </div>

          <div className={styles.pathGrid}>
            {paths.map((path) => (
              <article className={styles.pathCard} key={path.number}>
                <div className={styles.cardTopline}>
                  <span>{path.number}</span>
                  <span>{path.eyebrow}</span>
                </div>
                <h3>{path.title}</h3>
                <p>{path.description}</p>
                <Link to={path.link}>
                  {path.linkLabel}
                  <span aria-hidden="true">→</span>
                </Link>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.toolbelt} aria-labelledby="toolbelt-title">
          <div>
            <p className={styles.sectionKicker}>The deeper toolbelt</p>
            <h2 id="toolbelt-title">Go closer to the metal when you need to.</h2>
          </div>
          <nav aria-label="More Artisanal capabilities">
            {supportingLinks.map((item) => (
              <Link to={item.link} key={item.link}>
                <span>{item.label}</span>
                <span aria-hidden="true">↗</span>
              </Link>
            ))}
          </nav>
        </section>

        <section className={styles.closingCta}>
          <div className={styles.ctaMark} aria-hidden="true">
            <span>dart</span>
            <strong>_</strong>
          </div>
          <div>
            <p className={styles.sectionKicker}>Not sure where to begin?</p>
            <h2>Take the ten-minute tour.</h2>
            <p>
              Begin with a normal Dart program. Add only what makes it clearer,
              friendlier, and easier to use.
            </p>
          </div>
          <Link to="/docs/docs_index">
            Read the introduction
            <span aria-hidden="true">→</span>
          </Link>
        </section>
      </main>
    </Layout>
  );
}
