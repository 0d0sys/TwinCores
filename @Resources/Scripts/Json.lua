-- Small JSON reader; data is never evaluated as Lua source.
local J = {}
function J.decode(s)
  local p = 1
  local function ws() local _,e=s:find('^[ \n\r\t]*',p); p=(e or p-1)+1 end
  local function utf(n)
    if n<128 then return string.char(n) end
    if n<2048 then return string.char(192+math.floor(n/64),128+n%64) end
    if n<65536 then return string.char(224+math.floor(n/4096),128+math.floor(n/64)%64,128+n%64) end
    return string.char(240+math.floor(n/262144),128+math.floor(n/4096)%64,128+math.floor(n/64)%64,128+n%64)
  end
  local function str()
    assert(s:sub(p,p)=='"');p=p+1
    local out={}
    while p<=#s do
      local c=s:sub(p,p);p=p+1
      if c=='"' then return table.concat(out) end
      if c=='\\' then
        c=s:sub(p,p);p=p+1
        local esc={['"']='"',['\\']='\\',['/']='/',b='\b',f='\f',n='\n',r='\r',t='\t'}
        if c=='u' then
          local n=assert(tonumber(s:sub(p,p+3),16));p=p+4
          if n>=55296 and n<=56319 and s:sub(p,p+1)=='\\u' then
            local low=assert(tonumber(s:sub(p+2,p+5),16));p=p+6
            n=65536+(n-55296)*1024+(low-56320)
          end
          out[#out+1]=utf(n)
        else out[#out+1]=assert(esc[c]) end
      else out[#out+1]=c end
    end
    error('Unclosed JSON string')
  end
  local value
  value=function()
    ws();local c=s:sub(p,p)
    if c=='"' then return str() end
    if c=='{' or c=='[' then
      local object=c=='{';local close=object and '}' or ']';p=p+1;ws();local t={}
      if s:sub(p,p)==close then p=p+1;return t end
      while true do
        ws();local k
        if object then k=str();ws();assert(s:sub(p,p)==':');p=p+1 else k=#t+1 end
        t[k]=value();ws();local nextchar=s:sub(p,p);p=p+1
        if nextchar==close then return t end
        assert(nextchar==',','JSON separator expected')
      end
    end
    for word,v in pairs({['true']=true,['false']=false,['null']=J.null}) do
      if s:sub(p,p+#word-1)==word then p=p+#word;return v end
    end
    local number=s:match('^-?%d+%.?%d*[eE]?[+-]?%d*',p)
    assert(number and #number>0,'JSON value expected');p=p+#number;return assert(tonumber(number))
  end
  local result=value();ws();assert(p>#s,'Trailing JSON');return result
end
J.null={}
return J
