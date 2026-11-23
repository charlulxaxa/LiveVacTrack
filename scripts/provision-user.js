#!/usr/bin/env node
/**
 * LiveVacTrack staff account provisioning tool.
 *
 * Creates a Firebase Auth user and a matching users/{uid} Firestore
 * document with a role. Run this from the scripts/ directory:
 *
 *   node provision-user.js \
 *     --email clerk2@livevactrack.test \
 *     --password secret123 \
 *     --role clerk \
 *     --name "Carla Dizon" \
 *     --area 0102801001 \
 *     --area-name "Poblacion, City of Batac, Ilocos Norte"
 *
 * Requires a service account key (GOOGLE_APPLICATION_CREDENTIALS) or
 * application default credentials. See README.md.
 */

const admin = require('firebase-admin');
const { program } = require('commander');

program
  .requiredOption('--email <email>', 'staff email address')
  .requiredOption('--password <password>', 'staff password')
  .requiredOption(
    '--role <role>',
    'registry | vet | clerk | inspector | disease_control'
  )
  .requiredOption('--name <name>', 'display name')
  .requiredOption(
    '--area <area>',
    'area id (PSGC barangay code in live mode), e.g. 0102801001'
  )
  .option(
    '--area-name <name>',
    'area display name, e.g. "Poblacion, City of Batac, Ilocos Norte"'
  )
  .option(
    '--project <project>',
    'Firebase project id (defaults to GOOGLE_CLOUD_PROJECT or ADC)'
  )
  .parse(process.argv);

const options = program.opts();

const VALID_ROLES = [
  'admin',
  'registry',
  'vet',
  'clerk',
  'inspector',
  'disease_control',
];

if (!VALID_ROLES.includes(options.role)) {
  console.error(
    `Invalid role "${options.role}". Valid roles: ${VALID_ROLES.join(', ')}`
  );
  process.exit(1);
}

const areaName = options.areaName || options.area;

function initAdmin() {
  if (admin.apps.length > 0) return;
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: options.project,
  });
}

async function provisionUser() {
  initAdmin();
  const auth = admin.auth();
  const firestore = admin.firestore();

  const userRecord = await auth.createUser({
    email: options.email,
    password: options.password,
    displayName: options.name,
    emailVerified: true,
  });

  await firestore.collection('users').doc(userRecord.uid).set({
    displayName: options.name,
    role: options.role,
    areaId: options.area,
    areaName,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await auth.setCustomUserClaims(userRecord.uid, { role: options.role });

  console.log(`Created staff account:`);
  console.log(`  UID:    ${userRecord.uid}`);
  console.log(`  Email:  ${options.email}`);
  console.log(`  Name:   ${options.name}`);
  console.log(`  Role:   ${options.role}`);
  console.log(`  Area:   ${areaName} (${options.area})`);
  console.log('');
  console.log(`Sign in with: ${options.email} / ${options.password}`);
}

provisionUser().catch((error) => {
  console.error('Failed to provision account:', error.message);
  process.exit(1);
});
