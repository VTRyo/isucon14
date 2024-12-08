# Puma.rb 設定ファイル

# バインド設定
bind "tcp://0.0.0.0:8080"

# ワーカー数 (プロセス数)
workers ENV.fetch("PUMA_WORKERS") { 8 } # 初期は8

# スレッド数 (最小: 0, 最大: 2)
threads_min = ENV.fetch("PUMA_MIN_THREADS") { 0 }
threads_max = ENV.fetch("PUMA_MAX_THREADS") { 16 } # 初期は8
threads threads_min, threads_max

# 環境設定
environment ENV.fetch("RAILS_ENV") { "production" }

# アプリケーションのルートディレクトリ
directory "/home/isucon/webapp/ruby"

# プリロード設定 (ワーカーごとに個別にメモリを使用しないための最適化)
preload_app!

# フック設定: ワーカーの起動時に必要な初期化処理
on_worker_boot do
  require "active_record" if defined?(ActiveRecord)
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# サーバー再起動時に必要な設定 (オプション)
plugin :tmp_restart
