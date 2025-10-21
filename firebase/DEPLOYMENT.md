# Firebase Deployment Guide for Wutzup

Step-by-step guide to deploy the Firestore database schema and Cloud Functions.

## Prerequisites Checklist

- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Python 3.13+ installed
- [ ] Firebase project created
- [ ] Firebase project initialized locally (`firebase init`)

## Quick Deploy (All Components)

```bash
# Deploy everything at once
firebase deploy

# This deploys:
# - Firestore security rules
# - Firestore indexes
# - Cloud Functions
```

## Step-by-Step Deployment

### Step 1: Login to Firebase

```bash
firebase login
```

### Step 2: Select Your Project

```bash
# List available projects
firebase projects:list

# Select your project
firebase use YOUR_PROJECT_ID

# Verify selection
firebase use
```

### Step 3: Deploy Firestore Security Rules

```bash
# Deploy security rules
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

**Expected Output:**
```
✔  Deploy complete!

Rules deployed:
  - firestore.rules
```

### Step 4: Deploy Firestore Indexes

```bash
# Deploy indexes
firebase deploy --only firestore:indexes
```

**Note:** Index creation can take 5-10 minutes. You'll receive an email when complete.

**Expected Output:**
```
✔  Deploy complete!

Indexes deployed:
  - Conversation index (participantIds, lastMessageTimestamp)
  - Messages indexes (timestamp)
```

### Step 5: Deploy Cloud Functions

```bash
# Deploy all Cloud Functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:on_message_created
```

**Note:** First deployment may take 3-5 minutes.

**Expected Output:**
```
✔  functions[on_message_created]: Successful create operation.
✔  functions[on_conversation_created]: Successful create operation.
✔  functions[on_presence_updated]: Successful create operation.
✔  functions[test_notification]: Successful create operation.
✔  functions[health_check]: Successful create operation.

Function URLs:
  test_notification: https://us-central1-YOUR_PROJECT.cloudfunctions.net/test_notification
  health_check: https://us-central1-YOUR_PROJECT.cloudfunctions.net/health_check
```

### Step 6: Seed Test Data (Optional)

```bash
# Install Python dependencies
pip install firebase-admin

# Seed database with test data
python firebase/seed_database.py --project-id YOUR_PROJECT_ID --clear
```

**Warning:** The `--clear` flag will delete all existing data!

### Step 7: Verify Deployment

```bash
# Check deployed functions
firebase functions:list

# View recent logs
firebase functions:log --limit 10

# Test health check endpoint
curl https://us-central1-YOUR_PROJECT.cloudfunctions.net/health_check
```

## Local Testing with Emulators

### Start Emulators

```bash
# Start all emulators
firebase emulators:start

# Start specific emulators
firebase emulators:start --only firestore,functions,auth
```

**Emulator URLs:**
- Emulator UI: http://localhost:4000
- Firestore: localhost:8080
- Auth: localhost:9099
- Functions: localhost:5001

### Seed Emulator with Test Data

```bash
# In another terminal
python firebase/seed_database.py --emulator --clear
```

### Connect iOS App to Emulators

Add to your iOS app initialization:

```swift
#if DEBUG
// Firestore Emulator
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

// Auth Emulator
Auth.auth().useEmulator(withHost: "localhost", port: 9099)

// Storage Emulator
Storage.storage().useEmulator(withHost: "localhost", port: 9199)
#endif
```

## Troubleshooting

### Issue: "Permission Denied" when deploying

**Solution:**
```bash
# Re-authenticate
firebase login --reauth

# Ensure you have owner/editor role in Firebase Console
```

### Issue: "Function deployment failed"

**Solution:**
```bash
# Check function logs
firebase functions:log

# Verify Python version
python --version  # Should be 3.13+

# Check requirements.txt
cat firebase/functions/requirements.txt
```

### Issue: "Index creation failed"

**Solution:**
1. Go to Firebase Console
2. Navigate to Firestore → Indexes
3. Check for failed indexes
4. Click the link in error message to auto-create
5. Or manually deploy again: `firebase deploy --only firestore:indexes`

### Issue: "Emulator won't start"

**Solution:**
```bash
# Kill any existing emulator processes
pkill -f firebase

# Clear emulator data
firebase emulators:exec --project=demo-test "echo 'Cleared'"

# Restart
firebase emulators:start
```

### Issue: "Cloud Functions not triggering"

**Solution:**
1. Check function is deployed: `firebase functions:list`
2. View logs: `firebase functions:log --only on_message_created`
3. Verify trigger path matches collection structure
4. Ensure Blaze plan is active (required for production)
5. Check function execution in Firebase Console

## Firebase Console Verification

After deployment, verify in Firebase Console:

### 1. Firestore Database
- Go to: Console → Firestore Database
- Should see empty collections (or test data if seeded)

### 2. Security Rules
- Go to: Console → Firestore → Rules
- Should see your deployed rules from `firestore.rules`

### 3. Indexes
- Go to: Console → Firestore → Indexes
- Should see:
  - Conversation index (building or complete)
  - Messages indexes (building or complete)

### 4. Cloud Functions
- Go to: Console → Functions
- Should see all 5 functions listed:
  - on_message_created
  - on_conversation_created
  - on_presence_updated
  - test_notification
  - health_check

### 5. Authentication
- Go to: Console → Authentication → Sign-in method
- Enable: Email/Password

### 6. Cloud Messaging
- Go to: Console → Cloud Messaging
- Upload APNs key for iOS push notifications

## Post-Deployment Tasks

### 1. Configure APNs for Push Notifications

1. Get APNs Authentication Key from Apple Developer Portal
2. Upload to Firebase Console → Project Settings → Cloud Messaging
3. Enter Key ID and Team ID

### 2. Download Configuration Files

```bash
# Download GoogleService-Info.plist for iOS
# From Firebase Console → Project Settings → iOS app
```

### 3. Set Up Budget Alerts

1. Go to: Console → Usage and billing
2. Set budget alert at $25 (or your preference)
3. Add notification emails

### 4. Enable App Check (Optional but Recommended)

1. Go to: Console → App Check
2. Register iOS app
3. Enable DeviceCheck provider
4. Enforce in production

## Update Deployment

### Update Security Rules Only

```bash
firebase deploy --only firestore:rules
```

### Update Indexes Only

```bash
firebase deploy --only firestore:indexes
```

### Update Specific Function

```bash
firebase deploy --only functions:on_message_created
```

### Update All Functions

```bash
firebase deploy --only functions
```

## Rollback

### Rollback Functions

```bash
# List previous deployments
firebase functions:log

# Not directly supported, redeploy previous version
# Maintain version control with git tags
```

### Rollback Security Rules

```bash
# Rules are versioned in Firebase Console
# Go to: Firestore → Rules → View all versions
# Click "Restore" on previous version
```

## Monitoring

### View Real-Time Logs

```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only on_message_created

# Follow logs (live)
firebase functions:log --tail
```

### Check Function Performance

```bash
# View in Firebase Console
# Functions → Select function → Usage tab
```

### Monitor Firestore Usage

```bash
# View in Firebase Console
# Firestore Database → Usage tab
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Firebase CLI
        run: npm install -g firebase-tools
      
      - name: Deploy to Firebase
        run: firebase deploy --token "${{ secrets.FIREBASE_TOKEN }}"
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### Get Firebase Token for CI

```bash
firebase login:ci
# Copy token and add to GitHub Secrets as FIREBASE_TOKEN
```

## Cost Estimation

### Free Tier (Spark Plan)
- Good for: Development, testing, < 100 users
- Limits:
  - 50K Firestore reads/day
  - 20K Firestore writes/day
  - 125K Cloud Functions invocations/month

### Paid Tier (Blaze Plan)
- Required for: Production Cloud Functions
- Estimated cost for 1,000 users:
  - Firestore: $5-15/month
  - Cloud Functions: $2-5/month
  - Storage: $1-3/month
  - **Total: ~$10-25/month**

## Security Checklist

Before going to production:

- [ ] Security rules deployed and tested
- [ ] Indexes created and built
- [ ] App Check enabled
- [ ] Budget alerts configured
- [ ] Backup strategy in place
- [ ] Monitoring set up
- [ ] APNs configured for push notifications
- [ ] Test all functions with production-like data
- [ ] Review security rules for edge cases
- [ ] Set up error alerting (email/Slack)

## Support Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Status Page](https://status.firebase.google.com)
- [Firebase Support](https://firebase.google.com/support)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase)

## Quick Reference Commands

```bash
# Login
firebase login

# Select project
firebase use YOUR_PROJECT_ID

# Deploy everything
firebase deploy

# Deploy specific components
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only functions

# Start emulators
firebase emulators:start

# View logs
firebase functions:log --tail

# List functions
firebase functions:list

# Seed database
python firebase/seed_database.py --emulator --clear
```

---

**Last Updated:** October 21, 2025

