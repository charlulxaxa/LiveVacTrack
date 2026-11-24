#!/usr/bin/env node
/**
 * Exports the built-in demo accounts (see DemoAuthService.accounts in
 * lib/data/services/auth_service.dart) to the Firebase project.
 *
 * Works on the free Spark plan: it uses the public Firebase Auth and
 * Firestore REST APIs with the app's API key, so no service account,
 * firebase-admin or Cloud Functions are needed. Each account signs itself up
 * and writes its own users/{uid} profile, which the Firestore rules must
 * allow.
 *
 * Safe to run more than once: an account that already exists is signed in
 * instead, and only its profile fields below are refreshed (disabled/removed
 * flags set by the super admin are kept).
 *
 *   node seed-demo-accounts.js
 *
 * Requires Node 18+ and Email/Password sign-in enabled in the Firebase
 * console (Authentication -> Sign-in method).
 */

const fs = require('fs');
const path = require('path');

// Keep in sync with AppConfig.demoPassword and DemoAuthService.accounts.
const DEMO_PASSWORD = 'demo1234';
const AREAS = {
  poblacion: 'Barangay Poblacion',
  'san-jose': 'Barangay San Jose',
};
const ACCOUNTS = [
  { email: 'admin@livevactrack.test', name: 'Super Admin', role: 'admin', area: 'poblacion' },
  { email: 'registry@livevactrack.test', name: 'Rita Reyes', role: 'registry', area: 'poblacion' },
  { email: 'vet@livevactrack.test', name: 'Dr. Vic Santos', role: 'vet', area: 'poblacion' },
  { email: 'clerk@livevactrack.test', name: 'Carla Dizon', role: 'clerk', area: 'poblacion' },
  { email: 'inspector@livevactrack.test', name: 'Insp. Noel Garcia', role: 'inspector', area: 'san-jose' },
  { email: 'disease@livevactrack.test', name: 'Dr. Maya Lim', role: 'disease_control', area: 'poblacion' },
];

function loadConfig() {
  const file = path.join(__dirname, '..', 'android', 'app', 'google-services.json');
  const json = JSON.parse(fs.readFileSync(file, 'utf8'));
  return {
    projectId: json.project_info.project_id,
    apiKey: json.client[0].api_key[0].current_key,
  };
}

async function post(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    const error = new Error(data.error?.message || response.statusText);
    error.code = data.error?.message;
    throw error;
  }
  return data;
}

async function signUpOrSignIn(apiKey, email, password) {
  const base = 'https://identitytoolkit.googleapis.com/v1/accounts';
  const body = { email, password, returnSecureToken: true };
  try {
    const data = await post(`${base}:signUp?key=${apiKey}`, body);
    return { ...data, created: true };
  } catch (error) {
    if (error.code !== 'EMAIL_EXISTS') throw error;
    const data = await post(`${base}:signInWithPassword?key=${apiKey}`, body);
    return { ...data, created: false };
  }
}

async function setDisplayName(apiKey, idToken, displayName) {
  await post(
    `https://identitytoolkit.googleapis.com/v1/accounts:update?key=${apiKey}`,
    { idToken, displayName, returnSecureToken: false },
  );
}

async function writeProfile(projectId, idToken, uid, account) {
  const fields = {
    displayName: { stringValue: account.name },
    email: { stringValue: account.email },
    role: { stringValue: account.role },
    areaId: { stringValue: account.area },
    areaName: { stringValue: AREAS[account.area] || account.area },
    isDemo: { booleanValue: true },
  };
  const mask = Object.keys(fields)
    .map((f) => `updateMask.fieldPaths=${f}`)
    .join('&');
  const url =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/users/${uid}?${mask}`;
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ fields }),
  });
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error?.message || response.statusText);
  }
}

async function main() {
  const { projectId, apiKey } = loadConfig();
  console.log(`Seeding demo accounts into ${projectId}\n`);

  let failures = 0;
  for (const account of ACCOUNTS) {
    try {
      const auth = await signUpOrSignIn(apiKey, account.email, DEMO_PASSWORD);
      await setDisplayName(apiKey, auth.idToken, account.name);
      await writeProfile(projectId, auth.idToken, auth.localId, account);
      console.log(
        `  ${auth.created ? 'created ' : 'updated '} ${account.email.padEnd(30)} ` +
          `${account.role.padEnd(16)} ${auth.localId}`,
      );
    } catch (error) {
      failures++;
      let hint = '';
      if (error.code === 'OPERATION_NOT_ALLOWED' || /CONFIGURATION_NOT_FOUND/.test(error.message)) {
        hint = ' (enable Authentication -> Email/Password in the Firebase console)';
      } else if (error.code === 'INVALID_LOGIN_CREDENTIALS' || error.code === 'INVALID_PASSWORD') {
        hint = ` (account exists with a password other than ${DEMO_PASSWORD})`;
      }
      console.error(`  FAILED   ${account.email}: ${error.message}${hint}`);
    }
  }

  console.log(`\nPassword for all demo accounts: ${DEMO_PASSWORD}`);
  if (failures > 0) process.exit(1);
}

main();
