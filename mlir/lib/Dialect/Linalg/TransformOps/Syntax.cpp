//===- Syntax.cpp - Custom syntax for Linalg transform ops ----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Linalg/TransformOps/Syntax.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/Support/InterleavedRange.h"

using namespace mlir;

ParseResult mlir::parseSemiFunctionType(OpAsmParser &parser, Type &argumentType,
                                        Type &resultType, bool resultOptional) {
  argumentType = resultType = nullptr;

  bool hasLParen = resultOptional ? parser.parseOptionalLParen().succeeded()
                                  : parser.parseLParen().succeeded();
  if (!resultOptional && !hasLParen)
    return failure();
  if (parser.parseType(argumentType).failed())
    return failure();
  if (!hasLParen)
    return success();

  return failure(parser.parseRParen().failed() ||
                 parser.parseArrow().failed() ||
                 parser.parseType(resultType).failed());
}

ParseResult mlir::parseSemiFunctionType(OpAsmParser &parser, Type &argumentType,
                                        SmallVectorImpl<Type> &resultTypes) {
  argumentType = nullptr;
  bool hasLParen = parser.parseOptionalLParen().succeeded();
  if (parser.parseType(argumentType).failed())
    return failure();
  if (!hasLParen)
    return success();

  if (parser.parseRParen().failed() || parser.parseArrow().failed())
    return failure();

  if (parser.parseOptionalLParen().failed()) {
    Type type;
    if (parser.parseType(type).failed())
      return failure();
    resultTypes.push_back(type);
    return success();
  }
  if (parser.parseTypeList(resultTypes).failed() ||
      parser.parseRParen().failed()) {
    resultTypes.clear();
    return failure();
  }
  return success();
}

void mlir::printSemiFunctionType(OpAsmPrinter &printer, Operation *op,
                                 Type argumentType, TypeRange resultType) {
  if (!resultType.empty())
    printer << "(";
  printer << argumentType;
  if (resultType.empty())
    return;
  printer << ") -> ";

  if (resultType.size() > 1)
    printer << "(";
  printer << llvm::interleaved(resultType);
  if (resultType.size() > 1)
    printer << ")";
}

void mlir::printSemiFunctionType(OpAsmPrinter &printer, Operation *op,
                                 Type argumentType, Type resultType,
                                 bool resultOptional) {
  assert(resultOptional || resultType != nullptr);
  return printSemiFunctionType(printer, op, argumentType,
                               resultType ? TypeRange(resultType)
                                          : TypeRange());
}
