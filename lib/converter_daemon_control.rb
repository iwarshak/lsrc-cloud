#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
daemon = File.join(File.dirname(File.expand_path(__FILE__)), "converter_daemon.rb")
Daemons.run(daemon)