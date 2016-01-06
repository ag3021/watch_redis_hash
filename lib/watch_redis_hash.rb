require 'json'

# persists any object with redis hash command

class WatchRedisHash
  def initialize(client: nil, key: nil, subkey: nil, each: nil)
    fail 'No Client provided to WatchRedisHash' unless @client
    @client = client
    @key = key
    @subkey = subkey
    _bind_each if each
    _bind unless each
  end

  def []=(key, val)
    @obj[key] = val
  end

  def load
    if @each
      @client.hgetall(@key) do |res|
        @obj.merge!(Hash[_parse_map_zip(res.keys, res.values)])
      end
    else
      @client.hget(@key, @subkey) do |res|
        @obj.merge!(JSON.parse(res))
      end
    end
  end

  private

  def _bind_each
    @each = true
    @obj = WatchHash.new.setbind do |(subkey, val)|
      @client.hset(@key, subkey, val.to_json)
    end
  end

  def _bind
    @obj = WatchHash.new.setbind(true) do |same_obj|
      @client.hset(@key, @subkey, same_obj.to_json)
    end
  end

  def _parse_map_zip(keys, vals)
    keys.map(&JSON.method(:parse))
    .zip(
      vals.map(&JSON.method(:parse))
    )
  end
end

require 'watch_redis_hash/watch_hash'
