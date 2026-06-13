TERMUX_PKG_HOMEPAGE=https://github.com/termux/proot-distro
TERMUX_PKG_DESCRIPTION="Termux official utility for managing proot'ed Linux distributions"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.38.0"
TERMUX_PKG_SRCURL=https://github.com/termux/proot-distro/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=10ddabe1df5f3b433e9add0d6c6460ece607ea39b3decb338ccde78c86c80aec
TERMUX_PKG_DEPENDS="bash, bzip2, coreutils, curl, file, findutils, gzip, ncurses-utils, proot (>= 5.1.107-32), sed, tar, termux-tools, unzip, util-linux, xz-utils"
TERMUX_PKG_SUGGESTS="bash-completion, termux-api"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"

termux_step_make_install() {
	env TERMUX_APP_PACKAGE="$TERMUX_APP_PACKAGE" \
		TERMUX_PREFIX="$TERMUX_PREFIX" \
		TERMUX_ANDROID_HOME="$TERMUX_ANDROID_HOME" \
		./install.sh

	# Patch: suppress id stderr for Android GIDs without /etc/group entries
	sed -i 's/id -Gn |/id -Gn 2>\/dev\/null |/' "${TERMUX_PREFIX}/bin/proot-distro"

	# Patch: LD_PRELOAD restore must not return non-zero (kills install with set -e)
	sed -i '/# Restore LD_PRELOAD after proot.$/,+1 s/\[ -n "\$TERMUX_LDPRELOAD" \] && export LD_PRELOAD="\$TERMUX_LDPRELOAD"/[ -n "\$TERMUX_LDPRELOAD" ] \&\& export LD_PRELOAD="\$TERMUX_LDPRELOAD" || true/' "${TERMUX_PREFIX}/bin/proot-distro"

	# Patch: use localedef --no-archive instead of dpkg-reconfigure locales
	# dpkg-reconfigure calls locale-gen which calls localedef without --no-archive,
	# which tries to create locale-archive via mmap -- blocked by Android kernel.
	sed -i 's/run_proot_cmd DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales/run_proot_cmd DEBIAN_FRONTEND=noninteractive localedef --no-archive -i en_US -f UTF-8 en_US.UTF-8/' "${TERMUX_PREFIX}/etc/proot-distro/debian.sh"
}
