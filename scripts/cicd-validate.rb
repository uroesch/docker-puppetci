#!/usr/bin/env ruby

# validate yaml files before commiting.

require 'find'
require 'yaml'

def find_yaml_files
  yaml_files = []
  Find.find('.') do |path|
    next if path =~ %r{.git/}
    next if path !~ %r{.ya?ml$}
    next if path =~ %r{./.gitlab-ci.yml}
    yaml_files.push path
  end
  return yaml_files
end


def validate_yaml_files
  exit_code = 0
  find_yaml_files.each do |path|
    begin
      YAML.load_file path
    rescue => err
      puts err.message
      exit_code += 1
    end
  end
  exit exit_code
end

validate_yaml_files
