require "totem"
require "colorize"
require "string_scanner"
require "./cnf_manager.cr"
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
      LOGGING.info "CnfConformance::VERSION: #{CnfConformance::VERSION}"
      LOGGING.info "version: #{version}"
      upsert_version = (version || CnfConformance::VERSION)
      LOGGING.info "upsert_version: #{upsert_version}"
      # cnf_bin_path = "cnf-conformance"
      # cnf_bin_asset_name = "#{cnf_bin_path}"
      cnf_bin_asset_name = "cnf-conformance"

      if ReleaseManager.remote_main_branch_hash == ReleaseManager.current_hash
        upsert_version = upsert_version.sub("HEAD", "main")
      end
      if upsert_version =~ /(?i)(main)/
        prerelease = true 
        draft = false
      else
        prerelease = true
        draft = true 
      end
      LOGGING.info "upsert_version: #{upsert_version}"
      LOGGING.info "upsert_version comparison: upsert_version =~ /(?i)(main|v[0-9]|test_version)/ : #{upsert_version =~ /(?i)(main|v[0-9]|test_version)/}"
      #master-381d20d
      invalid_version = !(upsert_version =~ /(?i)(main|v[0-9]|test_version)/)
      snap_shot_version = (upsert_version =~ /(?i)(main-)/)
      head = (ReleaseManager.current_branch == "HEAD")
      skip_snapshot_detached_head = (head && snap_shot_version)
      LOGGING.info "invalid_version: #{invalid_version}"
      LOGGING.info "current_branch: #{ReleaseManager.current_branch}"
      LOGGING.info "skip_snapshot_detached_head: #{skip_snapshot_detached_head}"
      if skip_snapshot_detached_head || invalid_version
        LOGGING.info "Not creating a release for : #{upsert_version}"
        return {found_release, asset} 
      end

      # NOTE: build MUST be done first so we can sha256sum for release notes
      # Build a static binary so it will be portable on other machines in non test
      unless ENV["CRYSTAL_ENV"]? == "TEST"
        # Rely on the docker ci to create the static binary
        # rm_resp = `rm ./cnf-conformance`
        # LOGGING.info "rm_resp: #{rm_resp}"
        # LOGGING.info "building static binary"
        # build_resp = `crystal build src/cnf-conformance.cr --release --static --link-flags "-lxml2 -llzma"`
        # LOGGING.info "build_resp: #{build_resp}"
        # the name of the binary asset must be unique across all releases in github for project
        # TODO if upsert version == test then make unique
        cnf_tarball_name = "cnf-conformance-#{upsert_version}.tar.gz"
        cnf_tarball = `tar -czvf #{cnf_tarball_name} ./#{cnf_bin_asset_name}`
        LOGGING.info "cnf_tarball: #{cnf_tarball}"
        # cnf_bin_asset_name = "#{cnf_bin_path}-static" # change upload name for static builds
        cnf_bin_asset_name = "#{cnf_tarball_name}" # change upload name for static builds
      end
      # sha_checksum = `sha256sum #{cnf_bin_path}`.split(" ")[0]
      sha_checksum = `sha256sum #{cnf_bin_asset_name}`.split(" ")[0]

      LOGGING.info "upsert_version: #{upsert_version}"
      release_resp = ReleaseManager::GithubReleaseManager.github_releases
      LOGGING.info "release_resp size: #{release_resp.size}"

      found_release = release_resp.find {|x| x["tag_name"] == upsert_version} 
      LOGGING.info "find found_release?: #{found_release}"

      if upsert_version =~ /(?i)(main)/
        latest_build = ReleaseManager.latest_snapshot
      else
        latest_build = ReleaseManager.latest_release
      end
      LOGGING.info "latest_build: #{latest_build}"
      issues = ReleaseManager.commit_message_issues(latest_build, "HEAD")
      LOGGING.info "issues: #{issues}"
      titles = issues.reduce("") do |acc, x| 
        acc + "- #{x} - #{ReleaseManager.issue_title(x)}\n"
      end
      # LOGGING.info "titles: #{titles}"
notes_template = <<-TEMPLATE
UPDATES
---
Issues addressed in this release:
#{titles}

Artifact info:
- Commit: #{upsert_version}
- SHA256SUM: #{sha_checksum} #{cnf_bin_asset_name}

TEMPLATE

      release_url = "https://api.github.com/repos/cncf/cnf-conformance/releases"
      unless found_release
        # /repos/:owner/:repo/releases
          # post(release_url, headers: {Accept: "application/vnd.github.v3+json"}, json: { "tag_name" => upsert_version, "draft" => draft, "prerelease" => prerelease, "name" => "#{upsert_version} #{Time.local.to_s("%B, %d %Y")}", "body" => notes_template }) found_release = JSON.parse(found_resp.body)
         
        headers = {Accept: "application/vnd.github.v3+json"}
        json = { "tag_name" => upsert_version, 
                 "draft" => draft, 
                 "prerelease" => prerelease, 
                 "name" => "#{upsert_version} #{Time.local.to_s("%B %d, %Y")}", 
                 "body" => notes_template }

        LOGGING.info "Release not found.  Creating a release: # url: #{release_url} headers: #{headers} json #{json}"

        found_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).post(release_url, headers: headers, json: json) 
        found_release = JSON.parse(found_resp.body)
        # TODO error if cant create a release
        LOGGING.info "(unless) found_release: #{found_release}"
      end

      # PATCH /repos/:owner/:repo/releases/:release_id
      found_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
        patch("#{release_url}/#{found_release["id"]}",
              json: { "tag_name" => upsert_version,
                      "draft" => draft,
                      "prerelease" => prerelease,
                      "name" => "#{upsert_version} #{Time.local.to_s("%B %d, %Y")}",
                      "body" => notes_template })
      found_release = JSON.parse(found_resp.body)

      LOGGING.info "found_release (after create): #{found_release}"

      # NOTE: so I wrote all this code... and then recognized tarballs and zips of the source
      # are automatically generated by github whenever you PUBLISH a release...
      # note that is AFTER you hit publish. before their won't be and you can double check this
      # by editing and already existing release
      #
      # left this code just in case or in case we want to upload other stuff
      #
      ## source_tarball_name = "cnf-conformance-#{upsert_version}"
      ## `git archive -o #{source_tarball_name} --format=tar.gz $(git rev-parse --abbrev-ref HEAD)`
      ## `git archive -o #{source_tarball_name} --format=zip $(git rev-parse --abbrev-ref HEAD)`

      ## LOGGING.info "source_tarball: #{source_tarball_name}"
      ## source_tarball_path = `#{source_tarball_name}.tar.gz`
      ## source_zip_path = `#{source_tarball_name}.zip`

      ## LOGGING.info "uploading binary"
      ## bin_asset_resp = ReleaseManager.upload_release_asset(found_release["id"], cnf_bin_path, cnf_bin_asset_name)
      ## LOGGING.info "uploading source tarball"
      ## source_tarball_asset_resp = ReleaseManager.upload_release_asset(found_release["id"], source_tarball_path, source_tarball_path)
      ## LOGGING.info "uploading source zip"
      ## source_zip_asset_resp = ReleaseManager.upload_release_asset(found_release["id"], source_zip_path, source_zip_path)

      ## const assets = [bin_asset_resp, source_tarball_asset_resp, source_zip_asset_resp]

      LOGGING.info "uploading binary"
      asset = ReleaseManager.upload_release_asset(found_release["id"], cnf_bin_asset_name)
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
      {% current_branch = `git rev-parse --abbrev-ref HEAD`.split("\n")[0].strip %}
      {% current_hash = `git rev-parse --short HEAD` %}
      {% current_status = `git status`.split("\n")[0].strip %}
      {% current_tag = (!`git tag --points-at HEAD`.empty? && `git tag --points-at HEAD`.split("\n")[-2].strip) || `git tag --points-at HEAD` %} 
      {% puts "current_branch during compile: #{current_branch}" %}
      {% puts "current_tag during compile: #{current_tag}" %}
      {% if current_tag.strip == "" %}
        VERSION = {{current_branch}} + "-#{Time.local.to_s("%Y-%m-%d-%H%M%S")}-{{current_hash.strip}}"
      {% else %}
        VERSION = {{current_tag.strip}}
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
    results = `git rev-parse --abbrev-ref HEAD`.split("\n")[0].strip
    LOGGING.info "current_branch rev-parse: #{results}"
    results.strip("\n")
  end

  def self.current_hash
    results = `git rev-parse --short HEAD`
    LOGGING.info "current_hash rev-parse: #{results}"
    results.strip("\n")
  end

  def self.remote_main_branch_hash(owner_repo="cncf/cnf-conformance")
    results =  `git ls-remote https://github.com/#{owner_repo}.git main | awk '{ print $1}' | cut -c1-7`.strip
    LOGGING.info "remote_main_branch_hash: #{results}"
    results.strip("\n")
  end

  # def self.upload_release_asset(release_id, asset_path, asset_name)
  def self.upload_release_asset(release_id, asset_name)
      # TODO Add test that checks for uploaded corrupted binary.
      # POST :server/repos/:owner/:repo/releases/:release_id/assets{?name,label}
      # asset_resp = Halite.basic_auth(user: ENV["GITHUB_USER"], pass: ENV["GITHUB_TOKEN"]).
      #   post("https://uploads.github.com/repos/cncf/cnf-conformance/releases/#{found_release["id"]}/assets?name=#{cnf_tarball_name}",
      #        headers: {
      #           "Content-Type" => "application/gzip",
      #           "Content-Length" => File.size("#{cnf_tarball_name}").to_s
      #   }, raw: "#{File.open("#{cnf_tarball_name}")}")A
    asset_resp = `curl --http1.1 -u #{ENV["GITHUB_USER"]}:#{ENV["GITHUB_TOKEN"]} -H "Content-Type: $(file -b --mime-type #{asset_name})" --data-binary @#{asset_name} "https://uploads.github.com/repos/cncf/cnf-conformance/releases/#{release_id}/assets?name=$(basename #{asset_name})"`
    LOGGING.info "asset_resp: #{asset_resp}"
    asset = JSON.parse(asset_resp.strip)
    LOGGING.info "asset: #{asset}"
    asset
  end

  def self.commit_message_issues(start_ref, end_ref)
    # github actions checkout must be set with this option for the git log command to work:
    # steps: 
    # - name: Checkout code
    #   uses: actions/checkout@v2
    #   with:
    #     fetch-depth: 0
    fetch_tags = `git fetch --tags`
    LOGGING.info "git fetch --tags: #{fetch_tags}"
    fetch = `git status`
    LOGGING.info "git status: #{fetch}"
    fetch = `git branch`
    LOGGING.info "git branch: #{fetch}"
    commit_messages = `git log #{start_ref}..#{end_ref}`
    # LOGGING.info "commit_messages: #{commit_messages}"
    #TODO scrape issue urls
    uniq_issues = commit_messages.scan(/(#[0-9]{1,9})/).not_nil!.map{|x| x[1]}.uniq
    LOGGING.info "uniq_issues: #{uniq_issues}"
    uniq_issues.map {|x| x.strip("\n")}
  end

  def self.latest_release
    resp = `curl -u #{ENV["GITHUB_USER"]}:#{ENV["GITHUB_TOKEN"]} --silent "https://api.github.com/repos/cncf/cnf-conformance/releases/latest"`
    LOGGING.info "latest_release: #{resp}"
    parsed_resp = JSON.parse(resp)
    parsed_resp["tag_name"]?.not_nil!.to_s
  end

  def self.latest_snapshot
    resp = `curl -u #{ENV["GITHUB_USER"]}:#{ENV["GITHUB_TOKEN"]} --silent "https://api.github.com/repos/cncf/cnf-conformance/releases"`
    LOGGING.info "latest_release: #{resp}"
    parsed_resp = JSON.parse(resp)
    prerelease = parsed_resp.as_a.select{ | x | x["prerelease"]==true && !("#{x["published_at"]?}".empty?) }
    latest_snapshot = prerelease.sort do |a, b|
      LOGGING.debug "a #{a}"
      LOGGING.debug "b #{b}"
      if (b["published_at"]? && a["published_at"]?)
        Time.parse(b["published_at"].as_s,
                   "%Y-%m-%dT%H:%M:%SZ",
                   Time::Location::UTC) <=>
          Time.parse(a["published_at"].as_s,
                     "%Y-%m-%dT%H:%M:%SZ",
                     Time::Location::UTC)
      else
        0
      end
    end
    LOGGING.debug "latest_snapshot: #{latest_snapshot}"
    latest_snapshot[0]["tag_name"]?.not_nil!.to_s
  end

  def self.issue_title(issue_number)
    pure_issue = issue_number.gsub("#", "")
    resp = `curl -u #{ENV["GITHUB_USER"]}:#{ENV["GITHUB_TOKEN"]} "https://api.github.com/repos/cncf/cnf-conformance/issues/#{pure_issue}"`
    # LOGGING.info "issue_text: #{resp}"
    parsed_resp = JSON.parse(resp)
    parsed_resp["title"]?.not_nil!.to_s
  end

  def self.detached_head?
    resp = `git rev-parse --abbrev-ref --symbolic-full-name HEAD`
    LOGGING.info "detached_head: #{resp}"
    resp.strip("\n") == "HEAD"
  end
end 
