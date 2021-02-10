# coding: utf-8
require "totem"
require "colorize"
require "./types/cnf_conformance_yml_type.cr"
require "./helm.cr"
require "uuid"
module CNFManager 

  module Points
    def self.points_yml
      # TODO get points.yml from remote http
      points = File.open("points.yml") do |f| 
        YAML.parse(f)
      end 
      # LOGGING.debug "points: #{points.inspect}"
      points.as_a
    end
    def self.create_points_yml
      unless File.exists?("#{POINTSFILE}")
        branch = ENV.has_key?("SCORING_ENV") ? ENV["SCORING_ENV"] : "master"
        default_scoring_yml = "https://raw.githubusercontent.com/cncf/cnf-conformance/#{branch}/scoring_config/#{DEFAULT_POINTSFILENAME}"
        `wget #{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}`
        `mv #{DEFAULT_POINTSFILENAME} #{POINTSFILE}`
      end
    end

    def self.create_final_results_yml_name
      FileUtils.mkdir_p("results") unless Dir.exists?("results")
      "results/cnf-conformance-results-" + Time.local.to_s("%Y%m%d-%H%M%S-%L") + ".yml"
    end

    def self.clean_results_yml(verbose=false)
      if File.exists?("#{CNFManager::Points::Results.file}")
        results = File.open("#{CNFManager::Points::Results.file}") do |f| 
          YAML.parse(f)
        end 
        File.open("#{CNFManager::Points::Results.file}", "w") do |f| 
          YAML.dump({name: results["name"],
                     status: results["status"],
                     exit_code: results["exit_code"],
                     points: results["points"],
                     items: [] of YAML::Any}, f)
        end 
      end
    end

    def self.task_points(task, passed=true)
      if passed
        field_name = "pass"
      else
        field_name = "fail"
      end
      points =CNFManager::Points.points_yml.find {|x| x["name"] == task}
      LOGGING.warn "****Warning**** task #{task} not found in points.yml".colorize(:yellow) unless points
      if points && points[field_name]? 
          points[field_name].as_i if points
      else
        points =CNFManager::Points.points_yml.find {|x| x["name"] == "default_scoring"}
        points[field_name].as_i if points
      end
    end

    def self.total_points(tag=nil)
      if tag
        tasks = CNFManager::Points.tasks_by_tag(tag)
      else
        tasks = CNFManager::Points.all_task_test_names
      end
      yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
        YAML.parse(file)
      end
      yaml["items"].as_a.reduce(0) do |acc, i|
        if i["points"].as_i? && i["name"].as_s? &&
            tasks.find{|x| x == i["name"]}
          (acc + i["points"].as_i)
        else
          acc
        end
      end
    end

    def self.total_max_points(tag=nil)
      if tag
        tasks = CNFManager::Points.tasks_by_tag(tag)
      else
        tasks = CNFManager::Points.all_task_test_names
      end
      tasks.reduce(0) do |acc, x|
        points = CNFManager::Points.task_points(x)
        if points
          acc + points
        else
          acc
        end
      end
    end

    def self.upsert_task(task, status, points) 
      results = File.open("#{CNFManager::Points::Results.file}") do |f| 
        YAML.parse(f)
      end 

      result_items = results["items"].as_a
      # remove the existing entry
      result_items = result_items.reject do |x| 
        x["name"] == task  
      end

      result_items << YAML.parse "{name: #{task}, status: #{status}, points: #{points}}"
      File.open("#{CNFManager::Points::Results.file}", "w") do |f| 
        YAML.dump({name: results["name"],
                   status: results["status"],
                   points: results["points"],
                   exit_code: results["exit_code"],
                   items: result_items}, f)
      end 
    end

    def self.failed_task(task, msg)
      CNFManager::Points.upsert_task(task, FAILED, CNFManager::Points.task_points(task, false))
      stdout_failure "#{msg}"
    end

    def self.passed_task(task, msg)
      CNFManager::Points.upsert_task(task, PASSED, CNFManager::Points.task_points(task))
      stdout_success "#{msg}"
    end

    def self.failed_required_tasks
      yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
        YAML.parse(file)
      end
      yaml["items"].as_a.reduce([] of String) do |acc, i|
        if i["status"].as_s == "failed" && 
            i["name"].as_s? && 
            CNFManager::Points.task_required(i["name"].as_s)
          (acc << i["name"].as_s)
        else
          acc
        end
      end
    end

    def self.task_required(task)
      points =CNFManager::Points.points_yml.find {|x| x["name"] == task}
      LOGGING.warn "task #{task} not found in points.yml".colorize(:yellow) unless points
      if points && points["required"]? && points["required"].as_bool == true
        true
      else
        false
      end
    end

    def self.all_task_test_names
      result_items =CNFManager::Points.points_yml.reduce([] of String) do |acc, x|
        if x["name"].as_s == "default_scoring" ||
            x["tags"].as_s.split(",").find{|x|x=="platform"}
          acc
        else
          acc << x["name"].as_s
        end
      end
    end

    def self.tasks_by_tag(tag)
      #TODO cross reference points.yml tags with results
      found = false
      result_items =CNFManager::Points.points_yml.reduce([] of String) do |acc, x|
        if x["tags"].as_s? && x["tags"].as_s.includes?(tag)
          acc << x["name"].as_s
        else
          acc
        end
      end
    end

    def self.all_result_test_names(results_file)
      results = File.open(results_file) do |f| 
        YAML.parse(f)
      end 
      result_items = results["items"].as_a.reduce([] of String) do |acc, x|
        acc << x["name"].as_s
      end
    end

    def self.results_by_tag(tag)
      task_list = tasks_by_tag(tag)

      results = File.open("#{CNFManager::Points::Results.file}") do |f| 
        YAML.parse(f)
      end 

      found = false
      result_items = results["items"].as_a.reduce([] of YAML::Any) do |acc, x|
        if x["name"].as_s? && task_list.find{|tl| tl == x["name"].as_s}
          acc << x
        else
          acc
        end
      end
    end

    class Results
      @@file : String
      @@file = CNFManager::Points.create_final_results_yml_name
      LOGGING.info "CNFManager::Points::Results.file"
      continue = false
      LOGGING.info "file exists?:#{File.exists?(@@file)}"
      if File.exists?("#{@@file}")
        stdout_info "Do you wish to overwrite the #{@@file} file? If so, your previous results.yml will be lost."
        print "(Y/N) (Default N): > "
        if ENV["CRYSTAL_ENV"]? == "TEST"
          continue = true
        else
          user_input = gets
          if user_input == "Y" || user_input == "y"
            continue = true
          end
        end
      else
        continue = true
      end
      if continue
        File.open("#{@@file}", "w") do |f|
          YAML.dump(CNFManager::Points.template_results_yml, f)
        end
      end
      def self.file
        @@file
      end
    end

    def self.template_results_yml
  #TODO add tags for category summaries
  YAML.parse <<-END
name: cnf conformance 
status: 
points: 
exit_code: 0
items: []
END
    end
  end

  def self.final_cnf_results_yml
    LOGGING.info "final_cnf_results_yml" 
    results_file = `find ./results/* -name "cnf-conformance-results-*.yml"`.split("\n")[-2].gsub("./", "")
    if results_file.empty?
      raise "No cnf_conformance-results-*.yml found! Did you run the all task?"
    end
    results_file
  end
end
