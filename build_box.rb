require 'json'
require 'faye/websocket'
require 'eventmachine'
require 'date'

class BuildBox
  def initialize(room_name)
    @room_name = room_name
    @boxes = []
    @size = 1
    @build_interval = 0.01
  end

  def create_box(x, y, z, r, g, b)
    x, y, z = [x, y, z].map(&:floor)
    @boxes << [x, y, z, r, g, b]
  end

  def remove_box(x, y, z)
    x, y, z = [x, y, z].map(&:floor)
    @boxes.reject! { |box| box[0] == x && box[1] == y && box[2] == z }
  end

  def set_box_size(box_size)
    @size = box_size
  end

  def set_build_interval(interval)
    @build_interval = interval
  end

  def clear_boxes
    @boxes = []
    @size = 1
    @build_interval = 0.01
  end

  def send_data
    puts 'send_data'
    now = DateTime.now
    data_to_send = {
      "boxes": @boxes,
      "size": @size,
      "interval": @build_interval,
      "date": now.to_s
    }.to_json

    EM.run do
      ws = Faye::WebSocket::Client.new('wss://render-nodejs-server.onrender.com')

      ws.on :open do |_event|
        p [:open]
        puts 'WebSocket connection open'
        ws.send(@room_name)
        puts "Joined room: #{@room_name}"
        ws.send(data_to_send)
        puts 'Sent data to server'
        clear_boxes
        ws.close
        # EM.stop
      end
    end
  end
end
