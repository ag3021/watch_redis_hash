require 'json'

# persists any object with redis hash command

class WatchRedisHash
  def initialize(client, key, subkey)
    @client = client
    @key = key
    @subkey = subkey
    @obj = WatchHash.new.setbind(true) do |same_obj|
      @client.hset(@key, @subkey, same_obj.to_json)
    end
  end

  def []=(key, val)
    @obj[key] = val
  end

  def load
    @client.hget(@key, @subkey) do |res|
      @obj.merge!(JSON.parse(res))
    end
  end
end

require 'watch_redis_hash/watch_hash'
