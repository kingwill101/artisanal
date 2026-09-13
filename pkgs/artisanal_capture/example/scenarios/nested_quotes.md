# Nested Markdown

Normal text before the quote.

> A quoted paragraph with **bold text**, *emphasis*, and `inline code`.
>
> > ## Nested section
> >
> > A deeper paragraph that should wrap without losing either quote border.
> >
> > - First list item with enough text to wrap across several terminal columns.
> > - Second list item
> >   - Nested list item
> >
> > ```dart
> > final answer = 42;
> > print(answer);
> > ```
> >
> > | Part | Status |
> > | --- | --- |
> > | Layout | Quoted |
> > | Styles | Preserved |
>
> Back at the outer level.

- A list item before a quote

  > A quote inside the list item.
  >
  > Followed by another quoted paragraph.

  The list item continues here.

Normal text after the quote.
