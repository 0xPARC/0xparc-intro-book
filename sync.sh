#!/bin/bash

set -euxo pipefail

latexmk
typst compile retreat-notes.typ
gsutil cp evan/evan-pcp-old-notes.pdf gs://web.evanchen.cc/upload/0xparc-notes-sp2024.pdf
gsutil cp evan/evan-retreat-notes.pdf gs://web.evanchen.cc/upload/0xparc-retreat-sp2024.pdf
gsutil setmeta -h 'Cache-Control:private, max-age=0, no-transform' gs://web.evanchen.cc/upload/0xparc-notes-sp2024.pdf
gsutil setmeta -h 'Cache-Control:private, max-age=0, no-transform' gs://web.evanchen.cc/upload/0xparc-retreat-sp2024.pdf
