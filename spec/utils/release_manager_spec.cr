require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/release_manager.cr"
require "file_utils"
require "sam"

describe "ReleaseManager" do
  # after_all do
  #   ReleaseManager::GithubReleaseManager.delete_release("test_version")
  # end
  # it "'#ReleaseManager.tag' should return the list of tags on the current branch"  do
  #   (ReleaseManager.tag.size).should be > 0
  # end
  # it "'#ReleaseManager.tag' should accept a list of options"  do
  #     (ReleaseManager.tag("--list")).should_not eq([""])
  #     (ReleaseManager.tag("--list 'shouldbeempty'")).should eq([""]) 
  # end
  # it "'#ReleaseManager.current_branch' should return the current branch as a string"  do
  #   if ReleaseManager.on_a_tag?
  #     (ReleaseManager.tag("--list")).should_not eq([""])
  #   else
  #     (ReleaseManager.current_branch).should_not eq("")
  #   end
  # end
  #
  # it "'#ReleaseManager.current_hash' should return the current hash as a string"  do
  #   (ReleaseManager.current_hash).should_not eq("")
  # end
  #
  # it "'#ReleaseManager.remote_master_branch_hash' should return the current hash as a string"  do
  #   (ReleaseManager.remote_master_branch_hash).should_not eq("")
  # end
  #
  # it "'#ReleaseManager::GithubReleaseManager.github_releases' should return the existing releases", tags: "release"  do
  #   (ReleaseManager::GithubReleaseManager.github_releases.size).should be > 0
  # end
  #
  # it "'#ReleaseManager::GithubReleaseManager.upsert_release' should return the upserted release and asset response", tags: "release"  do
  #   found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("test_version")
  #   if asset
  #     (asset["errors"]?==nil || (asset["errors"]? && asset["errors"][0]["code"]  == "already_exists")).should be_truthy
  #   else
  #     (asset).should_not be_nil
  #   end
  # end
  #
  # it "'#ReleaseManager::GithubReleaseManager.upsert_release' should return nil if not on a valid version", tags: "release"  do
  #   found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("invalid_version")
  #   (asset).should be_nil
  # end
  #
  # it "'#ReleaseManager::GithubReleaseManager.delete_release' should delete the release from the found_id", tags: "release"  do
  #   found_release, asset = ReleaseManager::GithubReleaseManager.upsert_release("test_version")
  #   resp_code = ReleaseManager::GithubReleaseManager.delete_release("test_version")
  #   (resp_code == 204).should be_truthy
  # end
  # it "'#ReleaseManager.detached_head?' should return if the head is detached", tags: "release"  do
  #   (ReleaseManager.detached_head?).should_not be_nil
  # end

  it "'#ReleaseManager.commit_message_issues' should list previsions releases", tags: "release"  do
    issues = ReleaseManager.commit_message_issues("HEAD~5", "HEAD")
    (issues[0].match(/#/)).should_not be_nil
  end
  #
  # it "'#ReleaseManager.latest_release' should return latest release", tags: "release"  do
  #   issues = ReleaseManager.latest_release
  #   # https://github.com/semver/semver/blob/master/semver.md#is-v123-a-semantic-version
  #   (issues.match(/^(.|)(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/)).should_not be_nil
  # end
  #
  # it "'#ReleaseManager.issue_title' should return issue title", tags: "release"  do
  #   issues = ReleaseManager.issue_title("#318")
  #   (issues.match(/#206 documentation update/)).should_not be_nil
  # end

end
