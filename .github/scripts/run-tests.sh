#!/bin/bash
set -e

FLUX_SCHED_BRANCH=${1:-"master"}
FLUX_SCHED_URL=${2:-"https://github.com/flux-framework/flux-sched"}
FLUX_SCHED_VERSION=${3:-"0.48.0"}

python --version

# Here we want to prepare the environment so it looks like flux-sched
# We need to copy the content here into the Python bindings directory...
git clone --depth 1 -b ${FLUX_SCHED_BRANCH} ${FLUX_SCHED_URL} /tmp/flux-sched
cp -R ./ /tmp/flux-sched/resource/reapi/bindings/python

# Flag to build the python directory...
echo "add_subdirectory(python)" >> /tmp/flux-sched/resource/reapi/bindings/CMakeLists.txt
root=$(pwd)
cd /tmp/flux-sched
echo "Present working directory $(pwd)"

# Build flux-sched first...
export FLUX_SCHED_VERSION
export LD_LIBRARY_PATH=$(pwd)/resource/reapi/bindings
./configure
make -j

# Test relative to flux_sched (local module)
FLUXSCHED_PYTHON_ROOT=$(pwd)/resource/reapi/bindings/python
export PYTHONPATH=FLUXSCHED_PYTHON_ROOT
cd $FLUXSCHED_PYTHON_ROOT
pytest -xs ./tests/test_*.py
echo $?

# Test full build and install
# python3 -m build  --sdist --wheel
sed -i "s/version=\"0.0.0\"/version=\"$FLUX_SCHED_VERSION\"/" setup.py
python -m build --sdist --wheel --no-isolation
mv ./dist $root/dist
mv ./build $root/build
