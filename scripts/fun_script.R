plot_png <- function(p, fn, width = 5.5, height = 4, ppi = 300) {
    #' If p is a function, call it to generate the plot; → This is useful for functions that directly draw to the current device (e.g., corrplot), and does not return a plot object.
    #' If p is a static plot object, print it directly.
    #' @param p A plot object or a function that generates a plot when called.
    #' @param fn File name to save the image.
    png(fn, width = width * ppi, height = height * ppi, res = ppi)
    if (is.function(p)) p() else print(p)
    dev.off()
}

quick_summary <- function(x, full = FALSE) {
    # Function to compute basic descriptive statistics
    if (!full) {
        # Basic summary
        data.frame(
            n = length(x),
            min = min(x),
            mean = mean(x),
            median = median(x),
            max = max(x),
            sd = sd(x),
            skewness = moments::skewness(x),
            kurtosis = moments::kurtosis(x),
            row.names = NULL
        )
    } else {
        # Full summary with quartiles and IQR
        data.frame(
            n = length(x),
            min = min(x),
            Q1 = quantile(x, 0.25),
            mean = mean(x),
            median = median(x),
            Q3 = quantile(x, 0.75),
            max = max(x),
            IQR = IQR(x),
            sd = sd(x),
            skewness = moments::skewness(x),
            kurtosis = moments::kurtosis(x),
            row.names = NULL
        )
    }
}

preview_data <- function(df, n = 4, gap = "...", digits = 3, width = 70, ...) {
    #' Show the first and last n rows of a data frame as a kable table, with a blank row between the two parts.
    #' Original row names are kept, so the jump in row numbers shows that rows were skipped.
    #' In PDF output, a wide table is split into stacked column blocks so the font stays readable.
    #' @param df A data frame, tibble or data.table.
    #' @param n Number of rows to show at the top and at the bottom.
    #' @param gap Row label of the blank separator row; use "" for a fully blank row.
    #' @param digits Number of decimal places, passed to knitr::kable().
    #' @param width PDF only: maximum characters per table row before the columns are split into another block.
    #' @param ... Other arguments passed to knitr::kable(), e.g. caption.
    df <- as.data.frame(df) # tibbles and data.tables don't support row names
    n_obs <- nrow(df)
    if (n_obs > 2 * n) {
        top <- seq_len(n)
        bottom <- (n_obs - n + 1):n_obs
        out <- df[c(top, NA, bottom), , drop = FALSE] # NA index gives an all-NA row
        rownames(out) <- c(rownames(df)[top], gap, rownames(df)[bottom])
    } else {
        out <- df
    }
    op <- options(knitr.kable.NA = "") # show NA cells as blank
    on.exit(options(op))
    if (!knitr::is_latex_output()) {
        return(knitr::kable(out, digits = digits, ...))
    }

    # PDF: pandoc squeezes a wide pipe table into narrow, overlapping columns.
    # Instead, estimate each column's width in characters and fill blocks of at most `width` characters.
    col_chars <- vapply(out, function(x) {
        if (is.numeric(x)) x <- round(x, digits)
        max(nchar(format(x)), na.rm = TRUE)
    }, numeric(1))
    col_chars <- pmax(col_chars, nchar(names(out))) + 2 # + 2 for column padding
    show_rownames <- !identical(rownames(out), as.character(seq_len(nrow(out))))
    budget <- width - if (show_rownames) max(nchar(rownames(out))) + 2 else 0
    block <- integer(length(col_chars))
    b <- 1
    used <- 0
    for (j in seq_along(col_chars)) {
        if (used > 0 && used + col_chars[j] > budget) {
            b <- b + 1
            used <- 0
        }
        block[j] <- b
        used <- used + col_chars[j]
    }

    args <- modifyList(list(format = "latex", booktabs = TRUE, linesep = "", digits = digits), list(...))
    caption <- args$caption
    args$caption <- NULL
    tabs <- vapply(split(names(out), block), function(cols) {
        tab <- do.call(knitr::kable, c(list(out[, cols, drop = FALSE]), args))
        # shrink a block only if it is still wider than the page
        paste0("\\begin{adjustbox}{max width=\\linewidth, center}\n", trimws(tab), "\n\\end{adjustbox}")
    }, character(1))
    body <- paste(tabs, collapse = "\n\\par\\medskip\n")
    if (!is.null(caption)) {
        body <- paste0("\\begin{table}\n\\caption{", caption, "}\n", body, "\n\\end{table}")
    }
    knitr::asis_output(
        paste0("\n```{=latex}\n\\begingroup\\small\n", body, "\n\\endgroup\n```\n"),
        meta = list(rmarkdown::latex_dependency("booktabs"), rmarkdown::latex_dependency("adjustbox"))
    )
}
