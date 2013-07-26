# Onering Facts - HAProxy Stats
#   provides collection of statistics from HAProxy
#
require 'set'
require 'socket'

haproxy = nil
sockets_seen = Set.new()

# find all haproxy configs, ensuring haproxy.cfg is always front of the line
Dir["/etc/haproxy/*.cfg"].sort{|a,b| (b == 'haproxy.cfg' ? 1 : a<=>b) }.each do |cfg|
  haproxy ||= []
  pools = {}
  cfg_data = (File.read(cfg).lines rescue [])

  description = (cfg_data.select{|i| i =~ /^\s* description / }.first.strip.split(' ',2).last.gsub('"','') rescue nil)
  socket = (cfg_data.select{|i| i =~ /^\s* stats socket / }.first.strip.split(' ')[2] rescue nil)

# stats socket must be present in the config, a real file, and not have been seen before
  if not socket.nil? and File.exists?(socket) and not sockets_seen.include?(socket)
    sockets_seen << socket
    stats = UNIXSocket.new(socket)
    stats.puts("show stat")

    instance = {
      :name        => File.basename(cfg, '.cfg'),
      :socket      => socket,
      :path        => cfg,
      :description => description,
      :pools       => []
    }

    stats.read.lines.each do |line|
      next if line[0].chr == '#'
      line = line.strip.chomp
      next if line.empty?
      line = line.split(',')

      begin
        pools[line[0]] ||= {
          :name     => line[0],
          :services => []
        }

        pools[line[0]][:services] << ({
          :name => line[1],
          :queue => {
            :current => line[2].to_i,
            :maximum => line[3].to_i,
            :limit   => line[25].to_i
          },
          :sessions => {
            :rate         => line[33].to_i,
            :rate_limit   => line[34].to_i,
            :rate_maximum => line[35].to_i,
            :current      => line[4].to_i,
            :maximum      => line[5].to_i,
            :limit        => line[6].to_i,
            :total        => line[7].to_i
          },
          :bytes => {
            :in => line[8].to_i,
            :out => line[9].to_i
          },
          :denied => {
            :request  => line[10].to_i,
            :response => line[11].to_i
          },
          :errors => {
            :request    => line[12].to_i,
            :connection => line[13].to_i,
            :response   => line[14].to_i
          },
          :warnings => {
            :retry      => line[15].to_i,
            :redispatch => line[16].to_i
          },
          :status => line[17].downcase,
          :online => (line[17].downcase == 'up'),
          :weight => line[18].to_i,
          :checks => {
            :status => (case line[36].upcase.to_sym
              when :UNK      then :unknown
              when :INI      then :initializing
              when :SOCKERR  then :socket_error
              when :L4OK     then :layer4_ok
              when :L4TMOUT  then :layer4_timeout
              when :L4CON    then :layer4_connection_failed
              when :L6OK     then :layer6_ok
              when :L6TOUT   then :layer6_ssl_timeout
              when :L6RSP    then :layer6_ssl_protocol_error
              when :L7OK     then :layer7_ok
              when :L7OKC    then :layer7_ok
              when :L7TOUT   then :layer7_timeout
              when :L7RSP    then :layer7_protocol_error
              when :L7STS    then :layer7_server_error
              else nil
              end
            ),
            :response_code => line[37].to_i,
            :duration      => line[38].to_i,
            :fail_details  => line[45],
            :failed        => line[21].to_i,
            :downs         => line[22].to_i
          },
          :http => {
            :request => {
              :rate         => line[46].to_i,
              :rate_maximum => line[47].to_i,
              :total        => line[48].to_i,
              :client_abort => line[49].to_i,
              :server_abort => line[50].to_i
            },
            :response => {
              '100'   => line[39].to_i,
              '200'   => line[40].to_i,
              '300'   => line[41].to_i,
              '400'   => line[42].to_i,
              '500'   => line[43].to_i,
              'other' => line[44].to_i
            }
          },
          :last_changed_at => Time.at(Time.now.to_i - line[23].to_i).strftime('%Y-%m-%d %H:%M:%S %z'),
          :downtime => line[24].to_i,
          :pid => line[26].to_i,
          :proxy_id   => line[27].to_i,
          :service_id => line[28].to_i,
          :throttle   => line[29],
          :selected   => line[30].to_i,
          :tracked    => line[31],
          :type       => (case line[32].to_i
            when 0 then :frontend
            when 1 then :backend
            when 2 then :server
            when 3 then :socket
            else nil
            end
          )
        })
      rescue
        next
      end
    end

    instance[:pools] = pools.values()
    haproxy << instance
  end
end


if not haproxy.nil?
  Facter.add('haproxy') do
    setcode { haproxy }
  end
end
