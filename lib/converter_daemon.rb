#!/usr/bin/env ruby

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "../"))
$:.unshift(File.join(RAILS_ROOT, "app", "models"))
ENV["AWS_ACCESS_KEY_ID"] ||= File.open("#{RAILS_ROOT}/files/access.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/access.txt")
ENV["AWS_SECRET_ACCESS_KEY"] ||= File.open("#{RAILS_ROOT}/files/secret.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/secret.txt")

require 'rubygems'
require 'right_aws'
require 'sdb/active_sdb'
require 'json'
require 'convert_job'
require 'active_support'


RightAws::ActiveSdb.establish_connection

loop do
  sqs = RightAws::SqsGen2.new
  convert_queue = sqs.queue("convert")

  message = convert_queue.pop
  if message
    job = JSON.parse message.to_s
    puts "Found a new message #{job.key}"
    job.run!
  end
  sleep(5)
end