this is a simple bot using wot api and running on heroku

omit deploying to heroku process

set environmental argument first(heroku setting tab)
required:
TOKEN = your own bot token
PREFIX = command prefix(example: / )
DATABASE_URL = database url(when you add heroku postgres addon, automatically adds)
optional:
none

usage:
/stats IGN => status check command
/trees => trees player cut(using databse)
/rate => old status command

when you want to boot this bot locally, edit source
main.rb at 17, 18 line
token = 'set your own bot token!'; prefix = '/'
uri = URI.parse('database url')

then type
ruby main.rb -l

This software is released under the MIT License, see LICENSE.txt.