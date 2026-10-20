.pragma library

var PROFILE_FORMAT_VERSION = 1;

function validateProfiles(profiles) {
    if (!Array.isArray(profiles) || profiles.length === 0) return false;
    var seenIds = {};
    for (var i = 0; i < profiles.length; i++) {
        var profile = profiles[i];
        if (!profile || typeof profile !== "object") return false;
        if (typeof profile.id !== "string" || profile.id.trim() === "" || seenIds[profile.id]) return false;
        if (typeof profile.name !== "string" || profile.name.trim() === "") return false;
        if (!profile.data || typeof profile.data !== "object" || Array.isArray(profile.data)) return false;
        seenIds[profile.id] = true;
    }
    return true;
}

function defaultProfileIndex(profiles) {
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].isDefault) return i;
    }
    for (var namedIndex = 0; namedIndex < profiles.length; namedIndex++) {
        if (profiles[namedIndex].name === "Default") return namedIndex;
    }
    var oldestIndex = 0;
    for (var candidate = 1; candidate < profiles.length; candidate++) {
        var oldestTime = Number(profiles[oldestIndex].createdAt);
        var candidateTime = Number(profiles[candidate].createdAt);
        if (isFinite(candidateTime) && (!isFinite(oldestTime) || candidateTime < oldestTime)) oldestIndex = candidate;
    }
    return oldestIndex;
}

function activeProfileId(profiles, requestedId) {
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].id === requestedId) return requestedId;
    }
    return profiles.length > 0 ? profiles[0].id : "";
}

function canDeleteProfile(profiles, profileId) {
    if (!profiles || profiles.length <= 1) return false;
    for (var i = 0; i < profiles.length; i++) {
        if (profiles[i].id === profileId) return !profiles[i].isDefault;
    }
    return false;
}

function serializeProfiles(profiles) {
    return JSON.stringify({ version: PROFILE_FORMAT_VERSION, profiles: profiles });
}
