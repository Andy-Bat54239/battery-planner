# Battery Planner

Battery Planner lets you plan your phone use hour by hour and shows whether the battery survives the day. It signs users in with Firebase Authentication, and each user's data is saved in Cloud Firestore under their own id, so two accounts never see each other's data, and every change appears live.

- **Login:** email and password (Firebase Authentication).
- **Data:** `users/{uid}/hours`, one document per hour.
- **Live:** the plan listens to Firestore with `snapshots()`, so changes show without restarting.
- **Edit and delete:** tap an hour to edit it; the bin icon in the app bar deletes the whole plan.
- **Rules:** `firestore.rules` only lets a signed-in user read and write their own `users/{uid}` data. Test mode is not used.

## Screenshots

![Login](screenshots/login.png)
![My data in Firestore](screenshots/console.png)
![Live update](screenshots/live.png)
![Second account sees nothing of mine](screenshots/denied.png)
