-- init.lua module
-- Author: Arne Meeuw
-- github.com/ameeuw
--

-- Declare global name concatenated from purpose-name and MAC address
name = 'MqttClient:'..string.sub(wifi.sta.getmac(),13,-1)

-- Initialize Esp module and add begin() callback
Esp = require("Esp").new(
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
