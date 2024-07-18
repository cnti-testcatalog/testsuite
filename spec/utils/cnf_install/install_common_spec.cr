require "../../spec_helper"

it "'CNFInstall.exclusive_install_method_tags' should return false if install method tags are not exclusive", tags: ["cnf-config"]  do
    config = CNFManager.parsed_config_file("./spec/fixtures/cnf-testsuite-not-exclusive.yml")
    resp = CNFInstall.exclusive_install_method_tags?(config)
    (resp).should be_false 
end