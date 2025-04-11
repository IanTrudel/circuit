FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
   git cmake ninja-build build-essential g++ \
   libedit-dev libreadline-dev libncurses5-dev libxml2-dev \
   zlib1g-dev pkg-config libsqlite3-dev libz3-dev z3 \
   python3 python3-pip python3-setuptools \
   zsh

WORKDIR /opt

RUN git clone https://github.com/google/googletest.git -b v1.16.0

WORKDIR /opt/googletest/build
RUN cmake .. && make && make install

# Building Slang
WORKDIR /opt
RUN git clone https://github.com/MikePopoloski/slang.git --depth 1

WORKDIR /opt/slang/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_INSTALL_PREFIX=/opt/slang -DSLANG_INCLUDE_TOOLS=ON \
   -Wdev --log-level=VERBOSE

RUN cmake --build . --target install

RUN ctest --output-on-failure

# Building CIRCT

#RUN pip install pybind11 setuptools lit

WORKDIR /opt
RUN git clone https://github.com/llvm/circt.git

WORKDIR /opt/circt
RUN git submodule init
RUN git submodule update

WORKDIR llvm/build
RUN cmake -G Ninja ../llvm \
    -DLLVM_ENABLE_PROJECTS="mlir" \
    -DLLVM_TARGETS_TO_BUILD="host" \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
RUN ninja
RUN ninja check-mlir

WORKDIR /opt/circt/build
RUN cmake -G Ninja .. \
    -DMLIR_DIR=$PWD/../llvm/build/lib/cmake/mlir \
    -DLLVM_DIR=$PWD/../llvm/build/lib/cmake/llvm \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DCMAKE_BUILD_TYPE=DEBUG \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
RUN ninja
RUN ninja
RUN ninja check-circt
# RUN ninja check-circt-integration
RUN ninja install

ENV PATH="/opt/llvm/bin:/opt/circt/bin:/opt/slang/bin:$PATH"

RUN mkdir -p /workspace
CMD ["/usr/bin/zsh"]
