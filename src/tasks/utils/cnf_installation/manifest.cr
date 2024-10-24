module CNFInstall
  module Manifest
    def self.manifest_path_to_ymls(manifest_path)
      Log.info { "manifest_path_to_ymls file_path: #{manifest_path}" }
      manifest = File.read(manifest_path)
      manifest_string_to_ymls(manifest)
    end

    def self.manifest_string_to_ymls(manifest_string)
      Log.info { "manifest_string_to_ymls" }
      split_content = manifest_string.split(/(\s|^)---(\s|$)/)
      ymls = split_content.map { | manifest |
        YAML.parse(manifest)
        # compact seems to have problems with yaml::any
      }.reject{|x|x==nil}
      Log.debug { "manifest_string_to_ymls:\n #{ymls}" }
      ymls
    end

    def self.combine_ymls_as_manifest_string(ymls : Array(YAML::Any)) : String
      Log.info { "combine_ymls_as_manifest_string" }
      manifest = ymls.map do |yaml_object|
        yaml_object.to_yaml
      end.join
      Log.debug { "combine_ymls_as_manifest:\n #{manifest}" }
      manifest
    end
    
    def self.manifest_ymls_from_file_list(manifest_file_list)
      ymls = manifest_file_list.map do |x|
        manifest_path_to_ymls(x)
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

    # Apply namespaces only to resources that are retrieved from Kubernetes as namespaced resource kinds.
    # Namespaced resource kinds are utilized exclusively during the Helm installation process.
    def self.add_namespace_to_resources(manifest_string, namespace) 
      Log.for("add_namespace_to_resources").info { "Updating metadata.namespace field for resources in generated manifest" }
      namespaced_resources = KubectlClient::ShellCmd.run("kubectl api-resources --namespaced=true --no-headers", "", false).[:output]
      list_of_namespaced_resources = namespaced_resources.split("\n").select { |item| !item.empty? }
      list_of_namespaced_kinds = list_of_namespaced_resources.map do |line|
        line.split(/\s+/).last
      end
      parsed_manifest = manifest_string_to_ymls(manifest_string)
      ymls = [] of YAML::Any

      parsed_manifest.each do |resource|
        if resource["kind"].as_s.in?(list_of_namespaced_kinds)
          Helm.ensure_resource_with_namespace(resource, namespace)
          Log.for("add_namespace_to_resources").info { "Added #{namespace} namespace for resource: {kind: #{resource["kind"]}, name: #{resource["metadata"]["name"]}}" }
        end
        ymls << resource
      end

      string_manifest_with_namespaces = combine_ymls_as_manifest_string(ymls)
      Log.for("add_namespace_to_resources").debug { "\n#{string_manifest_with_namespaces}" }
      string_manifest_with_namespaces
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
          generated_manifest_with_namespaces = add_namespace_to_resources(generated_manifest, namespace)
          add_manifest_to_file(deployment_name, generated_manifest_with_namespaces, COMMON_MANIFEST_FILE_PATH)
        rescue ex : Helm::ManifestGenerationError
          Log.for("generate_common_manifest").error { ex.message }
          manifest_generated_successfully = false
        end
      end
      manifest_generated_successfully
    end
  end
end