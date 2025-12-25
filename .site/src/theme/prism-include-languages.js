import siteConfig from '@generated/docusaurus.config';

const registerMarkupTemplating = (Prism) => {
  if (Prism.languages['markup-templating']) {
    return;
  }

  const getPlaceholder = (language, index) =>
    `___${language.toUpperCase()}${index}___`;

  Object.defineProperties((Prism.languages['markup-templating'] = {}), {
    buildPlaceholders: {
      value: (env, language, placeholderPattern, replaceFilter) => {
        if (env.language !== language) {
          return;
        }

        const tokenStack = (env.tokenStack = []);

        env.code = env.code.replace(placeholderPattern, (match) => {
          if (typeof replaceFilter === 'function' && !replaceFilter(match)) {
            return match;
          }
          let i = tokenStack.length;
          let placeholder;
          while (env.code.indexOf((placeholder = getPlaceholder(language, i))) !== -1) {
            i += 1;
          }
          tokenStack[i] = match;
          return placeholder;
        });

        env.grammar = Prism.languages.markup;
      },
    },
    tokenizePlaceholders: {
      value: (env, language) => {
        if (env.language !== language || !env.tokenStack) {
          return;
        }

        env.grammar = Prism.languages[language];

        let j = 0;
        const keys = Object.keys(env.tokenStack);

        const walkTokens = (tokens) => {
          for (let i = 0; i < tokens.length; i += 1) {
            if (j >= keys.length) {
              break;
            }

            const token = tokens[i];
            if (typeof token === 'string' || (token.content && typeof token.content === 'string')) {
              const key = keys[j];
              const placeholder = getPlaceholder(language, key);
              const value = env.tokenStack[key];
              const source = typeof token === 'string' ? token : token.content;
              const index = source.indexOf(placeholder);

              if (index > -1) {
                j += 1;
                const before = source.substring(0, index);
                const middle = new Prism.Token(
                  language,
                  Prism.tokenize(value, env.grammar),
                  `language-${language}`,
                  value,
                );
                const after = source.substring(index + placeholder.length);

                const replacement = [];
                if (before) {
                  replacement.push(...walkTokens([before]));
                }
                replacement.push(middle);
                if (after) {
                  replacement.push(...walkTokens([after]));
                }

                if (typeof token === 'string') {
                  tokens.splice(i, 1, ...replacement);
                } else {
                  token.content = replacement;
                }
              }
            } else if (token.content) {
              walkTokens(token.content);
            }
          }

          return tokens;
        };

        walkTokens(env.tokens);
      },
    },
  });
};

const registerLiquid = (Prism) => {
  if (Prism.languages.liquid) {
    return;
  }

  Prism.languages.liquid = {
    comment: {
      pattern: /(^\{%\s*comment\s*%\})[\s\S]+(?=\{%\s*endcomment\s*%\}$)/,
      lookbehind: true,
    },
    delimiter: {
      pattern: /^\{(?:\{\{|[%\{])-?|-?(?:\}\}|[%\}])\}$/,
      alias: 'punctuation',
    },
    string: {
      pattern: /"[^"]*"|'[^']*'/,
      greedy: true,
    },
    keyword:
      /\b(?:as|assign|break|(?:end)?(?:capture|case|comment|for|form|if|paginate|raw|style|tablerow|unless)|continue|cycle|decrement|echo|else|elsif|in|include|increment|limit|liquid|offset|range|render|reversed|section|when|with)\b/,
    object:
      /\b(?:address|all_country_option_tags|article|block|blog|cart|checkout|collection|color|country|country_option_tags|currency|current_page|current_tags|customer|customer_address|date|discount_allocation|discount_application|external_video|filter|filter_value|font|forloop|fulfillment|generic_file|gift_card|group|handle|image|line_item|link|linklist|localization|location|measurement|media|metafield|model|model_source|order|page|page_description|page_image|page_title|part|policy|product|product_option|recommendations|request|robots|routes|rule|script|search|selling_plan|selling_plan_allocation|selling_plan_group|shipping_method|shop|shop_locale|sitemap|store_availability|tax_line|template|theme|transaction|unit_price_measurement|user_agent|variant|video|video_source|view)\b/,
    function: [
      {
        pattern: /(\|\s*)\w+/,
        lookbehind: true,
        alias: 'filter',
      },
      {
        pattern: /(\.\s*)(?:first|last|size)/,
        lookbehind: true,
      },
    ],
    boolean: /\b(?:false|nil|true)\b/,
    range: {
      pattern: /\.\./,
      alias: 'operator',
    },
    number: /\b\d+(?:\.\d+)?\b/,
    operator: /[!=]=|<>|[<>]=?|[|?:=-]|\b(?:and|contains(?=\s)|or)\b/,
    punctuation: /[.,\[\]()]/,
    empty: {
      pattern: /\bempty\b/,
      alias: 'keyword',
    },
  };

  Prism.hooks.add('before-tokenize', (env) => {
    const liquidPattern =
      /\{%\s*comment\s*%\}[\s\S]*?\{%\s*endcomment\s*%\}|\{(?:%[\s\S]*?%|\{\{[\s\S]*?\}\}|\{[\s\S]*?\})\}/g;
    let insideRaw = false;

    Prism.languages['markup-templating'].buildPlaceholders(
      env,
      'liquid',
      liquidPattern,
      (match) => {
        const tagMatch = /^\{%-?\s*(\w+)/.exec(match);
        if (tagMatch) {
          const tag = tagMatch[1];
          if (tag === 'raw' && !insideRaw) {
            insideRaw = true;
            return true;
          }
          if (tag === 'endraw') {
            insideRaw = false;
            return true;
          }
        }

        return !insideRaw;
      },
    );
  });

  Prism.hooks.add('after-tokenize', (env) => {
    Prism.languages['markup-templating'].tokenizePlaceholders(env, 'liquid');
  });
};

export default function prismIncludeLanguages(PrismObject) {
  const {
    themeConfig: {prism},
  } = siteConfig;
  const additionalLanguages = prism?.additionalLanguages ?? [];

  const prismBefore = globalThis.Prism;
  globalThis.Prism = PrismObject;
  if (typeof globalThis.eval === 'function') {
    globalThis.eval('var Prism = globalThis.Prism');
  }

  additionalLanguages.forEach((lang) => {
    if (lang === 'markup') {
      return;
    }
    if (lang === 'liquid') {
      registerMarkupTemplating(PrismObject);
      registerLiquid(PrismObject);
      return;
    }
    if (lang === 'php') {
      require('prismjs/components/prism-markup-templating.js');
    }
    require(`prismjs/components/prism-${lang}`);
  });

  delete globalThis.Prism;
  if (typeof prismBefore !== 'undefined') {
    globalThis.Prism = prismBefore;
  }
}
