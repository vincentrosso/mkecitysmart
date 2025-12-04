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
    group_id = created.get("id") or created.get("_id")
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
    parser.add_argument("--app-id", required=True, help="Codemagic app ID")
    parser.add_argument("--token", required=True, help="Codemagic API token")
    parser.add_argument(
        "--group",
        required=True,
        help="Variable group name (e.g. firebase-secrets)",
    )
    parser.add_argument(
        "--description",
        help="Optional description for the variable group",
    )
    parser.add_argument("--env-file", required=True, type=pathlib.Path)
    parser.add_argument("--android-json", required=True, type=pathlib.Path)
    parser.add_argument("--ios-plist", required=True, type=pathlib.Path)
    args = parser.parse_args(argv)

    for path in (args.env_file, args.android_json, args.ios_plist):
        if not path.exists():
            print(f"Missing file: {path}", file=sys.stderr)
            return 1

    group_id = ensure_group(args.app_id, args.token, args.group, args.description)
    variables = [
        {
            "name": "FIREBASE_ENV_FILE",
            "value": args.env_file.read_text(encoding="utf-8"),
            "secure": True,
        },
        {
            "name": "ANDROID_GOOGLE_SERVICES_JSON",
            "value": encode_file(args.android_json),
            "secure": True,
        },
        {
            "name": "IOS_GOOGLE_SERVICE_INFO_PLIST",
            "value": encode_file(args.ios_plist),
            "secure": True,
        },
    ]
    bulk_import(args.app_id, args.token, group_id, variables)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
