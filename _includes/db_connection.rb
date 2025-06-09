require 'mysql2'

module DatabaseConnection
  def self.connect
    config = Jekyll.configuration['db']
    
    client = Mysql2::Client.new(
      host: config['host'],
      username: config['user'],
      password: config['password'],
      database: config['database'],
      port: config['port'],
      ssl_mode: config['ssl_mode']
    )
    
    return client
  rescue Mysql2::Error => e
    puts "数据库连接错误: #{e.message}"
    nil
  end
end 