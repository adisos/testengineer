require "testengineer/version"
require 'timeout'
require 'foreman/engine/cli'

module TestEngineer
  class << self
    attr_accessor :procfile
  end

  self.procfile = 'Procfile'

  def self.foreman
    $foreman
  end

  def self.wait_for_socket(host='localhost', port=nil)
    return if port.nil?

    puts "Waiting for server at #{host}:#{port} to come online.."
    running = false
    while !running do
      sleep 0.2
      begin
        TCPSocket.new(host, port)
      rescue Errno::ECONNREFUSED => e
        next
      end
      running = true
    end
  end

  def self.stop_process(name)
    if foreman.nil?
      puts "Foreman hasn't been started, whoops"
      return
    end

    if name.nil?
      raise ArgumentError, "TestEngineer#stop_process cannot handle a nil process name"
    end
    procs = foreman.send(:running_processes)
    procs.each do |pid, p|
      parts = p.name.split('.')
      unless parts.first.start_with? name
        next
      end
      p.kill 'SIGTERM'
      ::Timeout.timeout(5) do
        begin
          Process.waitpid(pid)
        rescue Errno::ECHILD
        end
      end
    end
    # If we don't set @terminating to false, then the eventual invocation of
    # #terminate_gracefully will return immediately
    foreman.instance_variable_set(:@terminating, false)
  end

  def self.start_stack
    procfile = File.expand_path(self.procfile, Dir.pwd)
    unless File.exists? procfile
      raise StandardError, 'Procfile does not exist!'
    end
    $foreman = ::Foreman::Engine::CLI.new
    foreman.load_procfile(procfile)

    Thread.new do
      foreman.start
    end
  end

  def self.stop_stack
    begin
      foreman.send(:terminate_gracefully) unless foreman.nil?
    rescue Errno::ECHILD => e
      # Children terminated before we could kill them, no big deal
    end
    foreman = nil
  end
end
