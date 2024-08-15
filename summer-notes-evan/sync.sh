#!/usr/bin/env bash
set -euxo pipefail

typst compile 0xparc-summer-2024-notes.typ
gsutil cp 0xparc-summer-2024-notes.pdf gs://web.evanchen.cc/private/
