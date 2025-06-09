require 'jekyll'
require_relative '_includes/db_connection'

# 加载 Jekyll 配置
config = Jekyll.configuration({
  'source' => '.',
  'destination' => '_site'
})

# 测试数据库连接
client = DatabaseConnection.connect

if client
  puts "数据库连接成功！"
  
  # 测试查询
  begin
    result = client.query("SELECT VERSION()")
    puts "数据库版本: #{result.first['VERSION()']}"
  rescue Mysql2::Error => e
    puts "查询错误: #{e.message}"
  ensure
    client.close
  end
else
  puts "数据库连接失败！"
end 