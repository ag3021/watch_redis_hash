# persists any object with redis hash command
require 'bigdecimal'
require 'yajl/json_gem'

class WatchRedisHash
  NUM_REG = /^[-+]?([0-9]+\.[0-9]+|[0-9]+)$/

  def initialize(client: nil, key: nil, subkey: nil, each: nil, publish: nil, tag: nil, symbolize: true, default: nil)
    fail 'No Client provided to WatchRedisHash' unless client
    @client = client
    @key = key
    @default = default
    @subkey = subkey
    @symbolize = !!symbolize
    @publish = !!publish
    @tag = tag
    _bind_each if each
    _bind unless each
  end

  def []=(key, val)
    @obj[_coerce_format(key)] = val
  end

  def [](key)
    @obj[_coerce_format(key)]
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

  def _coerce_format(key)
    return key.map { |k| k.is_a?(Symbol) ? k.to_s : k } if key.is_a?(Array)
    key
  end

  def _bind_each
    @each = true
    (@obj = WatchHash.new(@default)).setbind do |(subkey, val)|
      @client.hset(@key, subkey, jval = val.to_json) do |ok|
        if ok && @publish
          key = "#{@key}:#{val[@tag]}:#{subkey}" if @tag && val[@tag]
          key = "#{@key}:#{subkey}" unless key
          @client.publish(key, jval)
        end
      end
    end
  end

  def _bind
    if @tag
      @channel = "#{@key}:#{@tag}:#{@subkey}"
    else
      @channel = "#{@key}:#{@subkey}"
    end
    (@obj = WatchHash.new(@default)).setbind(true) do |same_obj|
      @client.hset(@key, @subkey, same_obj = same_obj.to_json) do |ok|
        @client.publish("#{@key}:#{@subkey}", same_obj) if ok && @publish
      end
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
