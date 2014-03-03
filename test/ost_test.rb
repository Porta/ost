ENV["OST_TIMEOUT"] = "1"

require File.expand_path("test_helper", File.dirname(__FILE__))

scope do

  def ost(&job)
    thread = Thread.new do
      Ost[:events].each do |item|
        begin
          yield(item)
        ensure
          thread.kill
        end
      end
    end

    thread.join
  end

  def enqueue(id)
    Ost[:events].push(id)
  end

  prepare do
    #Redis.current.flushall
    redis = Redic.new
    redis.call("FLUSHALL")
  end

  setup do
    #Ost[:events].redis.quit
    #Redis.new
    Redic.new
  end

  test "allows access to the queued items" do
    enqueue(1)

    assert_equal ["1"], Ost[:events].items
  end

  test "allows access to the underlying key" do |redis|
    # assert_equal 0, Ost[:events].key.llen
    assert_equal 0, redis.call("LLEN", Ost[:events].key)
  end

  test "process items from the queue" do |redis|
    enqueue(1)

    results = []

    ost do |item|
      results << item
    end

    assert_equal [], Ost[:events].items
    assert_equal ["1"], results
  end

  test "doesn't yield the block on timeout" do |redis|
    results = []

    Thread.new do
      sleep 2

      #redis.lpush(Ost[:events].key, 1)
      redis.call("LPUSH", Ost[:events].key, 1)
    end

    ost do |item|
      results << item
    end

    assert_equal [], Ost[:events].items
    assert_equal ["1"], results
  end

  test "halt processing a queue" do
    Thread.new do
      sleep 0.5
      Ost[:always_empty].stop
    end

    Ost[:always_empty].each { }

    assert true
  end

  test "halt processing all queues" do
    Thread.new do
      sleep 0.5
      Ost.stop
    end

    t1 = Thread.new { Ost[:always_empty].each { } }
    t2 = Thread.new { Ost[:always_empty_too].each { } }

    t1.join
    t2.join

    assert true
  end

  test "maintains a backup queue for when worker dies" do |redis|
    enqueue(1)

    # assert_equal 0, Ost[:events].backup.llen
    assert_equal 0, redis.call("LLEN", Ost[:events].backup)

    begin
      Ost[:events].each do |item|
        item.some_error
      end
    rescue
    end

    # assert_equal ["1"], Ost[:events].backup.lrange(0, -1)
    assert_equal ["1"], redis.call("LRANGE", Ost[:events].backup, 0, -1)
  end

  test "cleans up the backup queue on success" do |redis|
    enqueue(1)

    done = false

    Thread.new do
      Ost[:events].each do |item|
        # assert_equal ["1"], Ost[:events].backup.lrange(0, -1)
        assert_equal ["1"], redis.call("LRANGE", Ost[:events].backup, 0, -1)
        done = true
      end
    end

    until done; end

    Ost[:events].stop

    # assert_equal 0, Ost[:events].backup.llen
    assert_equal 0, redis.call("LLEN", Ost[:events].backup)

#README: I'm not sure how to replace this test
    # assert_equal false, Ost[:events].backup.exists

  end

#README: Should this test be deprecated?
  # test "uses same redis instance" do
  #   queue = Ost['foo']

  #   assert_equal queue.key.redis, queue.redis
  # end

  test "report the queue size" do
    queue = Ost[:size]

    assert_equal 0, queue.size

    queue << 1

    assert_equal 1, queue.size

    done = false

    Thread.new do
      Ost[:size].each do |item|
        done = true
      end
    end

    until done; end

    assert_equal 0, queue.size
  end

  test "passing url to connect" do
    assert_equal "redis://127.0.0.1:6379", Ost.options

    Ost.connect("redis://127.0.0.1:6379/11")

    assert_equal "redis://127.0.0.1:6379/11", Ost.options
  end

end
