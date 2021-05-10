require "sam"
require "file_utils"
require "colorize"
require "totem"

desc "Sets up an airgapped tarball"
task "airgapped",  do  |_, args|
  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
  #./cnf-testsuite offline of=~/airgapped.tar.gz
  #./cnf-testsuite offline output-file=~/mydir/airgapped.tar.gz
  output_file = args.named["output-file"].as(String) if args.named["output-file"]?
    output_file = args.named["of"].as(String) if args.named["of"]?
  if output_file && !output_file.empty?
      AirGap.generate(output_file)
  else
    AirGap.generate()
  end
  stdout_success "Airgap setup complete"
end

task "configuration_file_setup" do |_, args|
  VERBOSE_LOGGING.info "configuration_file_setup" if check_verbose(args)
  CNFManager::Points.create_points_yml
end

