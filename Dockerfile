# Building googletest (gtest)
FROM ubuntu:22.04 AS googletest-builder

ARG JOBS=4

RUN apt-get update && apt-get install -y \
   cmake g++ git

RUN mkdir -p /opt
WORKDIR /opt

RUN git clone https://github.com/google/googletest.git -b v1.16.0
WORKDIR /opt/googletest
RUN mkdir build
WORKDIR /opt/googletest/build
RUN cmake ..
RUN make -j$JOBS && make install

# Building LLVM
FROM ubuntu:22.04 AS llvm-builder

ARG LLVM_VERSION=18
ARG JOBS=4

RUN apt-get update && apt-get install -y \
   git cmake ninja-build build-essential pkg-config \
   libedit-dev libncurses5-dev libxml2-dev libsqlite3-dev zlib1g-dev \
   python3 python3-pip python3-setuptools \
   zsh curl unzip doxygen graphviz

COPY --from=googletest-builder /opt/googletest/googletest/include /usr/local/include
COPY --from=googletest-builder /opt/googletest/build/lib /usr/local/lib

RUN mkdir -p /opt
WORKDIR /opt

RUN git clone https://github.com/llvm/llvm-project.git --branch release/${LLVM_VERSION}.x --depth 1 
#--single-branch

RUN mkdir -p /opt/llvm-build
WORKDIR /opt/llvm-build
RUN cmake -G Ninja ../llvm-project/llvm \
   #-DLLVM_ENABLE_PROJECTS="bolt;clang;clang-tools-extra;compiler-rt;cross-project-tests;lld;lldb;mlir" \
   -DLLVM_ENABLE_PROJECTS="mlir;clang;clang-tools-extra;lld;lldb" \
   -DLLVM_TARGETS_TO_BUILD="host" \
   -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_CXX_STANDARD=17 \
   -DLLVM_ENABLE_ASSERTIONS=ON \
   -DLLVM_BUILD_UTILS=ON \
   -DLLVM_INSTALL_UTILS=ON \
   -DLLVM_INCLUDE_TOOLS=ON \
   -DLLVM_USE_SPLIT_DWARF=ON \
   -DMLIR_ENABLE_EXECUTION_ENGINE=ON \
   -DCMAKE_INSTALL_PREFIX=/opt/llvm \
   -DLLVM_INCLUDE_TESTS=ON \
   -DLLVM_INSTALL_GTEST=ON \
   -DLLVM_BUILD_TESTS=ON
RUN ninja -j$JOBS
RUN ninja -j$JOBS FileCheck count not split-file
RUN ninja -j$JOBS check-llvm
RUN ninja -j$JOBS check-lit
RUN ninja -j$JOBS check-mlir
RUN ninja install

ENV PATH="/opt/llvm/bin:$PATH"

RUN diff -qr ./llvm/bin /opt/llvm/bin | grep "^Only in ./llvm/bin" | awk -F': ' '{print $2}' | while read file; do cp "./llvm/bin/$(basename "$file")" /opt/llvm/bin/; done

RUN mkdir -p /opt/testsuite/
COPY testsuite /opt/testsuite/
RUN mlir-opt /opt/testsuite/llvm/basic.mlir > /dev/null

# Building Slang
FROM ubuntu:22.04 AS slang-builder

ARG JOBS=4

RUN apt-get update && apt-get install -y \
    git cmake ninja-build build-essential \
    libreadline-dev python3 python3-pip

WORKDIR /opt
RUN git clone https://github.com/MikePopoloski/slang.git --depth 1

WORKDIR /opt/slang-build
RUN cmake ../slang -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_INSTALL_PREFIX=/opt/slang -DSLANG_INCLUDE_TOOLS=ON \
   -Wdev --log-level=VERBOSE

RUN cmake --build . --target install -j$JOBS

RUN ctest --output-on-failure

ENV PATH="/opt/slang/bin:$PATH"

RUN mkdir -p /opt/testsuite/
COPY testsuite /opt/testsuite/
RUN slang /opt/testsuite/sv/adder.sv > /dev/null

# Building CIRCT
FROM ubuntu:22.04 AS circt-builder

ARG JOBS=4

RUN apt-get update && apt-get install -y \
   git cmake ninja-build build-essential g++ \
   python3 python3-pip python3-setuptools \
   libedit-dev libncurses5-dev libxml2-dev \
   zlib1g-dev pkg-config libsqlite3-dev libz3-dev z3

RUN pip3 install pybind11 setuptools lit

ENV LLVM_DIR=/opt/llvm/lib/cmake/llvm
ENV MLIR_DIR=/opt/llvm/lib/cmake/mlir
ENV SLANG_DIR=/opt/slang/lib/cmake/slang
ENV CMAKE_PREFIX_PATH="/opt/install/llvm;/opt/install/slang"

RUN mkdir -p /opt

WORKDIR /opt
RUN git clone https://github.com/llvm/circt.git --depth 1

WORKDIR /opt/circt
RUN git submodule update --init --recursive

COPY --from=googletest-builder /opt/googletest/googletest/include /usr/local/include
COPY --from=googletest-builder /opt/googletest/build/lib /usr/local/lib
COPY --from=llvm-builder /opt/llvm /opt/llvm
COPY --from=slang-builder /opt/slang /opt/slang

RUN /opt/llvm/bin/llvm-lit --version || echo "the world has crumbled, again, sir!"

RUN pip install lit

WORKDIR /opt/circt-build

RUN cmake -G Ninja ../circt \
   -DCMAKE_BUILD_TYPE=Release \
   -DCIRCT_RELEASE_TAG_ENABLED=ON \
   -DCMAKE_INSTALL_PREFIX=/opt/circt \
   -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH \
   -DCMAKE_CXX_STANDARD=17 \
   -DLLVM_USE_SPLIT_DWARF=ON \
   -DCIRCT_SLANG_FRONTEND_ENABLED=ON \
   -DPYTHON_EXECUTABLE=$(which python3) \
   -DCIRCT_GTEST_AVAILABLE=ON
RUN ninja -j$JOBS
RUN ninja -j$JOBS check-circt
RUN ninja -j$JOBS install

#-DLLVM_EXTERNAL_LIT=/opt/llvm/bin/llvm-lit \
#   -DLLVM_DIR=$LLVM_DIR \
#   -DMLIR_DIR=$MLIR_DIR \

ENV PATH="/opt/circt/bin:$PATH"

RUN mkdir -p /opt/testsuite/
COPY testsuite /opt/testsuite/
RUN firtool /opt/testsuite/firtool/simple.fir > /dev/null
RUN firtool /opt/testsuite/firtool/full.fir > /dev/null

# Building the final image
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
   git cmake ninja-build build-essential pkg-config \
   libedit-dev libncurses5-dev libxml2-dev libsqlite3-dev zlib1g-dev \
   python3 python3-pip python3-setuptools \
   zsh curl unzip doxygen graphviz

COPY --from=googletest-builder /opt/googletest/googletest/include /usr/local/include
COPY --from=googletest-builder /opt/googletest/build/lib /usr/local/lib
COPY --from=llvm-builder /opt/llvm /opt/llvm
COPY --from=slang-builder /opt/slang /opt/slang
COPY --from=circt-builder /opt/circt /opt/circt

ENV PATH="/opt/llvm/bin:/opt/circt/bin:/opt/slang/bin:$PATH"

RUN mkdir -p /workspace
CMD ["/usr/bin/zsh"]
