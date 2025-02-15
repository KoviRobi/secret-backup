#!/usr/bin/env nix-shell
#! nix-shell ./shell.nix -i bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <keys>"
  exit 1
fi

mkdir -p 1-sec 2-paperkeys 3-split 4-png 5-labelled

for key in "$@"; do
  gpg --export-options backup --export-secret-keys "$key" >"1-sec/$key.sec"

  paperkey <"1-sec/$key.sec" --output-type raw >"2-paperkeys/$key.paperkey"

  split -b 1273 "2-paperkeys/$key.paperkey" "3-split/$key.paperkey."

  cd 3-split
  for f in "$key".paperkey.??; do
    qrencode <"$f" -8 -l H -o "../4-png/$f.png"
  done
  cd ..

  cd 4-png
  for f in "$key".paperkey.??.png; do
    magick "$f" \
      -font DejaVu-Sans -background white "label:$f" \
      +swap -gravity Center -append "../5-labelled/$f"
  done
  cd ..

  [ -d 6-test ] || mkdir 6-test
  [ -d 6-test/gnupghome ] || mkdir 6-test/gnupghome
  chmod 700 6-test/gnupghome
  [ -x pubkey.gpg ] || gpg --export >pubkey.gpg
  cat >6-test/test-"$key".sh <<EOF
export GNUPGHOME=\$(realpath gnupghome)
for f in ../5-labelled/$key.paperkey.??.png; do
  g=\${f#../5-labelled/}
  h=\${g%.png}
  zbarimg -1 --raw -Sbinary \$f > \$h.bin;
done
cat $key.paperkey.??.bin > $key.paperkey
paperkey --pubring ../pubkey.gpg < $key.paperkey | gpg --pinentry-mode loopback --import
EOF
  chmod +x 6-test/test-"$key".sh
done
