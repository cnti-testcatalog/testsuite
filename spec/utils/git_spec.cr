require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/git.cr"
require "file_utils"
require "sam"

describe "Git" do
  it "'#Git.tag' should return the list of tags on the current branch"  do
    (Git.tag).should contain("v0.3.0")
  end
  it "'#Git.tag' should accept a list of options"  do
      (Git.tag("--list")).should_not eq([""])
      (Git.tag("--list 'shouldbeempty'")).should eq([""]) 
  end
  it "'#Git.current_branch' should return the current branch as a string"  do
    if Git.on_a_tag?
      (Git.current_branch).should eq("HEAD")
    else
      (Git.current_branch).should_not eq("")
    end
  end

  it "'#Git.current_hash' should return the current hash as a string"  do
    (Git.current_hash).should_not eq("")
  end
end
