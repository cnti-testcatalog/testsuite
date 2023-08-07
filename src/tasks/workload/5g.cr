# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "Test if a 5G core supports SUCI Concealment"
task "suci_enabled" do |_, args|
  test_name = "specialized_init_system"
  CNFManager::Task.task_runner(args) do |args, config|
    Log.info { "Running #{test_name} test" }

    #todo put in prereq
    Helm.fetch("openverso/ueransim-gnb --version 0.2.5 --untar")
    File.write("gnb-ues-values.yaml", UES_VALUES)
    Helm.install("ueransim #{Dir.current}/ueransim-gnb --values ./gnb-ues-values.yaml")

    #TODO cluster_tools exec tshark command: tshark -ni any -Y nas_5gs.mm.type_id -T json > test.file 
    #TODO look for connection text (sanity check)
    ClusterTools.exec("tshark -ni any -Y nas_5gs.mm.type_id  -T json > test.log")

    #todo cluster_tools exec get text-<uniqueid>.file 
    #TODO parse tshark command
    #TODO look for authentication text
    #todo cluster_tools exec delete text-<uniqueid>.file 


    # extra
    #TODO tshark library
    #TODO 5g tools library
    #TODO 5g RAN and Core mobile traffic check (connection check)
    #TODO 5g RAN (only) mobile traffic check ????
    #TODO ueransim library (w/setup command)
    #TODO Open5gs libary (w/setup command)

    nil
  end

end
