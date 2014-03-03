#require "nest"
require 'redic'
require 'nido'

module Ost
  TIMEOUT = ENV["OST_TIMEOUT"] || 2

  class Queue
    attr :key
    attr :backup
    attr :redis

    def initialize(name)
      # @key = Nest.new(:ost, redis)[name]
      @key = Nido.new(:ost)[name]
      @backup = @key[Socket.gethostname][Process.pid]
      @redis = Redic.new(Ost.options)
    end

    def push(value)
      # key.lpush(value)
      @redis.call("LPUSH", @key, value)
    end

    def each(&block)
      @stopping = false

      loop do
        break if @stopping

        # item = @key.brpoplpush(@backup, TIMEOUT)
        item = @redis.call("BRPOPLPUSH", @key, @backup, TIMEOUT)

        next unless item

        block.call(item)

        # @backup.lpop
        @redis.call("LPOP", @backup)
      end
    end

    def stop
      @stopping = true
    end

    def items
      # key.lrange(0, -1)
      @redis.call("LRANGE", key, 0, -1)
    end

    alias << push
    alias pop each

    def size
      # key.llen
      @redis.call("LLEN", key)
    end

    # def redis
    #   # @redis ||= Redis.connect(Ost.options)
    #   @redis ||= Redic.new(Ost.options)
    # end
  end

  @queues = Hash.new do |hash, key|
    hash[key] = Queue.new(key)
  end

  def self.[](queue)
    @queues[queue]
  end

  def self.stop
    @queues.each { |_, queue| queue.stop }
  end

  @options = nil

  def self.connect(options = nil)
    @options = options
  end

  def self.options
    @options || "redis://127.0.0.1:6379"
  end
end
