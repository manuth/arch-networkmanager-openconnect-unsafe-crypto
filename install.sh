#!/bin/bash
contextRoot="$(mktemp -d)";
workingDir="$(pwd)";
scriptRoot="$(realpath "${BASH_SOURCE%/*}")";
patchFile="allow_insecure_crypto.patch";
patchedConfig="openssl_insecure_crypto.cnf";

git clone https://aur.archlinux.org/networkmanager-openconnect-useragent-git.git "$contextRoot";
cd "$contextRoot";
cp "$scriptRoot/$patchFile" .;
cp "$scriptRoot/$patchedConfig" .;

    sed -i \
        -e "/^depends=(/{ s/ openconnect / openconnect-git / }" \
        -e "s/^\(source=(.*\)\()\)/\1 \"local:\/\/$patchFile\" \"local:\/\/$patchedConfig\"\2/" \
        -e "s/^\(sha256sums=(.*\)\()\)/\1 'SKIP' 'SKIP'\2/" \
        -e "/^build() {/{" \
            -e 'a\' \
            -e '  cd NetworkManager-openconnect\' \
            -e '  git apply "${srcdir}/'"$patchFile"'"\' \
            -e "  cd .." \
        -e "}" \
        -e "/^package() {/{" \
            -e 'a mkdir -p "${pkgdir}/usr/local/etc/ssl"' \
            -e 'a cp "${srcdir}/'"$patchedConfig"'" "${pkgdir}/usr/local/etc/ssl/openssl_insecure_crypto.cnf"' \
        -e "}" \
        PKGBUILD

makepkg --noconfirm -si;
cd "$workingDir";
rm -rf "$contextRoot";
