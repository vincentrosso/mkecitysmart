#!/usr/bin/env python3
"""Environment + secrets health check for the MKEPark Flutter project."""

from __future__ import annotations

import os
import plistlib
import subprocess
import sys
from pathlib import Path
from typing import Dict

ROOT_DIR = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT_DIR / ".env.firebase"
IOS_BUNDLE_ID = "com.mkecitysmart.app"
IOS_GOOGLE_PLIST = ROOT_DIR / "ios" / "Runner" / "GoogleService-Info.plist"
WEB_CONFIG = ROOT_DIR / "web" / "firebase-config.json"
WEB_CONFIG_EXAMPLE = ROOT_DIR / "web" / "firebase-config.example.json"

REQUIRED_ENV_KEYS = [
    "FIREBASE_IOS_API_KEY",
    "FIREBASE_IOS_APP_ID",
    "FIREBASE_IOS_MESSAGING_SENDER_ID",
    "FIREBASE_IOS_PROJECT_ID",
    "FIREBASE_IOS_STORAGE_BUCKET",
    "FIREBASE_IOS_BUNDLE_ID",
    "FIREBASE_IOS_GOOGLE_SERVICE_INFO_PATH",
]

GOOGLE_CONFIG_PATHS = {
    "FIREBASE_ANDROID_GOOGLE_SERVICES_PATH": ("Android google-services.json", True),
    "FIREBASE_IOS_GOOGLE_SERVICE_INFO_PATH": ("iOS GoogleService-Info.plist", True),
    "FIREBASE_MACOS_GOOGLE_SERVICE_INFO_PATH": ("macOS GoogleService-Info.plist", False),
}

PLACEHOLDER_TOKENS = ("REPLACE_ME", "MISSING_FIREBASE", "TODO")

had_failure = False


def main() -> int:
    print("🔎  MKEPark doctor\n")
    env_values = check_env_file()
    check_flutter_cli()
    if env_values:
        check_env_keys(env_values)
        check_secret_paths(env_values)
    check_ios_runner_plist(env_values)
    check_web_config()
    print()
    if had_failure:
        print("❌  Issues found. See messages above.")
        return 1
    print("✅  All required checks passed.")
    return 0


def check_flutter_cli() -> None:
    record_header("Checking Flutter installation")
    try:
        result = subprocess.run(
            ["flutter", "--version"],
            capture_output=True,
            text=True,
            check=True,
        )
        version_line = result.stdout.strip().splitlines()[0]
        record(True, f"Flutter available ({version_line})")
    except FileNotFoundError:
        record(False, "Flutter CLI not found on PATH.")
    except subprocess.CalledProcessError as err:
        stderr = (err.stderr or "").strip()
        if "Operation not permitted" in stderr or "Permission denied" in stderr:
            record(
                True,
                "Flutter CLI detected but cannot update cache (sandboxed). "
                "Run commands with ./scripts/flutter_with_secrets.sh when needed.",
            )
        else:
            record(False, f"flutter --version failed: {stderr}")


def check_env_file() -> Dict[str, str]:
    record_header("Checking .env.firebase")
    if not ENV_FILE.exists():
        record(False, f"{ENV_FILE} missing. Copy .env.firebase.example and fill it in.")
        return {}
    record(True, f"Found {ENV_FILE}")
    return load_env(ENV_FILE)


def check_env_keys(env_values: Dict[str, str]) -> None:
    record_header("Validating required env keys")
    for key in REQUIRED_ENV_KEYS:
        value = env_values.get(key, "").strip()
        if not value:
            record(False, f"{key} is not set.")
            continue
        if any(token in value for token in PLACEHOLDER_TOKENS):
            record(False, f"{key} still uses a placeholder value ({value}).")
        else:
            record(True, f"{key} set.")


def check_secret_paths(env_values: Dict[str, str]) -> None:
    record_header("Ensuring secret files exist")
    for key, (label, required) in GOOGLE_CONFIG_PATHS.items():
        raw_path = env_values.get(key, "").strip()
        if not raw_path:
            if required:
                record(False, f"{label}: no path configured in {key}.")
            else:
                record(True, f"{label}: optional, no path configured.")
            continue
        path = Path(os.path.expanduser(raw_path))
        if path.exists():
            record(True, f"{label}: found at {path}")
        else:
            msg = f"{label}: file not found at {path}"
            if required:
                record(False, msg)
            else:
                record(True, f"{msg} (optional)")


def check_ios_runner_plist(env_values: Dict[str, str]) -> None:
    record_header("Checking ios/Runner/GoogleService-Info.plist")
    if not IOS_GOOGLE_PLIST.exists():
        record(
            False,
            f"{IOS_GOOGLE_PLIST} missing. Copy the real plist into the Runner target.",
        )
        return
    try:
        with IOS_GOOGLE_PLIST.open("rb") as fh:
            plist = plistlib.load(fh)
    except Exception as exc:  # pylint: disable=broad-except
        record(False, f"Failed to parse GoogleService-Info.plist: {exc}")
        return

    expected_bundle = env_values.get("FIREBASE_IOS_BUNDLE_ID", IOS_BUNDLE_ID)
    actual_bundle = plist.get("BUNDLE_ID")
    if not actual_bundle:
        record(False, "GoogleService-Info.plist missing BUNDLE_ID key.")
    elif actual_bundle != expected_bundle:
        record(
            False,
            f"Plist bundle ID '{actual_bundle}' does not match expected '{expected_bundle}'.",
        )
    else:
        record(True, f"Plist bundle ID matches ({actual_bundle}).")

    app_id = plist.get("GOOGLE_APP_ID")
    if not app_id:
        record(False, "GoogleService-Info.plist missing GOOGLE_APP_ID.")
    elif any(token in app_id for token in PLACEHOLDER_TOKENS):
        record(False, "GoogleService-Info.plist has a placeholder GOOGLE_APP_ID.")
    else:
        record(True, "GoogleService-Info.plist contains a GOOGLE_APP_ID.")


def check_web_config() -> None:
    record_header("Checking web/firebase-config.json")
    if WEB_CONFIG.exists():
        record(True, f"Found {WEB_CONFIG}")
    elif WEB_CONFIG_EXAMPLE.exists():
        record(
            True,
            "web/firebase-config.json missing (copy firebase-config.example.json and fill it in to enable Firebase on web).",
        )
    else:
        record(
            True,
            "web/firebase-config.json missing (no example file found). Web builds will need manual dart-defines.",
        )


def load_env(path: Path) -> Dict[str, str]:
    values: Dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, raw_value = line.split("=", 1)
        values[key.strip()] = raw_value.strip().strip('"')
    return values


def record_header(message: str) -> None:
    print(f"\n-- {message} --")


def record(ok: bool, message: str) -> None:
    global had_failure
    icon = "✅" if ok else "❌"
    print(f"{icon} {message}")
    if not ok:
        had_failure = True


if __name__ == "__main__":
    sys.exit(main())
