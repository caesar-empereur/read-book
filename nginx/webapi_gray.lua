local table = require("table")
local redis = require "resty.redis" 
local luajson = require "luajson"

local cache = redis.new() 
cache:set_timeout(1000)

local ok, err = cache.connect(cache, '127.0.0.1', 6379) 
if not ok then 
	ngx.log(ngx.ERR, " failed to connect reids: ", err) 
	ngx.exec("@prolist")
	return
end 

local hostname =  ngx.req.get_uri_args()["hostname"]

ngx.log(ngx.ERR,  "hostname is ",  hostname)

if hostname == nil  then
       ngx.log(ngx.ERR,  "hostname null return ")
       return
end


local res, err = cache:get(hostname)
if res == nil then
	ngx.log(ngx.ERR, " get http host null ", hostname)
	ngx.exec("@prolist")
	return
end

ngx.log(ngx.ERR, " value  in  redis ", res)

local table1 = luajson.json2lua(res)

ngx.log(ngx.ERR, " convert table ", type(table1))

local type = table1['operate']
local ip = table1["ip"]
local port = table1["port"]
local weight = table1["weight"]

ngx.log(ngx.ERR, " get table value ", type,  ip, port, weight)

local getUrl = ""

if type=='update' 
then
	getUrl = "/dynamic?upstream=zone_for_backends&server=" .. ip .. ":" .. port .. "weight:" .. weight
else
	getUrl = "/dynamic?upstream=zone_for_backends&server=" .. ip .. ":" .. port .. "&" .. type  ..  "="
end
ngx.log(ngx.ERR, " nginx get url ", getUrl)
return ngx.exec(getUrl)