require 'em-hiredis'
require 'watch_redis_hash'

EM.run do
  client = EM::Hiredis.connect
  client.callback do |*|
    whr = WatchRedisHash.new(client: client, key: 'andy', each: true)
    whr.load
    whr[6] = {hey: 765}
    EM.add_timer(5) { p whr }
  end
end
