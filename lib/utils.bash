
list_all () {
  local -r repo_url="$1"

  git ls-remote --tags "${repo_url}" | awk '{print $2}' | sed -e 's#refs/tags/##' -e 's#\^{}##' -e 's#v##' | uniq | sort -t '.' -k 1,1n -k 2,2n | tr '\n' ' '

  get_git_tags "https://github.com/kopia/kopia" | tr -s ' '
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
  mkdir -p "${ASDF_INSTALL_PATH}/bin/${toolname}"
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
    echo https://github.com/kopia/kopia/releases/download/v"${version}"/kopia-"${version}"-"${platform}"-"${architecture}".tar.gz
  fi

}