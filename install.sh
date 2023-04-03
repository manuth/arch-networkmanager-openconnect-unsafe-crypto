#!/bin/bash
if [ ! "$UID" -eq 0 ]
then
    sudo bash "$BASH_SOURCE";
else
    scriptRoot="$(realpath "${BASH_SOURCE%/*}")";
    workingDir="$(pwd)";
    contextDir="$(mktemp -d)";
    patchFile="allow_insecure_crypto.patch";
    patchedConfig="openssl_insecure_crypto.cnf";
    chmod a+rwx "$contextDir"

    git clone https://aur.archlinux.org/networkmanager-openconnect-useragent-git.git "$contextDir";
    cd "$contextDir";
    cp "$scriptRoot/$patchFile" .;
    cp "$scriptRoot/$patchedConfig" .;

    sed -i \
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
    echo "$contextDir";
fi;
