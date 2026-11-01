# Project rules

## Paper figures: text size

Text in every ggplot figure that goes into the paper (main or supplementary) must be at least ggplot's default size for
titles and larger than it for other text, **at the size it is printed** (author rule, 27 October 2026; sizes reduced
by about 10% on 28 October 2026):

| Element | Minimum printed size | ggplot default |
|---|---|---|
| Axis titles, legend titles | 11 pt | 11 pt |
| Axis tick labels, legend text, facet strip labels, text drawn in the plot (`geom_text`, `annotate`) | 9 pt | 8.8 pt |
| Panel tags (A, B, C) | 12 pt | 13.2 pt |

- **Printed size** = size in the script × printed width ÷ saved width (`ggsave` width).
- **Printed width** is the figure's `\includegraphics` width in `main.tex`: `\linewidth` is 6.5 in (12 pt article,
  1 in margins), `0.95\linewidth` is 6.2 in. For a figure not yet in `main.tex`, assume `\linewidth`.
- `geom_text` and `annotate` sizes are in mm: points = size × 2.845.
- Save figures close to their printed width (about 6.5–7.5 in) so that sizes in the script are close to printed
  sizes; a figure saved 16 in wide needs about 27 pt axis titles to meet the rule.
- Check a figure against this rule whenever it is created or changed.
- **Exception (author request, 28 October 2026):** Figure 4 and its supplementary IHME version
  (`R_cbh/reporting/24_malaria_mortality_rates.R`) use text 20% below the original sizes: axis titles 9.6 pt, other
  text 8 pt, panel tags 10.4 pt. Keep these unless the author asks otherwise.

## Paper figures: no subtext

Figures for the paper carry no title, subtitle or caption text inside the image (`labs(title, subtitle, caption)`,
`ggtitle`, `plot_annotation(title, subtitle, caption)`, or notes placed below or above the panels) (author rule,
27 October 2026). Explanations, notes on which points are labelled or adjusted, and data sources go in the figure's
caption file (`CAPTION*.md`). Panel tags (A, B, C), facet strip labels, axis titles, legends and in-panel annotations
that label the data remain.

The Overleaf `main.tex` is read-only for this work: the author edits it by hand. Give proposed text and captions in the
conversation and never edit `main.tex`; manuscript drafts are not kept in the repo (author decision, 1 November 2026).
