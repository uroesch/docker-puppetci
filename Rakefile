require 'yaml'

# ------------------------------------------------------------------------------
# Setup
# ------------------------------------------------------------------------------
# See https://bundler.io/guides/bundler_docker_guide.html for more information.
ENV.delete('BUNDLE_PATH')
ENV.delete('BUNDLE_BIN')

# ------------------------------------------------------------------------------
# Globals
# ------------------------------------------------------------------------------
BUNDLE_BASE_DIR   = '/usr/local/bundle'
BUNDLE_VENDOR_DIR = 'vendor/bundle'
GEMS              = {
  'puppet'             => { version: ENV.fetch('PUPPET', '7') },
  'puppet-check'       => { version: ENV.fetch('PUPPET_CHECK', '2') },
  'r10k'               => { version: ENV.fetch('R10K', '4') },
  'octocatalog-diff'   => { version: ENV.fetch('OCTOCATALOG_DIFF', '2') },
  'puppet-syntax'      => { version: ENV.fetch('PUPPET_SYNTAX', '2') },
  'puppet-lint'        => { 
    version: ENV.fetch('PUPPET_LINT', '4'), 
    gems: [ 
      'puppet-ghostbuster',
      'voxpupuli-puppet-lint-plugins',
      'puppet-lint-absolute_classname-check',
      'puppet-lint-absolute_template_path',
      'puppet-lint-alias-check',
      'puppet-lint-anchor-check',
      'puppet-lint-appends-check',
      'puppet-lint-array_formatting-check',
      'puppet-lint-empty_trailing_lines',
      'puppet-lint-exec_idempotent-check',
      'puppet-lint-extended',
      'puppet-lint-file_ensure-check',
      'puppet-lint-global_definition-check',
      'puppet-lint-halyard',
      'puppet-lint-hiera',
      'puppet-lint-i18n',
      'puppet-lint-last_comment_line-check',
      'puppet-lint-leading_zero-check',
      'puppet-lint-lookup_in_parameter-check',
      'puppet-lint-manifest_whitespace-check',
      'puppet-lint-module_reference-check',
      'puppet-lint-nine-check',
      'puppet-lint-optional_default-check',
      'puppet-lint-package_ensure-check',
      'puppet-lint-param-docs',
      'puppet-lint-param-types',
      'puppet-lint-param_comment-check',
      'puppet-lint-params_empty_string-check',
      'puppet-lint-racism_terminology-check',
      'puppet-lint-resource_reference_syntax',
      'puppet-lint-spaceship_operator_without_tag-check',
      'puppet-lint-strict_indent-check',
      'puppet-lint-summary_comment-check',
      'puppet-lint-topscope-variable-check',
      'puppet-lint-trailing_comma-check',
      'puppet-lint-unquoted_string-check',
      'puppet-lint-variable_contains_upcase',
      'puppet-lint-version_comparison-check',
    ]
  }
}

def add_additional_gems gems
  gems.each do |gem|
    sh %(bundle add #{gem} --skip-install)
  end
end

def create_bin_stub gem, **config
  binary = File.join('/usr/local/bin', gem) 
  stub   = <<~STUB
    #!/usr/bin/env bash
    export GEM_HOME="#{config[:bundle_dir]}"
    export BUNDLE_GEMFILE="#{config[:gemfile]}"
    export BUNDLE_BIN=#{config[:bin_dir]}
    export BUNDLE_PATH="#{config[:vendor_dir]}"
    export BUNDLE_APP_CONFIG="#{config[:bundle_dir]}"
    cd #{config[:bundle_dir]} && bundle exec #{gem} "${@}"
    STUB
  File.write(binary, stub)
  chmod 755, binary
end

def bundle_config gem
  bundle_dir = File.join BUNDLE_BASE_DIR, gem
  bin_dir    = File.join bundle_dir, 'bin'
  vendor_dir = File.join bundle_dir, BUNDLE_VENDOR_DIR
  gemfile    = File.join bundle_dir, 'Gemfile'

  # Under docker and root we need to override the defaults
  # for each gem!
  ENV['GEM_HOME']       = bundle_dir
  ENV['BUNDLE_APP_DIR'] = bundle_dir

  { 
    bundle_dir: bundle_dir, 
    bin_dir: bin_dir,
    vendor_dir: vendor_dir,
    gemfile: gemfile
  }
end

def bundle_gem gem, meta
  gems       = meta.fetch :gems, []
  version    = meta.fetch :version, '0'

  config = bundle_config gem

  mkdir_p config[:bundle_dir]
  cd config[:bundle_dir] do
    sh %(bundle init)
    sh %(bundle config set --local path "#{config[:vendor_dir]}")
    sh %(bundle config set --local gemfile "#{config[:gemfile]}")
    sh %(bundle config set --local bin "#{config[:bin_dir]}")
    sh %(bundle config list) 
    add_additional_gems gems
    sh %(bundle add #{gem} --version "~> #{version}" --skip-install)
    sh %(bundle install)
    sh %(bundle binstubs --force "#{gem}") 
    create_bin_stub gem, config 
  end
end 

task :default => :install

desc 'Install all gems via bundler'
task :install do 
  GEMS.each do |gem, version|
    Rake::Task["bundle:#{gem}"].invoke
  end
end 

namespace :clean do
  desc 'Clean up everything'
  task :all do
    rm_rf BUNDLE_BASE_DIR
  end
end

namespace :bundle do
  GEMS.each do |gem, meta|
    Rake::Task.define_task gem do |task|
      task.add_description("Install bundled gem '#{gem}'")
      bundle_gem gem, meta
    end
  end
end
