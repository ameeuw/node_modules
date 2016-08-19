-- init.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--

-- Declare global name concatenated from purpose-name and MAC address
name = name or 'MqttClient:'..string.sub(wifi.sta.getmac(),13,-1)


function beginMQTT()
-- Initialize Esp module and add begin() callback
Esp = Esp or require("Esp").new(
    function()
        MqttClient = require("MqttClient").new('m-e-e-u-w.de', 62763)
        MqttClient:register("telnet/input",
            function(topic, message)
                node.input(message)
            end)

        function s_output(str)
        -- Filter non printable characters
            local string,_ = string.gsub(str,'%c','')
            if (string~="") then
                MqttClient.MqttClient:publish(MqttClient.topic.."telnet/output", string,0,0)
            end
        end

        net.dns.setdnsserver('8.8.8.8',0)
        node.output(s_output,1)
    end)
end

function beginWS()
  Esp = Esp or require("Esp").new(
    function()
      -- mdns.register("fishtank", {hardware='NodeMCU'})
      mdns.register(name, {hardware='ESP866'})
      server = net.createServer(net.TCP, 30)
      server:listen(62763,
        function(connection)

          connection:on("receive",
            function(c, string)
              node.input(string)
            end)

        function s_output(str)
        -- Filter non printable characters
          local string,_ = string.gsub(str,'%c','')
          if (string~="") then
            connection:send(string)
          end
        end
        node.output(s_output,1)
      end
      )
    end
  )
end
