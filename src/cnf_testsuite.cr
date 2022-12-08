require "./tasks/utils/utils.cr"
require "release_manager"

module CnfTestSuite
  ReleaseManager::CompileTimeVersionGenerater.tagged_version
end
