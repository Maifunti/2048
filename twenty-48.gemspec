# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'twenty_48/version'

Gem::Specification.new do |spec|
  spec.name = "twenty_48"
  spec.date = '2025-10-06'
  spec.version = Twenty48::VERSION
  spec.authors = ["Yakubu Lamay"]
  spec.email = ["yakubu.lamay@gmail.com"]
  spec.homepage = 'https:/www.yakubulamay.com'

  spec.summary = '2048'
  spec.description = 'Simple game of 2048 playable from terminal'
  spec.license = "MIT"

  spec.files += Dir.glob("lib/**/*")
  spec.executables = ['twenty_48']
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 3.1'

  # this dependency is optional
  spec.add_dependency('tty-cursor', '~> 0.7')
  spec.add_dependency('tty-reader', '~> 0.9')
  spec.add_dependency('tty-screen', '~> 0.8')
  spec.add_dependency('httparty', '~> 0.23')
  spec.add_dependency('curses')
  spec.add_dependency('mutex_m')
  spec.add_dependency('ostruct')
  spec.add_dependency('readline')
  spec.add_dependency('zeitwerk')
  spec.add_dependency('concurrent-ruby')
  spec.add_dependency('ld-eventsource')
  spec.add_dependency('justify')
end
