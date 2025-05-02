local M = {}

---@enum EventType
M.Type = {
    RENAME = "rename",
    DELETE = "delete",
    CREATE = "create",
    FILE_ENTER = "file_enter",
}

---@class Event
---@field type EventType
---@field data table
---@field handler_id integer?

---@class EventHandler
---@field handler fun(event: Event)
---@field for_events table<EventType>
---@field id integer

---@class Queue
---@field events Event[]
---@field subscribers EventHandler[]
M.queue = { events = {}, subscribers = {} }
M.global_id = 0

---@param event Event
function M.push(event)
    table.insert(M.queue.events, event)
end

---@param type EventType
---@param data table
function M.fire(type, data)
    table.insert(M.queue.events, { type = type, data = data })
end

---@param for_events EventType[]
---@param handler fun(event: Event)
---@return integer id
function M.subscribe(for_events, handler)
    local set = {}
    for _, t in ipairs(for_events) do
        set[t] = true
    end

    local id = M.global_id
    M.global_id = M.global_id + 1

    table.insert(M.queue.subscribers, {
        id = id,
        handler = handler,
        for_events = set,
    })

    return id
end

---@param id integer
function M.unsubscribe(id)
    for i, subscriber in ipairs(M.queue.subscribers) do
        if subscriber.id == id then
            table.remove(M.queue.subscribers, i)
            return true
        end
    end
    return false
end

function M.dispatch()
    for _, event in ipairs(M.queue.events) do
        for _, sub in ipairs(M.queue.subscribers) do
            if sub.for_events[event.type] then
                local ok, err = pcall(sub.handler, vim.fn.extend(event, { handler_id = sub.id }))
                if not ok then
                    vim.notify(
                        string.format(
                            "Error in event handler %d for %s: %s",
                            sub.id,
                            event.type,
                            err
                        ),
                        vim.log.levels.ERROR
                    )
                end
            end
        end
    end

    M.queue.events = {}
end

return M
