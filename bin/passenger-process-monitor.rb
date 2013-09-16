#!/usr/bin/env ruby

# $Id: passenger-process-monitor.rb 4924 2011-05-12 08:14:11Z do2 $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-scripts/trunk/bin/passenger-process-monitor.rb $
# $LastChangedRevision: 4924 $
# $LastChangedDate: 2011-05-12 09:14:11 +0100 (Thu, 12 May 2011) $
# $LastChangedBy: do2 $

#
# Passenger Process Monitor
# 
# By Darren Oakley
# Based heavily on a script by James Smith (https://gist.github.com/851520)
# That in turn was based on a similar script by Jon Bettcher
#
# - Check memory usage of all paseenger child process and kill if grows too large.
# - Also kill off long running passengers to prevent memory leak issues and stray processes.
#

# Path to the PID file for the passenger/apache instance - protects against multiple
# passenger instances on the same machine screwing this up...
PASSENGER_PID_FILE     = "/var/run/team87/apache2-ruby19.pid"
PASSENGER_PID          = File.open(PASSENGER_PID_FILE,"r").read().chomp()

# Path to the passenger-status and passenger-memory-status binaries
PASSENGER_BIN          = "/software/team87/brave_new_world/app/ruby-1.9.2-p0/lib/ruby/gems/1.9/bin"
PASSENGER_STATUS       = "#{PASSENGER_BIN}/passenger-status #{PASSENGER_PID} 2>/dev/null"
PASSENGER_MEMORY_STATS = "#{PASSENGER_BIN}/passenger-memory-stats #{PASSENGER_PID} 2>/dev/null"

# Passenger limits
MAX_REQUEST_COUNT      = 100
MAX_UPTIME             = 3660 # seconds - 1 hour 1 min
MAX_MEMORY             = 500  # mb

class PassengerStatsCollection < Hash
  def over_max_uptime
    self.map { |k,v| v[:uptime] && v[:uptime] >= MAX_UPTIME ? k : nil }.compact
  end
  
  def over_max_requests
    self.map { |k,v| v[:processed] && v[:processed] >= MAX_REQUEST_COUNT ? k : nil }.compact
  end
  
  def over_max_memory
    self.map { |k,v| v[:resident] && v[:resident] >= MAX_MEMORY ? k : nil }.compact
  end
  
  def bad
    (over_max_uptime + over_max_requests + over_max_memory).uniq
  end
  
  def any_over_max_uptime?
    !over_max_uptime.empty?
  end
  
  def any_over_max_requests?
    !over_max_requests.empty?
  end
  
  def any_over_max_memory?
    !over_max_memory.empty?
  end
  
  def any_bad?
    any_over_max_memory? || any_over_max_requests? || any_over_max_uptime?
  end
end

# Turns these into seconds:
# 0h 5m
# 3d 5h 3m
# 3m 5s
def parse_uptime(time)
  sec = 0
  time.strip.split(/ +/).each do |part|
    unit = part[0..-2].to_i
    case part[-1..-1]
    when 'm' then unit *= 60
    when 'h' then unit *= 3600
    when 'd' then unit *= (24*3600)
    end
    sec += unit
  end
  sec
end

def get_status
  pids = PassengerStatsCollection.new
  
  `#{PASSENGER_STATUS}`.each_line do |line|
    if line =~ /^[ \*]*PID/ then
      parts = line.strip.split(/ +/)
      pids[parts[2].to_i] = {
        :sessions => parts[4],
        :processed => parts[6].to_i,
        :uptime => parse_uptime(line.match(/Uptime:.*$/).to_s[8..-1])
      }
    end
  end
  
  `#{PASSENGER_MEMORY_STATS}`.each_line do |line|
    if line =~ /\d+ .*Rails/ then
      parts = line.strip.split(/ +/)
      pid = parts[0].to_i
      pids[pid] = {} if pids[pid].nil?
      pids[pid].merge!({
        :virtual => parts[1].to_f,
        :resident => parts[3].to_f
      })
    end
  end
  
  pids
end

def main
  puts "Passenger Status:"
  status = get_status
  status.each do |k, v|
    puts "#{k}: #{v.inspect}"
  end
  
  # Nothing to do
  unless status.any_bad?
    puts "All passenger processes running within operating parameters"
    return
  end
  
  # Tell all over_max_memory and over_max_uptime instances to abort
  over_max_memory_uptime = ( status.over_max_memory + status.over_max_uptime )
  over_max_memory_uptime.each do |pid|
    begin
      puts "sending -ABRT to #{pid}"
      Process.kill(:ABRT, pid)
    rescue Errno::ESRCH => error
    end
  end
  
  # Tell all over_max_requests instances to shut down gracefully
  over_max_requests = status.over_max_requests
  (over_max_requests - over_max_memory_uptime).each do |pid|
    begin
      puts "sending -USR1 to #{pid}"
      Process.kill(:USR1, pid)
    rescue Errno::ESRCH => error
    end
  end
  
  # Give them a chance to die gracefully
  sleep 30
  
  # Find and kill any pids which are still bad
  (status.bad & get_status.bad).each do |pid|
    begin
      Process.kill(:KILL, pid)
      puts "had to kill -9 #{pid}"
    rescue Errno::ESRCH => error
      # No problem - the process has been killed :)
    end
  end
end

main