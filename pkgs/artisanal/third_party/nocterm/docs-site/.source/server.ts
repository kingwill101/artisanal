// @ts-nocheck
import * as __fd_glob_29 from "../content/docs/testing/visual.mdx?collection=docs"
import * as __fd_glob_28 from "../content/docs/testing/matchers.mdx?collection=docs"
import * as __fd_glob_27 from "../content/docs/testing/basics.mdx?collection=docs"
import * as __fd_glob_26 from "../content/docs/interactivity/mouse.mdx?collection=docs"
import * as __fd_glob_25 from "../content/docs/interactivity/keyboard.mdx?collection=docs"
import * as __fd_glob_24 from "../content/docs/interactivity/focus.mdx?collection=docs"
import * as __fd_glob_23 from "../content/docs/terminal-concepts/limitations.mdx?collection=docs"
import * as __fd_glob_22 from "../content/docs/terminal-concepts/how-terminals-work.mdx?collection=docs"
import * as __fd_glob_21 from "../content/docs/terminal-concepts/ansi.mdx?collection=docs"
import * as __fd_glob_20 from "../content/docs/fundamentals/theming.mdx?collection=docs"
import * as __fd_glob_19 from "../content/docs/fundamentals/state.mdx?collection=docs"
import * as __fd_glob_18 from "../content/docs/fundamentals/hot-reload.mdx?collection=docs"
import * as __fd_glob_17 from "../content/docs/fundamentals/components.mdx?collection=docs"
import * as __fd_glob_16 from "../content/docs/fundamentals/building-uis.mdx?collection=docs"
import * as __fd_glob_15 from "../content/docs/components/text.mdx?collection=docs"
import * as __fd_glob_14 from "../content/docs/components/terminal.mdx?collection=docs"
import * as __fd_glob_13 from "../content/docs/components/scrolling.mdx?collection=docs"
import * as __fd_glob_12 from "../content/docs/components/overlays.mdx?collection=docs"
import * as __fd_glob_11 from "../content/docs/components/layout.mdx?collection=docs"
import * as __fd_glob_10 from "../content/docs/components/input.mdx?collection=docs"
import * as __fd_glob_9 from "../content/docs/installation.mdx?collection=docs"
import * as __fd_glob_8 from "../content/docs/index.mdx?collection=docs"
import * as __fd_glob_7 from "../content/docs/first-app.mdx?collection=docs"
import * as __fd_glob_6 from "../content/docs/examples.mdx?collection=docs"
import { default as __fd_glob_5 } from "../content/docs/testing/meta.json?collection=docs"
import { default as __fd_glob_4 } from "../content/docs/terminal-concepts/meta.json?collection=docs"
import { default as __fd_glob_3 } from "../content/docs/interactivity/meta.json?collection=docs"
import { default as __fd_glob_2 } from "../content/docs/fundamentals/meta.json?collection=docs"
import { default as __fd_glob_1 } from "../content/docs/components/meta.json?collection=docs"
import { default as __fd_glob_0 } from "../content/docs/meta.json?collection=docs"
import { server } from 'fumadocs-mdx/runtime/server';
import type * as Config from '../source.config';

const create = server<typeof Config, import("fumadocs-mdx/runtime/types").InternalTypeConfig & {
  DocData: {
  }
}>({"doc":{"passthroughs":["extractedReferences"]}});

export const docs = await create.docs("docs", "content/docs", {"meta.json": __fd_glob_0, "components/meta.json": __fd_glob_1, "fundamentals/meta.json": __fd_glob_2, "interactivity/meta.json": __fd_glob_3, "terminal-concepts/meta.json": __fd_glob_4, "testing/meta.json": __fd_glob_5, }, {"examples.mdx": __fd_glob_6, "first-app.mdx": __fd_glob_7, "index.mdx": __fd_glob_8, "installation.mdx": __fd_glob_9, "components/input.mdx": __fd_glob_10, "components/layout.mdx": __fd_glob_11, "components/overlays.mdx": __fd_glob_12, "components/scrolling.mdx": __fd_glob_13, "components/terminal.mdx": __fd_glob_14, "components/text.mdx": __fd_glob_15, "fundamentals/building-uis.mdx": __fd_glob_16, "fundamentals/components.mdx": __fd_glob_17, "fundamentals/hot-reload.mdx": __fd_glob_18, "fundamentals/state.mdx": __fd_glob_19, "fundamentals/theming.mdx": __fd_glob_20, "terminal-concepts/ansi.mdx": __fd_glob_21, "terminal-concepts/how-terminals-work.mdx": __fd_glob_22, "terminal-concepts/limitations.mdx": __fd_glob_23, "interactivity/focus.mdx": __fd_glob_24, "interactivity/keyboard.mdx": __fd_glob_25, "interactivity/mouse.mdx": __fd_glob_26, "testing/basics.mdx": __fd_glob_27, "testing/matchers.mdx": __fd_glob_28, "testing/visual.mdx": __fd_glob_29, });