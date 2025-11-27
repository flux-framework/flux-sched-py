FROM fluxrm/flux-core:bookworm

# docker build -t ghcr.io/converged-computing/flux-sched-py:latest .

LABEL maintainer="Vanessasaurus <@vsoch>"
ARG FLUX_SCHED_VERSION=0.48.0
ENV FLUX_SCHED_VERSION=${FLUX_SCHED_VERSION}
USER root

RUN sudo apt-get update
RUN sudo apt-get -qq install -y --no-install-recommends \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-regex-dev \
    python3-yaml \
    libyaml-cpp-dev \
    libedit-dev \
    ninja-build \
    python3-pip \
    curl

# Assuming installing to /usr/local
ENV LD_LIBRARY_PATH=/usr/lib:/usr/local/lib

RUN curl -s -L https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4-linux-$(uname -m).sh > cmake.sh ;\
    sudo bash cmake.sh --prefix=/usr/local --skip-license ;\
    rm cmake.sh

RUN git clone -b v${FLUX_SCHED_VERSION} https://github.com/flux-framework/flux-sched /opt/flux-sched && \
    echo "add_subdirectory(python)" >> /opt/flux-sched/resource/reapi/bindings/CMakeLists.txt && \
    python3 -m pip install IPython pre-commit pyflakes black isort pytest Cython build --break-system-packages

COPY ./ /opt/flux-sched/resource/reapi/bindings/python

WORKDIR /opt/flux-sched
RUN export LD_LIBRARY_PATH=$(pwd)/resource/reapi/bindings && \
    ./configure && \
    make -j

RUN FLUXSCHED_PYTHON_ROOT=$(pwd)/resource/reapi/bindings/python && \
   export PYTHONPATH=FLUXSCHED_PYTHON_ROOT && \
   cd $FLUXSCHED_PYTHON_ROOT && \
   sed -i "s/version=\"0.0.0\"/version=\"$FLUX_SCHED_VERSION\"/" setup.py && \
   python3 -m build --sdist --wheel --no-isolation && \
   pip install ./dist/flux_sched-*.whl --break-system-packages
