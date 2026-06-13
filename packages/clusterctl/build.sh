TERMUX_PKG_HOMEPAGE=https://github.com/anomalyco/clandro-pkg
TERMUX_PKG_DESCRIPTION="Control Android apps via the Cluster Bridge (Shizuku)"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@anomalyco"
TERMUX_PKG_VERSION="1.0.0"
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_AUTO_UPDATE=false

termux_step_make_install() {
	install -Dm755 "$TERMUX_PKG_BUILDER_DIR/clusterctl" "$TERMUX_PREFIX/bin/clusterctl"
}
