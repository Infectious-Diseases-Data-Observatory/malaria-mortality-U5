# Project rules

## Paper figures: text size

Text in every ggplot figure that goes into the paper (main or supplementary) must be larger than ggplot's defaults
**at the size it is printed** (author rule, 27 October 2026):

| Element | Minimum printed size | ggplot default |
|---|---|---|
| Axis titles, legend titles | 12 pt | 11 pt |
| Axis tick labels, legend text, facet strip labels, text drawn in the plot (`geom_text`, `annotate`) | 10 pt | 8.8 pt |

- **Printed size** = size in the script × printed width ÷ saved width (`ggsave` width).
- **Printed width** is the figure's `\includegraphics` width in `main.tex`: `\linewidth` is 6.5 in (12 pt article,
  1 in margins), `0.95\linewidth` is 6.2 in. For a figure not yet in `main.tex`, assume `\linewidth`.
- `geom_text` and `annotate` sizes are in mm: points = size × 2.845.
- Save figures close to their printed width (about 6.5–7.5 in) so that sizes in the script are close to printed
  sizes; a figure saved 16 in wide needs about 30 pt axis titles to meet the rule.
- Check a figure against this rule whenever it is created or changed.

## Paper figures: no subtext

Figures for the paper carry no title, subtitle or caption text inside the image (`labs(title, subtitle, caption)`,
`ggtitle`, `plot_annotation(title, subtitle, caption)`, or notes placed below or above the panels) (author rule,
27 October 2026). Explanations, notes on which points are labelled or adjusted, and data sources go in the figure's
caption file (`CAPTION*.md`). Panel tags (A, B, C), facet strip labels, axis titles, legends and in-panel annotations
that label the data remain.

The Overleaf `main.tex` is read-only for this work: propose text and captions in the repo (`docs/manuscript/`) and
never edit it.
