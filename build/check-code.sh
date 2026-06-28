#!/usr/bin/env bash
# Компилирует все примеры из code/ с теми же флагами, что в книге.
# Падает, если хоть один файл не собрался или дал предупреждение.
#
# Файлы .m компилируются с ARC и Foundation (как в основной части книги).
# Файлы с суффиксом *.mrr.m — БЕЗ ARC (-fno-objc-arc): это примеры ручного
# управления памятью (retain/release/autorelease) из главы про память.
# Чистый Си из вводных глав лежит в *.c.

set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CODE="$ROOT/code"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
shopt -s nullglob

compile() {  # $1 = файл, $2... = доп. флаги
  local f="$1"; shift
  local name; name="$(basename "$f")"
  local out="$TMP/${name%.*}"
  if clang "$@" -Wall -Wextra -O2 "$f" -o "$out" 2> "$TMP/$name.log"; then
    if [ -s "$TMP/$name.log" ]; then
      echo "WARN  $name"; cat "$TMP/$name.log"; fail=1
    else
      echo "OK    $name"
    fi
  else
    echo "FAIL  $name"; cat "$TMP/$name.log"; fail=1
  fi
}

# Чистый Си (вводные главы)
for f in "$CODE"/*.c; do
  compile "$f" -std=c11
done

# Objective-C без ARC (ручное управление памятью)
for f in "$CODE"/*.mrr.m; do
  compile "$f" -fno-objc-arc -framework Foundation
done

# Objective-C с ARC (основная часть). Исключаем уже обработанные *.mrr.m.
for f in "$CODE"/*.m; do
  case "$f" in *.mrr.m) continue;; esac
  compile "$f" -fobjc-arc -framework Foundation
done

if [ "$fail" -ne 0 ]; then
  echo "--- есть проблемы ---"
  exit 1
fi
echo "--- все примеры собрались чисто ---"
