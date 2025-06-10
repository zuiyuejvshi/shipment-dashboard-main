require 'sinatra'
require 'mysql2'
require 'json'

# 数据库配置
DB_CONFIG = {
  host: 'gateway01.ap-southeast-1.prod.aws.tidbcloud.com',
  port: 4000,
  username: '3uRMqrpVw7VeBqR.root',
  password: 'r76xy1HDH6bGg85x',
  database: 'test',
  ssl_mode: :verify_identity
}

# 创建数据库连接
def get_db_connection
  Mysql2::Client.new(DB_CONFIG)
rescue Mysql2::Error => e
  puts "数据库连接错误: #{e.message}"
  nil
end

# 创建表（如果不存在）
def create_table_if_not_exists
  client = get_db_connection
  return unless client

  client.query(<<-SQL)
    CREATE TABLE IF NOT EXISTS shipments (
      tracking_number VARCHAR(100) PRIMARY KEY,
      client_code VARCHAR(50),
      transport_mode VARCHAR(20),
      status VARCHAR(20),
      goods_description TEXT,
      package_count INT,
      estimated_days INT,
      created_at DATETIME,
      shipped_date DATE,
      estimated_arrival DATE,
      arrival_date DATE,
      pickup_date DATE
    )
  SQL
  client.close
end

# 初始化表
create_table_if_not_exists

# 添加新运单
post '/api/shipments' do
  content_type :json
  
  begin
    data = JSON.parse(request.body.read)
    client = get_db_connection
    
    # 计算预计到达日期
    created_at = Time.parse(data['created_at'])
    estimated_arrival = created_at + (data['estimated_days'].to_i * 24 * 60 * 60)
    
    # 插入数据
    client.query(<<-SQL)
      INSERT INTO shipments (
        tracking_number, client_code, transport_mode, status,
        goods_description, package_count, estimated_days,
        created_at, estimated_arrival
      ) VALUES (
        '#{data['tracking_number']}',
        '#{data['client_code']}',
        '#{data['transport_mode']}',
        '未发货',
        '#{client.escape(data['goods_description'])}',
        #{data['package_count']},
        #{data['estimated_days']},
        '#{data['created_at']}',
        '#{estimated_arrival.strftime('%Y-%m-%d')}'
      )
    SQL
    
    { success: true, message: '运单创建成功' }.to_json
  rescue => e
    status 500
    { success: false, message: e.message }.to_json
  ensure
    client&.close
  end
end

# 获取所有运单
get '/api/shipments' do
  content_type :json
  
  begin
    client = get_db_connection
    result = client.query('SELECT * FROM shipments ORDER BY created_at DESC')
    
    shipments = result.map do |row|
      row.each_with_object({}) do |(key, value), hash|
        hash[key] = value
      end
    end
    
    { success: true, data: shipments }.to_json
  rescue => e
    status 500
    { success: false, message: e.message }.to_json
  ensure
    client&.close
  end
end

# 获取单个运单
get '/api/shipments/:tracking_number' do
  content_type :json
  
  begin
    client = get_db_connection
    result = client.query("SELECT * FROM shipments WHERE tracking_number = '#{params[:tracking_number]}'")
    
    if result.count > 0
      shipment = result.first
      { success: true, data: shipment }.to_json
    else
      status 404
      { success: false, message: '运单不存在' }.to_json
    end
  rescue => e
    status 500
    { success: false, message: e.message }.to_json
  ensure
    client&.close
  end
end 