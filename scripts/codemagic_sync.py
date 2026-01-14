#!/usr/bin/env python3
"""
Sync Firebase secrets to a Codemagic variable group using the v3 API.

Example:
  python scripts/codemagic_sync.py \
    --token $CODEMAGIC_TOKEN \
    --group firebase-secrets \
    --env-file .env.firebase \
    --android-json .secrets/firebase/android/google-services.json \
    --ios-plist .secrets/firebase/ios/GoogleService-Info.plist
"""
from __future__ import annotations

import argparse
import base64
import json
import pathlib
import sys
from typing import Any, Dict, List

import urllib.request

API_ROOT = "https://codemagic.io/api/v3/apps"


def api_request(
    method: str,
    path: str,
    token: str,
    payload: Dict[str, Any] | None = None,
) -> Any:
    url = f"{API_ROOT}{path}"
    data = None
    headers = {"x-auth-token": token}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:  # nosec B310
        body = resp.read()
        if 200 <= resp.status < 300:
            if not body:
                return None
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return body.decode()
        raise RuntimeError(f"Codemagic API error {resp.status}: {body.decode()}")


def encode_file(path: pathlib.Path) -> str:
    return base64.b64encode(path.read_bytes()).decode("ascii")


def list_groups(app_id: str, token: str) -> List[Dict[str, Any]]:
    data = api_request("GET", f"/{app_id}/variable-groups", token)
    if isinstance(data, dict):
        groups = (
            data.get("variableGroups")
            or data.get("variable_groups")
            or data.get("data")
            or []
        )
        if isinstance(groups, list):
            return groups
    if isinstance(data, list):
        return data
    return []


def ensure_group(app_id: str, token: str, name: str, description: str | None) -> str:
    for group in list_groups(app_id, token):
        if group.get("name") == name:
            group_id = group.get("id") or group.get("_id")
            if group_id:
                return group_id
    payload: Dict[str, Any] = {"name": name}
    if description:
        payload["description"] = description
    created = api_request("POST", f"/{app_id}/variable-groups", token, payload)
    group_data = (
        created.get("variableGroup")
        or created.get("variable_group")
        or created
    )
    group_id = group_data.get("id") or group_data.get("_id")
    if not group_id:
        raise RuntimeError("Failed to create variable group")
    print(f"✔ Created variable group '{name}' ({group_id})")
    return group_id


def bulk_import(app_id: str, token: str, group_id: str, variables: List[Dict[str, Any]]) -> None:
    payload = {"variables": variables}
    api_request(
        "POST",
        f"/{app_id}/variable-groups/{group_id}/variables/bulk-import",
        token,
        payload,
    )
    print(f"✔ Uploaded {len(variables)} variables to group {group_id}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Codemagic secret sync (v3)")
    parser.add_argument("--app-id", help="Codemagic app ID")
    parser.add_argument("--token", help="Codemagic API token")
    parser.add_argument(
        "--group",
        required=True,
        help="Variable group name (e.g. firebase-secrets)",
    )
    parser.add_argument(
        "--description",
        help="Optional description for the variable group",
    )
    parser.add_argument("--env-file", type=pathlib.Path)
    parser.add_argument("--android-json", type=pathlib.Path)
    parser.add_argument("--ios-plist", type=pathlib.Path)
    parser.add_argument("--distribution-p12", type=pathlib.Path)
    parser.add_argument("--distribution-p12-password", help="Password for the .p12 certificate")
    parser.add_argument("--provisioning-profile", type=pathlib.Path)
    parser.add_argument("--app-store-key", type=pathlib.Path)
    args = parser.parse_args(argv)

    config = {}
    config_path = pathlib.Path(__file__).with_name("codemagic.conf")
    if config_path.exists():
        for line in config_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            config[key.strip()] = value.strip()

    if not args.app_id:
        args.app_id = config.get("CODEMAGIC_APP_ID")
    if not args.token:
        args.token = config.get("CODEMAGIC_TOKEN")

    def config_path_value(key: str) -> pathlib.Path | None:
        value = config.get(key)
        return pathlib.Path(value) if value else None

    if args.env_file is None:
        args.env_file = config_path_value("FIREBASE_ENV_FILE")
    if args.android_json is None:
        args.android_json = config_path_value("ANDROID_GOOGLE_SERVICES_JSON")
    if args.ios_plist is None:
        args.ios_plist = config_path_value("IOS_GOOGLE_SERVICE_INFO_PLIST")
    if args.distribution_p12 is None:
        args.distribution_p12 = config_path_value("IOS_DISTRIBUTION_P12")
    if args.distribution_p12_password is None:
        args.distribution_p12_password = config.get("IOS_DISTRIBUTION_P12_PASSWORD")
    if args.provisioning_profile is None:
        args.provisioning_profile = config_path_value("IOS_PROVISIONING_PROFILE")
    if args.app_store_key is None:
        args.app_store_key = config_path_value("APP_STORE_CONNECT_KEY")

    if not args.app_id or not args.token:
        print("Error: provide --app-id and --token (or define them in codemagic.conf).", file=sys.stderr)
        return 1

    file_args = [
        ("env_file", args.env_file),
        ("android_json", args.android_json),
        ("ios_plist", args.ios_plist),
        ("distribution_p12", args.distribution_p12),
        ("provisioning_profile", args.provisioning_profile),
        ("app_store_key", args.app_store_key),
    ]

    for label, path in file_args:
        if path is None:
            continue
        if not path.exists():
            print(f"Missing {label}: {path}", file=sys.stderr)
            return 1

    group_id = ensure_group(args.app_id, args.token, args.group, args.description)
    variables = []
    if args.env_file:
        variables.append(
            {
                "name": "FIREBASE_ENV_FILE",
                "value": args.env_file.read_text(encoding="utf-8"),
                "secure": True,
            }
        )
    if args.android_json:
        variables.append(
            {
                "name": "ANDROID_GOOGLE_SERVICES_JSON",
                "value": encode_file(args.android_json),
                "secure": True,
            }
        )
    if args.ios_plist:
        variables.append(
            {
                "name": "IOS_GOOGLE_SERVICE_INFO_PLIST",
                "value": encode_file(args.ios_plist),
                "secure": True,
            }
        )
    if args.distribution_p12:
        if not args.distribution_p12_password:
            print("distribution-p12-password is required when --distribution-p12 is provided", file=sys.stderr)
            return 1
        variables.append(
            {
                "name": "IOS_DISTRIBUTION_CERTIFICATE",
                "value": encode_file(args.distribution_p12),
                "secure": True,
            }
        )
        variables.append(
            {
                "name": "IOS_CERTIFICATE_PASSWORD",
                "value": args.distribution_p12_password,
                "secure": True,
            }
        )
    if args.provisioning_profile:
        variables.append(
            {
                "name": "IOS_PROVISIONING_PROFILE",
                "value": encode_file(args.provisioning_profile),
                "secure": True,
            }
        )
    if args.app_store_key:
        variables.append(
            {
                "name": "APP_STORE_CONNECT_PRIVATE_KEY",
                "value": args.app_store_key.read_text(encoding="utf-8"),
                "secure": True,
            }
        )
    if not variables:
        print("No variables to upload. Provide at least one file/secret.", file=sys.stderr)
        return 1
    bulk_import(args.app_id, args.token, group_id, variables)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
