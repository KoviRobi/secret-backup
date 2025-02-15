#!/usr/bin/env nix-shell
#! nix-shell ./shell.nix -i bash

set -euo pipefail

read -r -p "passphrase: " passphrase

mkdir -p 1-sym 3-split 4-png 5-labelled

pass git ls-files -z | while read -r -d "" file; do
  out="$(echo "$file" | sed -e 's+_+__+g' -e 's+/+_+g' -e 's+\.gpg$++')"
  pass git show --textconv "@:$file" |
    gpg --batch --symmetric --passphrase-fd=5 5<<<"$passphrase" >"1-sym/$out.bin"

  split -b 1273 "1-sym/$out.bin" "3-split/$out.pass."

  cd 3-split
  for f in "$out".pass.??; do
    qrencode <"$f" -d 120 -8 -l H -o "../4-png/$f.png"
  done
  cd ..

  cd 4-png
  for f in *.pass.??.png; do
    magick "$f" \
      -font DejaVu-Sans -background white "label:$f" \
      +swap -gravity Center -append "../5-labelled/$f"
  done
  cd ..

  [ -d 6-test ] || mkdir 6-test
  [ -d 6-test/gnupghome ] || mkdir 6-test/gnupghome
  chmod 700 6-test/gnupghome
  [ -x pubkey.gpg ] || gpg --export >pubkey.gpg
  cat >6-test/test-"$out".sh <<EOF
export GNUPGHOME=\$(realpath gnupghome)
for f in ../5-labelled/$out.pass.??.png; do
  g=\${f#../5-labelled/}
  h=\${g%.png}
  zbarimg -1 --raw -Sbinary \$f > \$h.bin;
done
cat $out.pass.??.bin >"$out.pass"
gpg --pinentry-mode loopback -d "$out.pass"
EOF
  chmod +x 6-test/test-"$out".sh
done
