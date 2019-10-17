require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'mysql2'
require 'pry'


client = Mysql2::Client.new(
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: '030115mami',
    database: 'sittchingdb',
    reconnect: true,
)

enable :sessions

# ======================

def is_login()
  if session[:user_id].nil?
    redirect '/login'
  end
end

# ======================

get '/' do
  @title = 'TOP'
  erb :top
end

# ======================

get '/login' do
  @title = 'ログイン'
  @page_info = session[:page_info]
  session[:page_info] = nil
  erb :login
end

# ======================

post '/login' do
  sql = "select id,parent_flg from users where mailaddress = '#{params[:mailaddress]}' and password = '#{params[:password]}';"
  client.query(sql)

  res = client.query(sql)
  res.each do |row|
    @user_id = row["id"]
    @parent_flg = row["parent_flg"]
  end

  if sql
    session[:user_id] = @user_id

    if @parent_flg === 1 then
      redirect '/parentpage'
    else
      redirect '/sitterpage'
    end

  else
    redirect '/login'
  end
end

# ======================

get '/signup_parent' do
  @title = '新規登録'
  erb :signup_parent
end

# ======================

post '/signup_parent' do

  sql = "INSERT INTO users (`id`, `last_name`, `first_name`,`password`,`mailaddress`,`sex`,`parent_flg`,`sitter_flg`) VALUES (NULL,'#{params[:last_name]}', '#{params[:first_name]}','#{params[:password]}','#{params[:mailaddress]}','#{params[:sex]}',1,0);"
  client.query(sql)

  sql2 = "select id from users where mailaddress = '#{params[:mailaddress]}'"
  client.query(sql2)
  res = client.query(sql2)
  res.each do |row|
    @user_id = row["id"]
  end

  sql3 = "insert into profile_sitter VALUES(NULL,'お住まいの地域','自己紹介',#{@user_id});"
  client.query(sql3)

  sql4 = "insert into profile_image values(null,'/prof_images/default.jpg',#{@user_id});"
  client.query(sql4)

  redirect '/parentpage'
end

# ======================

get '/parentpage' do
  @title = 'トップページ'
  is_login()
  sql = "select first_name,last_name from users where id = #{session[:user_id]};"
  client.query(sql)

  res = client.query(sql)
  res.each do |row|
    @first_name = row["first_name"]
    @last_name = row["last_name"]
  end

  sql1 = "select image_pass from profile_image where user_id = #{session[:user_id]};"
  res = client.query(sql1)
  res.each do |row|
    @profile_image = row["image_pass"]
  end

  erb :parentpage
end

# ======================

get '/signup_sitter' do
  @title = '新規登録'
  erb :signup_sitter
end

# ======================

post '/signup_sitter' do
  sql = "INSERT INTO users (`id`, `last_name`, `first_name`,`mailaddress`,`password`,`sex`,`parent_flg`,`sitter_flg`) VALUES (NULL,'#{params[:last_name]}', '#{params[:first_name]}','#{params[:mailaddress]}','#{params[:password]}','#{params[:sex]}',0,1);"
  client.query(sql)

  sql2 = "select id from users where mailaddress = '#{params[:mailaddress]}';"
  client.query(sql2)
  client.query(sql2).each do |row|
    @user_id = row["id"]
  end

  sql3 = "insert into profile_sitter VALUES(NULL,'お住まいの地域','自己紹介',#{@user_id});"
  client.query(sql3)

  sql4 = "insert into profile_image values(null,'/prof_images/default.jpg',#{@user_id});"
  client.query(sql4)

  redirect '/login'
end

# ======================

get '/sitterpage' do
  @title = 'シッターページ'
  is_login()

  sql = "select first_name,last_name from users where id = #{session[:user_id]};"
  res = client.query(sql)
  res.each do |row|
    @first_name = row["first_name"]
    @last_name = row["last_name"]
  end

  sql1 = "select image_pass from profile_image where user_id = #{session[:user_id]};"
  res = client.query(sql1)
  res.each do |row|
    @profile_image = row["image_pass"]
  end

  erb :sitterpage
end

# ======================

get '/reserve_list' do
  @title = '予約一覧'
  is_login()

  sql = "select id,date,start_time,end_time,reservation from reserve_date where user_id = #{session[:user_id]};"
  client.query(sql)

  @res = client.query(sql)
  @res.each do |row|
    row["id"]
    row["date"]
    row["start_time"]
    row["end_time"]
    row["reservation"]
  end

  erb :reserve_list
end

# ======================

get '/reserve_add' do
  is_login()
  erb :reserve_add
end

# ======================

post '/reserve_add' do
  sql = "insert into reserve_date(id,date,start_time,end_time,reservation,user_id) values(NULL, '#{params[:date]}', '#{params[:start_time]}', '#{params[:end_time]}', 0, #{session[:user_id]});"
  client.query(sql)

  redirect '/reserve_list'
end

# ======================

get '/reserve_edit/:reserve_id' do
  is_login()
  @reserve_id = params[:reserve_id]

  sql = "select date,start_time,end_time from reserve_date where id = #{@reserve_id};"
  res = client.query(sql)
  res.each do |row|
    @date = row["date"]
    @start_time = row["start_time"]
    @end_time = row["end_time"]
  end

  erb :reserve_edit
end

# ======================

post '/reserve_edit/:reserve_id' do
  @reserve_id = params[:reserve_id]

  sql = "update reserve_date set date = '#{params[:date]}', start_time = '#{params[:start_time]}', end_time = '#{params[:end_time]}' where id = #{@reserve_id} ;"
  client.query(sql)

  redirect '/reserve_list'
end

# ======================

get '/reserve_del/:reserve_id' do
  is_login()

  sql = "delete from reserve_date WHERE id = #{params[:reserve_id]}"
  res = client.query(sql)

  redirect '/reserve_list'
end

# ======================

get '/reserve_search' do
  erb :reserve_search
end

# ======================

post '/reserve_search' do
  session[:date] = params[:date]

  redirect '/search_list'
end

# ======================

get '/search_list' do
  sql = "select last_name,sex,image_pass,reserve_date.id,date,start_time,end_time from users inner join reserve_date on users.id = reserve_date.user_id inner join profile_image on users.id = profile_image.user_id where date = '#{session[:date]}' and reservation = 0;"

  @res = client.query(sql)
  @res.each do |row|
    row['last_name']
    row['sex']
    row['image_pass']
    row['id']
    row['date']
    row['start_time']
    row['end_time']
  end

  erb :search_list
end

# ======================

get '/reservation/:reserve_id' do
  @reserve_id = params[:reserve_id]

  sql1 = "select user_id,date,start_time,end_time from reserve_date where id = #{@reserve_id} ;"
  res = client.query(sql1)
  res.each do |row|
    @user_id = row['user_id']
    @date = row['date']
    @start_time = row['start_time']
    @end_time = row['end_time']
  end

  sql2 = "select last_name,first_name from users where id = #{@user_id};"
  res = client.query(sql2)
  res.each do |row|
    @last_name = row['last_name']
    @first_name = row['first_name']
  end

  sql3 = "select region,introduce from profile_sitter where user_id = #{@user_id};"
  res = client.query(sql3)
  res.each do |row|
    @region = row['region']
    @introduce = row['introduce']
  end

  sql4 = "select image_pass from profile_image where user_id = #{@user_id}"
  res = client.query(sql4)
  res.each do |row|
    @image_pass = row['image_pass']
  end

  erb :reservation
end

# ======================

post '/reserve' do

  sql = "select user_id from reserve_date where id = #{params[:reserve_id]};"
  res = client.query(sql)
  res.each do |row|
    @sitter_id = row["user_id"]
  end

  sql1 = "insert into reservation_date values(null, #{params[:reserve_id]}, #{@sitter_id}, #{session[:user_id]});"
  client.query(sql1)

  sql2 = "UPDATE reserve_date SET reservation = 1 WHERE id = #{params[:reserve_id]};"
  client.query(sql2)

  redirect '/parentpage'
end

# ======================
get '/reservesitter_list' do
  sql = "select last_name,reserve_date.id,date,start_time,end_time from users inner join reservation_date on users.id = reservation_date.sitter_user inner join reserve_date on reserve_date.id = reservation_date.reserve_id where parent_user = #{session[:user_id]};"

  @res = client.query(sql)
  @res.each do |row|
    row['last_name']
    row['id']
    row['date']
    row['start_time']
    row['end_time']
  end

  erb :reservesitter_list
end

# ======================

get '/reservesitter_del/:reserve_id' do
  params[:reserve_id]

  sql = "UPDATE reserve_date SET reservation = 0 WHERE id = #{params[:reserve_id]};"
  client.query(sql)

  sql2 = "delete from reservation_date WHERE reserve_id = #{params[:reserve_id]}"
  client.query(sql2)

  redirect '/reservesitter_list'
end

# ======================

get '/profile_edit_sitter' do
  is_login()

  sql = "select last_name,first_name,region,introduce from users inner join profile_sitter on users.id = profile_sitter.user_id where user_id = #{session[:user_id]};"
  res = client.query(sql)
  res.each do |row|
    @last_name = row["last_name"]
    @first_name = row["first_name"]
    @region = row["region"]
    @introduce = row["introduce"]
  end
  erb :profile_edit_sitter
end

# ======================

post '/profile_edit_sitter' do

  sql = "update profile_sitter set region = '#{params[:region]}' ,introduce = '#{params[:introduce]}' where user_id = #{session[:user_id]};"
  client.query(sql)

  sql1 = "update users set last_name = '#{params[:last_name]}',first_name = '#{params[:first_name]}' where id = #{session[:user_id]};"
  client.query(sql1)

  redirect '/sitterpage'
end

# ======================

# ======================

get '/profile_edit_parent' do
  is_login()

  sql = "select last_name,first_name,region,introduce from users inner join profile_parent on users.id = profile_parent.user_id where user_id = #{session[:user_id]};"
  res = client.query(sql)
  res.each do |row|
    @last_name = row["last_name"]
    @first_name = row["first_name"]
    @region = row["region"]
    @introduce = row["introduce"]
  end
  erb :profile_edit_parent
end

# ======================

post '/profile_edit_parent' do

  sql = "update profile_parent set region = '#{params[:region]}' ,introduce = '#{params[:introduce]}' where user_id = #{session[:user_id]};"
  client.query(sql)

  sql1 = "update users set last_name = '#{params[:last_name]}',first_name = '#{params[:first_name]}' where id = #{session[:user_id]};"
  client.query(sql1)

  redirect '/parentpage'
end

# ======================

post '/image_change_sitter' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]

  File.open("./public/prof_images/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  sql = "update profile_image set image_pass = '/prof_images/#{@filename}' where user_id = #{session[:user_id]};"
  client.query(sql)

  redirect '/sitterpage'

end

# ======================

post '/image_change_parent' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]

  File.open("./public/prof_images/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  sql = "update profile_image set image_pass = '/prof_images/#{@filename}' where user_id = #{session[:user_id]};"
  client.query(sql)

  redirect '/parentpage'

end

# ======================

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end
