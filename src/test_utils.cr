module TestUtils
  def self.clean_results_yml(verbose=false)
    file_path = CNFManager::Points::Results.file
    if !File.exists?(file_path)
      results = CNFManager::Points.parse_results_file()
      File.open(file_path, "w") do |f|
        YAML.dump({name: results["name"],
                  status: results["status"],
                  exit_code: results["exit_code"],
                  points: results["points"],
                  items: [] of YAML::Any}, f)
      end
    end
  end
end