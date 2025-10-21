# Firebase Deployment Guide for Wutzup

## 🚀 Quick Deploy

```bash
cd firebase
firebase deploy
```

This single command:
1. ✅ Deploys Firestore security rules
2. ✅ Deploys Firestore indexes
3. ✅ Deploys Cloud Functions
4. ✅ **Automatically seeds database with test data** 🎉

## What Gets Seeded

After every `firebase deploy`, the database is automatically populated with:

### Users
- Uses **all existing Firebase Auth users**
- Ensures they have Firestore user documents
- No new users are created

### Conversations
- **10+ conversations** between existing users
- Mix of one-on-one and group chats
- Group chats with fun names:
  - "Family Chat"
  - "Weekend Plans"
  - "Book Club"
  - "Fitness Buddies"
  - "Recipe Exchange"
  - "Game Night Crew"

### Messages
- **30-120+ family-friendly messages** total
- 3-8 messages per conversation
- Wholesome content like:
  - "Hey! How's your day going?"
  - "Did you see that amazing sunset yesterday?"
  - "Anyone up for a weekend hike?"
  - "Let's plan a picnic for next month!"

### Presence
- Online/offline status for all users
- First 2 users set as online
- Rest set as offline

## Prerequisites

⚠️ **Important:** You need at least **2 Firebase Authentication users** before seeding works!

### Create Test Users

**Method 1: Firebase Console** (Recommended)
```
1. Go to https://console.firebase.google.com
2. Select project → Authentication → Users
3. Click "Add user"
4. Create accounts:
   - alice@example.com / password123
   - bob@example.com / password123
```

**Method 2: iOS App**
```
1. Build and run the app
2. Register accounts through the app
```

## Deployment Commands

### Deploy Everything
```bash
firebase deploy
```

### Deploy Specific Components
```bash
# Firestore only (rules + indexes + auto-seed)
firebase deploy --only firestore

# Cloud Functions only
firebase deploy --only functions

# Multiple components
firebase deploy --only firestore:rules,functions
```

## Manual Seeding

You can also seed manually without deploying:

```bash
# Production
cd firebase
python3 seed_database.py --project-id YOUR_PROJECT_ID

# Local emulator
firebase emulators:start
# In another terminal:
python3 seed_database.py --emulator
```

## Clear and Reseed

**⚠️ WARNING: This deletes all existing conversations and messages!**

```bash
cd firebase
python3 seed_database.py --project-id YOUR_PROJECT_ID --clear --auto-confirm
```

Use this when you want a completely fresh start with new seed data.

## Disable Automatic Seeding

If you don't want automatic seeding on deploy:

1. Edit `firebase.json`
2. Comment out or remove the postdeploy hook:

```json
{
  "hooks": {
    "postdeploy": {
      "firestore": [
        // "python3 seed_database.py --project-id $GCLOUD_PROJECT --auto-confirm"
      ]
    }
  }
}
```

## Monitoring Deployment

### View Logs
```bash
# Cloud Functions logs
firebase functions:log

# Specific function
firebase functions:log --only on_message_created

# Real-time monitoring
firebase functions:log --follow
```

### Check Status
```bash
# List deployed functions
firebase functions:list

# Check Firestore rules
firebase firestore:indexes

# View project info
firebase projects:list
```

## Deployment Workflow

### Initial Setup
```bash
# 1. Login to Firebase
firebase login

# 2. Set project
firebase use YOUR_PROJECT_ID

# 3. Create test users (Firebase Console)
# Go to Authentication → Add users

# 4. Deploy everything
firebase deploy

# ✅ Done! Database seeded automatically
```

### Daily Development
```bash
# 1. Make code changes
# 2. Test locally with emulator
firebase emulators:start

# 3. Deploy when ready
firebase deploy

# ✅ Fresh seed data created automatically
```

### Production Deployment
```bash
# 1. Ensure all tests pass
# 2. Review changes
git diff

# 3. Deploy to production
firebase deploy

# 4. Monitor for errors
firebase functions:log --follow

# 5. Verify in Firebase Console
open https://console.firebase.google.com
```

## Troubleshooting

### "No existing users found"
**Problem:** Seeding script can't find Firebase Auth users  
**Solution:** Create at least 2 users in Firebase Authentication first

### "Permission denied"
**Problem:** Not authenticated with Firebase  
**Solution:**
```bash
firebase login
gcloud auth application-default login
```

### "Module not found"
**Problem:** Missing Python dependencies  
**Solution:**
```bash
pip install firebase-admin
```

### Seeding takes too long
**Problem:** Large number of users creates too many conversations  
**Solution:** The script automatically caps at 15 conversations. To adjust:
```python
# Edit seed_database.py, line ~237
if conv_count >= 15:  # Change this number
    break
```

### Want different seed data
**Solution:** Edit `seed_database.py` and customize:
- Message templates (lines 288-322)
- Group names (lines 225-232)
- Number of messages per conversation (line 342)

## Cost Considerations

### Seeding Costs (per deployment)
- **Firestore writes:** ~50-150 documents
- **Estimated cost:** $0.00027 per seed (well within free tier)

### Free Tier Coverage
- **50K reads/day, 20K writes/day**
- Can seed ~133 times per day before hitting limits
- ✅ Completely free for normal development

### Production Tips
1. Disable auto-seeding in production (comment out hook)
2. Only seed staging/development environments
3. Use manual seeding for controlled test data
4. Monitor Firebase usage dashboard

## Security Notes

⚠️ **Important Security Considerations:**

1. **Admin Privileges:** Seeding script has admin access
2. **User Data:** Script can read all Firebase Auth users
3. **Firestore Access:** Script bypasses security rules
4. **Production Data:** Be careful with `--clear` flag!

**Best Practices:**
- ✅ Only run on staging/development
- ✅ Never expose Firebase credentials
- ✅ Review seed script before running
- ✅ Use `--auto-confirm` only in trusted environments

## Environment Variables

The postdeploy hook uses `$GCLOUD_PROJECT`:
- Automatically set by Firebase CLI during deployment
- Contains the current project ID
- No manual configuration needed

## Related Documentation

- [SEEDING.md](./SEEDING.md) - Complete seeding documentation
- [QUICK_SEED_GUIDE.md](./QUICK_SEED_GUIDE.md) - Quick reference
- [README.md](./README.md) - Main Firebase documentation
- [SCHEMA.md](./SCHEMA.md) - Database schema

## Support

Having issues? Check:
1. Firebase Console logs
2. Function deployment status: `firebase functions:list`
3. Firestore rules: Verify they're deployed
4. Authentication: Ensure users exist
5. Permissions: Run `firebase login` again

---

**Last Updated:** October 21, 2025  
**Feature:** Automatic database seeding on deploy  
**Status:** ✅ Production ready
