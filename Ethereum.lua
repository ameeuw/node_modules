--[[
Ethereum.lua module
Author: Arne Meeuw
github.com/ameeuw

Skeleton for creating a Ethereum

Initialize:
Ethereum = require('Ethereum').new(rpc, port)

Methods:
Ethereum:function()
 --]]

 --[[
 Send Transaction:
 {"jsonrpc":"2.0","method":"eth_sendTransaction","params": [{"from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155", "to": "0xd46e8dd67c5d32be8058bb8eb970870f07244567", "gas": "0x76c0", "gasPrice": "0x9184e72a000", "value": "0x9184e72a",
  "data": "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
}],"id":1}

SHA3 Hash
{"jsonrpc":"2.0","method":"web3_sha3","params":["0x68656c6c6f20776f726c64"],"id":64}

Sign SHA3 Hash of a transaction:


Send signed raw transaction:
{"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":[{"0xf874808504e3b29200825208940c4dcdd4a0dbe68c026d4f8671c46522f9a321bc87071afd498d000089da00000000000000001ca0cbad9a67559fe667314888c545ae6553efb6ecb9f9d4417b666443b8e59db439a0235fd131cb1b2a489ffd1b77fd50b2ac2fe2234c7bbac6ee5ab1a4956e14b80f"}],"id":1}

Address
0xD0434D724D30Ad4774A358e6319e88D6c21C9F9B
Privkey
6292eabe26fa1dd4c5ced6cbaafbaee0b3b3c9b93a3cf8756674c3427a1d7707

0xf874808504e3b29200825208940c4dcdd4a0dbe68c026d4f8671c46522f9a321bc87071afd498d000089da00000000000000001ca0cbad9a67559fe667314888c545ae6553efb6ecb9f9d4417b666443b8e59db439a0235fd131cb1b2a489ffd1b77fd50b2ac2fe2234c7bbac6ee5ab1a4956e14b80f

--]]
local Ethereum = {}
Ethereum.__index = Ethereum

function Ethereum.new(rpc, port)

	local self = setmetatable({}, Ethereum)
	name = name or 'Ethereum:'..string.sub(wifi.sta.getmac(),13,-1)

	return self
end

function Ethereum.sendData(self)
	local data =
	http.post()
end

return Ethereum
