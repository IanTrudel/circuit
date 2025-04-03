MLIR_PATH ?= /opt/mlir        # or wherever MLIR is installed inside your Docker
CLANG     ?= clang++
CXXFLAGS  += -fPIC -shared -std=c++17 -O2 \
             -I$(MLIR_PATH)/include \
             -I$(MLIR_PATH)/tools/mlir/include \
             `llvm-config --cxxflags`
LDFLAGS   += `llvm-config --ldflags --libs core Support` \
             -lMLIRIR -lMLIRPass -lMLIRSupport

TARGET = MoorePrettyPrinter.so
SRC    = MoorePrettyPrinter.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CLANG) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)

