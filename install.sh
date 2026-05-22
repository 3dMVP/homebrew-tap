#!/usr/bin/env sh
set -eu

repo="${BLOBIT_REPO:-3dMVP/homebrew-tap}"
version="${BLOBIT_VERSION:-latest}"
install_dir="${BLOBIT_INSTALL_DIR:-$HOME/.local/bin}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "required command not found: $1" >&2
    exit 1
  fi
}

case "$(uname -s)" in
  Darwin)
    os="darwin"
    ;;
  Linux)
    os="linux"
    ;;
  *)
    echo "unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

case "$os:$(uname -m)" in
  darwin:arm64 | darwin:aarch64)
    target="aarch64-apple-darwin"
    extension="zip"
    ;;
  darwin:x86_64)
    target="x86_64-apple-darwin"
    extension="zip"
    ;;
  linux:x86_64 | linux:amd64)
    target="x86_64-unknown-linux-gnu"
    extension="tar.gz"
    ;;
  *)
    echo "unsupported platform: $(uname -s) $(uname -m)" >&2
    exit 1
    ;;
esac

require_command curl

if [ "$version" = "latest" ]; then
  latest_url="$(curl -fsIL -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")"
  version="${latest_url##*/}"
fi

case "$version" in
  v*)
    tag="$version"
    version_number="${version#v}"
    ;;
  *)
    tag="v$version"
    version_number="$version"
    ;;
esac

artifact_dir="blobit-v${version_number}-${target}"
archive_name="${artifact_dir}.${extension}"
download_url="https://github.com/${repo}/releases/download/${tag}/${archive_name}"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

curl -fsSL "$download_url" -o "$tmp_dir/$archive_name"

case "$extension" in
  zip)
    require_command unzip
    unzip -q "$tmp_dir/$archive_name" -d "$tmp_dir"
    ;;
  tar.gz)
    tar -xzf "$tmp_dir/$archive_name" -C "$tmp_dir"
    ;;
esac

mkdir -p "$install_dir"
install -m 0755 "$tmp_dir/$artifact_dir/blobit" "$install_dir/blobit"

echo "Installed blobit ${tag} to ${install_dir}/blobit"
