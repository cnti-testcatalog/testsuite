require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/release_manager.cr"
require "file_utils"
require "sam"

describe "ReleaseManager" do
  after_all do
    ReleaseManager::GithubReleaseManager.delete_release("test_version")
    $?.success?.should be_true
  end
  it "'#ReleaseManager.tag' should return the list of tags on the current branch"  do
    (ReleaseManager.tag[0]).should match(/(?i)(master|v[0-1]|test_version)/)
  end
  it "'#ReleaseManager.tag' should accept a list of options"  do
      (ReleaseManager.tag("--list")).should_not eq([""])
      (ReleaseManager.tag("--list 'shouldbeempty'")).should eq([""]) 
  end
  it "'#ReleaseManager.current_branch' should return the current branch as a string"  do
    if ReleaseManager.on_a_tag?
      (ReleaseManager.current_branch).should eq("HEAD")
    else
      (ReleaseManager.current_branch).should_not eq("")
    end
  end

  it "'#ReleaseManager.current_hash' should return the current hash as a string"  do
    (ReleaseManager.current_hash).should_not eq("")
  end

  it "'#ReleaseManager::GithubReleaseManager.github_releases' should return the existing releases", tags: "release"  do
    (ReleaseManager::GithubReleaseManager.github_releases.size).should be > 0
  end

  it "'#ReleaseManager::GithubReleaseManager.upsert_release' should return the upserted release and asset response", tags: "release"  do
    found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("test_version")
    # (asset["errors"]?==nil || (asset["errors"]? && asset["errors"].find |x| {x["code"] =~ /already_exists/})).should be_truthy
    if asset
      (asset["errors"]?==nil || (asset["errors"]? && asset["errors"][0]["code"]  == "already_exists")).should be_truthy
    else
      (asset).should_not be_nil
    end
    # (asset["url"]?).should match("https://api.github.com/repos/cncf/cnf-conformance/releases/assets")

  end

  # TODO uncomment after travis is tested and working
  # it "'#ReleaseManager::GithubReleaseManager.upsert_release' should return nil if not on a valid version", tags: "release"  do
  #   found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("invalid_version")
  #   (asset).should be_nil
  # end

  it "'#ReleaseManager::GithubReleaseManager.delete_release' should delete the release from the found_id", tags: "release"  do
    found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("test_version")
    resp_code = ReleaseManager::GithubReleaseManager.delete_release("test_version")
    (resp_code == 204).should be_truthy
  end

end
