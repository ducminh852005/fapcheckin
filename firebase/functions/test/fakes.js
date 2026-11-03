// Firestore Admin giả lập trong bộ nhớ, đủ cho các hàm thông báo/nhắc lịch/góp ý.
export function fakeDb(initial = {}) {
  const store = new Map(Object.entries(initial)); // path -> data

  const docRef = (path) => ({
    id: path.split('/').pop(),
    path,
    get: async () => ({ id: path.split('/').pop(), exists: store.has(path), data: () => store.get(path), ref: docRef(path) }),
    create: async (data) => {
      if (store.has(path)) {
        const e = new Error('6 ALREADY_EXISTS: Document already exists');
        e.code = 6;
        throw e;
      }
      store.set(path, { ...data });
    },
    set: async (data) => { store.set(path, { ...data }); },
    update: async (data) => {
      if (!store.has(path)) { const e = new Error('5 NOT_FOUND'); e.code = 5; throw e; }
      store.set(path, { ...store.get(path), ...data });
    },
    delete: async () => { store.delete(path); },
  });

  const query = (path, filters = []) => ({
    doc: (id) => docRef(`${path}/${id}`),
    where: (field, op, value) => {
      if (op !== '==') throw new Error(`fake chỉ hỗ trợ ==, nhận ${op}`);
      return query(path, [...filters, [field, value]]);
    },
    get: async () => {
      const depth = path.split('/').length + 1;
      const docs = [...store.entries()]
        .filter(([p]) => p.startsWith(`${path}/`) && p.split('/').length === depth)
        .filter(([, d]) => filters.every(([f, v]) => d?.[f] === v))
        .map(([p, d]) => ({ id: p.split('/').pop(), data: () => d, ref: docRef(p) }));
      return { docs, empty: docs.length === 0 };
    },
  });

  const batch = () => {
    const ops = [];
    return {
      update: (ref, data) => ops.push(() => ref.update(data)),
      set: (ref, data) => ops.push(() => ref.set(data)),
      commit: async () => {
        for (const op of ops) await op();
      },
    };
  };

  return { store, doc: docRef, collection: (path) => query(path), batch };
}

export function fakeMessaging(failures = {}) {
  const sent = [];
  return {
    sent,
    sendEachForMulticast: async (msg) => {
      sent.push(msg);
      return {
        responses: msg.tokens.map((t) => (failures[t]
          ? { success: false, error: { code: failures[t] } }
          : { success: true })),
      };
    },
  };
}

export function deps(db, messaging = null) {
  return {
    db,
    messaging,
    serverTimestamp: () => 'SERVER_TS',
    toTimestamp: (d) => d.toISOString(),
    log: () => {},
  };
}
