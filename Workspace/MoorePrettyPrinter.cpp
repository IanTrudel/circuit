#include "mlir/IR/Operation.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Support/IndentedOstream.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"

using namespace mlir;

namespace {
struct MoorePrettyPrinterPass
    : public PassWrapper<MoorePrettyPrinterPass, OperationPass<ModuleOp>> {
  void runOnOperation() override {
    ModuleOp module = getOperation();
    llvm::outs() << "=== Moore Pretty Printed Output ===\n";
    for (auto &op : module.getOps()) {
      op.print(llvm::outs(), OpPrintingFlags().enableDebugInfo(true));
      llvm::outs() << "\n";
    }
  }
};
} // namespace

extern "C" void registerMoorePrettyPrinter() {
  PassRegistration<MoorePrettyPrinterPass>(
      "moore-pretty-print", "Pretty print Moore IR");
}

