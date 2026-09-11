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

test("first Realtime subscription performs a silent catch-up fetch", async () => {
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
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
    realtimeCatchUpGeneration: 0,
    realtimeCatchUpQueue: [],
    realtimeCatchUpPromise: Promise.resolve(),
    setSync() {},
    loadAll(options) {
      loadCalls.push(options);
    },
    console,
  };
  const optionalHelpers = [
    "runRealtimeUpdate",
    "finishRealtimeCatchUp",
    "withRealtimeCatchUp",
  ]
    .filter((name) => html.includes(`function ${name}(`))
    .map(extractFunction)
    .join(";");

  vm.runInNewContext(
    `${optionalHelpers};${extractFunction("subscribeRealtime")}; subscribeRealtime();`,
    context,
  );
  await statusCallback("SUBSCRIBED");

  assert.equal(loadCalls.length, 1, "SUBSCRIBED must close the snapshot-to-stream gap");
  assert.deepEqual(
    structuredClone(loadCalls[0]),
    { silent: true },
    "catch-up fetch must not reset ready UI to loading",
  );
});

test("overlapping SUBSCRIBED callbacks serialize catch-up loads", async () => {
  let statusCallback;
  const releases = [];
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
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
    realtimeCatchUpGeneration: 0,
    realtimeCatchUpQueue: [],
    realtimeCatchUpPromise: Promise.resolve(),
    setSync() {},
    loadAll() {
      let release;
      const promise = new Promise((resolve) => {
        release = resolve;
      });
      releases.push(release);
      loadCalls.push(promise);
      return promise;
    },
    console,
  };
  const helpers = [
    "runRealtimeUpdate",
    "finishRealtimeCatchUp",
    "withRealtimeCatchUp",
  ]
    .map(extractFunction)
    .join(";");

  vm.runInNewContext(
    `${helpers};${extractFunction("subscribeRealtime")}; subscribeRealtime();`,
    context,
  );

  const first = statusCallback("SUBSCRIBED");
  const second = statusCallback("SUBSCRIBED");
  await Promise.resolve();
  assert.equal(loadCalls.length, 1, "second catch-up must wait for the first");

  releases[0]();
  await first;
  await Promise.resolve();
  assert.equal(loadCalls.length, 2);

  releases[1]();
  await second;
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
    liveDataLoadGeneration: 0,
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
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

test("older load completion cannot overwrite a newer snapshot", async () => {
  const releases = [];
  let coreBatch = -1;

  function coreQuery(table, batch) {
    const builder = {
      select() {
        return builder;
      },
      eq() {
        return builder;
      },
      maybeSingle() {
        return builder;
      },
      order() {
        return builder;
      },
      then(resolve, reject) {
        return releases[batch].promise
          .then(() => {
            if (table === "tournament_settings") {
              return { data: { batch, poolsFinalized: false }, error: null };
            }
            if (table === "teams") {
              return { data: [{ id: 1, batch }], error: null };
            }
            return { data: [], error: null };
          })
          .then(resolve, reject);
      },
    };
    return builder;
  }

  function immediateQuery() {
    const result = Promise.resolve({ data: [], error: null });
    const builder = {
      select() {
        return builder;
      },
      order() {
        return builder;
      },
      then(resolve, reject) {
        return result.then(resolve, reject);
      },
    };
    return builder;
  }

  const context = {
    liveDataLoadGeneration: 0,
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
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
    sb: {
      from(table) {
        if (table === "tournament_settings") {
          coreBatch += 1;
          let release;
          const promise = new Promise((resolve) => {
            release = resolve;
          });
          releases.push({ promise, release });
        }
        if (["team_registrations", "registration_players"].includes(table)) {
          return immediateQuery();
        }
        return coreQuery(table, coreBatch);
      },
    },
    promiseTimeout: (promise) => promise,
    mapSettings: (row) => row,
    mapTeam: (row) => row,
    mapPool: (row) => row,
    mapBracket: (row) => row,
    mapRegistration: (row) => row,
    mapRegPlayer: (row) => row,
    activeScore: null,
    $: () => null,
    freezeActiveScoreForPoolChange() {},
    renderLiveDataGuard() {},
    setSync() {},
    renderAll() {},
    markLiveDataError(error) {
      throw error;
    },
    loadConfirmationFromURL: async () => {},
    console,
  };

  vm.runInNewContext(`${extractFunction("loadAll")}; this.loadAll = loadAll;`, context);
  const older = context.loadAll({ silent: true });
  const newer = context.loadAll({ silent: true });

  releases[1].release();
  await newer;
  assert.equal(context.state.teams[0].batch, 1);

  releases[0].release();
  await older;
  assert.equal(
    context.state.teams[0].batch,
    1,
    "late completion from the older load must be ignored",
  );
});

test("Realtime changes received during catch-up win over the REST snapshot", async () => {
  let statusCallback;
  const tableCallbacks = {};
  let releaseSnapshot;
  const snapshotReady = new Promise((resolve) => {
    releaseSnapshot = resolve;
  });
  const channel = {
    on(_event, filter, callback) {
      tableCallbacks[filter.table] = callback;
      return this;
    },
    subscribe(callback) {
      statusCallback = callback;
      return this;
    },
  };
  const context = {
    sb: { channel: () => channel },
    state: {
      liveDataState: "ready",
      teams: [{ id: 1, score: 9 }],
      poolMatches: [],
      bracketMatches: [],
      settings: {},
    },
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
    realtimeCatchUpGeneration: 0,
    realtimeCatchUpQueue: [],
    realtimeCatchUpPromise: Promise.resolve(),
    mapTeam: (row) => ({ ...row }),
    mapPool: (row) => ({ ...row }),
    mapBracket: (row) => ({ ...row }),
    renderAll() {},
    setSync() {},
    markLiveDataError(error) {
      throw error;
    },
    $: () => null,
    activeScore: null,
    activeConfirmationToken: null,
    freezeActiveScoreForPoolChange() {},
    refreshRegistrations: async () => {},
    loadConfirmationFromURL: async () => {},
    console,
  };
  context.loadAll = async () => {
    await snapshotReady;
    context.state.teams = [{ id: 1, score: 10 }];
  };
  const optionalHelpers = [
    "runRealtimeUpdate",
    "finishRealtimeCatchUp",
    "withRealtimeCatchUp",
  ]
    .filter((name) => html.includes(`function ${name}(`))
    .map(extractFunction)
    .join(";");

  vm.runInNewContext(
    `${optionalHelpers};${extractFunction("subscribeRealtime")}; subscribeRealtime();`,
    context,
  );

  const catchUp = statusCallback("SUBSCRIBED");
  tableCallbacks.teams({ eventType: "UPDATE", new: { id: 1, score: 11 } });
  releaseSnapshot();
  await Promise.resolve(catchUp);
  await Promise.resolve();

  assert.equal(
    context.state.teams[0].score,
    11,
    "queued Realtime update must be replayed after the REST snapshot",
  );
});

test("Realtime rows newer than a winning snapshot survive a stale catch-up", async () => {
  let statusCallback;
  let teamCallback;
  let releaseCatchUp;
  const catchUpReady = new Promise((resolve) => {
    releaseCatchUp = resolve;
  });
  const channel = {
    on(_event, filter, callback) {
      if (filter.table === "teams") teamCallback = callback;
      return this;
    },
    subscribe(callback) {
      statusCallback = callback;
      return this;
    },
  };
  const context = {
    sb: { channel: () => channel },
    state: {
      liveDataState: "ready",
      teams: [{ id: 1, score: 10 }],
      poolMatches: [],
      bracketMatches: [],
      settings: {},
    },
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
    realtimeCatchUpGeneration: 0,
    realtimeCatchUpQueue: [],
    realtimeCatchUpPromise: Promise.resolve(),
    mapTeam: (row) => ({ ...row }),
    mapPool: (row) => ({ ...row }),
    mapBracket: (row) => ({ ...row }),
    renderAll() {},
    setSync() {},
    markLiveDataError(error) {
      throw error;
    },
    $: () => null,
    activeScore: null,
    activeConfirmationToken: null,
    freezeActiveScoreForPoolChange() {},
    refreshRegistrations: async () => {},
    loadConfirmationFromURL: async () => {},
    loadAll: async () => {
      await catchUpReady;
    },
    console,
  };
  const helpers = [
    "runRealtimeUpdate",
    "finishRealtimeCatchUp",
    "withRealtimeCatchUp",
  ]
    .map(extractFunction)
    .join(";");

  vm.runInNewContext(
    `${helpers};${extractFunction("subscribeRealtime")}; subscribeRealtime();`,
    context,
  );

  const catchUp = statusCallback("SUBSCRIBED");
  teamCallback({ eventType: "UPDATE", new: { id: 1, score: 11 } });

  // A retry/admin load outside the catch-up wins and commits its own snapshot.
  context.state.teams = [{ id: 1, score: 12 }];
  context.appliedSnapshotSequence = context.realtimeEventSequence;

  teamCallback({ eventType: "UPDATE", new: { id: 1, score: 13 } });
  releaseCatchUp();
  await catchUp;

  assert.equal(
    context.state.teams[0].score,
    13,
    "an event received after the winning snapshot must not be discarded",
  );
});

test("Realtime registration rows apply without a blocking refetch", async () => {
  let statusCallback;
  const tableCallbacks = {};
  let refreshCalls = 0;
  const channel = {
    on(_event, filter, callback) {
      tableCallbacks[filter.table] = callback;
      return this;
    },
    subscribe(callback) {
      statusCallback = callback;
      return this;
    },
  };
  const context = {
    sb: { channel: () => channel },
    state: {
      liveDataState: "ready",
      teams: [],
      poolMatches: [],
      bracketMatches: [],
      registrations: [],
      registrationPlayers: [],
      settings: {},
    },
    realtimeEventSequence: 0,
    appliedSnapshotSequence: 0,
    realtimeCatchUpGeneration: 0,
    realtimeCatchUpQueue: [],
    realtimeCatchUpPromise: Promise.resolve(),
    mapTeam: (row) => row,
    mapPool: (row) => row,
    mapBracket: (row) => row,
    mapRegistration: (row) => ({ id: row.id, teamName: row.team_name }),
    mapRegPlayer: (row) => ({
      id: row.id,
      registrationId: row.registration_id,
      playerNumber: row.player_number,
    }),
    renderAll() {},
    setSync() {},
    markLiveDataError(error) {
      throw error;
    },
    $: () => null,
    activeScore: null,
    activeConfirmationToken: null,
    freezeActiveScoreForPoolChange() {},
    refreshRegistrations: async () => {
      refreshCalls += 1;
    },
    loadConfirmationFromURL: async () => {},
    loadAll: async () => {},
    console,
  };
  const helpers = [
    "runRealtimeUpdate",
    "finishRealtimeCatchUp",
    "withRealtimeCatchUp",
  ]
    .map(extractFunction)
    .join(";");

  vm.runInNewContext(
    `${helpers};${extractFunction("subscribeRealtime")}; subscribeRealtime();`,
    context,
  );

  await tableCallbacks.team_registrations({
    eventType: "INSERT",
    new: { id: 4, team_name: "Grass Team" },
  });
  await tableCallbacks.registration_players({
    eventType: "INSERT",
    new: { id: 9, registration_id: 4, player_number: 1 },
  });

  assert.equal(refreshCalls, 0);
  assert.equal(context.state.registrations[0].teamName, "Grass Team");
  assert.equal(context.state.registrationPlayers[0].registrationId, 4);
  assert.equal(typeof statusCallback, "function");
});

test("registration and pool builder distinguish connecting from failure", () => {
  const elements = new Map();
  const element = (id) => {
    if (!elements.has(id)) {
      elements.set(id, {
        classList: { add() {} },
        disabled: false,
        innerHTML: "",
        textContent: "",
      });
    }
    return elements.get(id);
  };
  const context = {
    state: {
      liveDataState: "loading",
      registrations: [],
      registrationPlayers: [],
      settings: {},
    },
    $: element,
  };

  vm.runInNewContext(
    `${extractFunction("renderRegistrations")};${extractFunction("renderPoolBuilder")}`,
    context,
  );

  context.renderRegistrations();
  context.renderPoolBuilder();

  assert.equal(element("registrationCount").textContent, "Connecting live data…");
  assert.match(element("registrationPublicList").innerHTML, /connecting/i);
  assert.match(element("poolBuilderStatus").innerHTML, /connecting/i);
  assert.doesNotMatch(element("poolPreviewMessage").textContent, /Retry Live Data/i);
  assert.equal(element("regTeamName").disabled, true);
  assert.equal(element("previewPoolsBtn").disabled, true);

  context.state.liveDataState = "error";
  context.renderRegistrations();
  context.renderPoolBuilder();

  assert.equal(element("registrationCount").textContent, "Live data unavailable");
  assert.match(element("registrationPublicList").innerHTML, /reconnect/i);
  assert.match(element("poolBuilderStatus").innerHTML, /unavailable/i);
  assert.match(element("poolPreviewMessage").textContent, /Retry Live Data/i);
});

test("mobile navigation keeps long labels inside narrow grid cells", () => {
  const start = html.indexOf("/* ONE WAY v40");
  assert.notEqual(start, -1, "mobile navigation styles must exist");
  const mobileNav = html.slice(start, html.indexOf("</style>", start));
  assert.ok(mobileNav.includes("min-width:0;"), "buttons must be shrinkable");
  assert.ok(mobileNav.includes("font-size:clamp("), "labels need responsive type");
});
