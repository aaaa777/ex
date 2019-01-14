def wotlab_rwr_c(player_name, mode)
  return 0 if mode <= 1 || mode >= 6 
  url = "https://wotlabs.net/sea/player/#{player_name}"
  charset = nil
  html = open(url) do |f|
      charset = f.charset
      f.read
  end
  doc = Nokogiri::HTML.parse(html, nil, charset)
  doc.xpath("//div[@id=\"tankerStats\"]/div[#{mode}]").each do |node|
    color = node.attribute('class').value
    color = color.split(' ').last
    hcol = 0
    case color
    when "dred" then
      hcol = 8912896
    when "red" then
      hcol = 16711680
    when "orange" then
      hcol = 16746496
    when "yellow" then
      hcol = 16776960
    when "green" then
      hcol = 8690468
    when "dgreen" then
      hcol = 5075750
    when "blue" then
      hcol = 4233663
    when "dblue" then
      hcol = 3764934
    when "purple" then
      hcol = 7945654
    when "dpurple" then
      hcol = 4198512
    else
      hcol = 0
    end
    return hcol
  end
end


def wot_api_req(mode, arg)
  url = URI.parse('https://api.worldoftanks.asia')
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  case mode
  when 'player_id'
    url_mode = '/wot/account/list/'
    url_arg = "&search=#{arg}&language=en"
  when 'player_stats'
    url_mode = '/wot/account/info/'
    url_arg = "&account_id=#{arg}&language=en"
  when 'clan_stats'
    url_mode = '/wgn/clans/membersinfo/'
    url_arg = "&account_id=#{arg}&game=wot&language=en"
  end
  res = http.get("#{url_mode}?application_id=15c64c54e46703f81a0925541c3abdbd#{url_arg}")
  return JSON.parse(res.body)
end

def user_search(database, id, attr)
  result = database.exec("select #{attr} from user_attr where id = #{id}")
  result.each do |row|
    return row[attr]
  end
  return nil
end

def user_add(database, id, ign)
  database.exec("insert into user_attr values(#{id}, '#{ign}', 4)")
  return
end

def user_del(database, id)
  database.exec("delete from user_attr where id = #{id}")
end

def rate_mode_ex(arg)
  rate_mode = ''
  case true
  when arg.is_a?(String)
    rate_mode = 4
    case arg
    when 'wn8'
      rate_mode = 2
    when 'wr', 'winrate'
      rate_mode = 3
    when 'rwn8', 'recentwn8'
      rate_mode = 4
    when 'rwr', 'recentwinrate'
      rate_mode = 5
    when 'wgr', 'wargamingrate'
      rate_mode = nil
    else
      rate_mode = false
    end
  when arg.is_a?(Integer)
    return '' if arg <= 1 || arg >= 6
    rate_mode = 'rwn8'
    case arg
    when 2
      rate_mode = 'wn8'
    when 3
      rate_mode = 'wr'
    when 4
      rate_mode = 'rwn8'
    when 5
      rate_mode = 'rwr'
    else
      rate_mode = false
    end
  when nil
    rate_mode = 'wgr'
  end
  return rate_mode
end
