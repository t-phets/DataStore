--!strict

local ProfileSessionTypes = require("../Types/ProfileSessionTypes")

local SessionAccess = {}

function SessionAccess.FindWritable(
    getSession: ProfileSessionTypes.SessionProvider,
    userId: number
): ProfileSessionTypes.SessionLookup
    local session = getSession(userId)
    if session == nil then
        return { ok = false, reason = "ProfileNotLoaded" }
    end
    if session.state == "Closing" then
        return { ok = false, reason = "PlayerClosing" }
    end
    return { ok = true, session = session }
end

return SessionAccess