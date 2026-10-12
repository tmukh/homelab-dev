"""Seal a Kubernetes Secret without the plaintext touching disk, the terminal history or a chat.

Values are typed at a hidden prompt, piped straight into kubeseal with the cluster's public cert
(deploy/platform/sealed-secrets/pub-cert.pem), and only the SealedSecret is written.

    python scripts/seal_secret.py --namespace monitoring --name alertmanager-telegram \
        --key bot-token --out deploy/platform/monitoring/manifests/alertmanager-telegram.sealed.yaml
"""

import argparse
import getpass
import subprocess
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parent.parent
CERT = REPO / "deploy" / "platform" / "sealed-secrets" / "pub-cert.pem"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--namespace", required=True)
    p.add_argument("--name", required=True)
    p.add_argument("--key", action="append", default=[], help="typed at a hidden prompt; repeatable")
    p.add_argument("--file", action="append", default=[], help="key=path, value read from the file")
    p.add_argument("--out", required=True, type=Path)
    args = p.parse_args()

    if not args.key and not args.file:
        sys.exit("give at least one --key or --file")
    data = {}
    for item in args.file:
        key, _, path = item.partition("=")
        data[key] = Path(path).read_text(encoding="utf-8")
    for key in args.key:
        value = getpass.getpass(f"{key}: ")
        if not value:
            sys.exit(f"empty value for {key}, nothing written")
        data[key] = value
    secret = {
        "apiVersion": "v1",
        "kind": "Secret",
        "metadata": {"name": args.name, "namespace": args.namespace},
        "stringData": data,
    }
    sealed = subprocess.run(
        ["kubeseal", "--cert", str(CERT), "--format", "yaml"],
        input=yaml.safe_dump(secret),
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(sealed, encoding="utf-8", newline="\n")
    print(f"wrote {args.out} (keys: {', '.join(data)})")


if __name__ == "__main__":
    main()
