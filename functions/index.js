const crypto = require('crypto');
const { initializeApp } = require('firebase-admin/app');
const {
  getFirestore,
  Timestamp,
  FieldValue,
} = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');

initializeApp();
const db = getFirestore();

// The signing secret never reaches the app. Set it with:
//   firebase functions:secrets:set PERMIT_SIGNING_SECRET
// For the emulator, put PERMIT_SIGNING_SECRET=... in functions/.secret.local.
const permitSigningSecret = defineSecret('PERMIT_SIGNING_SECRET');

const STAFF_ROLES = [
  'registry',
  'vet',
  'clerk',
  'inspector',
  'disease_control',
];

// Area ids are PSGC barangay codes in live mode (see the location picker), so
// they are accepted as opaque strings rather than a fixed list.

const MANILA_OFFSET_MS = 8 * 60 * 60 * 1000;

function toDate(value) {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function manilaParts(date) {
  const shifted = new Date(date.getTime() + MANILA_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth(),
    day: shifted.getUTCDate(),
  };
}

/** Midnight in Asia/Manila for the calendar day that contains [date]. */
function startOfManilaDay(date) {
  const parts = manilaParts(date);
  return new Date(Date.UTC(parts.year, parts.month, parts.day) - MANILA_OFFSET_MS);
}

/** 23:59:59.999 in Asia/Manila for the calendar day that contains [date]. */
function endOfManilaDay(date) {
  return new Date(startOfManilaDay(date).getTime() + 24 * 60 * 60 * 1000 - 1);
}

function signingSecret() {
  const value = permitSigningSecret.value();
  if (!value) {
    throw new HttpsError(
      'failed-precondition',
      'The permit signing secret is not configured.',
    );
  }
  return value;
}

/** Must match lib/data/demo/demo_signing.dart (HMAC-SHA256, lowercase hex). */
function signPermitId(permitId) {
  return crypto
    .createHmac('sha256', signingSecret())
    .update(permitId, 'utf8')
    .digest('hex');
}

function signatureMatches(permitId, signedCode) {
  if (typeof signedCode !== 'string' || signedCode.length === 0) return false;
  const expected = signPermitId(permitId);
  const actual = signedCode.trim().toLowerCase();
  if (expected.length !== actual.length) return false;
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(actual));
}

async function roleFor(uid, token) {
  if (token && typeof token.role === 'string' && token.role.length > 0) {
    return token.role;
  }
  const snapshot = await db.collection('users').doc(uid).get();
  return snapshot.exists ? snapshot.get('role') : null;
}

async function requireRole(request, allowedRoles) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  const role = await roleFor(request.auth.uid, request.auth.token);
  if (!allowedRoles.includes(role)) {
    throw new HttpsError(
      'permission-denied',
      'This account is not allowed to perform that action.',
    );
  }
  return { uid: request.auth.uid, role };
}

function permitToResponse(permitId, data) {
  const iso = (value) => {
    const date = toDate(value);
    return date ? date.toISOString() : null;
  };
  return {
    id: permitId,
    animalId: data.animalId,
    farmerId: data.farmerId,
    origin: data.origin,
    destination: data.destination,
    travelDate: iso(data.travelDate),
    requestedBy: data.requestedBy,
    areaId: data.areaId,
    status: data.status,
    signedCode: data.signedCode,
    validUntil: iso(data.validUntil),
    issuedAt: iso(data.issuedAt),
    createdAt: iso(data.createdAt),
  };
}

// --------------------------------------------------------------- issuePermit

exports.issuePermit = onCall(
  { secrets: [permitSigningSecret] },
  async (request) => {
    const { uid } = await requireRole(request, ['clerk']);

    const data = request.data || {};
    const animalId = typeof data.animalId === 'string' ? data.animalId : '';
    const origin = typeof data.origin === 'string' ? data.origin.trim() : '';
    const destination =
      typeof data.destination === 'string' ? data.destination.trim() : '';
    const travelDate = toDate(data.travelDate);

    if (!animalId || !origin || !destination || !travelDate) {
      throw new HttpsError(
        'invalid-argument',
        'animalId, origin, destination and travelDate are required.',
      );
    }

    const today = startOfManilaDay(new Date());
    if (startOfManilaDay(travelDate) < today) {
      throw new HttpsError(
        'failed-precondition',
        'The travel date cannot be in the past.',
      );
    }

    const animalRef = db.collection('animals').doc(animalId);
    const animalSnapshot = await animalRef.get();
    if (!animalSnapshot.exists) {
      throw new HttpsError('not-found', 'That animal is not registered.');
    }
    const animal = animalSnapshot.data();

    const vaccinatedUntil = toDate(animal.vaccinatedUntil);
    const vaccinatedForTravel =
      animal.vaxStatus === 'valid' &&
      vaccinatedUntil !== null &&
      startOfManilaDay(vaccinatedUntil) >= startOfManilaDay(travelDate);

    if (!vaccinatedForTravel) {
      throw new HttpsError(
        'failed-precondition',
        'The animal is not vaccinated for the selected travel date.',
      );
    }

    const activeQuarantine = await db
      .collection('quarantines')
      .where('areaId', '==', animal.areaId)
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (!activeQuarantine.empty) {
      throw new HttpsError(
        'failed-precondition',
        `${animal.barangay} is under an active quarantine. New permits are blocked.`,
      );
    }

    const permitId = `PMT-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
    const validUntil = new Date(
      Math.min(
        endOfManilaDay(travelDate).getTime(),
        endOfManilaDay(vaccinatedUntil).getTime(),
      ),
    );
    const now = new Date();

    const permit = {
      animalId,
      farmerId: animal.farmerId || '',
      origin,
      destination,
      travelDate: Timestamp.fromDate(startOfManilaDay(travelDate)),
      requestedBy: uid,
      areaId: animal.areaId || '',
      status: 'issued',
      signedCode: signPermitId(permitId),
      validUntil: Timestamp.fromDate(validUntil),
      issuedAt: Timestamp.fromDate(now),
      createdAt: Timestamp.fromDate(now),
    };

    await db.collection('permits').doc(permitId).set(permit);

    return {
      permitId,
      permit: permitToResponse(permitId, permit),
    };
  },
);

// -------------------------------------------------------------- verifyPermit

exports.verifyPermit = onCall(
  { secrets: [permitSigningSecret] },
  async (request) => {
    const { uid } = await requireRole(request, STAFF_ROLES);

  const data = request.data || {};
  const permitId = typeof data.permitId === 'string' ? data.permitId.trim() : '';
  const signedCode =
    typeof data.signedCode === 'string' ? data.signedCode.trim() : '';
  const checkpointName =
    typeof data.checkpointName === 'string' && data.checkpointName.trim()
      ? data.checkpointName.trim()
      : 'Unnamed checkpoint';

  if (!permitId || !signedCode) {
    throw new HttpsError(
      'invalid-argument',
      'permitId and signedCode are required.',
    );
  }

  const checkedAt = new Date();
  const snapshot = await db.collection('permits').doc(permitId).get();

  let result;
  let message;
  let signatureValid = false;
  let permit = null;

  if (!snapshot.exists) {
    result = 'invalid';
    message = 'No permit with that ID exists in the registry.';
  } else {
    const dataMap = snapshot.data();
    permit = permitToResponse(permitId, dataMap);
    signatureValid = signatureMatches(permitId, signedCode);

    const validUntil = toDate(dataMap.validUntil);
    if (!signatureValid) {
      result = 'invalid';
      message = 'The signed code does not match. This permit may be forged.';
    } else if (dataMap.status === 'revoked') {
      result = 'revoked';
      message = 'This permit was revoked by a quarantine or the permit office.';
    } else if (validUntil === null || validUntil.getTime() < checkedAt.getTime()) {
      result = 'expired';
      message = 'This permit is past its valid-until date.';
    } else {
      result = 'valid';
      message = 'Signed code verified. The permit is genuine and still valid.';
    }
  }

  await db.collection('verifications').add({
    permitId,
    animalId: permit ? (permit.animalId || '') : '',
    result,
    inspectorUid: uid,
    checkpointName,
    scannedAt: Timestamp.fromDate(checkedAt),
    wasOffline: false,
    signatureValid,
  });

  return {
    result,
    message,
    signatureValid,
    checkedAt: checkedAt.toISOString(),
    permitId,
    permit,
  };
  },
);

// --------------------------------------------------------- declareQuarantine

exports.declareQuarantine = onCall(async (request) => {
  const { uid } = await requireRole(request, ['disease_control']);

  const data = request.data || {};
  const areaId = typeof data.areaId === 'string' ? data.areaId.trim() : '';
  const areaName =
    typeof data.areaName === 'string' && data.areaName.trim()
      ? data.areaName.trim()
      : areaId;
  const reason = typeof data.reason === 'string' ? data.reason.trim() : '';

  if (!areaId || !reason) {
    throw new HttpsError(
      'invalid-argument',
      'areaId and reason are required.',
    );
  }

  const existing = await db
    .collection('quarantines')
    .where('areaId', '==', areaId)
    .where('status', '==', 'active')
    .limit(1)
    .get();

  if (!existing.empty) {
    throw new HttpsError(
      'already-exists',
      'That area already has an active quarantine.',
    );
  }

  const now = new Date();
  const quarantineRef = db.collection('quarantines').doc();

  const affected = await db
    .collection('permits')
    .where('areaId', '==', areaId)
    .where('status', '==', 'issued')
    .get();

  const batch = db.batch();
  batch.set(quarantineRef, {
    areaId,
    areaName,
    reason,
    status: 'active',
    startedAt: Timestamp.fromDate(now),
    declaredBy: uid,
    sourceMessageId: null,
    createdAt: FieldValue.serverTimestamp(),
  });

  for (const doc of affected.docs) {
    batch.update(doc.ref, {
      status: 'revoked',
      revokedAt: Timestamp.fromDate(now),
      revokedReason: 'quarantine',
    });
  }

  await batch.commit();

  return { revokedCount: affected.size, quarantineId: quarantineRef.id };
});

// ----------------------------------------------------- createStaffAccount

/**
 * Creates a staff account (Auth user + users/{uid} document + role claim).
 * Restricted to the super admin and registry office.
 */
exports.createStaffAccount = onCall(async (request) => {
  await requireRole(request, ['admin']);

  const data = request.data || {};
  const email =
    typeof data.email === 'string' ? data.email.trim().toLowerCase() : '';
  const password = typeof data.password === 'string' ? data.password : '';
  const displayName =
    typeof data.displayName === 'string' ? data.displayName.trim() : '';
  const role = typeof data.role === 'string' ? data.role : '';
  const areaId = typeof data.areaId === 'string' ? data.areaId.trim() : '';
  const areaName =
    typeof data.areaName === 'string' && data.areaName.trim()
      ? data.areaName.trim()
      : areaId;

  if (!email || !password || !displayName || !role || !areaId) {
    throw new HttpsError(
      'invalid-argument',
      'email, password, displayName, role and areaId are required.',
    );
  }
  if (!STAFF_ROLES.includes(role)) {
    throw new HttpsError(
      'invalid-argument',
      `role must be one of: ${STAFF_ROLES.join(', ')}.`,
    );
  }
  if (areaId.length > 20) {
    throw new HttpsError('invalid-argument', 'areaId is not valid.');
  }
  if (password.length < 8) {
    throw new HttpsError(
      'invalid-argument',
      'Password must be at least 8 characters.',
    );
  }

  let userRecord;
  try {
    userRecord = await getAuth().createUser({
      email,
      password,
      displayName,
      emailVerified: true,
    });
  } catch (error) {
    if (error && error.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'That email is already registered.');
    }
    if (error && error.code === 'auth/invalid-email') {
      throw new HttpsError('invalid-argument', 'That email address is not valid.');
    }
    if (error && error.code === 'auth/invalid-password') {
      throw new HttpsError('invalid-argument', error.message || 'Invalid password.');
    }
    throw new HttpsError('internal', 'Could not create the account.');
  }

  await db.collection('users').doc(userRecord.uid).set({
    displayName,
    role,
    areaId,
    areaName,
    createdAt: FieldValue.serverTimestamp(),
  });

  await getAuth().setCustomUserClaims(userRecord.uid, { role });

  return {
    uid: userRecord.uid,
    email,
    displayName,
    role,
    areaId,
    areaName,
  };
});

// -------------------------------------------------------- Firestore triggers

/** Keeps the animal's cached vaccination window in step with new records. */
exports.onVaccinationCreated = onDocumentCreated(
  'vaccinations/{vaccinationId}',
  async (event) => {
    const vaccination = event.data ? event.data.data() : null;
    if (!vaccination || !vaccination.animalId) return;

    const until = toDate(vaccination.validUntil);
    if (!until) return;

    const animalRef = db.collection('animals').doc(vaccination.animalId);
    const animal = await animalRef.get();
    if (!animal.exists) return;

    const current = toDate(animal.get('vaccinatedUntil'));
    if (current && current.getTime() >= until.getTime()) return;

    await animalRef.update({
      vaxStatus: 'valid',
      vaccinatedUntil: Timestamp.fromDate(until),
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

/** Safety net: a quarantine written directly also revokes issued permits. */
exports.onQuarantineCreated = onDocumentCreated(
  'quarantines/{quarantineId}',
  async (event) => {
    const quarantine = event.data ? event.data.data() : null;
    if (!quarantine || !quarantine.areaId) return;
    if (quarantine.status !== 'active') return;

    const affected = await db
      .collection('permits')
      .where('areaId', '==', quarantine.areaId)
      .where('status', '==', 'issued')
      .get();

    if (affected.empty) return;

    const batch = db.batch();
    for (const doc of affected.docs) {
      batch.update(doc.ref, {
        status: 'revoked',
        revokedAt: FieldValue.serverTimestamp(),
        revokedReason: 'quarantine',
      });
    }
    await batch.commit();
  },
);

/** Daily: mark animals whose vaccination window has closed as expired. */
exports.refreshVaccinationStatus = onSchedule(
  { schedule: 'every day 00:05', timeZone: 'Asia/Manila' },
  async () => {
    const now = Timestamp.now();
    const snapshot = await db
      .collection('animals')
      .where('vaxStatus', '==', 'valid')
      .where('vaccinatedUntil', '<', now)
      .get();

    if (snapshot.empty) return;

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.update(doc.ref, {
        vaxStatus: 'expired',
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  },
);
