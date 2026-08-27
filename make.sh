#!/usr/bin/env bash
# Build a FogApi client from the shared spec, on Linux or macOS.
#
# Same CLI as make.ps1, and it delegates to it rather than reimplementing the
# stages. That is deliberate: AutoRest's build-module.ps1 hard-requires
# PowerShell Core, so the build logic has to run under pwsh either way, and a
# second implementation in bash would only drift from the first.
#
# So this script's whole job is to find a usable pwsh, explain clearly how to
# install one if it cannot, and hand over.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIN_PWSH_MAJOR=7

CLIENT="pwsh"
TARGET="All"
WEB=""
LIVE=""
CHECK_SURFACE=0
SHOW_HELP=0

usage() {
	cat <<'EOF'
Usage: ./make.sh [options]

  --client <name>   Client to build, or 'all'. Default: pwsh
  --target <stage>  Single stage, or All. Default: All
                    pwsh stages: Document Generate Compile Surface Merge Help Test
  --web <path>      Generate from a fogproject checkout's packages/web
                    (needs php; no server or database required)
  --live <url>      Generate from a running server's document, e.g.
                    https://fog.example.com/fog -- the only way to pick up that
                    server's plugins, and the only way the client learns a real
                    base URL
  --check-surface   Compare the public surface to the committed snapshot and
                    fail on any change, instead of recording it (CI gate)
  -h, --help        Show the selected client's own help

Examples:
  ./make.sh
  ./make.sh --live https://fog.example.com/fog
  ./make.sh --target Compile
  ./make.sh --client all
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--client)
			[ $# -ge 2 ] || { echo "--client needs a value" >&2; exit 1; }
			CLIENT="$2"; shift 2 ;;
		--target)
			[ $# -ge 2 ] || { echo "--target needs a value" >&2; exit 1; }
			TARGET="$2"; shift 2 ;;
		--web)
			[ $# -ge 2 ] || { echo "--web needs a value" >&2; exit 1; }
			WEB="$2"; shift 2 ;;
		--live)
			[ $# -ge 2 ] || { echo "--live needs a value" >&2; exit 1; }
			LIVE="$2"; shift 2 ;;
		--check-surface)
			CHECK_SURFACE=1; shift ;;
		-h|--help)
			SHOW_HELP=1; shift ;;
		*)
			echo "Unknown option: $1" >&2
			echo >&2
			usage >&2
			exit 1 ;;
	esac
done

if [ "$SHOW_HELP" -eq 1 ] && [ -z "$WEB$LIVE" ] && [ "$TARGET" = "All" ]; then
	# Plain --help with nothing else: show this script's usage rather than
	# spinning up pwsh just to print the client's help.
	usage
	exit 0
fi

if ! command -v pwsh >/dev/null 2>&1; then
	cat >&2 <<EOF
PowerShell ${MIN_PWSH_MAJOR}+ (pwsh) is required but was not found on PATH.

The build cannot avoid it: AutoRest emits build-module.ps1 and refuses to run
outside PowerShell Core, so this script delegates rather than duplicating it.

Install it with your distro's package manager, or see
https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux
EOF
	exit 1
fi

pwsh_major="$(pwsh -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.Major' 2>/dev/null || echo 0)"
if [ "$pwsh_major" -lt "$MIN_PWSH_MAJOR" ]; then
	echo "PowerShell ${MIN_PWSH_MAJOR}+ is required, found major version ${pwsh_major}." >&2
	exit 1
fi

args=(-Client "$CLIENT" -Target "$TARGET")
[ -n "$WEB" ] && args+=(-Web "$WEB")
[ -n "$LIVE" ] && args+=(-Live "$LIVE")
[ "$CHECK_SURFACE" -eq 1 ] && args+=(-CheckSurface)
[ "$SHOW_HELP" -eq 1 ] && args+=(-Help)

exec pwsh -NoProfile -NonInteractive -File "$SCRIPT_DIR/make.ps1" "${args[@]}"
