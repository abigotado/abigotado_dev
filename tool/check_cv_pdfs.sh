#!/usr/bin/env bash
# Fails when a résumé PDF in web/cv/ carries a phone-like number.
#
# The PDFs are binary, so a re-export that still has the phones would pass
# review unseen and land in public history. The check fails closed: an
# unreadable PDF, an image-only PDF, or a missing file is an error too. It never
# prints a match, because the Actions log is public.
#
#   tool/check_cv_pdfs.sh              check web/cv/*.pdf (needs pdftotext)
#   tool/check_cv_pdfs.sh --self-test  check the detector against fixed cases
set -euo pipefail
shopt -s nullglob

# Exits 0 when stdin holds something phone-like. Year ranges (2019-2021) are
# dropped first so résumé dates don't trip the digit-run rule. Empty input also
# counts as a hit, so a failed extraction can never pass.
phone_like() {
  perl -CSD -0777 -ne '
    exit 0 unless /\S/;
    s/\s+/ /g;
    s/\b(?:19|20)\d\d\s?[-\x{2013}]\s?(?:19|20)\d\d\b//g;
    exit(/\+\s?\d|(?:\d[\s().\x{00A0}\x{2011}\x{2013}-]{0,2}){7,}\d/ ? 0 : 1);
  '
}

self_test() {
  local failed=0 sample
  local -a hits=(
    '+7 (999) 123-45-67'
    '8 999 123 45 67'
    '8 999 123–45–67'
    '11 1234-5678'
    '15-1234-5678'
    '612 34 56 78'
    $'tel 612\302\24034\302\24056\302\24078'
    $'call 11 1234\n-5678'
  )
  local -a misses=(
    '2019-2021'
    '2019 – 2021'
    '09.2024 – 01.2026'
    '70–75%'
    'version 1.2.3'
  )
  for sample in "${hits[@]}"; do
    if ! printf '%s' "$sample" | phone_like; then
      echo "self-test: missed a phone-like sample: $sample"
      failed=1
    fi
  done
  for sample in "${misses[@]}"; do
    if printf '%s' "$sample" | phone_like; then
      echo "self-test: false positive on: $sample"
      failed=1
    fi
  done
  if printf '' | phone_like; then :; else
    echo 'self-test: empty text must fail closed'
    failed=1
  fi
  return "$failed"
}

check_pdfs() {
  local -a pdfs=(web/cv/*.pdf)
  local failed=0 pdf text
  if ((${#pdfs[@]} < 2)); then
    echo '::error::expected the en and ru résumé PDFs in web/cv/'
    return 1
  fi
  for pdf in "${pdfs[@]}"; do
    if ! text=$(pdftotext "$pdf" -); then
      echo "::error file=$pdf::pdftotext could not read the résumé PDF"
      failed=1
    elif ! grep -qE 'Kovalenko|Коваленко' <<<"$text"; then
      echo "::error file=$pdf::no extractable résumé text — a scanned PDF can't be checked"
      failed=1
    elif phone_like <<<"$text" || LC_ALL=C grep -aqE 'tel:|wa\.me' "$pdf"; then
      echo "::error file=$pdf::phone-like number or link in the résumé PDF — re-render it without phones"
      failed=1
    fi
  done
  return "$failed"
}

case "${1:-}" in
  --self-test) self_test ;;
  '') check_pdfs ;;
  *) echo "usage: $0 [--self-test]" >&2; exit 2 ;;
esac
