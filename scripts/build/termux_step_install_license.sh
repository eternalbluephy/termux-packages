# shellcheck shell=bash
termux_step_install_license() {
	[[ "$TERMUX_PKG_METAPACKAGE" == 'true' ]] && return

	mkdir -p "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME"
	local LICENSE COUNTER=0

	# Was a license file specified?
	if [[ -n "${TERMUX_PKG_LICENSE_FILE}" ]]; then
		COUNTER=1
		local LICENSE_FILEPATH
		local -A INSTALLED_LICENSES=()
		while read -r LICENSE; do
			# Skip empty lines
			[[ -z "${LICENSE}" ]] && continue

			# Check that the license file exists in the source files
			[[ -f "$TERMUX_PKG_SRCDIR/$LICENSE" ]] || {
				termux_error_exit "$TERMUX_PKG_SRCDIR/$LICENSE does not exist"
			}

			LICENSE_FILEPATH="$(basename "$LICENSE")"
			if [[ -n ${INSTALLED_LICENSES[${LICENSE_FILEPATH}]:-} ]]; then
				# We have already installed a license file named $(basename $LICENSE) so add a suffix to it
				TARGET="$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/${LICENSE_FILEPATH}.$((COUNTER++))"
			else
				TARGET="$TERMUX_PREFIX/share/doc/${TERMUX_PKG_NAME}/${LICENSE_FILEPATH}"
				# shellcheck disable=SC2190 # this is a valid way to assign key value pairs
				INSTALLED_LICENSES+=("${LICENSE_FILEPATH}" 'already installed')
			fi
			cp -f "${TERMUX_PKG_SRCDIR}/${LICENSE}" "$TARGET"
		done <<< "${TERMUX_PKG_LICENSE_FILE//,/$'\n'}"
	else # If a license file wasn't specified, find the one we need
		local TO_LICENSE             # link target for generic licenses
		local COMMON_LICENSE_FILES=( # search list for licenses with copyright information
		'COPYING' 'Copyright.txt'
		'copyright' 'Copyright' 'COPYRIGHT'
		'licence' 'Licence' 'LICENCE' # spelled with 'C'
		'license' 'License' 'LICENSE' # spelled with 'S'
		'license.txt' 'License.txt'
		'LICENSE.txt' 'LICENSE.TXT'
		'license.md' 'LICENSE.md'
		)
		# Parse the license(s)
		while read -r LICENSE; do
			# Skip empty lines
			[[ -z "${LICENSE}" ]] && continue

			case "$LICENSE" in
				# These licenses contain copyright information,
				# so we cannot use a generic license file
				'BSD'|'BSD 2-Clause'|'BSD 3-Clause'|'BSD Simplified'\
				|'curl'|'HPND'|'ISC'|'Libpng'|'MIT'|'Openfont-1.1'\
				|'PythonPL'|'X11'|'ZLIB')
				# Find the license file in the source files
				for FILE in "${COMMON_LICENSE_FILES[@]}"; do
					[[ -f "$TERMUX_PKG_SRCDIR/$FILE" ]] && {
						if (( COUNTER )); then
							cp -f "${TERMUX_PKG_SRCDIR}/$FILE" "${TERMUX_PREFIX}/share/doc/${TERMUX_PKG_NAME}/copyright.${COUNTER}"
						else
							cp -f "${TERMUX_PKG_SRCDIR}/$FILE" "${TERMUX_PREFIX}/share/doc/${TERMUX_PKG_NAME}/copyright"
						fi
						# since this is a post-increment, (( 0 )) would be falsey
						# thus `set -e` would kill the script on the first iteration
						# using `true` prevents this
						: $(( COUNTER++ ))
					}
				done
				;;
				# For the rest we can use a link to the generic license file
				*) [[ -f "$TERMUX_SCRIPTDIR/packages/termux-licenses/LICENSES/${LICENSE}.txt" ]] && {
						# the link target depends on the libc being used
						if [[ "$TERMUX_PACKAGE_LIBRARY" == 'bionic' ]]; then
							TO_LICENSE="../../LICENSES/${LICENSE}.txt"
						elif [[ "$TERMUX_PACKAGE_LIBRARY" == 'glibc' ]]; then
							TO_LICENSE="../../../../share/LICENSES/${LICENSE}.txt"
						fi
						if (( COUNTER )); then
							ln -sf "$TO_LICENSE" "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME/copyright.$((COUNTER++))"
						else
							ln -sf "$TO_LICENSE" "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME/copyright"
						fi
					}
				;;
			esac
		done <<< "${TERMUX_PKG_LICENSE//,/$'\n'}"
		local license_files
		license_files="$(find -L "$TERMUX_PREFIX/share/doc/$TERMUX_PKG_NAME" -maxdepth 1 \( -type f -o -type l \) -name "copyright*")"
		[[ -n "$license_files" ]] || {
			termux_error_exit "No LICENSE file was installed for $TERMUX_PKG_NAME"
		}
	fi
return 0
}
