const functions = require("firebase-functions/v1");
const admin = require('firebase-admin');
const { geohashQueryBounds, distanceBetween } = require('geofire-common');

admin.initializeApp();
const db = admin.firestore();


exports.notifyUsersNearReport = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    console.log('🔥 Fire report function triggered for reportId:', context.params.reportId);
    
    const data = snap.data();
    if (!data) {
      console.log('❌ No data found in report document');
      return null;
    }

    console.log('📊 Report data:', JSON.stringify(data, null, 2));

    const lat = Number(data.latitude);
    const lon = Number(data.longitude);
    const reporterUid = data.reporterUid || null;
    const reportDescription = data.description || 'Fire reported by community member';
    const reportRadiusMeters = data.radiusMeters || 5000; // Use radius from report or default to 5km
    
    console.log('📍 Fire location:', { lat, lon });
    console.log('👤 Reporter UID:', reporterUid);
    console.log('📝 Description:', reportDescription);
    console.log('📏 Report radius:', reportRadiusMeters, 'meters');
    
    if (Number.isNaN(lat) || Number.isNaN(lon)) {
      console.log('❌ Invalid coordinates - lat:', lat, 'lon:', lon);
      return null;
    }

    const center = [lat, lon];
    const radiusInM = reportRadiusMeters; // Use the actual radius from the fire report
    console.log('🎯 Search center:', center, 'radius:', radiusInM, 'meters');
    
    const bounds = geohashQueryBounds(center, radiusInM);
    console.log('📐 Geohash bounds:', bounds.length, 'bounds generated');

    const candidateDocs = [];
    await Promise.all(
      bounds.map(async ([start, end], index) => {
        console.log(`🔍 Querying bound ${index + 1}/${bounds.length}: ${start} to ${end}`);
        const q = db
          .collection('user_presence')
          .orderBy('geohash')
          .startAt(start)
          .endAt(end);
        const snapQ = await q.get();
        console.log(`📋 Found ${snapQ.docs.length} candidate documents in bound ${index + 1}`);
        candidateDocs.push(...snapQ.docs);
      })
    );
    
    console.log(`📊 Total candidate documents: ${candidateDocs.length}`);

    // If no users found in user_presence, also check users collection
    if (candidateDocs.length === 0) {
      console.log('🔍 No users found in user_presence, checking users collection...');
      try {
        const usersSnapshot = await db.collection('users').get();
        console.log(`📋 Found ${usersSnapshot.docs.length} users in users collection`);
        
        for (const userDoc of usersSnapshot.docs) {
          const userData = userDoc.data();
          if (userData.location && userData.fcmToken) {
            const userLat = userData.location.latitude;
            const userLon = userData.location.longitude;
            const distM = distanceBetween([userLat, userLon], center) * 1000;
            console.log(`👤 User ${userDoc.id} at (${userLat}, ${userLon}) - Distance: ${Math.round(distM)}m`);
            
            if (distM <= radiusInM) {
              console.log(`✅ Adding user ${userDoc.id} from users collection`);
              candidateDocs.push({
                id: userDoc.id,
                data: () => ({
                  uid: userDoc.id,
                  latitude: userLat,
                  longitude: userLon,
                  fcmToken: userData.fcmToken
                })
              });
            }
          }
        }
        console.log(`📊 Total candidate documents after users check: ${candidateDocs.length}`);
      } catch (error) {
        console.error('❌ Error checking users collection:', error);
      }
    }

    const tokens = [];
    const dedupUid = new Set();
    
    console.log('👥 Processing candidate users...');
    for (let i = 0; i < candidateDocs.length; i++) {
      const doc = candidateDocs[i];
      const d = doc.data() || {};
      const uLat = Number(d.latitude);
      const uLon = Number(d.longitude);
      const token = d.fcmToken;
      const uid = d.uid || doc.id;
      
      console.log(`👤 User ${i + 1}/${candidateDocs.length}:`, {
        uid,
        lat: uLat,
        lon: uLon,
        hasToken: !!token,
        tokenPreview: token ? `${token.substring(0, 20)}...` : 'none'
      });
      
      if (!token || Number.isNaN(uLat) || Number.isNaN(uLon)) {
        console.log(`⚠️  Skipping user ${uid}: missing token or invalid coordinates`);
        continue;
      }
      
      if (reporterUid && uid === reporterUid) {
        console.log(`🚫 Skipping reporter ${uid} (same as report creator)`);
        continue;
      }

      const distM = distanceBetween([uLat, uLon], center) * 1000; 
      console.log(`📏 Distance for user ${uid}: ${Math.round(distM)}m (limit: ${radiusInM}m)`);
      
      if (distM <= radiusInM && !dedupUid.has(uid)) {
        console.log(`✅ Adding user ${uid} to notification list`);
        dedupUid.add(uid);
        tokens.push(token);
      } else if (distM > radiusInM) {
        console.log(`❌ User ${uid} too far: ${Math.round(distM)}m > ${radiusInM}m`);
      } else {
        console.log(`🔄 User ${uid} already processed (duplicate)`);
      }
    }

    console.log(`🎯 Final notification targets: ${tokens.length} users`);
    
    if (tokens.length === 0) {
      console.log('❌ No users found within radius - no notifications sent');
      return null;
    }

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
      apns: {
        payload: {
          aps: {
            alert: {
              title: '🔥 Fire Alert - Community Report',
              body: `Fire reported ${Math.round(radiusInM/1000)}km from you: ${reportDescription}`,
            },
            sound: 'default',
          }
        }
      }
    };

    console.log('📨 Notification message template:', JSON.stringify({
      notification: message.notification,
      data: message.data,
      android: message.android,
      apns: message.apns
    }, null, 2));
    console.log(`🚀 Sending fire alert notification to ${tokens.length} users near fire report at ${lat}, ${lon}`);
    
    try {
      // Send individual messages instead of batch to avoid 404 errors
      console.log(`� Sending ${tokens.length} individual notifications...`);
      
      let successCount = 0;
      let failureCount = 0;
      const errors = [];
      
      for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        console.log(`� Sending notification ${i + 1}/${tokens.length} to token: ${token.substring(0, 20)}...`);
        
        try {
          const individualMessage = {
            token: token,
            notification: message.notification,
            data: message.data,
            android: message.android,
            apns: message.apns
          };
          
          await admin.messaging().send(individualMessage);
          successCount++;
          console.log(`✅ Notification ${i + 1} sent successfully`);
        } catch (sendError) {
          failureCount++;
          const errorMessage = sendError.message || 'Unknown error';
          errors.push({ index: i, token: token.substring(0, 20), error: errorMessage });
          console.log(`❌ Notification ${i + 1} failed: ${errorMessage}`);
        }
        
        // Add small delay between sends to avoid rate limiting
        if (i < tokens.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 100));
        }
      }
      
      console.log('✅ All notifications processed:', {
        successCount,
        failureCount,
        totalTokens: tokens.length
      });
      
      if (errors.length > 0) {
        console.log('❌ Failed notifications:', errors);
      }
    } catch (error) {
      console.error('❌ Failed to send notifications:', error);
      console.error('❌ Error details:', {
        code: error.code,
        message: error.message,
        stack: error.stack
      });
      // Don't throw error to avoid function retry, just log it
    }
    
    console.log('🏁 Fire notification function completed successfully');
    return null;
  });


