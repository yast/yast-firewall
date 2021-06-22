# Copyright (c) [2017-2021] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

# Set the paths
srcdir = File.expand_path("../src", __dir__)
y2dirs = ENV.fetch("Y2DIR", "").split(":")
ENV["Y2DIR"] = y2dirs.unshift(srcdir).join(":")

require "yast"
require "yast/rspec"

LIBS_TO_SKIP = ["installation/security_settings"].freeze

# Hack to avoid to require some files
#
# This is here to avoid a cyclic dependency with yast-installation at build time.
# The package yast-firewall does not include a BuildRequires for yast-installation, so the require
# for files defined by that package must be avoided.
module Kernel
  alias_method :old_require, :require

  def require(path)
    old_require(path) unless LIBS_TO_SKIP.include?(path)
  end
end

# stub module to prevent its Import
# Useful for modules from different yast packages, to avoid build dependencies
def stub_module(name, fake_class = nil)
  fake_class = Class.new { def self.fake_method; end } if fake_class.nil?
  Yast.const_set name.to_sym, fake_class
end

# stub classes from other modules to speed up a build
# rubocop:disable Style/SingleLineMethods
stub_module("AutoInstall", Class.new { def self.issues_list; []; end })
# rubocop:enable Style/SingleLineMethods

# some tests have translatable messages
ENV["LANG"] = "en_US.UTF-8"
ENV["LC_ALL"] = "en_US.UTF-8"

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    # make sure we mock only the existing methods
    # https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles/partial-doubles
    c.verify_partial_doubles = true
  end
end

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  # track all ruby files under src
  SimpleCov.track_files("#{srcdir}/**/*.rb")

  # additionally use the LCOV format for on-line code coverage reporting at CI
  if ENV["CI"] || ENV["COVERAGE_LCOV"]
    require "simplecov-lcov"

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      # this is the default Coveralls GitHub Action location
      # https://github.com/marketplace/actions/coveralls-github-action
      c.single_report_path = "coverage/lcov.info"
    end

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]
  end
end
