require "totem"
require "colorize"
require "./sample_utils.cr"
require "logger"
require "halite"

module ReleaseManager 
  module GithubReleaseManager
    def self.github_releases : Array(JSON::Any)
      existing_releases = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
        get("https://api.github.com/repos/cncf/cnf-conformance/releases", 
            headers: {Accept: "application/vnd.github.v3+json"})
      JSON.parse(existing_releases.body).as_a
    end 

    def self.upsert_release(version=nil) : Tuple((JSON::Any | Nil), (JSON::Any | Nil))
      LOGGING.info "upsert_release"
      found_release : (JSON::Any | Nil) = nil
      asset : (JSON::Any | Nil) = nil
      upsert_version = (version || CnfConformance::VERSION)
      if upsert_version =~ /(?i)(master)/
        prerelease = false
      else
        prerelease = true
      end
      unless upsert_version =~ /(?i)(master|v[0-1]|test_version)/
        LOGGING.info "Not creating a release for : #{upsert_version}"
        return {found_release, asset} 
      end
      LOGGING.info "upsert_version: #{upsert_version}"
      release_resp = ReleaseManager::GithubReleaseManager.github_releases
      LOGGING.info "release_resp size: #{release_resp.size}"
      found_release = release_resp.find {|x| x["tag_name"] == upsert_version} 
      LOGGING.info "find found_release?: #{found_release}"
      unless found_release
        # /repos/:owner/:repo/releases
        found_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
          post("https://api.github.com/repos/cncf/cnf-conformance/releases", 
               headers: {Accept: "application/vnd.github.v3+json"},
               json: { "tag_name" => upsert_version, 
                       "draft" => true, 
                       "prerelease" => prerelease, 
                       "name" => "#{upsert_version} #{Time.local.to_s("%B, %d %Y")}", 
                       "body" => "TEMPLATE: Fill out release notes" })
        found_release = JSON.parse(found_resp.body)
        # TODO error if cant create a release
        LOGGING.info "(unless) found_release: #{found_release}"
      end
      cnf_tarball_name = "cnf-conformance-#{upsert_version}.tar.gz"
      cnf_tarball = `tar -czvf #{cnf_tarball_name} ./cnf-conformance`
      LOGGING.info "cnf_tarball: #{cnf_tarball}"

      # PATCH /repos/:owner/:repo/releases/:release_id
      found_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
        patch("https://api.github.com/repos/cncf/cnf-conformance/releases/#{found_release["id"]}", 
              json: { "tag_name" => upsert_version,
                      "draft" => true, 
                      "prerelease" => prerelease, 
                      "name" => "#{upsert_version} #{Time.local.to_s("%B, %d %Y")}", 
                      "body" => "TEMPLATE: Fill out release notes" })
      found_release = JSON.parse(found_resp.body)

      LOGGING.info "found_release (after create): #{found_release}"
      LOGGING.info "found_release id: #{found_release["id"]}"
      # POST :server/repos/:owner/:repo/releases/:release_id/assets{?name,label}
      asset_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
        post("https://uploads.github.com/repos/cncf/cnf-conformance/releases/#{found_release["id"]}/assets?name=#{cnf_tarball_name}",
             headers: {
                "Content-Type" => "application/gzip",
                "Content-Length" => File.size("#{cnf_tarball_name}").to_s 
        }, raw: "#{File.open("#{cnf_tarball_name}")}")
        # asset = `curl -u nupejosh:#{ENV["GITHUB_TOKEN"]} -H "Content-Type: $(file -b --mime-type #{cnf_filename})" --data-binary @#{cnf_filename} "https://uploads.github.com/repos/cncf/cnf-conformance/releases/#{found_release["id"]}/assets?name=$(basename #{cnf_filename})"`
       asset = JSON.parse(asset_resp.body)
      LOGGING.info "asset: #{asset}"
      {found_release, asset}
    end

    def self.delete_release(version)
      # DELETE /repos/:owner/:repo/releases/assets/:asset_id
      # DELETE /repos/:owner/:repo/releases/:release_id
      release_resp = ReleaseManager::GithubReleaseManager.github_releases
      puts "this is the version #{version}"
      found_release = release_resp.find {|x| x["tag_name"] == "#{version}"} 
      puts "this is found_release #{typeof(found_release)}"
      if found_release
        puts "this is found_release id #{found_release["id"]}"
        resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
          delete("https://api.github.com/repos/cncf/cnf-conformance/releases/#{found_release["id"]}")
        resp_code = resp.status_code
        LOGGING.info "resp_code: #{resp_code}"
      else 
        resp_code = 404
      end 
      resp_code
    end 

    #TODO get github secrets and add them to the CI (e.g. travis) secrets list 
  end
  module CompileTimeVersionGenerater
    macro tagged_version
      {% current_branch = `git rev-parse --abbrev-ref HEAD` %}
      {% current_hash = `git rev-parse --short HEAD` %}
      {% current_tag = `git tag --points-at HEAD` %}
      {% if current_tag.strip == "" %}
        VERSION = "{{current_branch.strip}}-{{current_hash.strip}}"
      {% else %}
        VERSION = "{{current_tag.strip}}"
      {% end %}
    end
  end

  def self.tag(options="")
    results = `git tag #{options}`
    LOGGING.info "git tag: #{results}"
    results.split("\n")
  end

  def self.on_a_tag?
    ReleaseManager.tag("--points-at HEAD") != [""]
  end

  def self.current_tag
    ReleaseManager.tag("--points-at HEAD")
  end

  def self.current_branch
    results = `git rev-parse --abbrev-ref HEAD`
    LOGGING.info "current_branch rev-parse: #{results}"
    results.strip("\n")
  end

  def self.current_hash
    results = `git rev-parse --short HEAD`
    LOGGING.info "current_hash rev-parse: #{results}"
    results.strip("\n")
  end

end 
