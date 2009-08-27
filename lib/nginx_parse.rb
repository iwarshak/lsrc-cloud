#!/usr/bin/env ruby
#
# (c)2009 Ian Warshak <iwarshak@stripey.net>
#
#
# A simple tool to be run on a nginx based load balancer
# Adds and removes backend webservers from the config file
# and sends an HUP signal to the master process which gracefully
# restarts nginx
#
# The idea is that part of the startup process for a new backend server
# is to do something like this to add a new backend
# 
# ssh -c root@$LOAD_BALANCER 'nginx_parse.rb add 1.2.3.4:80 mongrels restart'
#
# and when the server is being shutdown, it runs 
# 
# ssh -c root@$LOAD_BALANCER 'nginx_parse.rb remove 1.2.3.4:80 mongrels restart'
#
#
# This script assumes your nginx config has a config section named
# something like
#
# upstream <upstream name> {
# 1.2.3.4:8080;
# 1.2.3.5:8080;
# }
#
# where <upstream name> is passed in as a command line argument
#
#
# WARNING: THERE IS LITTLE TO NO ERROR CHECKING. IF YOUR UPSTREAM NAME IS WRONG
# THIS COULD BLOW UP YOUR WHOLE CONFIG.


require 'strscan'
class NginxParse
  attr_accessor :file, :before, :rest, :backends
  
  def parse(path_to_file, upstream_name = "backend")
    @file = path_to_file
    str = File.open(path_to_file).read
    scanner = StringScanner.new(str)
    @before = scanner.scan_until /upstream #{upstream_name} \{/
    servers = scanner.scan_until /\}/
    @rest = "}" + scanner.rest
    @backends = servers.gsub(/server/,'').gsub(/\s+/, '').gsub(/\}/, '').split(';')
  end
  
  def write_out
    #raise unless @file && @before && @rest && @backends
    File.open(@file, "w") do |f|
      f.write(@before)
      f.write("\n")
      @backends.each do |s|
        f.write("server #{s};\n")
      end
      f.write(@rest)
    end
  end
end

conf_file = ARGV[0]
command = ARGV[1]
backend_name = ARGV[2]
server = ARGV[3]
restart = ARGV[4]

if command == "add"
  parser = NginxParse.new
  parser.parse(conf_file, backend_name)
  parser.backends << server unless parser.backends.any?{|c| c == server }
  parser.write_out
elsif command == "remove"
  parser = NginxParse.new
  parser.parse(conf_file, backend_name)
  parser.backends.reject! {|c| c == server}
  parser.write_out
else
  puts "USAGE:\nnginx_parse.rb <path to nginx conf> add|remove <backend name> 1.2.3.4:5000 restart(optional)"
end

if restart == "restart"
  #pid_file = File.expand_path(File.join(File.dirname(conf_file), "..", "logs", "nginx.pid"))
  pid_file = "/var/run/nginx.pid"
  if File.exist?(pid_file)
    pid = File.open(pid_file).read
    system("kill -HUP #{pid}")
  else
    system("/etc/init.d/nginx restart")
  end
end