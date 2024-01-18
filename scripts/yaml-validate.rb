#!/usr/bin/env ruby


module Validate

  class Base
    require 'json'

    def initialize
      @files   = []
      @results = {}
    end

    def git_files
      `git log --name-only -n 1 --pretty=format:`.split("\n")
    end

    def files
      git_files.each do |file|
        next unless File.exist?(file)
        next unless file =~ @pattern
        @files.push(file)
      end
      @files
    end

    def results
      exit 0 if @results.keys.count == 0
      puts JSON.pretty_generate(@results)
      exit 1
    end
  end

  class YAML < Base
    require 'yaml'

    def initialize
      @pattern = %r{\.ya?ml$}
      super
    end

    def to_err(message)
      file  = message.sub(%r{\((.*)\):.*}, '\1')
      short = message.sub(%r{\(.*\):(.*) at.*}, '\1')
      line  = message.sub(%r{.*line (\d+).*}, '\1')
      pos   = message.sub(%r{.*column (\d+).*}, '\1')
      {
        issue_code: 'SYNTAX_ERROR',
        message: short,
        full_message: message,
        file: file,
        line: line,
        pos:  pos
      }
    end

    def validate
      files.each do |file|
        begin
          ::YAML.load_file(file)
        rescue Exception => err
          @results[file] = to_err(err.to_s)
        end
      end
    end
  end
end

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
yaml = Validate::YAML.new
yaml.validate
yaml.results
