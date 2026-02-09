# MKE CitySmart — App Features & Overview

> **Built by a young Milwaukee developer on a mission to make city life easier for every driver in Milwaukee.**

MKE CitySmart is the all-in-one city companion app for Milwaukee. It combines smart parking tools, real-time community data, city service schedules, and AI-powered predictions into a single app — so you never get a ticket, miss a street sweeping day, or circle the block for 20 minutes looking for a spot.

---

## 🅿️ Smart Parking
- **Interactive parking map** with real-time availability zones
- **Citation risk heatmap** — color-coded map showing where tickets are most likely (466K+ citations analyzed)
- **AI parking finder** — finds the safest parking spots near you based on time, day, weather, and citation history
- **Crowdsourced parking reports** — users report open spots, taken spots, and enforcement sightings in real-time
- **Live spot counts** — "~12 spots open nearby" powered by community data
- **Favorite spots** — save your go-to parking locations

## 🎫 Ticket Management
- **Ticket tracker** — log, photograph, and manage all your parking tickets
- **OCR ticket scanning** — take a photo of a ticket and auto-fill the details using AI text recognition
- **Late fee calculator** — tracks when late fees kick in
- **Pay/dispute workflows** — guided steps to pay or contest a ticket
- **Citation analytics** — see patterns in your ticket history

## 🧹 Street Sweeping & Alternate Side Parking
- **Street sweeping schedules** by zone with multi-stage notifications (24hr, 2hr, GPS-based)
- **Alternate side parking rules** — odd/even day logic with daily reminders
- **Morning, evening, and midnight alerts** so you never forget to move your car
- **Violation prevention streak** — gamified clean days tracker

## 🗑️ Garbage & Recycling
- **Pickup schedule lookup** by address using real Milwaukee DPW data
- **Smart reminders** — night-before and morning-of notifications with 30-minute intervals
- **Calendar integration** — add pickup events directly to your phone's calendar
- **Multi-language support** — English, Chinese, French, Hindi, Greek

## ⚡ EV Charging Map
- **Interactive charging station map** with Milwaukee-area stations
- **Filters** — fast charging (50kW+), available only
- **Weather overlay** — see current conditions while planning your route
- **Community sightings** — user-reported station status

## 🔔 Alerts & Notifications
- **Risk alerts** — high tow risk, citation risk, enforcement sightings
- **Street sweeping reminders** — GPS-based smart monitoring
- **Alternate side parking** — morning, evening, and midnight reminders
- **Garbage day reminders** — night before + morning of
- **Weather alerts** — NWS severe weather warnings
- **Customizable preferences** — choose what you want to be notified about

## 🚗 Vehicle Management
- **Multiple vehicles** — track plates, make, model, color for each car
- **Permit tracking** — view active permits and eligibility
- **Permit application workflow** — guided application process

## 📍 Saved Places
- **Save home, work, favorites** with custom parking preferences
- **Location-based alerts** — get notified about parking changes near your saved places

## 👥 Community Features
- **Community feed** — browse reports from other Milwaukee drivers
- **Sighting reports** — report enforcement, events, road closures
- **Upvote/downvote** — help verify community reports
- **Crowdsource contributions** — submit parking reports to help others

## 🚨 Tow Recovery Helper
- **Step-by-step guide** if your car gets towed
- **Tow lot finder** — locate where your car was taken
- **Fee information** — know what to expect before you go

## 👤 User Profile & Account
- **Email/password login**
- **Google Sign-In**
- **Sign in with Apple**
- **Guest mode** — use the app without an account
- **Profile management** — name, email, phone, address
- **Account deletion** — full GDPR-compliant data removal

## 💎 Premium (Pro) Subscription — $4.99/mo or $39.99/yr

| Feature | Free | Pro |
|---------|------|-----|
| Basic parking info | ✅ | ✅ |
| Street sweeping reminders | ✅ | ✅ |
| Crowdsource reports | ✅ | ✅ |
| 3-mile alert radius | ✅ | 15-mile |
| 3 alerts/day | ✅ | Unlimited |
| 7 days history | ✅ | 1 year |
| Citation risk heatmap | ❌ | ✅ |
| AI parking finder | ❌ | ✅ |
| Live spot counts | ❌ | ✅ |
| Tow recovery helper | ❌ | ✅ |
| Smart alerts | ❌ | ✅ |
| Ad-free | ❌ | ✅ |
| Priority support | ❌ | ✅ |

---

## 🛠️ Technical Overview
- **Platforms:** iOS, Android, and Web
- **39 screens** — full-featured city companion
- **37 services** — parking, predictions, crowdsource, notifications, subscriptions, and more
- **42,000+ lines of code**
- **209 automated tests**
- **Firebase powered** — Auth, Firestore, Analytics, Crashlytics, Cloud Messaging
- **AI/ML** — ML Kit OCR for ticket scanning, predictive parking safety engine
- **Dark theme** with a custom Milwaukee-inspired design

## 🏗️ Built to Scale
MKE CitySmart was architecturally designed to expand beyond Milwaukee to any U.S. city. The region-based system (`wi/milwaukee` → `wi/madison` → `il/chicago`) means the same app can serve drivers in Chicago, Madison, Minneapolis, and beyond — with city-specific data for each.

---

## About the Developer

MKE CitySmart was built from the ground up by **Dwayne Sampson**, a young developer from Milwaukee, Wisconsin. Born and raised in the city, Dwayne built this app to solve a problem he and every other Milwaukee driver faces — parking headaches, surprise tickets, and scattered city information. Every feature was designed with the Milwaukee community in mind, and the goal is simple: **make city life easier for everyone.**

---

*Available on the App Store and Google Play*
*www.mkecitysmart.com*
