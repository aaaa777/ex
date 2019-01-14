require 'discordrb'
require 'pg'
require "open-uri"
require 'net/https'
require 'json'
require 'uri'
require 'nokogiri'
require './defs'
require './data'

database = nil
random = Random.new
uri = nil
aobsbot = nil

if ARGV[0] == "-l" then
  token = 'set your own bot token!'; prefix = '/'
  uri = URI.parse('database url!')
  p 'local boot mode'
else
  token = ENV['TOKEN']; prefix = ENV['PREFIX']
  uri = URI.parse(ENV['DATABASE_URL'])
end

begin
  database = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
rescue => exception
  p expection
end

bot = Discordrb::Commands::CommandBot.new(token: token, client_id: client_id, name: name, prefix: prefix)

bot.command(:rate) do |e, *args|
  #break unless [526126341972819968, 229586488155701248].include?(e.channel.id)
  url = URI.parse('https://api.worldoftanks.asia')
  #okutariid = 2017936183
  user_name = args[0]
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  res = http.get("/wot/account/list/?application_id=15c64c54e46703f81a0925541c3abdbd&search=#{user_name}&language=en")
  api_json = JSON.parse(res.body)
  if api_json['meta']['count'] == 0
    e.respond(":warning: **[error]:**プレイヤー#{user_name}が見つかりませんでした") 
    break
  end
  user_id = api_json['data'].first['account_id'].to_i

  res =  http.get("/wgn/clans/membersinfo/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&game=wot&language=en")
  api_json = JSON.parse(res.body)
  clan_ico = 'https://cdn.discordapp.com/attachments/447846567630864406/525651177803874304/be26dcccb1bf297c199d37e54212071f.png'
  unless api_json['data']["#{user_id}"] == nil
    clan_sn = "[#{api_json['data']["#{user_id}"]['clan']['tag']}]"
    clan_ico = api_json['data']["#{user_id}"]['clan']['emblems']['x64']['wot'].gsub('http://', 'https://')
  end
  p clan_sn, clan_ico
  res = http.get("/wot/account/info/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&language=en")
  
  api_json = JSON.parse(res.body)
  unless api_json['status'] == 'ok'
    #'データの取得に失敗しました'
  else
    per_stat = api_json['data'][user_id.to_s]
    all_stat = per_stat['statistics']['all']

    #Time.at(1545323272).to_s
    embed = Discordrb::Webhooks::Embed.new
    embed.author = Discordrb::Webhooks::EmbedAuthor.new(
      name: "#{per_stat['nickname']}#{clan_sn}",
      url: "https://worldoftanks.asia/ja/community/accounts/#{per_stat['account_id']}-#{per_stat['nickname']}/",
      icon_url: clan_ico
    )
    embed.title = 'パーソナルレーティング'
    p_rate = per_stat['global_rating'].to_i
    embed.description = p_rate.to_s
    if p_rate < 2555
      embed.color = 16711680
    elsif p_rate < 4435
      embed.color = 16744448
    elsif p_rate < 6515
      embed.color = 16776960
    elsif p_rate < 8730
      embed.color = 65280
    elsif p_rate < 10175
      embed.color = 65535
    elsif p_rate < 99999
      embed.color = 8913151
    end
    embed.add_field(
      name: '戦闘数',
      value: all_stat['battles'].to_s,
      inline: true
    )
    embed.add_field(
      name: '勝率',
      value: "#{((all_stat['wins'].to_f/ all_stat['battles'].to_f)*100).round(2)} %",
      inline: true
    )
    embed.add_field(
      name: '命中率',
      value: "#{((all_stat['hits'].to_f/ all_stat['shots'].to_f)*100).round(2)} %",
      inline: true
    )
    embed.add_field(
      name: '平均経験値',
      value: (all_stat['xp'].to_f/ all_stat['battles'].to_f).round(2).to_s,
      inline: true
    )
    embed.add_field(
      name: '平均ダメージ',
      value: (all_stat['damage_dealt'].to_f/ all_stat['battles'].to_f).round(2).to_s,
      inline: true
    )
    embed.add_field(
      name: '平均アシスト',
      value: all_stat['avg_damage_assisted'].to_s,
      inline: true
    )
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(
      text: Time.at((per_stat['last_battle_time']+(60*60*9)).to_i).strftime('最終戦闘日:%Y年%-m月%-d日 %R'),
      icon_url: 'https://cdn.discordapp.com/attachments/447846567630864406/525651177803874304/be26dcccb1bf297c199d37e54212071f.png'
    )
    e.channel.send_embed('', embed)
  end
  nil
end

bot.command(:stats) do |e, *args|
  #break unless [526126341972819968, 229586488155701248, 447846567630864406].include?(e.channel.id)
  sysmsg = ''
  result = user_search(database, e.user.id, 'ign')
  user_name = args[0]
  fmsg = MessageFormat::Message.new({language: :ja})
  unless args[0]
    if user_search(database, e.user.id, 'id')
      user_name = user_search(database, e.user.id, 'ign')
    else
      return ":warning: **[error]:**`me`オプションに登録されていません！先に`/stats プレイヤー名 me`を打ってください"
    end
  else
    if user_name == 'me'
      
      return ":warning: **[error]:**`me`オプションに登録されていません！先に`/stats プレイヤー名 me`を打ってください" unless result
      user_name = result
    end
    return ':warning: **[error]:**使用可能なプレイヤー名は`A-Z,a-z,0-9,_`のみです' unless user_name.ascii_only?
    return ':warning: **[error]:**プレイヤー名は3文字以上24文字以下である必要があります' if user_name.size < 3 || user_name.size > 24
    #default_rate_mode = 4
  end

  rate_mode = 4
  rate_mode_s = 'rwn8'
  rate_mode_s = args[1].downcase if args.is_a?(Array) && args.size >= 2
  if rate_mode_s == 'me'
    if user_search(database, e.user.id, 'id')
      sysmsg = "登録IGNを#{result}から#{user_name}に変更しました"
      user_del(database, e.user.id)
      user_add(database, e.user.id, user_name)
    else
      sysmsg = "IGN:#{user_name}で登録しました、次回からは`/stats`で自身の戦績を確認できます"
      user_add(database, e.user.id, user_name)
    end
    rate_mode_s = 'rwn8'
  end
  rate_mode = rate_mode_ex(rate_mode_s)
  return ":warning: **[error]:**不明なオプション`#{rate_mode_s}`が指定されました\n有効なオプション一覧```ruby\n埋め込みメッセージ左の色の基準を変更できるオプション\nwgr , wargamingrate #=>パソレ\nwr  , winrate       #=>全体勝率\nwn8                 #=>WN8\nrwr , recentwinrate #=>直近勝率\nrwn8, recentwn8     #=>直近WN8\n(大文字小文字は区別しません)```" if rate_mode == false
  
  p rate_mode
  msg = e.respond("WoTLabsへ#{rate_mode_s}をリスエストしています…")
  color = 0
  open("https://wotlabs.net/sig_dark/sea/#{user_name}/signature.png")
  color = wotlab_rwr_c(user_name, rate_mode) if rate_mode
  msg.edit('WoTAPIへプレイヤー情報をリクエストしています…')
  #url = URI.parse('https://api.worldoftanks.asia')

  #http = Net::HTTP.new(url.host, url.port)
  #http.use_ssl = true
  #http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  #res = http.get("/wot/account/list/?application_id=15c64c54e46703f81a0925541c3abdbd&search=#{user_name}&language=en")
  api_json = wot_api_req('player_id', user_name)
  #api_json = JSON.parse(res.body)
  return ":warning: **[error]:**code:#{api_json['error']['code']} reason:#{api_json['error']['message']}" unless api_json['status'] == 'ok'
  #fmsg = MessageFormat::Message::Error.new(:player_not_found_api, {language: :ja, user_name: user_name}).output
  return fmsg.error(:player_not_found_api, {user_name: user_name}).output if api_json['meta']['count'] == 0
  
  user_id = api_json['data'].first['account_id'].to_i

  msg.edit('WoTAPIへ所属クランアイコンURLをリクエストしています…')
  #res =  http.get("/wgn/clans/membersinfo/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&game=wot&language=en")
  api_json = wot_api_req('clan_stats', user_id)  
  #api_json = JSON.parse(res.body)
  clan_ico = 'https://cdn.discordapp.com/attachments/447846567630864406/525651177803874304/be26dcccb1bf297c199d37e54212071f.png'
  unless api_json['data']["#{user_id}"] == nil
    clan_sn = "[#{api_json['data']["#{user_id}"]['clan']['tag']}]"
    clan_ico = api_json['data']["#{user_id}"]['clan']['emblems']['x64']['wot'].gsub('http://', 'https://')
  end
  p clan_sn, clan_ico
  msg.edit('WoTAPIへユーザー戦績をリクエストしています…')
  #res = http.get("/wot/account/info/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&language=en")
  api_json = wot_api_req('player_stats', user_id)
  #api_json = JSON.parse(res.body)
  per_stat = api_json['data'][user_id.to_s]
  all_stat = per_stat['statistics']['all']
  #Time.at(1545323272).to_s
  embed = Discordrb::Webhooks::Embed.new
  embed.author = Discordrb::Webhooks::EmbedAuthor.new(
    name: "#{per_stat['nickname']}#{clan_sn}",
    url: "https://worldoftanks.asia/ja/community/accounts/#{per_stat['account_id']}-#{per_stat['nickname']}/",
    icon_url: clan_ico
  )
  embed.title = 'パーソナルレーティング'
  p_rate = per_stat['global_rating'].to_i
  embed.description = p_rate.to_s
  unless rate_mode
    if p_rate < 2555
      embed.color = 16711680
    elsif p_rate < 4435
      embed.color = 16744448
    elsif p_rate < 6515
      embed.color = 16776960
    elsif p_rate < 8730
      embed.color = 65280
    elsif p_rate < 10175
      embed.color = 65535
    elsif p_rate < 99999
      embed.color = 8913151
    end
  else
    embed.color = color
  end
  embed.add_field(
    name: '戦闘数',
    value: all_stat['battles'].to_s,
    inline: true
  )
  embed.add_field(
    name: '勝率',
    value: "#{((all_stat['wins'].to_f/ all_stat['battles'].to_f)*100).round(2)} %",
    inline: true
  )
  embed.add_field(
    name: '命中率',
    value: "#{((all_stat['hits'].to_f/ all_stat['shots'].to_f)*100).round(2)} %",
    inline: true
  )
  embed.add_field(
    name: '平均経験値',
    value: (all_stat['xp'].to_f/ all_stat['battles'].to_f).round(2).to_s,
    inline: true
  )
  embed.add_field(
    name: '平均ダメージ',
    value: (all_stat['damage_dealt'].to_f / all_stat['battles'].to_f).round(2).to_s,
    inline: true
  )
  embed.add_field(
    name: '平均アシスト',
    value: all_stat['avg_damage_assisted'].to_s,
    inline: true
  )
  embed.add_field(
    name: 'WoTLabs search result',
    value: "https://wotlabs.net/sea/player/#{user_name}",
    inline: false
  )
  embed.image = Discordrb::Webhooks::EmbedImage.new(
    url: "https://wotlabs.net/sig_dark/sea/#{user_name}/signature.png"
  )
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(
    text: Time.at((per_stat['last_battle_time']+(60*60*9)).to_i).strftime('最終戦闘日:%Y年%-m月%-d日 %R'),
    icon_url: 'https://wotlabs.net/images/favicon.png'
  )
  msg.edit(sysmsg, embed)
  
end

bot.command(:trees) do |e|
  user_name = user_search(database, e.user.id, 'ign')
  return ':warning: **[error]:**`me`オプションに登録されていません！\n先に`/stats プレイヤー名 me`を打ってください' unless user_name

  msg = e.respond('WoTAPIへプレイヤー情報をリクエストしています…')
  url = URI.parse('https://api.worldoftanks.asia')
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  res = http.get("/wot/account/list/?application_id=15c64c54e46703f81a0925541c3abdbd&search=#{user_name}&language=en")
  api_json = JSON.parse(res.body)
  return ":warning: **[error]:**code:#{api_json['error']['code']} reason:#{api_json['error']['message']}" unless api_json['status'] == 'ok'
  return ":warning: **[error]:**プレイヤー#{user_name}が見つかりませんでした" if api_json['meta']['count'] == 0
  
  user_id = api_json['data'].first['account_id'].to_i

  msg.edit('WoTAPIへ森林伐採記録をリクエストしています…')
  res =  http.get("/wgn/clans/membersinfo/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&game=wot&language=en")
  api_json = JSON.parse(res.body)
  clan_ico = 'https://cdn.discordapp.com/attachments/447846567630864406/525651177803874304/be26dcccb1bf297c199d37e54212071f.png'
  unless api_json['data']["#{user_id}"] == nil
    clan_sn = "[#{api_json['data']["#{user_id}"]['clan']['tag']}]"
    clan_ico = api_json['data']["#{user_id}"]['clan']['emblems']['x64']['wot'].gsub('http://', 'https://')
  end
  
  msg.edit('WoTAPIへ所属クランアイコンURLをリクエストしています…')
  res = http.get("/wot/account/info/?application_id=15c64c54e46703f81a0925541c3abdbd&account_id=#{user_id}&language=en")

  api_json = JSON.parse(res.body)
  per_stat = api_json['data'][user_id.to_s]
  all_stat = per_stat['statistics']['all']

  embed = Discordrb::Webhooks::Embed.new
  embed.author = Discordrb::Webhooks::EmbedAuthor.new(
    name: "#{per_stat['nickname']}#{clan_sn}",
    url: "https://worldoftanks.asia/ja/community/accounts/#{per_stat['account_id']}-#{per_stat['nickname']}/",
    icon_url: clan_ico
  )
  embed.title = 'あなたが今までに倒した木の本数は…'
  embed.description = "#{per_stat['statistics']['trees_cut']}本！"
  embed.footer = Discordrb::Webhooks::EmbedFooter.new(
    text: 'Environmental destruction rating',
    icon_url: 'https://cdn.discordapp.com/attachments/447846567630864406/525651177803874304/be26dcccb1bf297c199d37e54212071f.png'
  )
  msg.edit('', embed)
end

bot.run