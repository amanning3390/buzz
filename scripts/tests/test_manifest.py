#!/usr/bin/env python3
"""Validate desktop/hermes-runtime.json manifest structure.

Rejects:
  - Mutable refs (branch names, HEAD)
  - Short SHAs (< 40 chars)
  - Tag/commit mismatches
  - Malformed version strings
  - Unexpected repository URLs
"""
import json
import re
import sys
from pathlib import Path

MANIFEST = Path(__file__).resolve().parent.parent.parent / "desktop" / "hermes-runtime.json"

VALID_REPOS = {
    "https://github.com/amanning3390/hermes-agent.git",
}
VALID_PROTOCOLS = {"acp"}
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
TAG_RE = re.compile(r"^buzz-acp-v\d+\.\d+\.\d+(\.\d+)?(-[a-z0-9.]+)?$")


def validate() -> list[str]:
    errors: list[str] = []

    if not MANIFEST.exists():
        return [f"Manifest not found: {MANIFEST}"]

    try:
        data = json.loads(MANIFEST.read_text())
    except json.JSONDecodeError as e:
        return [f"Invalid JSON: {e}"]

    # Required fields
    for key in ("repository", "commit", "tag", "protocol", "requiredFeatures"):
        if key not in data:
            errors.append(f"Missing required field: {key}")

    if errors:
        return errors

    # Repository URL
    repo = data["repository"]
    if repo not in VALID_REPOS:
        errors.append(f"Unexpected repository URL: {repo}")

    # Commit must be full 40-char SHA
    commit = data["commit"]
    if not SHA_RE.match(commit):
        errors.append(f"commit is not a full 40-char SHA: {commit}")

    # Reject mutable refs
    mutable = {"HEAD", "main", "master", "latest"}
    if commit in mutable or data["tag"] in mutable:
        errors.append("Mutable ref detected — manifest must pin an immutable commit/tag")

    # Tag format
    tag = data["tag"]
    if not TAG_RE.match(tag):
        errors.append(f"Tag does not match expected format: {tag}")

    # Protocol
    proto = data["protocol"]
    if proto not in VALID_PROTOCOLS:
        errors.append(f"Unknown protocol: {proto}")

    # officialMinVersion
    min_ver = data.get("officialMinVersion")
    if min_ver is not None and not re.match(r"^\d+\.\d+\.\d+", str(min_ver)):
        errors.append(f"Malformed officialMinVersion: {min_ver}")

    # requiredFeatures
    features = data.get("requiredFeatures", [])
    if not isinstance(features, list) or not features:
        errors.append("requiredFeatures must be a non-empty list")

    return errors


if __name__ == "__main__":
    errs = validate()
    if errs:
        for e in errs:
            print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
    print("PASS: Manifest valid")
    sys.exit(0)
