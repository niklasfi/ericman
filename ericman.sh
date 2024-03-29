#!/usr/bin/env bash

# usage:
# ./$0 VERSION
# with
#   VERSION being the version to interact with e.g. VERSION = 37.2.6.0

# treat globs without matches as empty lists
shopt -s nullglob
set -o pipefail
set -e

if [ -n "${ERICMAN_CONTEXT}" ]; then
  dir="${ERICMAN_CONTEXT}"
else
  dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi

version=${1:-$(cat "${dir:?}"/VERSION)}

if !(echo "${version:?}" | grep -Eq '^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$'); then
  echo "VERSION must look like 37.2.6.0"
  exit -1
fi

function eric_dl_old {
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Dokumentation.zip https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Dokumentation.zip
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Schemadokumentation.zip https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Schemadokumentation.zip
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Linux-x86_64.jar https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Linux-x86_64.jar
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Darwin-universal.jar https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Darwin-universal.jar
}

function eric_dl_new {
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Dokumentation.zip https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-${version:?}-Dokumentation.zip
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Schemadokumentation.zip https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-$(echo ${version:?} | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+').0-Schemadokumentation.zip
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Linux-x86_64.jar https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-$(echo ${version:?} | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+').0-Linux-x86_64.jar
  curl --fail -C - -o "${dir}"/ERiC-${version:?}-Darwin-universal.jar https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-$(echo ${version:?} | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+').0-Darwin-universal.jar
}

function eric_dl {
  echo "downloading ${version:?}"
  if [ "${version:?}" \< "37.3." ]; then
    eric_dl_old
  else
    eric_dl_new
  fi
}

function eric_unzip {
  echo "unzipping ${version:?}"

  tmp="$(mktemp -d)"

  unzip -u "${dir}/ERiC-${version:?}-Dokumentation.zip" -d "${tmp:?}"
  unzip -u "${dir}/ERiC-${version:?}-Schemadokumentation.zip" -d "${tmp:?}"
  unzip -u "${dir}/ERiC-${version:?}-Linux-x86_64.jar" -d "${tmp:?}" -x "META-INF/*"
  unzip -u "${dir}/ERiC-${version:?}-Darwin-universal.jar" -d "${tmp:?}" -x "META-INF/*"

  mkdir -p "${dir:?}/ERiC-${version:?}"

  rsync -r --remove-source-files \
    "${tmp:?}/ERiC-${version:?}/" \
    "${tmp:?}/ERiC-$(echo ${version:?} | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+').0/" \
    "${dir:?}/ERiC-${version:?}/"
  rm -r "${tmp:?}"
}

function eric_activate {
  echo "activating ${version:?}"

  ln -nfs "./ERiC-${version:?}" "${dir}/active"
}

function eric_bundle {
  version="$(readlink "${dir}/active" | grep -Eo '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$')"

  for b in "${dir}/bundle/"*.bundle; do
    echo "$(basename "${b}" .bundle)"

    output="${dir}/ERiC-${version:?}-$(basename "${b}" .bundle)"
    rsync --recursive --copy-links --delete \
      --exclude "*.pre-patch" \
      --exclude "*.patch" \
      --exclude ".install" \
      "${b}/" "${output}/"

    if [ -f "${b}/.pre-patch" ]; then
      "${b}/.pre-patch" "${output}" "${version}"
    fi

    for p in "${b}/"*".${version}.patch"; do
      f="$(basename "${p}" ".${version}.patch")"
      if ! patch --ignore-whitespace -d "${output}" < "${p}"; then
        echo "PATCHING FAILED"
        exit -1
      fi
    done

    if [ -f "${b}/.install" ]; then
      "${b}/.install" "${output}" "${version}"
    fi

    ln -nfs "./ERiC-${version:?}-$(basename "${b}" .bundle)" "${dir}/active-$(basename "${b}" .bundle)"
  done
}

eric_dl
eric_unzip
eric_activate
eric_bundle
