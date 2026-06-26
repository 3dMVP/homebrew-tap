#!/usr/bin/env sh
set -eu

repo="${BLOBIT_REPO:-Blobit-AI/homebrew-tap}"
version="${BLOBIT_VERSION:-latest}"
install_dir="${BLOBIT_INSTALL_DIR:-$HOME/.local/bin}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "required command not found: $1" >&2
    exit 1
  fi
}

run_codex_setup() {
  if "$install_dir/blobit" codex setup; then
    return 0
  fi

  echo "Codex plugin setup did not complete." >&2
  echo "You can retry later with:" >&2
  echo "  blobit codex setup" >&2
  return 0
}

prompt_codex_setup() {
  if ! command -v codex >/dev/null 2>&1; then
    return 0
  fi

  echo
  echo "Codex detected."
  echo "Blobit is recommended with the Blobit CLI Skill Pack for game asset workflows."

  case "${BLOBIT_INSTALL_CODEX_PLUGIN:-ask}" in
    yes | YES | true | TRUE | 1)
      run_codex_setup
      return 0
      ;;
    no | NO | false | FALSE | 0)
      echo "Skipped Codex plugin setup."
      return 0
      ;;
  esac

  if [ -r /dev/tty ] && [ -w /dev/tty ]; then
    printf "Install the recommended Codex plugin now? [Y/n] " > /dev/tty
    read answer < /dev/tty || answer=""
    case "$answer" in
      n | N | no | NO)
        echo "Skipped Codex plugin setup."
        ;;
      *)
        run_codex_setup
        ;;
    esac
    return 0
  fi

  echo "To install the recommended Codex plugin, run:"
  echo "  blobit codex setup"
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
prompt_codex_setup
