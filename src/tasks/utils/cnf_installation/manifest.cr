module CNFInstall
  module Manifest
    def self.parse_manifest_as_ymls(file_name)
      Log.info { "parse_manifest_as_ymls file_name: #{file_name}" }
      file_content = File.read(file_name)
      split_content = file_content.split(/(\s|^)---(\s|$)/)
      ymls = split_content.map { | manifest |
        #TODO strip out NOTES
        YAML.parse(manifest)
        # compact seems to have problems with yaml::any
      }.reject{|x|x==nil}
      Log.debug { "parse_manifest_as_ymls:\n #{ymls}" }
      ymls
    end
    
    def self.manifest_ymls_from_file_list(manifest_file_list)
      ymls = manifest_file_list.map do |x|
        parse_manifest_as_ymls(x)
      end
      ymls.flatten
    end
    
    def self.manifest_file_list(manifest_directory, silent=false)
      Log.info { "manifest_file_list" }
      Log.info { "manifest_directory: #{manifest_directory}" }
      if manifest_directory && !manifest_directory.empty? && manifest_directory != "/"
        cmd = "find #{manifest_directory}/ -name \"*.yml\" -o -name \"*.yaml\""
        Log.info { cmd }
        Process.run(
          cmd,
          shell: true,
          output: find_resp = IO::Memory.new,
          error: find_err = IO::Memory.new
        )
        manifests = find_resp.to_s.split("\n").select{|x| x.empty? == false}
        Log.info { "find response: #{manifests}" }
        if manifests.size == 0 && !silent
          raise "No manifest ymls found in the #{manifest_directory} directory!"
        end
        manifests
      else
        [] of String
      end
    end
    
    def self.manifest_containers(manifest_yml)
      Log.debug { "manifest_containers: #{manifest_yml}" }
      manifest_yml.dig?("spec", "template", "spec", "containers")
    end

    def self.add_manifest_to_file(deployment_name : String, manifest : String, destination_file)
      File.open(destination_file, "a+") do |file|
          file.puts manifest
          Log.info { "#{deployment_name} manifest was appended into #{destination_file} file" }
      end
    end
    
    def self.generate_common_manifest(config, deployment_name, namespace)
      manifest_generated_successfully = true
      case config.dynamic.install_method[0]
      when CNFInstall::InstallMethod::ManifestDirectory
        destination_cnf_dir = config.dynamic.destination_cnf_dir
        manifest_directory = config.deployments.get_deployment_param(:manifest_directory)
        list_of_manifests = manifest_file_list( destination_cnf_dir + "/" + manifest_directory )
        list_of_manifests.each do |manifest_path|
          manifest = File.read(manifest_path)
          add_manifest_to_file(deployment_name, manifest, COMMON_MANIFEST_FILE_PATH)
        end
      
      when CNFInstall::InstallMethod::HelmChart, CNFInstall::InstallMethod::HelmDirectory
        begin
          generated_manifest = Helm.generate_manifest(deployment_name, namespace)
          add_manifest_to_file(deployment_name, generated_manifest, COMMON_MANIFEST_FILE_PATH)
        rescue ex : Helm::ManifestGenerationError
          Log.for("generate_common_manifest").error { ex.message }
          manifest_generated_successfully = false
        end
      end
      manifest_generated_successfully
    end
  end
end