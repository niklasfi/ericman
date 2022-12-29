#!/bin/env bash

# usage:
# ./$0 VERSION
# with
#   VERSION being the version to interact with e.g. VERSION = 37.2.6.0

# treat globs without matches as empty lists
shopt -s nullglob

version=${1:?}
shift

if !(echo "$version" | grep -Eq '^[[:digit:]]+\.[[:digit:]]\.[[:digit:]]\.[[:digit:]]$'); then
  echo "VERSION must look like 37.2.6.0"
  exit -1
fi

if [ -n "${ERICMAN_CONTEXT}" ]; then
  dir="${ERICMAN_CONTEXT}"
else
  dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
fi

function eric_dl {
  echo "downloading $version"

  wget -cP "${dir}" https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Dokumentation.zip
  wget -cP "${dir}" https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Schemadokumentation.zip
  wget -cP "${dir}" https://download.elster.de/download/eric_${version:0:2}/ERiC-${version:?}-Linux-x86_64.jar
}

function eric_unzip {
  echo "unzipping $version"

  unzip -u "${dir}/ERiC-${version:?}-Dokumentation.zip" -d "${dir}"
  unzip -u "${dir}/ERiC-${version:?}-Schemadokumentation.zip" -d "${dir}"
  unzip -u "${dir}/ERiC-${version:?}-Linux-x86_64.jar" -d "${dir}" -x "META-INF/*"
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
  done
}

eric_dl
eric_unzip
eric_activate
eric_bundle
