#!/usr/bin/env sh

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o nounset
set -o errexit

# shellcheck disable=SC1094
# shellcheck disable=SC1091
. scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

CONTAINER_REPO_HOST_DESCRIPTION="private container repo host name, ex, repo.private.com"
CONTAINER_REPO_USERNAME_DESCRIPTION="private container repo user name"
CONTAINER_REPO_PASSWORD_DESCRIPTION="passowrd of the private container repo user"
CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION="name of private repo registry"
DEPLOYMENT_TEMP_FOLDER_DESCRIPTION="output folder path"
GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION="name of the default Google Cloud Project to use"
REPO_TYPE_DESCRIPTION="Container Registry type, can be [GCR] or [Private]"
VIAI_CAMERA_SRC_FOLDER_DESCRITPTION="VIAI Edge Camera application source folder path"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION="the url of VIAI Camera application source repository"
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION="the branch name of VIAI Camera application source"
VIAI_CAMERA_APP_IMAGE_TAG_DESCRPITION="Tag of the cotnainer image."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script builds VIAI application with Cloud Built."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -H $(is_linux && echo "| --container-repo-host"): ${CONTAINER_REPO_HOST_DESCRIPTION}"
  echo "  -U $(is_linux && echo "| --container-repo-user"): ${CONTAINER_REPO_USERNAME_DESCRIPTION}"
  echo "  -W $(is_linux && echo "| --container-repo-password"): ${CONTAINER_REPO_PASSWORD_DESCRIPTION}"
  echo "  -N $(is_linux && echo "| --container-repo-reg-name"): ${CONTAINER_REPO_REPOSITORY_NAME_DESCRIPION}"
  echo "  -p $(is_linux && echo "| --default-project"): ${GOOGLE_CLOUD_DEFAULT_PROJECT_DESCRIPTION}"
  echo "  -l $(is_linux && echo "| --git-repo-url"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL_DESCRIPTION}"
  echo "  -b $(is_linux && echo "| --git-repo-branch"): ${VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH_DESCRIPTION}"
  echo "  -T $(is_linux && echo "| --image-tag"): ${VIAI_CAMERA_APP_IMAGE_TAG_DESCRPITION}"
  echo "  -a $(is_linux && echo "| --input-path"): ${VIAI_CAMERA_SRC_FOLDER_DESCRITPTION}"
  echo "  -o $(is_linux && echo "| --output-path"): ${DEPLOYMENT_TEMP_FOLDER_DESCRIPTION}"
  echo "  -Y $(is_linux && echo "| --repo-type"): ${REPO_TYPE_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,container-repo-host:,container-repo-user:,container-repo-password:,container-repo-reg-name:,default-project:,git-repo-url:,git-repo-branch:,input-path:,image-tag:,output-path:,repo-type:"
SHORT_OPTIONS="hH:N:T:U:W:Y:a:b:l:o:p:"

CONTAINER_REPO_HOST=
CONTAINER_REPO_USERNAME=
CONTAINER_REPO_PASSWORD=
CONTAINER_REPO_REPOSITORY_NAME=
CONTAINER_REPO_TYPE=
DEPLOYMENT_TEMP_FOLDER=
GOOGLE_CLOUD_PROJECT=
VIAI_CAMERA_APP_IMAGE_TAG=
VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH=
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL=sso://cloudsolutionsarchitects/viai-edge-camera-integration
VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH=dev

# BSD getopt (bundled in MacOS) doesn't support long options, and has different parameters than GNU getopt
if is_linux; then
  TEMP="$(getopt -o "${SHORT_OPTIONS}" --long "${LONG_OPTIONS}" -n "${SCRIPT_BASENAME}" -- "$@")"
elif is_macos; then
  TEMP="$(getopt "${SHORT_OPTIONS} --" "$@")"
  echo "WARNING: Long command line options are not supported on this system."
fi
RET_CODE=$?
if [ ! ${RET_CODE} ]; then
  echo "Error while evaluating command options. Terminating..."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${ERR_ARGUMENT_EVAL_ERROR}
fi
eval set -- "${TEMP}"

while true; do
  case "${1}" in
  -N | --container-repo-reg-name)
    CONTAINER_REPO_REPOSITORY_NAME="${2}"
    shift 2
    ;;
  -H | --container-repo-host)
    CONTAINER_REPO_HOST="${2}"
    shift 2
    ;;
  -U | --container-repo-user)
    CONTAINER_REPO_USERNAME="${2}"
    shift 2
    ;;
  -W | --container-repo-password)
    CONTAINER_REPO_PASSWORD="${2}"
    shift 2
    ;;
  -p | --default-project)
    # shellcheck disable=SC2034
    GOOGLE_CLOUD_PROJECT="${2}"
    shift 2
    ;;
  -l | --git-repo-url)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL="${2}"
    shift 2
    ;;
  -b | --git-repo-branch)
    VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH="${2}"
    shift 2
    ;;
  -T | --image-tag)
    VIAI_CAMERA_APP_IMAGE_TAG="${2}"
    shift 2
    ;;
  -a | --input-path)
    VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH="${2}"
    shift 2
    ;;
  -o | --output-path)
    DEPLOYMENT_TEMP_FOLDER="${2}"
    shift 2
    ;;
  -Y | --repo-type)
    # shellcheck disable=SC2034
    CONTAINER_REPO_TYPE="${2}"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -h | --help | *)
    usage
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_OK
    ;;
  esac
done

echo "Creating and Pushing VIAI Camera Application docker image..."

clone_viai_camera_app "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH" "$VIAI_CAMERA_INTEGRATION_SOURCE_REPO_URL" "$VIAI_CAMERA_INTEGRATION_SOURCE_REPO_BRANCH"

GOOGLE_APPLICATION_CREDENTIALS_PATH="/root/.config/gcloud/application_default_credentials.json"
if [ -z "${VIAI_CAMERA_APP_IMAGE_TAG}" ]; then
  VIAI_CAMERA_APP_IMAGE_TAG=latest
fi

echo "Login to private repo and generates configuration file for private repository..."
docker build -t viai-camera-app-utility:1.0.0 "$(pwd)"/docker/private-repo

docker run -it --rm \
  --privileged \
  -e CONTAINER_REPO_HOST="${CONTAINER_REPO_HOST}" \
  -e CONTAINER_REPO_USERNAME="${CONTAINER_REPO_USERNAME}" \
  -e CONTAINER_REPO_PASSWORD="${CONTAINER_REPO_PASSWORD}" \
  -v "$DEPLOYMENT_TEMP_FOLDER":/data \
  "viai-camera-app-utility:1.0.0"

echo "Building VIAI Edge Camera application container images with Kaniko"
docker run \
  -v "$DEPLOYMENT_TEMP_FOLDER"/viai-edge-camera-integration:/workspace \
  -v "$DEPLOYMENT_TEMP_FOLDER":/kaniko/.docker \
  gcr.io/kaniko-project/executor:latest \
  --dockerfile=/workspace/Dockerfile \
  --destination="${CONTAINER_REPO_HOST}/${CONTAINER_REPO_REPOSITORY_NAME}/viai-camera-integration:${VIAI_CAMERA_APP_IMAGE_TAG}" --force \
  --insecure \
  --skip-tls-verify

# Clean up
rm -rf "$VIAI_CAMERA_INTEGRATION_DIRECTORY_PATH"/viai-edge-camera-integration/
