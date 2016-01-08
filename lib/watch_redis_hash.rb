# persists any object with redis hash command
require 'bigdecimal'
require 'yajl/json_gem'

class WatchRedisHash
  NUM_REG = /^[-+]?([0-9]+\.[0-9]+|[0-9]+)$/

  def initialize(client: nil, key: nil, subkey: nil, each: nil, symbolize: true)
    fail 'No Client provided to WatchRedisHash' unless client
    @client = client
    @key = key
    @subkey = subkey
    @symbolize = !!symbolize
    _bind_each if each
    _bind unless each
  end

  def []=(key, val)
    @obj[key] = val
  end

  def [](key)
    @obj[key]
  end

  def load(&blk)
    if @each
      @client.hgetall(@key) do |res|
        @obj.merge!(_parse_map_zip(res))
        blk.call if blk
      end
    else
      @client.hget(@key, @subkey) do |res|
        @obj.merge!(_parse(res))
        blk.call if blk
      end
    end
  end

  private

  def _bind_each
    @each = true
    (@obj = WatchHash.new).setbind do |(subkey, val)|
      @client.hset(@key, subkey, val.to_json)
    end
  end

  def _bind
    (@obj = WatchHash.new).setbind(true) do |same_obj|
      @client.hset(@key, @subkey, same_obj.to_json)
    end
  end

  def _parse_map_zip(res)
    Hash[*res.map(&method(:_parse))]
  end

  def _parse(val)
    JSON.parse(val, symbolize_keys: @symbolize)
  rescue
    if val =~ NUM_REG
      val = BigDecimal.new(val)
      val.frac == 0 ? val.to_i : val.to_f
    else
      @symbolize ? val.to_sym : val
    end
  end
end

require 'watch_redis_hash/watch_hash'

=begin
require 'em-hiredis'

EM.run do
  client = EM::Hiredis.connect('redis://localhost:6379')
  client.callback do |*|
    whr = WatchRedisHash.new(client: client, key: 'andy', each: true)
    whr[5] = {foobar: 'hey'}
    p whr
  end
end
=end
