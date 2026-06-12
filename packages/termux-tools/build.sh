TERMUX_PKG_HOMEPAGE=https://termux.dev/
TERMUX_PKG_DESCRIPTION="Basic system tools for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.46.0+really1.45.0"
TERMUX_PKG_REVISION=3
TERMUX_PKG_SRCURL=https://github.com/termux/termux-tools/archive/refs/tags/v1.45.0.tar.gz
TERMUX_PKG_SHA256=1ae29b1b875d95cc626dae323b45a2ace759969862d96094b2fa6d13bffe20d2
TERMUX_PKG_ESSENTIAL=true
#TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="newest-tag"
TERMUX_PKG_BREAKS="termux-keyring (<< 1.9)"
TERMUX_PKG_CONFLICTS="procps (<< 3.3.15-2)"
TERMUX_PKG_SUGGESTS="termux-api"

# Some of these packages are not dependencies and used only to ensure
# that core packages are installed after upgrading (we removed busybox
# from essentials).
TERMUX_PKG_DEPENDS="bzip2, coreutils, curl, dash, diffutils, findutils, gawk, grep, gzip, less, procps, psmisc, sed, tar, termux-am (>= 0.8.0), termux-am-socket (>= 1.5.0), termux-core, termux-exec, util-linux, xz-utils, dialog"

# Optional packages that are distributed as part of bootstrap archives.
TERMUX_PKG_RECOMMENDS="ed, dos2unix, inetutils, net-tools, patch, unzip"

termux_step_post_get_source() {
	# Patch .in template files before autoreconf processes them
	#
	# init-termux-properties.sh.in uses @TERMUX_HOME@ placeholder
	local props="$TERMUX_PKG_SRCDIR/init-termux-properties.sh.in"
	if [ -f "$props" ]; then
		sed -i \
			-e 's|@TERMUX_HOME@/\.config/termux/termux\.properties|@TERMUX_HOME@/.config/cl-andro/clandro.properties|g' \
			-e 's|@TERMUX_HOME@/\.termux/termux\.properties|@TERMUX_HOME@/.cl-andro/clandro.properties|g' \
			-e 's|@TERMUX_PREFIX@/share/examples/termux/termux\.properties @TERMUX_HOME@/\.termux/|@TERMUX_PREFIX@/share/examples/termux/termux.properties @TERMUX_HOME@/.cl-andro/clandro.properties|g' \
			-e 's|@TERMUX_HOME@/\.termux|@TERMUX_HOME@/.cl-andro|g' \
			"$props"
	fi

	# Patch scripts/*.in: simple ~/.termux and $HOME/.termux -> .cl-andro
	while IFS= read -r f; do
		sed -i \
			-e 's|~/\?\.termux|~/.cl-andro|g' \
			-e 's|\$HOME/\.termux|\$HOME/.cl-andro|g' \
			-e 's|termux\.properties|clandro.properties|g' \
			"$f"
	done < <(grep -rl '\.termux' "$TERMUX_PKG_SRCDIR/scripts/" 2>/dev/null || true)
}

termux_step_pre_configure() {
	autoreconf -vfi
}

termux_step_post_make_install() {
	TERMUX_PKG_CONFFILES="$(cat "$TERMUX_PKG_BUILDDIR/conffiles")"
}

termux_step_create_debscripts() {
	cat <<- EOF > ./preinst
	$(cat "$TERMUX_PKG_BUILDDIR/preinst")
	EOF
}
# Forge: Retrigger build with fixed run-docker.sh
