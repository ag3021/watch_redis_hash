class WatchRedisHash
  class WatchHash < Hash
    def setbind(all = nil, &blk)
      @whr_all = all
      @whr_cb = ->(){}
      @whr_cb = blk if blk
    end

    def []=(key, val)
      super
      @whr_cb.call(@whr_all ? self : [key, val])
    end
  end
end
