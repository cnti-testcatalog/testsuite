require "totem"
require "colorize"
require "./types/cnf_testsuite_yml_type.cr"
require "helm"
require "uuid"
require "./points.cr"

module CNFManager 

  module Task
    FAILURE = 1
    CRITICAL_FAILURE = 2

    def self.ensure_cnf_installed!

      cnf_installed = CNFManager.cnf_installed?

      LOGGING.info("ensure_cnf_installed?  #{cnf_installed}")
      
      unless cnf_installed
        puts "You must install a CNF first.".colorize(:yellow)
        exit 1
      end
    end

    def self.task_runner(args, task : Sam::Task|Nil=nil, check_cnf_installed=true, &block : Sam::Args, CNFManager::Config -> String | Colorize::Object(String) | CNFManager::TestcaseResult | Nil)
      LOGGING.info("task_runner args: #{args.inspect}")

      CNFManager::Points::Results.ensure_results_file!

      if check_cnf_installed
        ensure_cnf_installed!
      end

      if check_cnf_config(args)
        single_task_runner(args, task, &block)
      else
        all_cnfs_task_runner(args, task, &block)
      end
    end

    # TODO give example for calling
    def self.all_cnfs_task_runner(args, task : Sam::Task|Nil=nil, &block : Sam::Args, CNFManager::Config  -> String | Colorize::Object(String) | CNFManager::TestcaseResult | Nil)
      cnf_configs = CNFManager.cnf_config_list(silent: true)
      Log.info { "CNF configs found: #{cnf_configs.size}" }

      # Platforms tests dont have any cnfs
      if cnf_configs.size == 0
        single_task_runner(args, &block)
      else
        cnf_configs.map do |x|
          new_args = Sam::Args.new(args.named, args.raw)
          new_args.named["cnf-config"] = x
          single_task_runner(new_args, task, &block)
        end
      end
    end

    # TODO give example for calling
    def self.single_task_runner(args, task : Sam::Task|Nil=nil, &block : Sam::Args, CNFManager::Config -> String | Colorize::Object(String) | CNFManager::TestcaseResult | Nil)
      LOGGING.debug("single_task_runner args: #{args.inspect}")

      begin
        if args.named["cnf-config"]? # platform tests don't have a cnf-config
            config = CNFManager::Config.parse_config_yml(args.named["cnf-config"].as(String))    
        else
          config = CNFManager::Config.new({ destination_cnf_dir: "",
                                            source_cnf_file: "",
                                            source_cnf_dir: "",
                                            yml_file_path: "",
                                            install_method: {Helm::InstallMethod::HelmChart, ""},
                                            manifest_directory: "",
                                            helm_directory: "", 
                                            source_helm_directory: "",
                                            helm_chart_path: "", 
                                            manifest_file_path: "",
                                            release_name: "",
                                            service_name: "",
                                            helm_repository: {name: "", repo_url: ""},
                                            helm_chart: "",
                                            helm_values: "",
                                            helm_install_namespace: "",
                                            rolling_update_tag: "",
                                            container_names: [{"name" =>  "", "rolling_update_test_tag" => ""}],
                                            white_list_container_names: [""],
                                            docker_insecure_registries: [] of String,
                                            amf_label: "",
                                            smf_label: "",
                                            upf_label: "",
                                            ric_label: "",
                                            fiveG_core: {amf_service_name:  "",
                                                           mmc:  "",
                                                           mnc:  "",
                                                           sst:  "",
                                                           sd:  "",
                                                           tac:  "",
                                                           protectionScheme:  "",
                                                           publicKey:  "",
                                                           publicKeyId:  "",
                                                           routingIndicator:  "",
                                                           enabled:  "",
                                                           count:  "",
                                                           initialMSISDN:  "",
                                                           key:  "",
                                                           op:  "",
                                                           opType:  "",
                                                           type:  "",
                                                           apn:  "",
                                                           emergency:  "",
                                                          },
                                            image_registry_fqdns: Hash(String, String).new} )
        end
        test_start_time = Time.utc
        if task
          test_name = task.as(Sam::Task).name.as(String)
          Log.for(test_name).info { "Starting test" }
          Log.for(test_name).debug { "cnf_config: #{config}" }
          puts "🎬 Testing: [#{test_name}]"
        end
        ret = yield args, config
        if ret.is_a?(CNFManager::TestcaseResult)
          upsert_decorated_task(test_name, ret.state, ret.result_message, test_start_time)
        end
        #todo lax mode, never returns 1
        if args.raw.includes? "strict"
          if CNFManager::Points.failed_required_tasks.size > 0
            stdout_failure "Test Suite failed in strict mode. Stopping executing."
            stdout_failure "Failed required tasks: #{CNFManager::Points.failed_required_tasks.inspect}"
            update_yml("#{CNFManager::Points::Results.file}", "exit_code", "1")
            exit 1
          end
        end
        ret
      rescue ex
        # platform tests don't have a cnf-config
        # Set exception key/value in results
        # file to -1
        test_start_time = Time.utc
        LOGGING.error ex.message
        ex.backtrace.each do |x|
          LOGGING.error x
        end
        
        update_yml("#{CNFManager::Points::Results.file}", "exit_code", "2")
        if args.raw.includes? "strict" 
          LOGGING.info "Strict mode exception.  Stopping execution."
          exit 2
        else
          Log.info { "exception with skipped exit code" }
          upsert_decorated_task(test_name, CNFManager::ResultStatus::Error, "Unexpected error occurred", test_start_time)
        end
      end
    end
  end
end
