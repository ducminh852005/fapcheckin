import { getApps, initializeApp } from "firebase/app"
import { getAuth } from "firebase/auth"
import { getFirestore } from "firebase/firestore"

const firebaseConfig = {
  apiKey: "AIzaSyB6jzp1YAVEUhHA43OYTOPIPzy33UWSUsY",
  appId: "1:161196189514:web:2690898e4ff702d07c43b3",
  messagingSenderId: "161196189514",
  projectId: "fapcheckin-3bn2di",
  authDomain: "fapcheckin-3bn2di.firebaseapp.com",
  storageBucket: "fapcheckin-3bn2di.firebasestorage.app",
}

const app = getApps()[0] ?? initializeApp(firebaseConfig)

export const auth = getAuth(app)
export const firestore = getFirestore(app)
