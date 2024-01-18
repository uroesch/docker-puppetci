#!/opt/puppetlabs/puppet/bin/ruby

require 'json'

module Junit
  Template = <<~JUNIT_XML
    <?xml version="1.0" encoding="UTF-8"?>
    <testsuites>
      <id><%= id %></id>
      <name><%= name %> (<%= datetime %>)</name>
      <tests><%= tests %></tests>
      <failures><%= failures %></failures>
      <time><%= time %></time>
      <testsuite>
        <id><%= suite_name %></id>
        <name><%= suite_name %></name>
        <tests><%= tests %></tests>
        <failures><%= failures %></failures>
        <time><%= time %></time>
    <% errors.each do |file,error| %>
        <testcase>
          <suite><%= suite_name %></suite>
          <suitename><%= suite_name %></suitename>
          <id><%= File.basename(file) %>_<%= id %></id>
          <file><%= file %></file>
          <name><%= error['issue_code'] %></name>
          <time>0.001</time>
          <failure>
            <message><%= error['message'] %></message>
            <type>ERROR</type>
    <%= error['full_message'] %>

    Category: <%= error['issue_code'] %>
    File: <%= error['file'] %>
    Line: <%= error['line'] %>
    Pos: <%= error['pos'] %>
          </failure>
        </testcase>
    <% end %>
       </testsuite>
    </testsuites>
  JUNIT_XML

  class Junit::Xml
    require 'json'
    require 'pp'
    require 'erb'
    def initialize(json, **kwargs)
      @junit  = kwargs
      @errors = parse_json(json)
    end

    def parse_json(json)
      return {} if json.empty?
      json = normalize_json_stream(json)
      JSON.parse(json)
    end

    def normalize_json_stream(json)
      streams = json.strip.gsub(%r{^\{}, '').split(%r{^\}$})
      '{' + streams.join(',') + '}'
    end

    def dump
      pp @errors
    end

    def timestamp
      @junit[:ts] = @junit.fetch(:ts, Time.now)
    end

    def id
      ENV.fetch('CI_JOB_ID', timestamp.strftime('%Y%m%d%H%M%S_%6N'))
    end

    def suite_name
      ENV.fetch('CI_JOB_NAME', @junit[:name].downcase.gsub(%r{\s}, '_'))
    end

    def generate_meta
      @junit[:id]         = id
      @junit[:datetime]   = timestamp.strftime('%F %T')
      @junit[:suite_name] = suite_name
      @junit[:tests]      = @errors.keys.count
      @junit[:failures]   = @errors.keys.count
      @junit[:time]       = 0.001
      @junit[:errors]     = @errors
    end

    def to_xml
      generate_meta
      print ERB.new(Junit::Template, nil, '<>').result_with_hash(@junit)
    end
  end
end

junit = Junit::Xml.new(STDIN.read, name: 'Puppet Validate')
junit.to_xml
