import json
import os
import pathlib

import matplotlib.font_manager as fm
import pyfonts
from great_tables import GT, loc, style
from plotnine import element_line, element_rect, element_text, theme, theme_minimal


def get_brand_info() -> dict:
    raw = os.environ.get("QUARTO_EXECUTE_INFO", "")
    if not raw:
        return {}
    path = pathlib.Path(raw)
    if path.is_file():
        return json.loads(path.read_text())
    return json.loads(raw)


def _col_mix(a: str, b: str, amount: float = 0.25) -> str:
    """Blend two hex colours. amount=0 returns a, amount=1 returns b."""
    ra, ga, ba = int(a[1:3], 16), int(a[3:5], 16), int(a[5:7], 16)
    rb, gb, bb = int(b[1:3], 16), int(b[3:5], 16), int(b[5:7], 16)
    r = int(ra + (rb - ra) * amount)
    g = int(ga + (gb - ga) * amount)
    b_val = int(ba + (bb - ba) * amount)
    return f"#{r:02x}{g:02x}{b_val:02x}"


def configure_brand_fonts() -> None:
    info = get_brand_info()
    brand = info.get("format", {}).get("render", {}).get("brand", {})
    modes = [m for m in ["light", "dark"] if m in brand]
    doc_dir = pathlib.Path(info.get("document-path", "")).parent

    for mode in modes:
        fonts = brand[mode].get("data", {}).get("typography", {}).get("fonts", [])
        for font_spec in fonts:
            family = font_spec.get("family", "")
            source = font_spec.get("source", "")
            if not family or not source or source == "system":
                continue

            if source == "file":
                files = font_spec.get("files", [])
                if isinstance(files, dict):
                    files = [files]
                for f in files:
                    fp = f.get("path", "") if isinstance(f, dict) else str(f)
                    resolved = doc_dir / fp
                    if resolved.exists():
                        fm.fontManager.addfont(str(resolved))
                continue

            if source == "bunny":
                font_props = pyfonts.load_bunny_font(family)
            elif source == "google":
                font_props = pyfonts.load_google_font(family)
            else:
                continue
            fm.fontManager.addfont(font_props.get_file())


def get_brand_palette(brand_mode: str = "light") -> list[str]:
    info = get_brand_info()
    brand = info.get("format", {}).get("render", {}).get("brand", {})
    if not brand:
        return []
    if brand_mode not in brand:
        brand_mode = next(iter(brand))
    palette = brand[brand_mode].get("data", {}).get("color", {}).get("palette", {})
    return list(palette.values())


def theme_brand(base_size: int = 11, brand_mode: str = "light") -> theme:
    info = get_brand_info()
    brand = info.get("format", {}).get("render", {}).get("brand", {})
    if not brand:
        raise ValueError("No brand configuration found in execute info.")

    if brand_mode not in brand:
        brand_mode = next(iter(brand))

    brand_data = brand[brand_mode].get("data", {})
    colors = brand_data.get("color", {})
    typography = brand_data.get("typography", {})

    ink = colors.get("foreground", "black")
    paper = colors.get("background", "white")
    accent = _col_mix(ink, paper, 0.25)
    base_family = typography.get("base", "")
    heading_family = typography.get("headings", "")

    base_line_size = base_size / 22
    grid_major_colour = _col_mix(ink, paper, 0.8)
    grid_minor_colour = _col_mix(ink, paper, 0.9)

    return theme_minimal(base_size=base_size, base_family=base_family) + theme(
        plot_background=element_rect(fill=paper, colour="none"),
        panel_background=element_rect(fill=paper, colour="none"),
        panel_grid_major=element_line(
            colour=grid_major_colour, size=base_line_size
        ),
        panel_grid_minor=element_line(
            colour=grid_minor_colour, size=base_line_size * 0.5
        ),
        text=element_text(colour=ink),
        axis_title=element_text(family=heading_family),
        axis_line_x=element_line(colour=accent),
        axis_line_y=element_line(colour=accent),
        plot_title=element_text(
            family=heading_family,
            colour=accent,
            size=base_size * 2,
        ),
        plot_subtitle=element_text(colour=ink),
        legend_title=element_text(family=heading_family, colour=accent),
        legend_background=element_rect(fill=paper, colour="none"),
    )


def gt_brand(data, brand_mode: str = "light") -> GT:
    info = get_brand_info()
    brand = info.get("format", {}).get("render", {}).get("brand", {})
    if not brand:
        raise ValueError("No brand configuration found in execute info.")

    if brand_mode not in brand:
        brand_mode = next(iter(brand))

    brand_data = brand[brand_mode].get("data", {})
    colors = brand_data.get("color", {})
    typography = brand_data.get("typography", {})
    palette = list(colors.get("palette", {}).values())

    ink = colors.get("foreground", "black")
    paper = colors.get("background", "white")
    accent = _col_mix(ink, paper, 0.25)
    base_family = typography.get("base", "")
    heading_family = typography.get("headings", "")

    tbl = GT(data)
    tbl = tbl.tab_options(
        table_font_names=base_family,
        table_font_color=ink,
        table_background_color=paper,
        column_labels_background_color=palette[0] if palette else accent,
        column_labels_font_weight="bold",
        table_body_border_top_color=accent,
        table_body_border_bottom_color=accent,
    )
    tbl = tbl.tab_style(
        style=style.text(font=heading_family, color=paper, weight="bold"),
        locations=loc.column_labels(),
    )

    return tbl
