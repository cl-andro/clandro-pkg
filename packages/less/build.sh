TERMUX_PKG_HOMEPAGE=https://www.greenwoodsoftware.com/less/
TERMUX_PKG_DESCRIPTION="Terminal pager program used to view the contents of a text file one screen at a time"
# less has both the GPLv3 and its own "less license" which is a variation of a BSD 2-Clause license
TERMUX_PKG_LICENSE="GPL-3.0, custom"
TERMUX_PKG_LICENSE_FILE='COPYING, LICENSE'
TERMUX_PKG_MAINTAINER="Joshua Kahn <tom@termux.dev>"
TERMUX_PKG_VERSION="692"
TERMUX_PKG_SRCURL="https://github.com/gwsw/less/archive/refs/tags/v${TERMUX_PKG_VERSION}-rel.tar.gz"
TERMUX_PKG_SHA256=41d74ef73e548fbd2c3df3a28195a16cc1b995da720d853d7e3b2cbec473236f
TERMUX_PKG_DEPENDS="ncurses, pcre2"
TERMUX_PKG_REPLACES="lazyread"
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--with-regex=pcre2
--with-editor=editor
"
TERMUX_PKG_AUTO_UPDATE=true
# Official `less` release tags are marked with a `-rel` suffix
TERMUX_PKG_UPDATE_VERSION_REGEXP='\d{3}(?=-rel)'

termux_pkg_auto_update() {
	local latest_tags
	latest_tags="$(
		TERMUX_PKG_SRCURL="https://github.com/gwsw/less" \
		termux_github_api_get_tag
	)"

	termux_pkg_upgrade_version "${latest_tags}"
}

termux_step_pre_configure() {
	autoreconf -fi
	# Generate funcs.h (not included in GitHub release tarball)
	local src_list
	src_list="main.c screen.c brac.c ch.c charset.c cmdbuf.c command.c cvt.c decode.c edit.c evar.c filename.c forwback.c help.c ifile.c input.c jump.c line.c linenum.c lsystem.c mark.c optfunc.c option.c opttbl.c os.c output.c pattern.c position.c prompt.c search.c signal.c tags.c ttyin.c version.c xbuf.c"
	(cd "${TERMUX_PKG_SRCDIR}" && grep -h '^public [^;]*$' $src_list | sed 's/$/;/' > funcs.h)
}
