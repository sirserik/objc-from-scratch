#!/usr/bin/env bash
# Собирает PDF учебника «Objective-C с нуля» из docs/tutorial/*.md.
# Использование: ./build/build-pdf.sh [output.pdf] [файл1.md файл2.md ...]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Файл метаданных можно переопределить через переменную META
# (CI подставляет вариант со свободными шрифтами).
META="${META:-$ROOT/build/metadata.yaml}"
OUT="${1:-$ROOT/Objective-C-s-nulya.pdf}"
shift || true

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=(
    "$ROOT/docs/tutorial/00-intro.md"
    "$ROOT/docs/tutorial/01-setup.md"
    "$ROOT/docs/tutorial/02-c-basics.md"
    "$ROOT/docs/tutorial/03-pointers-memory.md"
    "$ROOT/docs/tutorial/04-c-arrays-strings.md"
    "$ROOT/docs/tutorial/05-objects-messages.md"
    "$ROOT/docs/tutorial/06-first-class.md"
    "$ROOT/docs/tutorial/07-init-dealloc.md"
    "$ROOT/docs/tutorial/08-properties.md"
    "$ROOT/docs/tutorial/09-inheritance.md"
    "$ROOT/docs/tutorial/10-protocols.md"
    "$ROOT/docs/tutorial/11-categories-extensions.md"
    "$ROOT/docs/tutorial/12-blocks.md"
    "$ROOT/docs/tutorial/13-memory-arc.md"
    "$ROOT/docs/tutorial/14-runtime-hierarchy.md"
    "$ROOT/docs/tutorial/15-foundation-strings.md"
    "$ROOT/docs/tutorial/16-foundation-numbers.md"
    "$ROOT/docs/tutorial/17-foundation-collections.md"
    "$ROOT/docs/tutorial/18-foundation-values.md"
    "$ROOT/docs/tutorial/19-foundation-files.md"
    "$ROOT/docs/tutorial/20-kvc-kvo.md"
    "$ROOT/docs/tutorial/21-concurrency-runloop.md"
    "$ROOT/docs/tutorial/22-modern-objc.md"
    "$ROOT/docs/tutorial/23-interop-swift.md"
    "$ROOT/docs/tutorial/24-next.md"
    "$ROOT/docs/tutorial/A-class-hierarchy.md"
    "$ROOT/docs/tutorial/B-cheatsheet.md"
    "$ROOT/docs/tutorial/C-interview-guide.md"
    "$ROOT/docs/tutorial/D-interview-junior.md"
    "$ROOT/docs/tutorial/E-interview-middle.md"
    "$ROOT/docs/tutorial/F-interview-senior.md"
  )
fi

EXISTING=()
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    EXISTING+=("$f")
  else
    echo "skip: $f (нет файла)" >&2
  fi
done

echo "Сборка PDF: ${#EXISTING[@]} глав → $OUT"

# Генерим .tex через pandoc, потом гоним xelatex 3 раза подряд —
# чтобы TOC, ссылки и номера страниц сошлись после любого объёма правок.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pandoc \
  -s \
  "$META" \
  "${EXISTING[@]}" \
  --pdf-engine=xelatex \
  --top-level-division=chapter \
  --highlight-style=tango \
  --listings=false \
  -o "$TMP/book.tex"

cd "$TMP"
for i in 1 2 3; do
  echo "  xelatex pass $i/3..."
  xelatex -interaction=batchmode -halt-on-error book.tex >/dev/null 2>&1 || {
    xelatex -interaction=nonstopmode book.tex 2>&1 | tail -30
    exit 1
  }
done

mv "$TMP/book.pdf" "$OUT"
cd "$ROOT"

echo "Готово: $OUT ($(du -h "$OUT" | cut -f1))"
