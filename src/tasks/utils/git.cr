require "totem"
require "colorize"
require "./sample_utils.cr"
require "logger"

module Git
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
    Git.tag("--points-at HEAD") != [""]
  end

  def self.current_tag
    Git.tag("--points-at HEAD")
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
