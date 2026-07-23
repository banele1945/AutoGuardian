# 🔥 Firebase Setup Guide for AutoGuardian

## Overview
This guide will help you set up Firebase Cloud Messaging (FCM) for push notifications in the AutoGuardian app.

## 📋 Prerequisites
- Google account
- Firebase project (free tier available)
- Android Studio (for Android setup)

## 🚀 Step-by-Step Setup

### 1. Create Firebase Project

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Sign in with your Google account

2. **Create New Project**
   - Click "Create a project"
   - Enter project name: `autoguardian-app`
   - Enable Google Analytics (optional)
   - Click "Create project"

3. **Add Android App**
   - Click "Android" icon
   - Package name: `com.example.auto_guardian`
   - App nickname: `AutoGuardian`
   - Click "Register app"

4. **Download Configuration**
   - Download `google-services.json`
   - Replace the placeholder file in `android/app/google-services.json`

### 2. Configure Firebase Console

1. **Enable Cloud Messaging**
   - Go to Project Settings
   - Click "Cloud Messaging" tab
   - Note your Server key (you'll need this for backend)

2. **Create Notification Channel**
   - Go to "Engage" > "Messaging"
   - Create a new campaign
   - Set up notification channel: `autoguardian_channel`

### 3. Backend Integration

Add these endpoints to your Node.js server:

```javascript
// Firebase Admin SDK setup
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Send notification to specific device
app.post('/api/notifications/send', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;
    
    const message = {
      notification: {
        title,
        body,
      },
      data,
      token,
    };

    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send notification to topic
app.post('/api/notifications/topic', async (req, res) => {
  try {
    const { topic, title, body, data } = req.body;
    
    const message = {
      notification: {
        title,
        body,
      },
      data,
      topic,
    };

    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### 4. ML Integration

Update your ML service to send notifications:

```javascript
// In your ML anomaly detection
const sendAnomalyNotification = async (anomalyData) => {
  try {
    const message = {
      notification: {
        title: '🚨 Vehicle Anomaly Detected',
        body: anomalyData.reason || 'Unusual driving pattern detected',
      },
      data: {
        type: 'anomaly',
        reason: anomalyData.reason,
        confidence: anomalyData.confidence.toString(),
        timestamp: new Date().toISOString(),
        location: JSON.stringify(anomalyData.location),
      },
      topic: 'anomalies', // or specific device token
    };

    await admin.messaging().send(message);
  } catch (error) {
    console.error('Failed to send anomaly notification:', error);
  }
};
```

## 🔧 Testing

### 1. Test Local Notifications
- Run the app
- Check console for FCM token
- Verify local notifications work

### 2. Test Push Notifications
- Use Firebase Console to send test message
- Verify notification appears on device

### 3. Test ML Notifications
- Trigger anomaly detection on server
- Verify notification is sent to app

## 📱 App Features

### AI/ML Dashboard
- **Statistics**: Shows data points, models trained, speed metrics
- **Anomalies**: Lists recent driving anomalies with confidence scores
- **Insights**: Safety score, route consistency, speed compliance
- **Training**: Manual trigger to retrain AI models

### Notification Types
1. **Anomaly Alerts**: Unusual driving patterns detected
2. **System Alerts**: Kill switch, disarm events
3. **Trip Updates**: New trips started/completed
4. **Security Events**: Unauthorized access attempts

## 🛠️ Troubleshooting

### Common Issues

1. **FCM Token Not Generated**
   - Check internet connection
   - Verify Firebase configuration
   - Check app permissions

2. **Notifications Not Received**
   - Verify FCM token is sent to server
   - Check notification permissions
   - Test with Firebase Console

3. **ML Service Errors**
   - Check server logs
   - Verify API endpoints
   - Test with Postman

### Debug Commands

```bash
# Check FCM token
flutter logs | grep "FCM Token"

# Test notification
adb shell am start -a android.intent.action.VIEW -d "firebase://autoguardian"

# Check app permissions
adb shell dumpsys package com.example.auto_guardian | grep permission
```

## 📊 Monitoring

### Firebase Console
- **Analytics**: User engagement, crash reports
- **Crashlytics**: App stability monitoring
- **Performance**: App performance metrics

### Server Logs
- Monitor ML API calls
- Track notification delivery
- Monitor anomaly detection

## 🔐 Security

### Best Practices
1. **Secure FCM Tokens**: Store tokens securely on server
2. **Validate Notifications**: Verify sender authenticity
3. **Rate Limiting**: Prevent notification spam
4. **Data Privacy**: Anonymize user data in ML models

### Environment Variables
```bash
# Add to your .env file
FIREBASE_PROJECT_ID=autoguardian-app
FIREBASE_SERVER_KEY=your_server_key_here
ML_API_KEY=your_ml_api_key_here
```

## 🎯 Next Steps

1. **Production Deployment**
   - Update package name
   - Configure signing keys
   - Set up production Firebase project

2. **Advanced Features**
   - Custom notification sounds
   - Rich notifications with images
   - Notification actions (buttons)

3. **Analytics Integration**
   - Track notification engagement
   - Monitor ML model performance
   - User behavior analytics

---

**Need Help?** Check the Firebase documentation or create an issue in the project repository. 