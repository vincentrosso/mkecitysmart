#!/usr/bin/env python3
"""
Lightweight Firebase Auth tester to exercise the same Identity Toolkit endpoints
the Flutter app uses. Supports email/password sign-up and sign-in via REST.

Config is sourced from environment variables first to respect any runtime
overrides, then falls back to the web config present in lib/firebase_options.dart.

Usage:
  python scripts/test_firebase_auth.py sign-up --email you@example.com --password hunter22
  python scripts/test_firebase_auth.py sign-in --email you@example.com --password hunter22
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from typing import Any, Dict

import requests


# Values must be provided via environment variables.
DEFAULT_PROJECT_ID = "mkeparkapp-6edc3"


@dataclass
class FirebaseConfig:
    api_key: str
    project_id: str

    @classmethod
    def load(cls) -> "FirebaseConfig":
        api_key = os.environ.get("FIREBASE_WEB_API_KEY", "")
        project_id = os.environ.get("FIREBASE_PROJECT_ID", DEFAULT_PROJECT_ID)
        if not api_key:
            raise RuntimeError(
                "FIREBASE_WEB_API_KEY is required. Export it before running this script."
            )
        return cls(api_key=api_key, project_id=project_id)


class FirebaseAuthClient:
    def __init__(self, config: FirebaseConfig) -> None:
        self.config = config
        self.base_url = (
            "https://identitytoolkit.googleapis.com/v1/accounts"
            f"?key={self.config.api_key}"
        )

    def _post(self, path: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        url = f"{self.base_url}:{path}"
        resp = requests.post(url, json=payload, timeout=15)
        try:
            data = resp.json()
        except json.JSONDecodeError:
            resp.raise_for_status()
            raise
        if not resp.ok:
            code = data.get("error", {}).get("message", "UNKNOWN")
            raise RuntimeError(f"{path} failed: {code}")
        return data

    def sign_up(self, email: str, password: str) -> Dict[str, Any]:
        return self._post(
            "signUp",
            {
                "email": email,
                "password": password,
                "returnSecureToken": True,
            },
        )

    def sign_in(self, email: str, password: str) -> Dict[str, Any]:
        return self._post(
            "signInWithPassword",
            {
                "email": email,
                "password": password,
                "returnSecureToken": True,
            },
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Firebase Auth REST tester")
    sub = parser.add_subparsers(dest="command", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--email", required=True, help="User email")
    common.add_argument(
        "--password",
        required=True,
        help="Password (must meet Firebase strength rules: >=6 chars, etc.)",
    )

    sub.add_parser("sign-up", parents=[common], help="Create account with email/password")
    sub.add_parser("sign-in", parents=[common], help="Sign in with email/password")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    cfg = FirebaseConfig.load()
    client = FirebaseAuthClient(cfg)

    try:
        if args.command == "sign-up":
            result = client.sign_up(args.email, args.password)
            print(json.dumps(result, indent=2))
        elif args.command == "sign-in":
            result = client.sign_in(args.email, args.password)
            print(json.dumps(result, indent=2))
        else:
            raise ValueError(f"Unknown command: {args.command}")
    except Exception as exc:  # noqa: BLE001 - surface REST errors directly
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
