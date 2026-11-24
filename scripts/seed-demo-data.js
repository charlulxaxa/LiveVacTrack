#!/usr/bin/env node
/**
 * Exports the demo records (farmers, animals, vaccinations, permits,
 * quarantines, checkpoint verifications) from lib/data/demo/demo_seed.dart
 * to Firestore, so live mode starts with the same data as demo mode.
 *
 * Works on the free Spark plan: it signs in with the demo accounts through
 * the public Auth REST API and writes through the Firestore REST API. Run
 * seed-demo-accounts.js first so those accounts exist.
 *
 *   node seed-demo-data.js           # add records that are missing
 *   node seed-demo-data.js --reset   # overwrite the demo records with fresh
 *                                    # copies (dates are relative to today)
 *
 * Demo user ids such as "u-vet" are replaced with the real Firebase UIDs of
 * the matching demo accounts. Records are keyed by the same ids as demo mode
 * (f1, a1, v1, PMT-1001, q1, ver1), so re-running never duplicates them.
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Keep in sync with AppConfig.demoPassword / AppConfig.demoSigningSecret.
const DEMO_PASSWORD = 'demo1234';
const DEMO_SIGNING_SECRET = 'livevactrack-demo-secret';

const DEMO_EMAILS = {
  'u-admin': 'admin@livevactrack.test',
  'u-registry': 'registry@livevactrack.test',
  'u-vet': 'vet@livevactrack.test',
  'u-clerk': 'clerk@livevactrack.test',
  'u-inspector': 'inspector@livevactrack.test',
  'u-disease': 'disease@livevactrack.test',
};

const reset = process.argv.includes('--reset');

function loadConfig() {
  const file = path.join(__dirname, '..', 'android', 'app', 'google-services.json');
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  return {
    projectId: json.project_info.project_id,
    apiKey: json.client[0].api_key[0].current_key,
  };
}

// ------------------------------------------------------------------ dates

const now = new Date();
const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
const DAY = 24 * 60 * 60 * 1000;
const HOUR = 60 * 60 * 1000;
const days = (n) => new Date(today.getTime() + n * DAY);
const hoursAgo = (n) => new Date(today.getTime() - n * HOUR);
const nowMinus = (ms) => new Date(now.getTime() - ms);

const sign = (permitId) =>
  crypto.createHmac('sha256', DEMO_SIGNING_SECRET).update(permitId).digest('hex');

// ------------------------------------------------- data (mirrors demo_seed)

function buildData(uid) {
  const farmers = [
    ['f1', 'Maria Santos', 'Poblacion', 'poblacion', '0917 000 0001', -120],
    ['f2', 'Jose Dela Cruz', 'San Jose', 'san-jose', '0917 000 0002', -110],
    ['f3', 'Ana Reyes', 'Sta. Cruz', 'sta-cruz', '0917 000 0003', -95],
    ['f4', 'Pedro Bautista', 'Poblacion', 'poblacion', '0917 000 0004', -80],
    ['f5', 'Liza Mendoza', 'San Jose', 'san-jose', '0917 000 0005', -60],
  ].map(([id, fullName, barangay, areaId, contactNo, created]) => ({
    id,
    data: {
      fullName, barangay, areaId, contactNo,
      registeredBy: uid('u-registry'),
      createdAt: days(created),
    },
  }));

  const farmerById = Object.fromEntries(farmers.map((f) => [f.id, f.data]));

  // id, tagNo, species, breed, farmerId, vaxStatus, vaccinatedUntil(days), registeredAt(days)
  const animals = [
    ['a1', 'LV-001', 'Cattle', 'Brahman', 'f1', 'valid', 180, -120],
    ['a2', 'LV-002', 'Cattle', 'Holstein', 'f2', 'valid', 45, -110],
    ['a3', 'LV-003', 'Goat', 'Boer', 'f3', 'expired', -12, -95],
    ['a4', 'LV-004', 'Carabao', 'Murrah', 'f1', 'none', null, -90],
    ['a5', 'LV-005', 'Swine', 'Landrace', 'f4', 'valid', 90, -80],
    ['a6', 'LV-006', 'Goat', 'Nubian', 'f5', 'valid', 8, -60],
    ['a7', 'LV-007', 'Cattle', 'Brahman', 'f2', 'expired', -60, -150],
    ['a8', 'LV-008', 'Swine', 'Duroc', 'f3', 'valid', 120, -70],
    ['a9', 'LV-009', 'Carabao', 'Philippine Carabao', 'f5', 'none', null, -45],
    ['a10', 'LV-010', 'Goat', 'Anglo-Nubian', 'f4', 'valid', 200, -30],
  ].map(([id, tagNo, species, breed, farmerId, vaxStatus, until, registered]) => {
    const farmer = farmerById[farmerId];
    return {
      id,
      data: {
        tagNo, species, breed, farmerId,
        farmerName: farmer.fullName,
        barangay: farmer.barangay,
        areaId: farmer.areaId,
        vaxStatus,
        vaccinatedUntil: until === null ? null : days(until),
        registeredBy: uid('u-registry'),
        registeredAt: days(registered),
      },
    };
  });

  const vaccinations = [
    ['v1', 'a1', 'FMD Vaccine', 'FMD-2026-01', -10, 180],
    ['v2', 'a2', 'FMD Vaccine', 'FMD-2026-02', -30, 45],
    ['v3', 'a5', 'Hog Cholera Vaccine', 'HC-2026-11', -5, 90],
    ['v4', 'a6', 'PPR Vaccine', 'PPR-2026-07', -20, 8],
    ['v5', 'a8', 'FMD Vaccine', 'FMD-2026-03', -15, 120],
    ['v6', 'a10', 'PPR Vaccine', 'PPR-2026-08', -7, 200],
  ].map(([id, animalId, vaccineName, batchNo, given, until]) => ({
    id,
    data: {
      animalId, vaccineName, batchNo,
      dateGiven: days(given),
      validUntil: days(until),
      vetUid: uid('u-vet'),
      vetName: 'Dr. Vic Santos',
      createdAt: days(given),
    },
  }));

  // id, animalId, farmerId, origin, destination, travelDate(days), areaId, status, validUntil(days), issuedAt
  const permits = [
    ['PMT-1001', 'a1', 'f1', 'Poblacion', 'Legazpi City', 2, 'poblacion', 'issued', 180, hoursAgo(5)],
    ['PMT-1002', 'a2', 'f2', 'San Jose', 'Legazpi City', 1, 'san-jose', 'revoked', 45, days(-3)],
    ['PMT-1003', 'a5', 'f4', 'Poblacion', 'Daraga', -3, 'poblacion', 'issued', -5, days(-6)],
    ['PMT-1004', 'a6', 'f5', 'San Jose', 'Legazpi City', 1, 'san-jose', 'revoked', 8, days(-1)],
    ['PMT-1005', 'a8', 'f3', 'Sta. Cruz', 'Legazpi City', 5, 'sta-cruz', 'issued', 120, hoursAgo(20)],
    ['PMT-1006', 'a10', 'f4', 'Poblacion', 'Sorsogon', 3, 'poblacion', 'issued', 200, hoursAgo(2)],
  ].map(([id, animalId, farmerId, origin, destination, travel, areaId, status, until, issuedAt]) => ({
    id,
    data: {
      animalId, farmerId, origin, destination,
      travelDate: days(travel),
      requestedBy: uid('u-clerk'),
      areaId, status,
      signedCode: sign(id),
      validUntil: days(until),
      issuedAt,
      createdAt: issuedAt,
    },
  }));

  const quarantines = [
    {
      id: 'q1',
      data: {
        areaId: 'san-jose',
        areaName: 'Barangay San Jose',
        reason: 'Suspected African Swine Fever detected in the barangay.',
        status: 'active',
        startedAt: days(-2),
        declaredBy: uid('u-disease'),
        sourceMessageId: 'das-2026-001',
      },
    },
    {
      id: 'q2',
      data: {
        areaId: 'poblacion',
        areaName: 'Barangay Poblacion',
        reason: 'Routine surveillance; no positive cases found.',
        status: 'lifted',
        startedAt: days(-30),
        liftedAt: days(-20),
        declaredBy: uid('u-disease'),
        sourceMessageId: 'das-2026-000',
      },
    },
  ];

  const verifications = [
    ['ver1', 'PMT-1001', 'a1', 'valid', nowMinus(DAY)],
    ['ver2', 'PMT-1002', 'a2', 'revoked', nowMinus(2 * HOUR)],
  ].map(([id, permitId, animalId, result, scannedAt]) => ({
    id,
    data: {
      permitId, animalId, result,
      inspectorUid: uid('u-inspector'),
      checkpointName: 'San Jose Checkpoint',
      scannedAt,
      wasOffline: false,
      signatureValid: true,
    },
  }));

  return { farmers, animals, vaccinations, permits, quarantines, verifications };
}

// --------------------------------------------------------------- REST calls

function toValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  return { stringValue: String(value) };
}

async function signIn(apiKey, email) {
  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password: DEMO_PASSWORD, returnSecureToken: true }),
    },
  );
  const data = await response.json();
  if (!response.ok) {
    throw new Error(
      `Could not sign in as ${email}: ${data.error?.message}. ` +
        'Run "node seed-demo-accounts.js" first.',
    );
  }
  return data;
}

async function writeDoc(projectId, idToken, collection, id, data) {
  const fields = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, toValue(v)]),
  );
  let url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/${collection}/${encodeURIComponent(id)}`;
  if (!reset) url += '?currentDocument.exists=false';

  const response = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
    body: JSON.stringify({ fields }),
  });
  if (response.ok) return reset ? 'written' : 'added';
  const body = await response.json().catch(() => ({}));
  if (body.error?.status === 'FAILED_PRECONDITION' || body.error?.status === 'ALREADY_EXISTS') {
    return 'kept';
  }
  throw new Error(`${collection}/${id}: ${body.error?.message || response.statusText}`);
}

async function main() {
  const { projectId, apiKey } = loadConfig();
  console.log(`Seeding demo data into ${projectId}${reset ? ' (reset)' : ''}\n`);

  const uids = {};
  let adminToken = null;
  for (const [demoId, email] of Object.entries(DEMO_EMAILS)) {
    const auth = await signIn(apiKey, email);
    uids[demoId] = auth.localId;
    if (demoId === 'u-admin') adminToken = auth.idToken;
  }
  const uid = (demoId) => uids[demoId];

  const data = buildData(uid);
  let failures = 0;
  for (const [collection, docs] of Object.entries(data)) {
    const counts = { added: 0, written: 0, kept: 0 };
    for (const doc of docs) {
      try {
        counts[await writeDoc(projectId, adminToken, collection, doc.id, doc.data)]++;
      } catch (error) {
        failures++;
        console.error(`  FAILED ${error.message}`);
      }
    }
    const summary = reset
      ? `${counts.written} written`
      : `${counts.added} added, ${counts.kept} already there`;
    console.log(`  ${collection.padEnd(14)} ${summary}`);
  }

  if (failures > 0) process.exit(1);
  console.log('\nDone.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
