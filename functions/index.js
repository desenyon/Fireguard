const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { geohashQueryBounds, distanceBetween } = require('geofire-common');

try { admin.app(); } catch (e) { admin.initializeApp(); }
const db = admin.firestore();


exports.notifyUsersNearReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const lat = Number(data.latitude);
    const lon = Number(data.longitude);
    const reporterUid = data.reporterUid || null;
    if (Number.isNaN(lat) || Number.isNaN(lon)) return null;

    const center = [lat, lon];
    const radiusInM = 5000; // 5 km
    const bounds = geohashQueryBounds(center, radiusInM);

    const candidateDocs = [];
    await Promise.all(
      bounds.map(async ([start, end]) => {
        const q = db
          .collection('user_presence')
          .orderBy('geohash')
          .startAt(start)
          .endAt(end);
        const snapQ = await q.get();
        candidateDocs.push(...snapQ.docs);
      })
    );

    const tokens = [];
    const dedupUid = new Set();
    for (const doc of candidateDocs) {
      const d = doc.data() || {};
      const uLat = Number(d.latitude);
      const uLon = Number(d.longitude);
      const token = d.fcmToken;
      const uid = d.uid || doc.id;
      if (!token || Number.isNaN(uLat) || Number.isNaN(uLon)) continue;
      if (reporterUid && uid === reporterUid) continue; 

      const distM = distanceBetween([uLat, uLon], center) * 1000; 
      if (distM <= radiusInM && !dedupUid.has(uid)) {
        dedupUid.add(uid);
        tokens.push(token);
      }
    }

    if (tokens.length === 0) return null;

    const message = {
      tokens,
      notification: {
        title: 'Nearby fire reported',
        body: 'A community report was filed within 5 km of your location.',
      },
      data: {
        reportId: context.params.reportId,
        latitude: String(lat),
        longitude: String(lon),
        radiusKm: '5',
      },
      android: { priority: 'high' },
    };

    await admin.messaging().sendMulticast(message);
    return null;
  });

/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
