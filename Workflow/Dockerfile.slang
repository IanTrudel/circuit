# Building Slang
FROM ubuntu:22.04 AS slang

RUN apt-get update && apt-get install -y \
    git cmake ninja-build build-essential \
    libreadline-dev python3 python3-pip

WORKDIR /opt
RUN git clone https://github.com/MikePopoloski/slang.git --depth 1

WORKDIR /opt/slang-build
RUN cmake ../slang -DCMAKE_BUILD_TYPE=Release \
   -DCMAKE_INSTALL_PREFIX=/opt/slang -DSLANG_INCLUDE_TOOLS=ON \
   -Wdev --log-level=VERBOSE

RUN cmake --build . --target install

RUN ctest --output-on-failure

RUN rm -rf /opt/slang-build

ENV PATH="/opt/slang/bin:$PATH"

RUN mkdir -p /opt/testsuite/
COPY Workflow/testsuite /opt/testsuite/
RUN slang /opt/testsuite/sv/adder.sv > /dev/null

