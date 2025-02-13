local PathPrefixHandler = {
  VERSION  = "0.1.0",
  PRIORITY = 800,
}

--function PathPrefixHandler:new()
--    plugin.super.new(self, "path-prefix")
--end

local function escape_hyphen(conf)
    local path_prefix = conf.path_prefix
    local should_escape = conf.escape

    if should_escape then
        return string.gsub(path_prefix, "%-", "%%%1")
    end

    return path_prefix
end

local function add_header(conf, path)
    local forwarded_header = conf.forwarded_header
    if forwarded_header then
        kong.log("Adding Header: X-Forwarded-Prefix ", conf.path_prefix)
        ngx.var.upstream_x_forwarded_prefix = conf.path_prefix
    end
end

function PathPrefixHandler:access(config)
    --plugin.super.access(self)

    local service_path = ngx.ctx.service.path or ""
    local full_path = kong.request.get_path()
    local replace_match = escape_hyphen(config)
    local path_without_prefix = full_path:gsub(replace_match, "", 1)

    if path_without_prefix == "" and service_path == "" then
        path_without_prefix = "/"
    end

    local new_path = path_without_prefix
    kong.log("rewriting ", full_path, " to ", path_without_prefix)
    if service_path ~= "" then
        kong.log("Prefixing request with service path ", service_path)
        new_path = service_path .. new_path
    end
    add_header(config, path_without_prefix)
    kong.service.request.set_path(new_path)
end

--plugin.PRIORITY = 800

return PathPrefixHandler
