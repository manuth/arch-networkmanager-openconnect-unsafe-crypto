#!/bin/bash
CONTEXT_ROOT="${CONTEXT_ROOT}";

if [ ! "$UID" -eq 0 ]
then
    CONTEXT_ROOT="$(mktemp -d)";
    workingDir="$(pwd)";

    sudo \
        CONTEXT_ROOT="${CONTEXT_ROOT}" \
        bash "$BASH_SOURCE";

    cd "$CONTEXT_ROOT";
    makepkg -si;
    cd "$workingDir";
    rm -rf "$CONTEXT_ROOT";
else
    scriptRoot="$(realpath "${BASH_SOURCE%/*}")";
    patchFile="allow_insecure_crypto.patch";
    patchedConfig="openssl_insecure_crypto.cnf";

    git clone https://aur.archlinux.org/networkmanager-openconnect-useragent-git.git "$CONTEXT_ROOT";
    cd "$CONTEXT_ROOT";
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
fi;
