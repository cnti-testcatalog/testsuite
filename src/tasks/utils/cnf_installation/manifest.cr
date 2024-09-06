module CNFInstall
  module Manifest
    def self.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
      Log.info { "parse_manifest_as_ymls template_file_name: #{template_file_name}" }
      templates = File.read(template_file_name)
      split_template = templates.split(/(\s|^)---(\s|$)/)
      ymls = split_template.map { | template |
        #TODO strip out NOTES
        YAML.parse(template)
        # compact seems to have problems with yaml::any
      }.reject{|x|x==nil}
      Log.debug { "read_template ymls: #{ymls}" }
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

    def self.add_manifest_to_file(release_name : String, manifest : String | Tuple(String, String), destination_file = "cnfs/common_manifest.yml")
      if File.exists?(destination_file)
        File.open(destination_file, "a") do |file|
          file.puts manifest
          Log.info { "#{release_name} manifest was appended into #{destination_file} file" }
        end
      else
        File.open(destination_file, "w") do |file|
          file.puts manifest
          Log.info { "Created #{destination_file} file with #{release_name} manifest." }
        end
      end
    end
    
    def self.generate_manifest(config, release_name, namespace)
      install_method = CNFInstall.cnf_installation_method(config)
      case install_method[0]
      when CNFInstall::InstallMethod::ManifestDirectory
        destination_cnf_dir = config.cnf_config[:destination_cnf_dir]
        manifest_directory = config.cnf_config[:manifest_directory]
        list_of_manifests = manifest_file_list( destination_cnf_dir + "/" + manifest_directory )
        list_of_manifests.each do |manifest_path|
          manifest = File.read(manifest_path)
          add_manifest_to_file(release_name: release_name, manifest: manifest)
        end
      
      when CNFInstall::InstallMethod::HelmChart, CNFInstall::InstallMethod::HelmDirectory
        begin
          generated_manifest = Helm.generate_manifest(release_name, namespace)
          add_manifest_to_file(release_name: release_name, manifest: generated_manifest)
        rescue ex : Helm::ManifestGenerationError
          Log.error { ex.message.colorize(:red) }
          exit 1
        end
      end
    end
  end
end