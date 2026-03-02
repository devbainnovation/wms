/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC9KgAClbcj21VPqRnFZL0QHKZ0Gdqhk2E',
  authDomain: 'devbaa-dwms.firebaseapp.com',
  projectId: 'devbaa-dwms',
  storageBucket: 'devbaa-dwms.firebasestorage.app',
  messagingSenderId: '934532670053',
  appId: '1:934532670053:web:89e32b69fdc40296cb1c8c',
  measurementId: 'G-K5G25T1FX8',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'WMS Notification';
  const options = {
    body: payload.notification?.body,
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(title, options);
});
