#todoist.rb
require 'net/http'
require 'open-uri'
require 'json'
require 'time'

require './TOKEN'

class TodoistList
  TOKEN = $TODOIST_TOKEN
  URL = 'https://api.todoist.com/sync/v8/sync'.freeze

  def self.obtain
    new.obtain
  end

  def obtain
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |https|
      format_msg(https.request(request))
    end
  end

  private

  def request
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(token: TOKEN, sync_token: '*', resource_types: '["items"]')
    request
  end

  def uri
    URI.parse(URL)
  end

  def format_msg(msg)
    msg = JSON.parse(msg.body)
    tasks = Hash.new
    out = ""
    msg["items"].select{|k| k["due"]!=nil and (Date.parse(k["due"]["date"]) <= Date.today + 1)}.each do |itm|

      /(\d{4}\-\d{2}\-\d{2})T?(\d{2}:\d{2})?(:\d{2})?Z?/ =~ itm["due"]["date"]
      date = $1
      time = $2
      # puts "date:#{date}, time:#{time}"
      content = time.nil? ? {disp: 1, title: itm["content"]} : {disp: -1, title: "[#{time}]#{itm["content"]}"}

      tasks.key?(date) ? tasks[date] << content : tasks[date] = [content]
    end

    # p tasks

    old = false
    tasks.sort.each do |a|
      out << "\n"
      case Date.parse(a[0])
      when Date.today + 1
        out << "⏳明日⏳\n"
      when Date.today
        out << "📅今日📅\n"
      else
        if old
          out.chomp!
        else
          out << "☠️期限切れ☠️\n"
          old = true
        end
      end

      a[1].sort_by{|k| k[:disp]}.each do |t|
          out << "✅️#{t[:title]}\n"
      end
    end

    out
  end

end

# ここからLINE

class LineNotify
  TOKEN = $LINE_NOTIFY_TOKEN
  URL = 'https://notify-api.line.me/api/notify'.freeze

  attr_reader :message

  def self.send(message)
    new(message).send
  end

  def initialize(message)
    @message = message
  end

  def send
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |https|
      https.request(request)
    end
  end

  private

  def request
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{TOKEN}"
    request.set_form_data(message: message)
    request
  end

  def uri
    URI.parse(URL)
  end
end

LineNotify.send(TodoistList.obtain)
# puts TodoistList.obtain
