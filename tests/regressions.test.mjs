import assert from "node:assert/strict";
import test from "node:test";
import vm from "node:vm";
import { readFile } from "node:fs/promises";

const html = await readFile(new URL("../index.html", import.meta.url), "utf8");

function extractFunction(name) {
  const functionStart = html.indexOf(`function ${name}(`);
  assert.notEqual(functionStart, -1, `Could not find function ${name}`);
  const start =
    html.slice(Math.max(0, functionStart - 6), functionStart) === "async "
      ? functionStart - 6
      : functionStart;

  const bodyStart = html.indexOf("){", functionStart) + 1;
  assert.notEqual(bodyStart, 0, `Could not find body for function ${name}`);
  let depth = 0;
  let quote = "";
  let escaped = false;

  for (let i = bodyStart; i < html.length; i += 1) {
    const char = html[i];

    if (quote) {
      if (escaped) escaped = false;
      else if (char === "\\") escaped = true;
      else if (char === quote) quote = "";
      continue;
    }

    if (char === '"' || char === "'" || char === "`") {
      quote = char;
      continue;
    }

    if (char === "{") depth += 1;
    if (char === "}") {
      depth -= 1;
      if (depth === 0) return html.slice(start, i + 1);
    }
  }

  throw new Error(`Could not extract function ${name}`);
}

test("first Realtime subscription performs a silent catch-up fetch", () => {
  let statusCallback;
  const loadCalls = [];
  const channel = {
    on() {
      return this;
    },
    subscribe(callback) {
      statusCallback = callback;
      return this;
    },
  };
  const context = {
    sb: { channel: () => channel },
    state: { liveDataState: "ready" },
    realtimeFirstSubscribe: true,
    setSync() {},
    loadAll(options) {
      loadCalls.push(options);
    },
  };

  vm.runInNewContext(`${extractFunction("subscribeRealtime")}; subscribeRealtime();`, context);
  statusCallback("SUBSCRIBED");

  assert.equal(loadCalls.length, 1, "SUBSCRIBED must close the snapshot-to-stream gap");
  assert.deepEqual(
    structuredClone(loadCalls[0]),
    { silent: true },
    "catch-up fetch must not reset ready UI to loading",
  );
});

test("silent load keeps ready UI while refreshing data", async () => {
  const syncCalls = [];
  let guardRenders = 0;

  function query(result) {
    const promise = Promise.resolve(result);
    const builder = {
      select() {
        return builder;
      },
      eq() {
        return builder;
      },
      maybeSingle() {
        return promise;
      },
      order() {
        return builder;
      },
      then(resolve, reject) {
        return promise.then(resolve, reject);
      },
    };
    return builder;
  }

  const results = {
    tournament_settings: { data: { id: 1 }, error: null },
    teams: { data: [{ id: 1 }], error: null },
    pool_matches: { data: [], error: null },
    bracket_matches: { data: [], error: null },
    team_registrations: { data: [], error: null },
    registration_players: { data: [], error: null },
  };
  const context = {
    state: {
      liveDataState: "ready",
      liveDataMessage: "",
      settings: { poolsFinalized: false },
      teams: [],
      poolMatches: [],
      bracketMatches: [],
      registrations: [],
      registrationPlayers: [],
    },
    sb: { from: (table) => query(results[table]) },
    promiseTimeout: (promise) => promise,
    mapSettings: () => ({ poolsFinalized: false }),
    mapTeam: (row) => row,
    mapPool: (row) => row,
    mapBracket: (row) => row,
    mapRegistration: (row) => row,
    mapRegPlayer: (row) => row,
    activeScore: null,
    $: () => null,
    freezeActiveScoreForPoolChange() {},
    renderLiveDataGuard() {
      guardRenders += 1;
    },
    setSync(...args) {
      syncCalls.push(args);
    },
    renderAll() {},
    markLiveDataError(error) {
      throw error;
    },
    loadConfirmationFromURL: async () => {},
    console,
  };

  vm.runInNewContext(`${extractFunction("loadAll")}; this.loadAll = loadAll;`, context);
  const refresh = context.loadAll({ silent: true });

  assert.equal(context.state.liveDataState, "ready");
  assert.equal(guardRenders, 0);
  assert.equal(
    syncCalls.some(([, text]) => text === "Connecting live data…"),
    false,
  );

  await refresh;
});

test("mobile navigation keeps long labels inside narrow grid cells", () => {
  const start = html.indexOf("/* ONE WAY v40");
  assert.notEqual(start, -1, "mobile navigation styles must exist");
  const mobileNav = html.slice(start, html.indexOf("</style>", start));
  assert.ok(mobileNav.includes("min-width:0;"), "buttons must be shrinkable");
  assert.ok(mobileNav.includes("font-size:clamp("), "labels need responsive type");
});
