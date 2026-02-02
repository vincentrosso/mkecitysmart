/**
 * Citation Data Analyzer
 * Processes 466K citations to extract hotspots by:
 * - Day of week
 * - Hour of day
 * - Location/Street patterns
 * - Violation types
 */

const fs = require('fs');
const readline = require('readline');

// Data accumulators
const hourCounts = {};       // hour -> count
const dayOfWeekCounts = {};  // dayOfWeek -> count
const streetCounts = {};     // street -> count
const violationCounts = {};  // violation -> count
const hourDayCounts = {};    // "day-hour" -> count

let totalRecords = 0;

async function processFile() {
  const fileStream = fs.createReadStream('citations_2025.csv');
  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity
  });

  let isHeader = true;
  
  for await (const line of rl) {
    if (isHeader) {
      isHeader = false;
      continue;
    }
    
    try {
      // Parse CSV line: ISSUENO,ISSUEDATE,ISSUETIME,VIODESCRIPTION,LOCATIONDESC1
      const parts = line.split(',');
      if (parts.length < 5) continue;
      
      const dateStr = parts[1]; // e.g., "1/1/2025"
      const timeStr = parts[2]; // e.g., "7:14:00 AM"
      const violation = parts[3];
      const location = parts[4];
      
      // Parse date
      const dateParts = dateStr.split('/');
      if (dateParts.length < 3) continue;
      const month = parseInt(dateParts[0]);
      const day = parseInt(dateParts[1]);
      const year = parseInt(dateParts[2]);
      const date = new Date(year, month - 1, day);
      const dayOfWeek = date.getDay(); // 0=Sun, 6=Sat
      
      // Parse time
      let hour = 0;
      const timeMatch = timeStr.match(/(\d+):(\d+):(\d+)\s*(AM|PM)/i);
      if (timeMatch) {
        hour = parseInt(timeMatch[1]);
        const isPM = timeMatch[4].toUpperCase() === 'PM';
        if (isPM && hour !== 12) hour += 12;
        if (!isPM && hour === 12) hour = 0;
      }
      
      // Extract street name (simplify)
      const streetMatch = location.match(/[NSEW]\s+(.+)/);
      const street = streetMatch ? streetMatch[1].split(' ')[0] : location.split(' ')[0];
      
      // Accumulate counts
      hourCounts[hour] = (hourCounts[hour] || 0) + 1;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] || 0) + 1;
      streetCounts[street] = (streetCounts[street] || 0) + 1;
      violationCounts[violation] = (violationCounts[violation] || 0) + 1;
      
      const dayHourKey = `${dayOfWeek}-${hour}`;
      hourDayCounts[dayHourKey] = (hourDayCounts[dayHourKey] || 0) + 1;
      
      totalRecords++;
      
      if (totalRecords % 50000 === 0) {
        console.log(`Processed ${totalRecords} records...`);
      }
    } catch (e) {
      // Skip malformed lines
    }
  }
  
  console.log(`\nTotal records processed: ${totalRecords}\n`);
  
  // Output results
  console.log('=== CITATIONS BY HOUR ===');
  for (let h = 0; h < 24; h++) {
    const count = hourCounts[h] || 0;
    const pct = ((count / totalRecords) * 100).toFixed(1);
    console.log(`${h.toString().padStart(2, '0')}:00 - ${count} (${pct}%)`);
  }
  
  console.log('\n=== CITATIONS BY DAY OF WEEK ===');
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  for (let d = 0; d < 7; d++) {
    const count = dayOfWeekCounts[d] || 0;
    const pct = ((count / totalRecords) * 100).toFixed(1);
    console.log(`${days[d]}: ${count} (${pct}%)`);
  }
  
  console.log('\n=== TOP 20 STREETS ===');
  const topStreets = Object.entries(streetCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 20);
  topStreets.forEach(([street, count]) => {
    console.log(`${street}: ${count}`);
  });
  
  console.log('\n=== TOP 10 VIOLATIONS ===');
  const topViolations = Object.entries(violationCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  topViolations.forEach(([violation, count]) => {
    console.log(`${violation}: ${count}`);
  });
  
  // Generate JSON data for the app
  const appData = {
    generated: new Date().toISOString(),
    totalCitations: totalRecords,
    byHour: hourCounts,
    byDayOfWeek: dayOfWeekCounts,
    byDayAndHour: hourDayCounts,
    topStreets: Object.fromEntries(topStreets),
    topViolations: Object.fromEntries(topViolations),
    peakHours: findPeakHours(hourCounts, totalRecords),
    peakDays: findPeakDays(dayOfWeekCounts, totalRecords),
  };
  
  fs.writeFileSync('citation_hotspots.json', JSON.stringify(appData, null, 2));
  console.log('\n✅ Saved citation_hotspots.json');
}

function findPeakHours(hourCounts, total) {
  const avg = total / 24;
  const peaks = [];
  for (let h = 0; h < 24; h++) {
    const count = hourCounts[h] || 0;
    if (count > avg * 1.3) { // 30% above average
      peaks.push({ hour: h, count, riskMultiplier: (count / avg).toFixed(2) });
    }
  }
  return peaks.sort((a, b) => b.count - a.count);
}

function findPeakDays(dayCounts, total) {
  const avg = total / 7;
  const peaks = [];
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  for (let d = 0; d < 7; d++) {
    const count = dayCounts[d] || 0;
    peaks.push({ 
      day: days[d], 
      dayIndex: d,
      count, 
      riskMultiplier: (count / avg).toFixed(2) 
    });
  }
  return peaks.sort((a, b) => b.count - a.count);
}

processFile().catch(console.error);
