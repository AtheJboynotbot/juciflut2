# Quick Fix for "TypeError: null is not a subtype of type 'String'"

## The Problem
Your existing faculty documents in Firestore don't have the new fields we just added:
- `phone_number`
- `office_location`  
- `date_of_birth`

The cached faculty doc ID might also be pointing to old data.

## Solution 1: Clear Browser Cache (Recommended)

### In Edge/Chrome:
1. Press `F12` to open DevTools
2. Go to **Application** tab
3. Expand **Local Storage** in left sidebar
4. Click on your app's URL (e.g., `http://localhost:8080`)
5. Click **Clear All** button
6. Refresh the page (`Ctrl+R`)

### Alternative - Use Console:
1. Press `F12`
2. Go to **Console** tab
3. Type: `localStorage.clear()`
4. Press Enter
5. Refresh the page

## Solution 2: Update Your Faculty Document in Firestore

Go to Firebase Console → Firestore → `faculty` collection → Your document

Add these fields:
```
phone_number: ""
office_location: ""
date_of_birth: null
```

## Solution 3: Re-login

Simply log out and log back in - this will trigger a fresh faculty doc lookup.
