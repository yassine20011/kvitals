import test from "node:test";
import assert from "node:assert/strict";
import { loadQmlLibrary } from "../helpers.js";
import { profile } from "../fixtures.js";

const Profiles = loadQmlLibrary("contents/ui/models/ProfileLogic.js");

test("profile validation rejects malformed and ambiguous persisted state", () => {
    assert.equal(Profiles.validateProfiles([profile()]), true);
    assert.equal(Profiles.validateProfiles([]), false);
    assert.equal(Profiles.validateProfiles([profile({ id: "" })]), false);
    assert.equal(Profiles.validateProfiles([profile({ name: " " })]), false);
    assert.equal(Profiles.validateProfiles([profile({ data: [] })]), false);
    assert.equal(Profiles.validateProfiles([profile(), profile()]), false, "duplicate IDs are ambiguous");
});

test("default migration prefers the named Default then the oldest profile", () => {
    const named = [
        profile({ id: "newer", name: "Gaming", createdAt: 20, isDefault: false }),
        profile({ id: "named", name: "Default", createdAt: 30, isDefault: false })
    ];
    assert.equal(Profiles.defaultProfileIndex(named), 1);

    const oldest = [
        profile({ id: "newer", name: "Gaming", createdAt: 20, isDefault: false }),
        profile({ id: "oldest", name: "Work", createdAt: 10, isDefault: false })
    ];
    assert.equal(Profiles.defaultProfileIndex(oldest), 1);
});

test("active profile selection falls back deterministically", () => {
    const profiles = [profile(), profile({ id: "profile-2", name: "Gaming", isDefault: false })];
    assert.equal(Profiles.activeProfileId(profiles, "profile-2"), "profile-2");
    assert.equal(Profiles.activeProfileId(profiles, "missing"), "profile-1");
    assert.equal(Profiles.activeProfileId([], "missing"), "");
});

test("only non-default profiles can be deleted when another profile remains", () => {
    const profiles = [profile(), profile({ id: "profile-2", name: "Default", isDefault: false })];
    assert.equal(Profiles.canDeleteProfile(profiles, "profile-1"), false);
    assert.equal(Profiles.canDeleteProfile(profiles, "profile-2"), true);
    assert.equal(Profiles.canDeleteProfile([profile()], "profile-1"), false);
    assert.equal(Profiles.canDeleteProfile(profiles, "missing"), false);
});

test("profile serialization carries the central format version", () => {
    const parsed = JSON.parse(Profiles.serializeProfiles([profile()]));
    assert.equal(parsed.version, Profiles.PROFILE_FORMAT_VERSION);
    assert.equal(parsed.profiles.length, 1);
});
