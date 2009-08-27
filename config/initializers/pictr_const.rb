class PictrConst
  if Rails.env == "production"
    PUBLIC_HOSTNAME = File.open("#{RAILS_ROOT}/files/public_hostname.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/public_hostname.txt")
    #REDIRECT_URL="http://#{PUBLIC_HOSTNAME}/pictures/callback"
    REDIRECT_URL="http://pictr.YOURDOMAIN.com/pictures/callback"
    SERVER_NAME= File.open("#{RAILS_ROOT}/files/server.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/server.txt")
    
    
  elsif Rails.env == "development"
    PUBLIC_HOSTNAME = File.open("#{RAILS_ROOT}/files/public_hostname.txt").read.chomp if File.exist?("#{RAILS_ROOT}/files/public_hostname.txt")
    REDIRECT_URL="http://localhost:3000/pictures/callback"
    SERVER_NAME="localhost"
  end
end