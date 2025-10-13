import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { geohashQueryBounds, distanceBetween } from 'geofire-common';

admin.initializeApp();
const db = admin.firestore();

// Expected report document fields: latitude, longitude, reporterUid, createdAt
export const notifyUsersNearReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    const lat = Number(data.latitude);
    const lon = Number(data.longitude);
    const reporterUid = data.reporterUid as string | undefined;
    if (isNaN(lat) || isNaN(lon)) return;

    const radiusInM = 5000; // 5 km
    const center = [lat, lon] as [number, number];
    const bounds = geohashQueryBounds(center, radiusInM);

    const matchingDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
    // user_presence docs contain: uid, fcmToken, latitude, longitude, geohash, updatedAt
    await Promise.all(
      bounds.map(async ([start, end]) => {
        const q = db
          .collection('user_presence')
          .orderBy('geohash')
          .startAt(start)
          .endAt(end);
        const snap = await q.get();
        matchingDocs.push(...snap.docs);
      })
    );

    const tokens: string[] = [];
    const notifyUsers: string[] = [];
    const uniqueByUid = new Set<string>();

    for (const doc of matchingDocs) {
      const d = doc.data() as any;
      const uLat = Number(d.latitude);
      const uLon = Number(d.longitude);
      const uid = (d.uid as string) || doc.id;
      const token = d.fcmToken as string | undefined;
      if (!token || isNaN(uLat) || isNaN(uLon)) continue;
      if (reporterUid && uid === reporterUid) continue; // skip author

      const distM = distanceBetween([uLat, uLon], center) * 1000; // km->m
      if (distM <= radiusInM && !uniqueByUid.has(uid)) {
        uniqueByUid.add(uid);
        tokens.push(token);
        notifyUsers.push(uid);
      }
    }

    if (tokens.length === 0) return;

    const message: admin.messaging.MulticastMessage = {
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
  });


