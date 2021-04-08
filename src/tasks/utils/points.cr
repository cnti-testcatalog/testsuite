require "totem"
require "colorize"
require "./types/cnf_conformance_yml_type.cr"
require "./helm.cr"
require "uuid"

module CNFManager

  module Points
    class Results

      enum ResultStatus
        Passed
        Failed
        Skipped
      end

      @@file : String
      @@file = CNFManager::Points.create_final_results_yml_name
      LOGGING.debug "Results.file"
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
        branch = ENV.has_key?("SCORING_ENV") ? ENV["SCORING_ENV"] : "main"
        default_scoring_yml = "https://raw.githubusercontent.com/cncf/cnf-conformance/#{branch}/scoring_config/#{DEFAULT_POINTSFILENAME}"
        # LOGGING.info "curl -o #{DEFAULT_POINTSFILENAME} #{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}"
        # `curl -o #{DEFAULT_POINTSFILENAME} #{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}`
        HTTP::Client.get("#{ENV.has_key?("SCORING_YML") ? ENV["SCORING_YML"] : default_scoring_yml}") do |response| 
          File.write("#{DEFAULT_POINTSFILENAME}", response.body_io)
        end
        `mv #{DEFAULT_POINTSFILENAME} #{POINTSFILE}`
      end
    end

    def self.create_final_results_yml_name
      FileUtils.mkdir_p("results") unless Dir.exists?("results")
      "results/cnf-conformance-results-" + Time.local.to_s("%Y%m%d-%H%M%S-%L") + ".yml"
    end

    def self.clean_results_yml(verbose=false)
      if File.exists?("#{Results.file}")
        results = File.open("#{Results.file}") do |f|
          YAML.parse(f)
        end
        File.open("#{Results.file}", "w") do |f|
          YAML.dump({name: results["name"],
                     status: results["status"],
                     exit_code: results["exit_code"],
                     points: results["points"],
                     items: [] of YAML::Any}, f)
        end
      end
    end

    def self.task_points(task, status : CNFManager::Points::Results::ResultStatus = CNFManager::Points::Results::ResultStatus::Passed)
      case status
      when CNFManager::Points::Results::ResultStatus::Passed
        resp = CNFManager::Points.task_points(task, true)
      when CNFManager::Points::Results::ResultStatus::Failed
        resp = CNFManager::Points.task_points(task, false)
      when CNFManager::Points::Results::ResultStatus::Skipped
        field_name = "skipped"
        points =points_yml.find {|x| x["name"] == task}
        LOGGING.warn "****Warning**** task #{task} not found in points.yml".colorize(:yellow) unless points
        if points && points[field_name]?
            resp = points[field_name].as_i if points
        else
          points =points_yml.find {|x| x["name"] == "default_scoring"}
          resp = points[field_name].as_i if points
        end
      end
      LOGGING.info "task_points: task: #{task} is worth: #{resp} points"
      resp
    end

    def self.task_points(task, passed=true)
      if passed
        field_name = "pass"
      else
        field_name = "fail"
      end
      points =points_yml.find {|x| x["name"] == task}
      LOGGING.warn "****Warning**** task #{task} not found in points.yml".colorize(:yellow) unless points
      if points && points[field_name]?
          points[field_name].as_i if points
      else
        points =points_yml.find {|x| x["name"] == "default_scoring"}
        points[field_name].as_i if points
      end
    end

    def self.total_points(tag=nil)
      if tag
        tasks = tasks_by_tag(tag)
      else
        tasks = all_task_test_names
      end
      yaml = File.open("#{Results.file}") do |file|
        YAML.parse(file)
      end
      LOGGING.debug "total_points: #{tag}, found tasks: #{tasks}"
      total = yaml["items"].as_a.reduce(0) do |acc, i|
        LOGGING.debug "total_points: #{tag}, #{i["name"].as_s} = #{i["points"].as_i}"
        if i["points"].as_i? && i["name"].as_s? &&
            tasks.find{|x| x == i["name"]}
          (acc + i["points"].as_i)
        else
          acc
        end
      end
      LOGGING.info "total_points: #{tag} = #{total}"
      total
    end

    def self.total_max_points(tag=nil)
      if tag
        tasks = tasks_by_tag(tag)
      else
        tasks = all_task_test_names
      end
      max = tasks.reduce(0) do |acc, x|
        points = task_points(x)
        if points
          acc + points
        else
          acc
        end
      end
      LOGGING.info "total_max_points: #{tag} = #{max}"
      max
    end

    def self.upsert_task(task, status, points)
      results = File.open("#{Results.file}") do |f|
        YAML.parse(f)
      end

      result_items = results["items"].as_a
      # remove the existing entry
      result_items = result_items.reject do |x|
        x["name"] == task
      end

      result_items << YAML.parse "{name: #{task}, status: #{status}, points: #{points}}"
      File.open("#{Results.file}", "w") do |f|
        YAML.dump({name: results["name"],
                   status: results["status"],
                   points: results["points"],
                   exit_code: results["exit_code"],
                   items: result_items}, f)
      end
      LOGGING.info "upsert_task: task: #{task} has status: #{status} and is awarded: #{points} points"
    end

    def self.failed_task(task, msg)
      upsert_task(task, FAILED, task_points(task, false))
      stdout_failure "#{msg}"
    end

    def self.passed_task(task, msg)
      upsert_task(task, PASSED, task_points(task))
      stdout_success "#{msg}"
    end

    def self.skipped_task(task, msg)
      upsert_task(task, SKIPPED, task_points(task))
      stdout_success "#{msg}"
    end

    def self.failed_required_tasks
      yaml = File.open("#{Results.file}") do |file|
        YAML.parse(file)
      end
      yaml["items"].as_a.reduce([] of String) do |acc, i|
        if i["status"].as_s == "failed" &&
            i["name"].as_s? &&
            task_required(i["name"].as_s)
          (acc << i["name"].as_s)
        else
          acc
        end
      end
    end

    def self.task_required(task)
      points =points_yml.find {|x| x["name"] == task}
      LOGGING.warn "task #{task} not found in points.yml".colorize(:yellow) unless points
      if points && points["required"]? && points["required"].as_bool == true
        true
      else
        false
      end
    end

    def self.all_task_test_names
      result_items =points_yml.reduce([] of String) do |acc, x|
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
      result_items =points_yml.reduce([] of String) do |acc, x|
        # LOGGING.debug "tasks_by_tag: tag:#{tag}, points.name:#{x["name"].as_s?}, points.tags:#{x["tags"].as_s?}"
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

      results = File.open("#{Results.file}") do |f|
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

    def self.final_cnf_results_yml
      LOGGING.info "final_cnf_results_yml"
      results_file = `find ./results/* -name "cnf-conformance-results-*.yml"`.split("\n")[-2].gsub("./", "")
      if results_file.empty?
        raise "No cnf_conformance-results-*.yml found! Did you run the all task?"
      end
      results_file
    end
  end

end
