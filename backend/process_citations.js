/**
 * Citation Data Processor for Parking Risk Heatmap
 * 
 * Processes Milwaukee parking citation data to generate risk scores
 * by location, time of day, and day of week.
 * 
 * Output: Firestore collection with aggregated risk data
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

// Initialize Firebase Admin
admin.initializeApp({
  projectId: "mkeparkapp-1ad15",
});
const db = admin.firestore();

// Milwaukee street geocoding cache (we'll build this as we process)
// Format: "street_name" -> { lat, lng }
const geocodeCache = new Map();

// Geohash encoding for efficient spatial queries
const GEOHASH_BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

function encodeGeohash(lat, lon, precision = 6) {
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let geohash = "";

  let latMin = -90, latMax = 90;
  let lonMin = -180, lonMax = 180;

  while (geohash.length < precision) {
    if (evenBit) {
      const lonMid = (lonMin + lonMax) / 2;
      if (lon >= lonMid) {
        idx = idx * 2 + 1;
        lonMin = lonMid;
      } else {
        idx = idx * 2;
        lonMax = lonMid;
      }
    } else {
      const latMid = (latMin + latMax) / 2;
      if (lat >= latMid) {
        idx = idx * 2 + 1;
        latMin = latMid;
      } else {
        idx = idx * 2;
        latMax = latMid;
      }
    }
    evenBit = !evenBit;
    if (++bit === 5) {
      geohash += GEOHASH_BASE32[idx];
      bit = 0;
      idx = 0;
    }
  }
  return geohash;
}

// Milwaukee address to approximate coordinates
// Using Milwaukee's grid system for accurate geocoding
function geocodeAddress(address) {
  if (!address) return null;
  
  // Check cache first
  const cacheKey = address.toLowerCase().trim();
  if (geocodeCache.has(cacheKey)) {
    return geocodeCache.get(cacheKey);
  }
  
  // Parse Milwaukee address format: "1234 N STREET ST" or "1234 STREET ST"
  const match = address.match(/^(\d+)\s+([NSEW])?\s*(.+)$/i);
  if (!match) return null;
  
  const houseNum = parseInt(match[1]);
  const direction = (match[2] || "").toUpperCase();
  const streetName = match[3].trim().toUpperCase();
  
  // Milwaukee grid system:
  // - Wisconsin Avenue is the north/south divider (lat baseline)
  // - The Milwaukee River/1st Street area is east/west divider (lng baseline)
  // - N/S addresses: house numbers indicate distance north/south of Wisconsin Ave
  // - E/W addresses: house numbers indicate distance east/west of 1st St
  // - Numbered streets run north-south, named streets typically east-west
  
  // Baseline coordinates (Wisconsin Ave & Water St - downtown)
  const baselineLat = 43.0389;  // Wisconsin Ave
  const baselineLng = -87.9122; // 1st Street area
  
  // Milwaukee uses 800 addresses per mile
  // 1 mile = ~0.0145 degrees latitude at this location
  // 1 mile = ~0.0189 degrees longitude at this location
  const latPerAddress = 0.0145 / 800;  // degrees per address number
  const lngPerAddress = 0.0189 / 800;  // degrees per address number
  
  let lat = baselineLat;
  let lng = baselineLng;
  
  // Check if street is a numbered street (runs N-S) vs named street (runs E-W)
  const streetNumMatch = streetName.match(/^(\d+)(ST|ND|RD|TH)/i);
  const isNumberedStreet = streetNumMatch !== null;
  
  if (isNumberedStreet) {
    // Numbered streets (like 27TH ST) run north-south
    // The street number indicates east-west position
    // House number indicates north-south position on that street
    const streetNum = parseInt(streetNumMatch[1]);
    
    // Street number sets the east-west position
    // Streets 1-99 are generally east of downtown, 100+ are west
    if (streetNum <= 5) {
      lng = baselineLng + (streetNum * 0.0025);  // East streets
    } else {
      // Most numbered streets are west of downtown
      lng = baselineLng - ((streetNum - 1) * 0.0019);
    }
    
    // House number sets north-south position
    if (direction === "N") {
      lat = baselineLat + (houseNum * latPerAddress);
    } else if (direction === "S") {
      lat = baselineLat - (houseNum * latPerAddress);
    } else {
      // No direction prefix - use small offset
      lat = baselineLat + ((houseNum % 2 === 0 ? 1 : -1) * houseNum * latPerAddress * 0.5);
    }
  } else {
    // Named streets - typically run east-west
    // House number indicates east-west position
    
    // Use street name hash to spread streets across lat range
    const streetHash = streetName.split("").reduce((a, c) => a + c.charCodeAt(0), 0);
    const streetOffset = ((streetHash % 200) - 100) * 0.0005;
    
    // Major named streets have known approximate latitudes
    const knownStreets = {
      "WISCONSIN": 43.0389,
      "WELLS": 43.0415,
      "STATE": 43.0440,
      "JUNEAU": 43.0470,
      "MCKINLEY": 43.0500,
      "CAPITOL": 43.0540,
      "RESERVOIR": 43.0600,
      "LOCUST": 43.0650,
      "KEEFE": 43.0700,
      "NORTH": 43.0530,
      "CENTER": 43.0640,
      "BURLEIGH": 43.0730,
      "SILVER SPRING": 43.1200,
      "OKLAHOMA": 42.9780,
      "LINCOLN": 42.9700,
      "FOREST HOME": 42.9850,
      "GREENFIELD": 42.9620,
    };
    
    // Find closest known street
    let closestLat = baselineLat + streetOffset;
    for (const [name, knownLat] of Object.entries(knownStreets)) {
      if (streetName.includes(name)) {
        closestLat = knownLat;
        break;
      }
    }
    lat = closestLat;
    
    // House number sets east-west position
    if (direction === "E") {
      lng = baselineLng + (houseNum * lngPerAddress);
    } else if (direction === "W") {
      lng = baselineLng - (houseNum * lngPerAddress);
    } else {
      lng = baselineLng + ((houseNum % 2 === 0 ? 1 : -1) * houseNum * lngPerAddress * 0.5);
    }
  }
  
  // Clamp to Milwaukee metro bounds
  lat = Math.max(42.9, Math.min(43.2, lat));
  lng = Math.max(-88.1, Math.min(-87.85, lng));
  
  const result = { lat, lng };
  geocodeCache.set(cacheKey, result);
  return result;
}

// Parse time string like "7:14:00 AM" to hour (0-23)
function parseHour(timeStr) {
  if (!timeStr) return null;
  const match = timeStr.match(/(\d+):(\d+):(\d+)\s*(AM|PM)?/i);
  if (!match) return null;
  
  let hour = parseInt(match[1]);
  const ampm = (match[4] || "").toUpperCase();
  
  if (ampm === "PM" && hour !== 12) hour += 12;
  if (ampm === "AM" && hour === 12) hour = 0;
  
  return hour;
}

// Parse date to day of week (0=Sunday, 6=Saturday)
function parseDayOfWeek(dateStr) {
  if (!dateStr) return null;
  const [month, day, year] = dateStr.split("/").map(Number);
  const date = new Date(year, month - 1, day);
  return date.getDay();
}

// Risk category based on violation type
function getViolationRiskCategory(violation) {
  const v = (violation || "").toUpperCase();
  
  if (v.includes("NIGHT PARKING")) return "night_parking";
  if (v.includes("METER")) return "meter";
  if (v.includes("HOUR") || v.includes("EXCESS")) return "time_limit";
  if (v.includes("SIGN") || v.includes("PROHIBITED")) return "no_parking";
  if (v.includes("REGISTRATION") || v.includes("UNREGISTERED")) return "registration";
  if (v.includes("FIRE HYDRANT")) return "fire_hydrant";
  if (v.includes("CROSSWALK")) return "crosswalk";
  if (v.includes("TOW") || v.includes("BLOCKING")) return "tow_zone";
  if (v.includes("RESIDENTIAL")) return "residential_permit";
  if (v.includes("BUS") || v.includes("LOADING")) return "loading_zone";
  
  return "other";
}

// Aggregate data structure
// Key: geohash_precision4 -> { hourly counts, daily counts, violation types }
const aggregatedData = new Map();

async function processCSV(filePath) {
  console.log("Processing citation data...");
  
  const fileStream = fs.createReadStream(filePath, { encoding: "latin1" });
  const rl = readline.createInterface({ input: fileStream, crlfDelay: Infinity });
  
  let lineNum = 0;
  let processed = 0;
  let skipped = 0;
  
  for await (const line of rl) {
    lineNum++;
    
    // Skip header
    if (lineNum === 1) continue;
    
    // Parse CSV (simple split, addresses don't have commas in this dataset)
    const parts = line.split(",");
    if (parts.length < 5) {
      skipped++;
      continue;
    }
    
    const [issueNo, issueDate, issueTime, violation, location] = parts;
    
    // Geocode the address
    const coords = geocodeAddress(location);
    if (!coords) {
      skipped++;
      continue;
    }
    
    const hour = parseHour(issueTime);
    const dayOfWeek = parseDayOfWeek(issueDate);
    const category = getViolationRiskCategory(violation);
    
    if (hour === null || dayOfWeek === null) {
      skipped++;
      continue;
    }
    
    // Generate geohash at precision 5 (~5km x 5km cells)
    // This groups nearby citations together
    const geohash = encodeGeohash(coords.lat, coords.lng, 5);
    
    // Aggregate
    if (!aggregatedData.has(geohash)) {
      aggregatedData.set(geohash, {
        geohash,
        lat: coords.lat,
        lng: coords.lng,
        totalCitations: 0,
        byHour: new Array(24).fill(0),
        byDayOfWeek: new Array(7).fill(0),
        byCategory: {},
        byHourAndDay: {}, // "hour_day" -> count
      });
    }
    
    const agg = aggregatedData.get(geohash);
    agg.totalCitations++;
    agg.byHour[hour]++;
    agg.byDayOfWeek[dayOfWeek]++;
    agg.byCategory[category] = (agg.byCategory[category] || 0) + 1;
    
    const hourDayKey = `${hour}_${dayOfWeek}`;
    agg.byHourAndDay[hourDayKey] = (agg.byHourAndDay[hourDayKey] || 0) + 1;
    
    processed++;
    
    if (processed % 50000 === 0) {
      console.log(`  Processed ${processed} citations...`);
    }
  }
  
  console.log(`\nProcessing complete:`);
  console.log(`  Total lines: ${lineNum}`);
  console.log(`  Processed: ${processed}`);
  console.log(`  Skipped: ${skipped}`);
  console.log(`  Unique geohash zones: ${aggregatedData.size}`);
  
  return aggregatedData;
}

// Calculate risk score (0-100) for a geohash zone
function calculateRiskScore(agg, globalMax) {
  // Base score from citation density
  const densityScore = Math.min(100, (agg.totalCitations / globalMax.totalCitations) * 100);
  
  // Higher weight for high-risk times
  const nightScore = (agg.byHour.slice(0, 6).reduce((a, b) => a + b, 0) / agg.totalCitations) * 100;
  const weekendScore = ((agg.byDayOfWeek[0] + agg.byDayOfWeek[6]) / agg.totalCitations) * 100;
  
  // Combined score
  return Math.round(densityScore * 0.6 + nightScore * 0.2 + weekendScore * 0.2);
}

// Find peak risk hours for a zone
function findPeakHours(agg) {
  const hourlyWithIndex = agg.byHour.map((count, hour) => ({ hour, count }));
  hourlyWithIndex.sort((a, b) => b.count - a.count);
  return hourlyWithIndex.slice(0, 3).map(h => h.hour);
}

// Find peak risk days for a zone
function findPeakDays(agg) {
  const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  const dailyWithIndex = agg.byDayOfWeek.map((count, day) => ({ day: days[day], dayNum: day, count }));
  dailyWithIndex.sort((a, b) => b.count - a.count);
  return dailyWithIndex.slice(0, 3).map(d => ({ day: d.day, dayNum: d.dayNum }));
}

async function uploadToFirestore(aggregatedData) {
  console.log("\nUploading to Firestore...");
  
  // Find global max for normalization
  let globalMax = { totalCitations: 0 };
  for (const agg of aggregatedData.values()) {
    if (agg.totalCitations > globalMax.totalCitations) {
      globalMax = agg;
    }
  }
  
  console.log(`  Global max citations in one zone: ${globalMax.totalCitations}`);
  
  const batch = db.batch();
  let batchCount = 0;
  let uploaded = 0;
  
  for (const [geohash, agg] of aggregatedData) {
    const riskScore = calculateRiskScore(agg, globalMax);
    const peakHours = findPeakHours(agg);
    const peakDays = findPeakDays(agg);
    
    // Top violation categories
    const topCategories = Object.entries(agg.byCategory)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([cat, count]) => ({ category: cat, count }));
    
    const docRef = db.collection("citation_risk_zones").doc(geohash);
    batch.set(docRef, {
      geohash,
      location: new admin.firestore.GeoPoint(agg.lat, agg.lng),
      totalCitations: agg.totalCitations,
      riskScore,
      riskLevel: riskScore >= 70 ? "high" : riskScore >= 40 ? "medium" : "low",
      byHour: agg.byHour,
      byDayOfWeek: agg.byDayOfWeek,
      peakHours,
      peakDays,
      topCategories,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    batchCount++;
    uploaded++;
    
    // Firestore batches limited to 500 operations
    if (batchCount >= 400) {
      await batch.commit();
      console.log(`  Uploaded ${uploaded} zones...`);
      batchCount = 0;
    }
  }
  
  // Commit remaining
  if (batchCount > 0) {
    await batch.commit();
  }
  
  console.log(`\nUpload complete: ${uploaded} risk zones created`);
}

// Create summary statistics document
async function createSummaryStats(aggregatedData) {
  console.log("\nCreating summary statistics...");
  
  let totalCitations = 0;
  const hourlyTotals = new Array(24).fill(0);
  const dailyTotals = new Array(7).fill(0);
  const categoryTotals = {};
  
  for (const agg of aggregatedData.values()) {
    totalCitations += agg.totalCitations;
    agg.byHour.forEach((c, i) => hourlyTotals[i] += c);
    agg.byDayOfWeek.forEach((c, i) => dailyTotals[i] += c);
    Object.entries(agg.byCategory).forEach(([cat, count]) => {
      categoryTotals[cat] = (categoryTotals[cat] || 0) + count;
    });
  }
  
  // Find highest risk hours globally
  const peakHour = hourlyTotals.indexOf(Math.max(...hourlyTotals));
  const peakDay = dailyTotals.indexOf(Math.max(...dailyTotals));
  const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  
  await db.collection("app_config").doc("citation_stats").set({
    totalCitations,
    totalZones: aggregatedData.size,
    byHour: hourlyTotals,
    byDayOfWeek: dailyTotals,
    byCategory: categoryTotals,
    peakHour,
    peakDay: days[peakDay],
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    dataSource: "Milwaukee 2025 Citations",
  });
  
  console.log(`  Total citations: ${totalCitations}`);
  console.log(`  Peak hour: ${peakHour}:00`);
  console.log(`  Peak day: ${days[peakDay]}`);
}

// Main execution
async function main() {
  const csvPath = path.join(__dirname, "citations_2025.csv");
  
  if (!fs.existsSync(csvPath)) {
    console.error("Citation CSV file not found:", csvPath);
    process.exit(1);
  }
  
  try {
    const data = await processCSV(csvPath);
    await uploadToFirestore(data);
    await createSummaryStats(data);
    
    console.log("\n✅ Citation risk data processing complete!");
    console.log("Data is now available in Firestore collection: citation_risk_zones");
    
    process.exit(0);
  } catch (err) {
    console.error("Error:", err);
    process.exit(1);
  }
}

main();
