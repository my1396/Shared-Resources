#!/bin/bash

# render-quiz.sh
# Renders a Quarto document and automatically appends suffix based on params.solution:
#   - params.solution: true  → _solution.pdf
#   - params.solution: false → _question.pdf
# Usage: ./render-quiz.sh quiz_05_logistic_regression.qmd

if [ $# -eq 0 ]; then
    echo "Usage: $0 <qmd_file>"
    exit 1
fi

QMD_FILE="$1"
BASE_NAME="${QMD_FILE%.qmd}"

# Drop a symlink left behind by an older version of this script, so Quarto
# writes a real file instead of following the link to a previous output.
if [ -L "${BASE_NAME}.pdf" ]; then
    rm -f "${BASE_NAME}.pdf"
fi

# LaTeX runs inside OneDrive often die on I/O timeouts. If the project's .quarto cache
# is symlinked out of OneDrive (setup-local-cache.sh), run LaTeX there instead; the
# finished PDF is moved into place below. Otherwise build next to the .qmd as before.
DOC_DIR="$(dirname "$QMD_FILE")"
DOC_STEM="$(basename "$BASE_NAME")"
if [ -L "$DOC_DIR/.quarto" ]; then
    LATEX_ARGS=(-M latex-output-dir:.quarto/latex)
    BUILT_PDF="$DOC_DIR/.quarto/latex/$DOC_STEM.pdf"
    rm -f "$BUILT_PDF"
else
    LATEX_ARGS=()
    BUILT_PDF="${BASE_NAME}.pdf"
fi

# A complete PDF ends with an %%EOF marker; a stub cut off by an I/O timeout does not
pdf_ok() { [ -f "$1" ] && tail -c 1024 "$1" | grep -aq '%%EOF'; }

# Render the document; retry, because LaTeX runs inside OneDrive sometimes die on
# I/O timeouts ("Operation timed out") and leave a truncated stub PDF behind
MAX_TRIES=3
RENDER_OK=0
for TRY in $(seq 1 $MAX_TRIES); do
    echo "Rendering $QMD_FILE (attempt $TRY of $MAX_TRIES)..."
    if quarto render "$QMD_FILE" --no-execute-daemon "${LATEX_ARGS[@]}" && pdf_ok "$BUILT_PDF"; then
        RENDER_OK=1
        break
    fi
done

# Never rename a broken PDF over a good one
if [ "$RENDER_OK" -ne 1 ]; then
    echo "✗ Render failed after $MAX_TRIES attempts; existing PDFs left unchanged."
    exit 1
fi

# Check if params.solution is true (and not commented out)
if grep -q "^\s*solution:\s*true" "$QMD_FILE" && ! grep -q "^\s*#.*solution:\s*true" "$QMD_FILE"; then
    SUFFIX="solution"
else
    SUFFIX="question"
fi

# Move the PDF into place via a temporary name, so a copy into OneDrive that is cut
# off by a timeout never replaces a good PDF
TARGET="${BASE_NAME}_${SUFFIX}.pdf"
if mv "$BUILT_PDF" "${TARGET}.part" && pdf_ok "${TARGET}.part"; then
    mv "${TARGET}.part" "$TARGET"
    echo "✓ Renamed to: $TARGET"
else
    rm -f "${TARGET}.part"
    echo "✗ Could not move the PDF into place; existing PDFs left unchanged."
    exit 1
fi
