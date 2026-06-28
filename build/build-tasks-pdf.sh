#!/usr/bin/env bash
# Собирает ОТДЕЛЬНЫЙ мини-PDF только с задачами с собеседований по
# Objective-C (гид + три раздела Junior/Middle/Senior).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
META="${META:-$ROOT/build/metadata-tasks.yaml}"
OUT="${1:-$ROOT/Zadachi-s-sobesedovaniy-po-Objective-C.pdf}"

FILES=(
  "$ROOT/docs/tutorial/C-interview-guide.md"
  "$ROOT/docs/tutorial/D-interview-junior.md"
  "$ROOT/docs/tutorial/E-interview-middle.md"
  "$ROOT/docs/tutorial/F-interview-senior.md"
)

echo "Сборка мини-PDF задач: ${#FILES[@]} раздела → $OUT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pandoc \
  -s \
  "$META" \
  "${FILES[@]}" \
  --pdf-engine=xelatex \
  --top-level-division=chapter \
  --highlight-style=tango \
  --listings=false \
  -o "$TMP/tasks.tex"

cd "$TMP"
for i in 1 2 3; do
  echo "  xelatex pass $i/3..."
  xelatex -interaction=batchmode -halt-on-error tasks.tex >/dev/null 2>&1 || {
    xelatex -interaction=nonstopmode tasks.tex 2>&1 | tail -30
    exit 1
  }
done

mv "$TMP/tasks.pdf" "$OUT"
cd "$ROOT"
echo "Готово: $OUT ($(du -h "$OUT" | cut -f1))"
