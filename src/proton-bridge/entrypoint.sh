#!/bin/sh
# Bridge keeps its vault key in `pass`, which needs a gpg key. Both live in $HOME,
# which is the persistent volume, so they are created once and reused.
set -eu

export GNUPGHOME="$HOME/.gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

if ! gpg --list-secret-keys bridge >/dev/null 2>&1; then
  gpg --batch --passphrase '' --quick-gen-key bridge default default never
fi
if [ ! -f "$HOME/.password-store/.gpg-id" ]; then
  pass init bridge
fi

exec /usr/lib/protonmail/bridge/bridge "$@"
