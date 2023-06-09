REPO_URL="https://github.com/kopia/kopia"


list_all () {
  git ls-remote --tags "${REPO_URL}" | awk '{print $2}' | sed -e 's#refs/tags/##' -e 's#\^{}##' -e 's#v##' | uniq | sort -t '.' -k 1,1n -k 2,2n | tr '\n' ' '
}

latest () {
  git ls-remote --tags "${REPO_URL}" | awk '{print $2}' | sed -e 's#refs/tags/##' -e 's#\^{}##' -e 's#v##' | grep -E "^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$" | uniq | sort -t '.' -k 1,1n -k 2,2n | tail -1
}

cleanup () {
  rm -rf "${ASDF_DOWNLOAD_PATH}/${toolname}.tar.gz"
}

download_release () {
  local -r toolname="$1"

  local -r download_url="$(get_download_url "${ASDF_INSTALL_VERSION}")"
  
  echo "Downloading version ${ASDF_INSTALL_VERSION} of ${toolname}"
  if curl -sfL -o "${ASDF_DOWNLOAD_PATH}/${toolname}.tar.gz" "${download_url}"; then
    tar zxf "${ASDF_DOWNLOAD_PATH}/${toolname}.tar.gz" -C "${ASDF_DOWNLOAD_PATH}"
  fi

  cleanup
}

install_version () {
  local -r version="$1"

  echo "Installing version ${ASDF_INSTALL_VERSION} of ${toolname}"
  mkdir -p "${ASDF_INSTALL_PATH}/bin"
  cp "${ASDF_DOWNLOAD_PATH}"/*/"${toolname}" "${ASDF_INSTALL_PATH}"/bin/"${toolname}"
  chmod +x "${ASDF_INSTALL_PATH}"/bin/"${toolname}"
}

fail() {
  echo -e "\e[31mFail:\e[m $*"
  exit 1
}

get_filename () {
  local -r version="$1"
  local -r ext="${2:-.zip}"
  local -r arch="$(get_arch)"

  echo "${version}/dist_${arch}${ext}"
}

get_download_url () {
  local -r version="$1"
  local platform
  local IS_EXISTS=1

  case "$OSTYPE" in
    darwin*) platform="macOS" ;;
    linux*) platform="linux" ;;
    openbsd*) platform="openbsd-experimental" ;;
    FreeBSD) platform="freebsd-experimental" ;;
     *) fail "Unsupported platform" ;;
  esac

  local architecture

  case "$(uname -m)" in
    aarch64* | arm64) architecture="arm64" ;;
    armv5* | armv6* | armv7*) architecture="arm" ;;
    x86_64*) architecture="x64" ;;
    *) fail "Unsupported architecture" ;;
  esac
  
  if [ "$platform" == "macOS" ]; then
    case $architecture in
      x64|arm64) IS_EXISTS=1 ;;
      *) fail "Unsupported architecture for ${platform}" ;;
    esac
  elif [ "$platform" == "linux" ]; then
    case $architecture in
      x64|arm64|arm) IS_EXISTS=1 ;;
      *) fail "Unsupported architecture for ${platform}" ;;
    esac
  elif [ "$platform" == "openbsd" ]; then
    case $architecture in
      x64|arm64|arm) IS_EXISTS=1 ;;
      *) fail "Unsupported architecture for ${platform}" ;;
    esac
  elif [ "$platform" == "freebsd" ]; then
    case $architecture in
      x64|arm64|arm) IS_EXISTS=1 ;;
      *) fail "Unsupported architecture for ${platform}" ;;
    esac
  fi

  if [ $IS_EXISTS -eq 1 ]; then
    echo "${REPO_URL}"/releases/download/v"${version}"/kopia-"${version}"-"${platform}"-"${architecture}".tar.gz
  fi

}