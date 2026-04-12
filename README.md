# Quarto Brand Renderings

Companion repository for the blog post [Branded Figures and Tables in R and Python with Quarto](https://mickael.canouil.fr/posts/2026-04-15-quarto-brand-figures-tables/) by [Mickaël Canouil](https://mickael.canouil.fr).

This repository contains six brand configurations with full R and Python implementations demonstrating how to apply Quarto's `brand` feature to code-generated figures and tables.

Browse the rendered examples at <https://m.canouil.dev/quarto-brand-renderings>.

## Structure

- `brand.R` / `brand.py`: reusable helper functions (`theme_brand()`, `gt_brand()`, `configure_brand_fonts()`, etc.).
- `brands/`: six brand configurations (colours, fonts, light/dark modes), each with an R and Python page.
- `fonts/`: local font files used by Brand 6.
- `inline-svglite.lua`: Lua filter that inlines SVG images for correct font rendering.
- `penguins.csv`: Palmer Penguins sample dataset.

## Requirements

- [Quarto CLI](https://quarto.org/) (>= 1.9.37).
- R packages: `ggplot2`, `gt`, `scales`, `systemfonts`, `jsonlite`.
- Python packages: listed in `pyproject.toml` (install with `uv sync`).

## Licence

Copyright (c) 2026 Mickaël Canouil.
MIT Licence.
