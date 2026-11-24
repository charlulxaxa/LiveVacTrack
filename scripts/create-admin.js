#!/usr/bin/env node
/**
 * Creates an official super admin account (Firebase Auth sign-in plus a
 * users/{uid} profile with role "admin"). Works on the free Spark plan.
 *
 *   node create-admin.js --email offadmin@gmail.com --password <password> \
 *     --name "Official Admin"
 *
 * The email must be listed in isBootstrapAdmin() in firestore.rules (deploy
 * the rules after adding it); that rule is what lets a brand-new admin write
 * its own profile without the Admin SDK. Safe to re-run: an existing account
 * is signed in and an existing profile is left alone.
 *
 * Official admins have no assigned area: they oversee every area.
 */

const fs = require('fs');
const path = require('path');

function arg(name) {
  const index = process.argv.indexOf(`--${name}`);
  return index >= 0 ? process.argv[index + 1] : undefined;
}

const email = (arg('email') || '').trim().toLowerCase();
const password = arg('password') || '';
const name = (arg('name') || '').trim();

if (!email || !password || !name) {
  console.error('Usage: node create-admin.js --email <email> --password <password> --name "<name>"');
  process.exit(1);
}
if (password.length < 8) {
  console.error('Password must be at least 8 characters.');
  process.exit(1);
}

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

async function main() {
  const { projectId, apiKey } = loadConfig();
  const base = 'https://identitytoolkit.googleapis.com/v1/accounts';
  const body = { email, password, returnSecureToken: true };

  let auth;
  let created = true;
  try {
    auth = await post(`${base}:signUp?key=${apiKey}`, body);
  } catch (error) {
    if (error.code !== 'EMAIL_EXISTS') throw error;
    created = false;
    auth = await post(`${base}:signInWithPassword?key=${apiKey}`, body);
  }
  await post(`${base}:update?key=${apiKey}`, {
    idToken: auth.idToken,
    displayName: name,
    returnSecureToken: false,
  });

  const docUrl =
    `https://firestore.googleapis.com/v1/projects/${projectId}` +
    `/databases/(default)/documents/users/${auth.localId}`;
  const response = await fetch(`${docUrl}?currentDocument.exists=false`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${auth.idToken}`,
    },
    body: JSON.stringify({
      fields: {
        displayName: { stringValue: name },
        email: { stringValue: email },
        role: { stringValue: 'admin' },
        isDemo: { booleanValue: false },
        createdAt: { timestampValue: new Date().toISOString() },
      },
    }),
  });

  let profile = 'created';
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    if (data.error?.status === 'FAILED_PRECONDITION') {
      profile = 'already existed (left unchanged)';
    } else if (data.error?.status === 'PERMISSION_DENIED') {
      throw new Error(
        `Firestore refused the profile. Add "${email}" to isBootstrapAdmin() ` +
          'in firestore.rules and run: firebase deploy --only firestore:rules',
      );
    } else {
      throw new Error(data.error?.message || response.statusText);
    }
  }

  console.log(`Official super admin ${created ? 'created' : 'already had a sign-in'}:`);
  console.log(`  Name:    ${name}`);
  console.log(`  Email:   ${email}`);
  console.log(`  UID:     ${auth.localId}`);
  console.log(`  Profile: ${profile}`);
}

main().catch((error) => {
  console.error('Failed:', error.message);
  process.exit(1);
});
