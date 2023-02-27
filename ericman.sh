#!/usr/bin/env bash

# usage:
# ./$0 VERSION
# with
#   VERSION being the version to interact with e.g. VERSION = 37.2.6.0

# treat globs without matches as empty lists
shopt -s nullglob

if [ -n "${ERICMAN_CONTEXT}" ]; then
  dir="${ERICMAN_CONTEXT}"
else
  dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi

version=${1:-$(cat "${dir:?}"/VERSION)}
shift

if !(echo "$version" | grep -Eq '^[[:digit:]]+\.[[:digit:]]\.[[:digit:]]\.[[:digit:]]$'); then
  echo "VERSION must look like 37.2.6.0"
  exit -1
fi

function eric_dl_old {
  curl -C - -o "${dir}"/ERiC-${version:?}-Dokumentation.zip https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Dokumentation.zip
  curl -C - -o "${dir}"/ERiC-${version:?}-Schemadokumentation.zip https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Schemadokumentation.zip
  curl -C - -o "${dir}"/ERiC-${version:?}-Linux-x86_64.jar https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Linux-x86_64.jar
  curl -C - -o "${dir}"/ERiC-${version:?}-Darwin-universal.jar https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Darwin-universal.jar
}

function eric_dl_new {
  curl -C - -o "${dir}"/ERiC-${version:?}-Dokumentation.zip https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-${version:?}-Dokumentation.zip
  curl -C - -o "${dir}"/ERiC-${version:?}-Schemadokumentation.zip https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-${version:?}-Schemadokumentation.zip
  curl -C - -o "${dir}"/ERiC-${version:?}-Linux-x86_64.jar https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-${version:?}-Linux-x86_64.jar
  curl -C - -o "${dir}"/ERiC-${version:?}-Darwin-universal.jar https://download.elster.de/download/eric/eric_${version:0:2}/ERiC-${version:?}-Darwin-universal.jar
}

function eric_dl {
  echo "downloading $version"
  if [ "${version:?}" \< "37.3." ]; then
    eric_dl_old
  else
    eric_dl_new
  fi
}

function eric_unzip {
  echo "unzipping $version"

  unzip -u "${dir}/ERiC-${version:?}-Dokumentation.zip" -d "${dir}"
  unzip -u "${dir}/ERiC-${version:?}-Schemadokumentation.zip" -d "${dir}"
  unzip -u "${dir}/ERiC-${version:?}-Linux-x86_64.jar" -d "${dir}" -x "META-INF/*"
  unzip -u "${dir}/ERiC-${version:?}-Darwin-universal.jar" -d "${dir}" -x "META-INF/*"
}

function eric_activate {
  echo "activating $version"

  ln -nfs "./ERiC-${version:?}" "${dir}/active"
}

function eric_bundle {
  version="$(readlink "${dir}/active" | grep -Eo '[[:digit:]]+\.[[:digit:]]\.[[:digit:]]\.[[:digit:]]$')"

  for b in "${dir}/bundle/"*.bundle; do
    echo "$(basename "${b}" .bundle)"

    output="${dir}/ERiC-${version:?}-$(basename "${b}" .bundle)"
    rsync --recursive --copy-links --delete \
      --exclude "*.patch" \
      --exclude ".install" \
      "${b}/" "${output}/"

    for p in "${b}/"*".${version}.patch"; do
      f="$(basename "${p}" ".${version}.patch")"
      if ! patch -d "${output}" < "${p}"; then
        echo "PATCHING FAILED"
        exit -1
      fi
    done

    if [ -f "${b}/.install" ]; then
      "${b}/.install" "${output}"
    fi

    ln -nfs "./ERiC-${version:?}-$(basename "${b}" .bundle)" "${dir}/active-$(basename "${b}" .bundle)"
  done
}

eric_dl
eric_unzip
eric_activate
eric_bundle
