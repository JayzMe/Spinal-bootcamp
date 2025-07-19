#!/bin/bash

# Default Scala and Almond versions
export DEFAULT_SCALA_VERSION=2.13.14
export DEFAULT_ALMOND_VERSION=0.14.1

# Active Scala version (can be changed with use_scala function)
export SCALA_VERSION=${SCALA_VERSION:-$DEFAULT_SCALA_VERSION}
export ALMOND_VERSION=${ALMOND_VERSION:-$DEFAULT_ALMOND_VERSION}

# Supported Scala versions
declare -A SUPPORTED_SCALA_VERSIONS=(
  ["2.12"]="2.12.10"
  ["2.13"]="2.13.14"
)

# Corresponding Almond versions for each Scala version
declare -A SUPPORTED_ALMOND_VERSIONS=(
  ["2.12"]="0.9.1"
  ["2.13"]="0.14.0-RC15"
)

# Jupyter configuration
export JUPYTER_DATA_DIR="$PWD/.venv/share/jupyter"
export JUPYTER_PATH="$JUPYTER_DATA_DIR"
export JUPYTER_KERNELS_DIR="$JUPYTER_DATA_DIR/kernels"

# Get kernel ID from Scala version
get_kernel_id() {
  local scala_version=$1
  local major_minor=$(echo "$scala_version" | cut -d. -f1,2 | tr -d '.')
  echo "scala$major_minor"
}

# Install Almond Scala kernel for current Scala version
install_almond() {
    local kernel_id=$(get_kernel_id "$SCALA_VERSION")
    local kernel_dir="$JUPYTER_DATA_DIR/kernels/$kernel_id"

    echo "Installing Almond Scala kernel for Scala $SCALA_VERSION..."
    echo "  - Kernel ID: $kernel_id"
    echo "  - Almond Version: $ALMOND_VERSION"

    # Check if kernel already exists
    if [ -d "$kernel_dir" ]; then
        echo "Removing existing kernel installation..."
        rm -rf "$kernel_dir"
    fi

    # Check if coursier is available
    if ! command -v cs &> /dev/null; then
        echo "Error: coursier (cs) not found. Please install coursier first."
        echo "You can install it from: https://get-coursier.io/docs/cli-installation"
        return 1
    fi

    # Install almond using coursier
    cs launch "almond:$ALMOND_VERSION" --scala "$SCALA_VERSION" -- --install --force --id "$kernel_id" --display-name "Scala ($SCALA_VERSION)" --jupyter-path "$JUPYTER_KERNELS_DIR"

    if [ $? -eq 0 ]; then
        echo "Almond Scala kernel installed successfully"
        return 0
    else
        echo "Error: Failed to install Almond Scala kernel"
        return 1
    fi
}

# Install all supported kernels
install_all_kernels() {
    local current_scala_version="$SCALA_VERSION"
    local current_almond_version="$ALMOND_VERSION"

    echo "Installing all supported Scala kernels..."

    for key in "${!SUPPORTED_SCALA_VERSIONS[@]}"; do
        export SCALA_VERSION="${SUPPORTED_SCALA_VERSIONS[$key]}"
        export ALMOND_VERSION="${SUPPORTED_ALMOND_VERSIONS[$key]}"

        echo "Installing kernel for Scala $SCALA_VERSION..."
        install_almond
    done

    # Restore original versions
    export SCALA_VERSION="$current_scala_version"
    export ALMOND_VERSION="$current_almond_version"

    echo "Restored active Scala version to $SCALA_VERSION"
}

# Check and setup Almond environment configuration
check_almond_env() {
    local kernel_id=$(get_kernel_id "$SCALA_VERSION")

    echo "Almond Scala kernel environment configured with:"
    echo "  - Scala Version: $SCALA_VERSION"
    echo "  - Almond Version: $ALMOND_VERSION"
    echo "  - Kernel ID: $kernel_id"
    echo "  - Jupyter Data Dir: $JUPYTER_DATA_DIR"

    # Check if kernel is actually installed
    if [ -d "$JUPYTER_DATA_DIR/kernels/$kernel_id" ]; then
        echo "  - Kernel status: Installed"
    else
        echo "  - Kernel status: Not installed"
        echo "Installing Almond kernel..."
        install_almond
    fi
}

# Switch to a specific Scala version
use_scala() {
    local version_key=$1

    if [ -z "$version_key" ]; then
        echo "Available Scala versions:"
        for key in "${!SUPPORTED_SCALA_VERSIONS[@]}"; do
            if [ "${SUPPORTED_SCALA_VERSIONS[$key]}" = "$SCALA_VERSION" ]; then
                echo "* $key (${SUPPORTED_SCALA_VERSIONS[$key]}) [active]"
            else
                echo "  $key (${SUPPORTED_SCALA_VERSIONS[$key]})"
            fi
        done
        return 0
    fi

    if [[ -n "${SUPPORTED_SCALA_VERSIONS[$version_key]}" ]]; then
        export SCALA_VERSION="${SUPPORTED_SCALA_VERSIONS[$version_key]}"
        export ALMOND_VERSION="${SUPPORTED_ALMOND_VERSIONS[$version_key]}"

        CURRENT_KERNEL_ID=$(get_kernel_id "$SCALA_VERSION")
        echo "Switched to Scala $SCALA_VERSION with:"
        echo "  - Almond: $ALMOND_VERSION"
        echo "  - Kernel ID: $CURRENT_KERNEL_ID"

        # Check if kernel is installed
        if [ ! -d "$JUPYTER_DATA_DIR/kernels/$CURRENT_KERNEL_ID" ]; then
            echo "Kernel not installed. Installing now..."
            install_almond
        fi
    else
        echo "Error: Unsupported Scala version key '$version_key'"
        echo "Available version keys: ${!SUPPORTED_SCALA_VERSIONS[@]}"
        return 1
    fi
}

# List all installed Jupyter kernels
list_kernels() {
    echo "Installed Jupyter kernels:"
    if [ -d "$JUPYTER_KERNELS_DIR" ]; then
        ls -1 "$JUPYTER_KERNELS_DIR"
    else
        echo "No Jupyter kernels directory found at $JUPYTER_KERNELS_DIR"
    fi
}

# Main execution
echo "This script helps install Almond Scala kernels for Jupyter."
echo "Please ensure 'coursier' (cs) is installed and available in your PATH."
echo "If not, install it from: https://get-coursier.io/docs/cli-installation"
echo ""

# Initialize environment with default Scala version and check Almond
check_almond_env

echo ""
echo "Usage examples:"
echo "  ./install_almond.sh install_almond           - Install Almond for the default Scala version ($DEFAULT_SCALA_VERSION)"
echo "  ./install_almond.sh install_all_kernels      - Install Almond for all supported Scala versions"
echo "  ./install_almond.sh use_scala 2.12           - Switch to Scala 2.12 (and install if not present)"
echo "  ./install_almond.sh list_kernels             - List all installed Jupyter kernels"
echo ""

# Execute function based on argument
if [ "$1" ]; then
  "$@"
fi