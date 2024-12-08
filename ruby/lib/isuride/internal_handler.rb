# frozen_string_literal: true

require 'isuride/base_handler'
require 'redis'

# Redis 接続のセットアップ
Redis.current = Redis.new(host: '54.199.56.249', port: 6379)

module Isuride
  class InternalHandler < BaseHandler
    # このAPIをインスタンス内から一定間隔で叩かせることで、椅子とライドをマッチングさせる
    # GET /api/internal/matching
    get '/matching' do
      # MEMO: 一旦最も待たせているリクエストに適当な空いている椅子マッチさせる実装とする。おそらくもっといい方法があるはず…
      ride = db.query('SELECT * FROM rides WHERE chair_id IS NULL ORDER BY created_at LIMIT 1').first
      unless ride
        halt 204
      end

      10.times do
        chair_id = Redis.current.srandmember("available_chairs")
        matched = db.query('SELECT * FROM chairs where id = ? LIMIT 1', chair_id).first
        unless matched
          halt 204
        end

        empty = db.xquery('SELECT COUNT(*) = 0 FROM (SELECT COUNT(chair_sent_at) = 6 AS completed FROM ride_statuses WHERE ride_id IN (SELECT id FROM rides WHERE chair_id = ?) GROUP BY ride_id) is_completed WHERE completed = FALSE', matched.fetch(:id), as: :array).first[0]
        if empty > 0
          # db.xquery('UPDATE rides SET chair_id = ? WHERE id = ?', matched.fetch(:id), ride.fetch(:id))
          db.xquery('UPDATE rides SET chair_id = ? WHERE id = ?', chair_id, ride.fetch(:id))
          break
        end
      end

      204
    end
  end

  def toggle_chair_active_status(db, chair_id, is_active)
    # `is_active` を更新
    db.xquery('UPDATE chairs SET is_active = ? WHERE id = ?', is_active, chair_id)
  
    if is_active
      # 椅子がアクティブになる場合、Redis キャッシュに追加
      Redis.current.sadd("available_chairs", chair_id)
      puts "Chair #{chair_id} has been activated and added to Redis cache."
    else
      # 椅子が非アクティブになる場合、Redis キャッシュから削除
      Redis.current.srem("available_chairs", chair_id)
      puts "Chair #{chair_id} has been deactivated and removed from Redis cache."
    end
  end


  def find_random_available_chair
    chair_id = Redis.current.srandmember("available_chairs")
    return nil unless chair_id
 
    # 必要に応じてデータベースから詳細情報を取得
    db.xquery('SELECT * FROM chairs WHERE id = ?', chair_id).first
  end
end
