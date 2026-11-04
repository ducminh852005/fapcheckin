import { getApps, initializeApp } from "firebase/app"
import { getAuth } from "firebase/auth"
import { getFirestore } from "firebase/firestore"

const firebaseConfig = {
  apiKey: "AIzaSyBqlu8uPKRM4d-zdCVOTQq4cCoQZhHuZ0Y",
  appId: "1:1076774489636:web:735f55965525ec971892b1",
  messagingSenderId: "1076774489636",
  projectId: "ducminh-41459",
  authDomain: "ducminh-41459.firebaseapp.com",
  storageBucket: "ducminh-41459.firebasestorage.app",
}

export const app = getApps()[0] ?? initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const firestore = getFirestore(app)
