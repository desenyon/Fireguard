const functions = require("firebase-functions/v1");
const admin = require('firebase-admin');
const { geohashQueryBounds, distanceBetween } = require('geofire-common');

admin.initializeApp();
const db = admin.firestore();


exports.notifyUsersNearReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    const lat = Number(data.latitude);
    const lon = Number(data.longitude);
    const reporterUid = data.reporterUid || null;
    const reportDescription = data.description || 'Fire reported by community member';
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

  
    const distanceKm = Math.round(distanceBetween(center, center) * 1000 / 1000); 
    
    const message = {
      tokens,
      notification: {
        title: '🔥 Fire Alert - Community Report',
        body: `Fire reported ${Math.round(radiusInM/1000)}km from you: ${reportDescription}`,
      },
      data: {
        type: 'fire_report',
        reportId: context.params.reportId,
        latitude: String(lat),
        longitude: String(lon),
        radiusKm: String(Math.round(radiusInM/1000)),
        description: reportDescription,
        timestamp: new Date().toISOString(),
      },
      android: { 
        priority: 'high',
        notification: {
          channelId: 'fire_alerts',
          icon: 'ic_fire_alert',
          color: '#FF6B00',
        }
      },
    };

    console.log(`Sending fire alert notification to ${tokens.length} users near fire report at ${lat}, ${lon}`);
    await admin.messaging().sendMulticast(message);
    return null;
  });


