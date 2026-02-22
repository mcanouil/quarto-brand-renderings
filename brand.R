first_non_empty <- function(...) {
  for (value in list(...)) {
    if (is.null(value) || length(value) == 0L) {
      next
    }
    if (is.character(value) && !nzchar(value[[1L]])) {
      next
    }
    return(value)
  }
  NULL
}

get_brand_info <- function() {
  jsonlite::fromJSON(Sys.getenv("QUARTO_EXECUTE_INFO", unset = ""))
}

configure_brand_fonts <- function(brand_mode = "light") {
  info <- get_brand_info()
  brand <- info[["format"]][["render"]][["brand"]]
  modes <- intersect(c("light", "dark"), names(brand))

  if (length(modes) == 0L) {
    return(invisible(NULL))
  }

  imports <- character(0L)
  doc_dir <- dirname(first_non_empty(info[["document-path"]], ""))

  for (mode in modes) {
    fonts <- brand[[mode]][["data"]][["typography"]][["fonts"]]
    if (is.null(fonts) || nrow(fonts) == 0L) {
      next
    }

    for (ifont in seq_len(nrow(fonts))) {
      family <- as.character(fonts[["family"]][[ifont]])
      source <- as.character(fonts[["source"]][[ifont]])
      if (!nzchar(family) || !nzchar(source) || identical(source, "system")) {
        next
      }

      if (identical(source, "file")) {
        files <- fonts[["files"]][[ifont]]
        if (is.data.frame(files) && "path" %in% names(files)) {
          for (fp in as.character(files[["path"]])) {
            resolved <- file.path(doc_dir, fp)
            if (file.exists(resolved)) {
              systemfonts::register_font(family, plain = resolved)
            }
          }
        }
        next
      }

      import_repository <- switch(
        source,
        google = "Google Fonts",
        bunny = "Bunny Fonts",
        NULL
      )
      local_repositories <- switch(
        source,
        google = c("Google Fonts", "Font Squirrel", "Font Library"),
        bunny = c(
          "Bunny Fonts",
          "Google Fonts",
          "Font Squirrel",
          "Font Library"
        ),
        NULL
      )

      systemfonts::require_font(
        family,
        repositories = local_repositories,
        error = FALSE,
        verbose = FALSE
      )

      if (identical(mode, brand_mode) && !is.null(import_repository)) {
        imports <- c(
          imports,
          systemfonts::fonts_as_import(
            family = family,
            type = "import",
            repositories = import_repository,
            may_embed = TRUE
          )
        )
      }
    }
  }

  systemfonts::reset_font_cache()

  dev <- knitr::opts_chunk$get("dev")
  if (
    !is.null(dev) && any(dev %in% c("svglite", "svg")) && length(imports) > 0L
  ) {
    dev_args <- knitr::opts_chunk$get("dev.args")
    if (is.null(dev_args)) {
      dev_args <- list()
    }
    dev_args[["web_fonts"]] <- unique(imports)
    knitr::opts_chunk$set(dev.args = dev_args)
  }

  invisible(NULL)
}

theme_brand <- function(base_size = 11, brand_mode = "light") {
  info <- get_brand_info()
  brand <- info[["format"]][["render"]][["brand"]]
  if (is.null(brand) || length(brand) == 0L) {
    stop("No brand configuration found in execute info.", call. = FALSE)
  }

  if (!brand_mode %in% names(brand)) {
    brand_mode <- names(brand)[[1L]]
  }

  brand_data <- brand[[brand_mode]][["data"]]
  colors <- brand_data[["color"]]
  typography <- brand_data[["typography"]]
  palette <- colors[["palette"]]
  palette_values <- if (is.null(palette)) {
    character(0L)
  } else {
    unname(unlist(palette, use.names = FALSE))
  }

  ink <- first_non_empty(colors[["foreground"]], "black")
  paper <- first_non_empty(colors[["background"]], "white")
  accent <- scales::col_mix(a = ink, b = paper, amount = 0.25)
  heading_family <- first_non_empty(typography[["headings"]], "")
  base_family <- first_non_empty(typography[["base"]], "")

  ggplot2::theme_minimal(
    base_size = base_size,
    base_family = base_family,
    header_family = heading_family,
    base_line_size = base_size / 22,
    base_rect_size = base_size / 22,
    ink = ink,
    paper = paper,
    accent = accent
  ) +
    ggplot2::theme(
      axis.line.x = ggplot2::element_line(colour = accent),
      axis.line.y = ggplot2::element_line(colour = accent),
      legend.title = ggplot2::element_text(colour = accent),
      plot.title = ggplot2::element_text(
        colour = accent,
        size = ggplot2::rel(2)
      ),
      plot.title.position = "plot",
      plot.subtitle = ggplot2::element_text(colour = ink),
      palette.colour.discrete = palette_values,
      palette.fill.discrete = palette_values,
      palette.colour.continuous = c(palette_values[[1L]], palette_values[[2L]]),
      palette.fill.continuous = c(palette_values[[1L]], palette_values[[2L]])
    )
}

gt_brand <- function(data, brand_mode = "light") {
  info <- get_brand_info()
  brand <- info[["format"]][["render"]][["brand"]]
  if (is.null(brand) || length(brand) == 0L) {
    stop("No brand configuration found in execute info.", call. = FALSE)
  }

  if (!brand_mode %in% names(brand)) {
    brand_mode <- names(brand)[[1L]]
  }

  brand_data <- brand[[brand_mode]][["data"]]
  colors <- brand_data[["color"]]
  typography <- brand_data[["typography"]]
  palette <- unname(unlist(colors[["palette"]], use.names = FALSE))

  ink <- first_non_empty(colors[["foreground"]], "black")
  paper <- first_non_empty(colors[["background"]], "white")
  accent <- scales::col_mix(a = ink, b = paper, amount = 0.25)
  heading_family <- first_non_empty(typography[["headings"]], "")
  base_family <- first_non_empty(typography[["base"]], "")

  tbl <- gt::gt(data)
  tbl <- gt::opt_table_font(tbl, font = base_family)
  tbl <- gt::tab_options(
    tbl,
    table.background.color = paper,
    table.font.color = ink,
    column_labels.background.color = palette[[1L]],
    column_labels.font.weight = "bold",
    table_body.border.top.color = accent,
    table_body.border.bottom.color = accent
  )
  tbl <- gt::tab_style(
    tbl,
    style = gt::cell_text(font = heading_family, color = paper),
    locations = gt::cells_column_labels()
  )

  tbl
}
