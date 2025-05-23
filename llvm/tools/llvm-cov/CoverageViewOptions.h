//===- CoverageViewOptions.h - Code coverage display options -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_COV_COVERAGEVIEWOPTIONS_H
#define LLVM_COV_COVERAGEVIEWOPTIONS_H

#include "RenderingSupport.h"
#include "llvm/Config/llvm-config.h"
#include <vector>

namespace llvm {

/// The options for displaying the code coverage information.
struct CoverageViewOptions {
  enum class OutputFormat {
    Text,
    HTML,
    Lcov
  };

  enum class BranchOutputType { Count, Percent, Off };

  bool Debug;
  bool Colors;
  bool ShowLineNumbers;
  bool ShowLineStats;
  bool ShowRegionMarkers;
  bool ShowMCDC;
  bool ShowBranchCounts;
  bool ShowBranchPercents;
  bool ShowExpandedRegions;
  bool ShowFunctionInstantiations;
  bool UnifyFunctionInstantiations;
  bool ShowFullFilenames;
  bool ShowBranchSummary;
  bool ShowMCDCSummary;
  bool ShowRegionSummary;
  bool ShowInstantiationSummary;
  bool ShowDirectoryCoverage;
  bool ExportSummaryOnly;
  bool SkipExpansions;
  bool SkipFunctions;
  bool SkipBranches;
  bool BinaryCounters;
  OutputFormat Format;
  BranchOutputType ShowBranches;
  std::string ShowOutputDirectory;
  std::vector<std::string> DemanglerOpts;
  uint32_t TabSize;
  std::string ProjectTitle;
  std::string CreatedTimeStr;
  unsigned NumThreads;
  std::string CompilationDirectory;
  float HighCovWatermark;
  float LowCovWatermark;

  /// Change the output's stream color if the colors are enabled.
  ColoredRawOstream colored_ostream(raw_ostream &OS,
                                    raw_ostream::Colors Color) const {
    return llvm::colored_ostream(OS, Color, Colors);
  }

  /// Check if an output directory has been specified.
  bool hasOutputDirectory() const { return !ShowOutputDirectory.empty(); }

  /// Check if a demangler has been specified.
  bool hasDemangler() const { return !DemanglerOpts.empty(); }

  /// Check if a project title has been specified.
  bool hasProjectTitle() const { return !ProjectTitle.empty(); }

  /// Check if the created time of the profile data file is available.
  bool hasCreatedTime() const { return !CreatedTimeStr.empty(); }

  /// Get the LLVM version string.
  std::string getLLVMVersionString() const {
    std::string VersionString = "Generated by llvm-cov -- llvm version ";
    VersionString += LLVM_VERSION_STRING;
    return VersionString;
  }
};
}

#endif // LLVM_COV_COVERAGEVIEWOPTIONS_H
