require "../utils/utils.cr"

def get_excluded_tasks(args)
  if args.named.has_key? "exclude"
    exclude = args.named["exclude"]
    if exclude.is_a? String
      exclude = exclude.includes?(",") ? exclude.split(",") : exclude.split(" ")
    else
      puts "Exclude argument should contain string value Ex.: (exclude=\"increase_decrease_capacity single_process_type\")"
      exit 1
    end
  else
    exclude = [] of String
  end
  unless exclude.empty?
    cert_tests = CNFManager::Points.tasks_by_tag_intersection(["cert"])
    exclude.each do |task|
      unless cert_tests.includes? task
        puts "Excluded task \"#{task}\" is not a cert test, check syntax"
        exit 1
      end
    end
  end
  exclude
end

  
def invoke_tasks_by_tag_list(parent_task, tags, exclude_tasks=[] of String)
  tasks = CNFManager::Points.tasks_by_tag_intersection(tags)
  tasks.each do |task|
    unless exclude_tasks.includes? task
      parent_task.invoke(task)
    end
  end
end

def cert_stdout_score(tags, full_name, exclude_warning = false)
  stdout_score(tags, full_name)
  if exclude_warning
    stdout_info "With \"exclude\" parameter, number of total tests executed isn't correct, keep in mind.".colorize(:yellow)
  end
end
