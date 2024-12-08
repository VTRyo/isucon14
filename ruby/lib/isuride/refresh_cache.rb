require 'redis'

Redis.current = Redis.new(host: '54.199.56.249', port: 6379) # 2号機

def refresh_redis_cache
  # Redis セットをクリア
  Redis.current.del("available_chairs")

  # データベースから空いている椅子を再取得してキャッシュ
  available_chairs = db.query('SELECT id FROM chairs WHERE is_active = TRUE').to_a
  available_chairs.each do |chair|
    Redis.current.sadd("available_chairs", chair.fetch(:id))
  end
end
