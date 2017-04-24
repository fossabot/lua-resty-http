local   rawget, rawset, setmetatable =
rawget, rawset, setmetatable

local str_lower, str_gsub =
string.lower, string.gsub


local _M = {
    _VERSION = '0.10',
}


local function hyphenate(k)
    return str_gsub(k, "_", "-")
end


-- Returns an empty headers table with internalised case normalisation.
-- Supports the same cases as in ngx_lua:
--
-- headers.content_length
-- headers["content-length"]
-- headers["Content-Length"]
function _M.new(self, opt)
    local mt = {
        allow_underscores = opt and opt.allow_underscores or false,
        normalised = {},
    }

    mt.__index = function(t, k)
        local k_hyphened = hyphenate(k)
        local k_normalised = str_lower(k_hyphened)
        return rawget(t, mt.normalised[k_normalised])
    end

    -- First check the normalised table. If there's no match (first time) add an entry for
    -- our current case in the normalised table. This is to preserve the human (prettier) case
    -- instead of outputting lowercased header names.
    --
    -- If there's a match, we're being updated, just with a different case for the key. We use
    -- the normalised table to give us the original key, and perorm a rawset().
    mt.__newindex = function(t, k, v)
        -- we support underscore syntax, so always hyphenate.
        local k_hyphened = hyphenate(k)

        -- lowercase hyphenated is "normalised"
        local k_normalised = str_lower(k_hyphened)

        if not mt.normalised[k_normalised] then
            local header_name = mt.allow_underscores and k or  k_hyphened
            mt.normalised[k_normalised] = header_name
            rawset(t, header_name, v)
        else
            rawset(t, mt.normalised[k_normalised], v)
        end
    end

    return setmetatable({}, mt)
end


return _M
