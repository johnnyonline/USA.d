// preview-2.js
// Node.js script for more accurate NFT SVG preview, aiming to match on-chain logic
const fs = require('fs');
const path = require('path');

// Absolute path to the repo-level assets directory (../../utils/assets from this file)
const ASSET_DIR = path.resolve(__dirname, '..', '..', 'utils', 'assets');

// --- SVG Helper Functions ---
function prop(key, val, last = false) { return `${key}="${val}"${last ? '' : ' '}`; }
function el(tag, props, children = '') { return children ? `<${tag} ${props}>${children}</${tag}>` : `<${tag} ${props}/>`; }

// --- Color Definitions ---
const COLORS_HEX = {
  GOLDEN: '#F8E9D5', CORAL: '#DBAC75', GREEN: '#ABD2FF', CYAN: '#499CFD',
  BLUE: '#036EEE', DARK_BLUE: '#033674', BROWN: '#E6C7A0',
  WHITE: '#FFF8ED', // STOIC_WHITE from baseSVG.sol
  TEXT_WHITE: '#FFFFFF'
};
const C = { GOLDEN: 'GOLDEN', CORAL: 'CORAL', GREEN: 'GREEN', CYAN: 'CYAN', BLUE: 'BLUE', DARK_BLUE: 'DARK_BLUE', BROWN: 'BROWN' };

// NOTE: The on-chain contracts use Geist font, but for preview purposes we use DM_Sans as a substitute
// This creates a minor visual difference between preview and actual on-chain NFTs
let FONT_GEIST_BASE64 = "";
try {
  FONT_GEIST_BASE64 = fs.readFileSync(path.join(ASSET_DIR, 'DM_Sans.txt'), 'utf8').trim();
} catch (e) {
  console.error("CRITICAL ERROR: Could not load font file assets/DM_Sans.txt. Text will not render correctly.", e.message);
  // Proceeding without font, but previews will be inaccurate.
}

// --- Bauhaus Pattern Generation (Ported from bauhaus.sol) ---
// --- IMG1 (Consistent with bauhaus.sol::_img1) ---
function colors1_sol(v) {
  const s = [
    { r1:C.BLUE, r2:C.GOLDEN, r3:C.GOLDEN, r4:C.BROWN, r5:C.CORAL, p:C.CYAN, c1:C.GREEN, c2:C.DARK_BLUE, c3:C.GOLDEN },
    { r1:C.GREEN,r2:C.BLUE,   r3:C.GOLDEN, r4:C.BROWN, r5:C.GOLDEN,p:C.CORAL,c1:C.BLUE,   c2:C.DARK_BLUE, c3:C.BLUE },
    { r1:C.BLUE, r2:C.GOLDEN, r3:C.CYAN,   r4:C.GOLDEN,r5:C.BROWN, p:C.GREEN,c1:C.CORAL, c2:C.DARK_BLUE, c3:C.BROWN },
    { r1:C.CYAN, r2:C.BLUE,   r3:C.BLUE,   r4:C.BROWN, r5:C.BLUE,  p:C.GREEN,c1:C.GOLDEN,c2:C.DARK_BLUE, c3:C.BLUE }
  ]; return s[v];
}
function rects1_sol(cs) {
  return [
    el('rect',prop('x','16')+prop('y','55')+prop('width','268')+prop('height','268')+prop('fill',COLORS_HEX.DARK_BLUE)),
    el('rect',prop('x','128')+prop('y','55')+prop('width','156')+prop('height','268')+prop('fill',COLORS_HEX[cs.r1])),
    el('rect',prop('x','228')+prop('y','55')+prop('width','56')+prop('height','56')+prop('fill',COLORS_HEX[cs.r2])),
    el('rect',prop('x','16')+prop('y','111')+prop('width','134')+prop('height','156')+prop('fill',COLORS_HEX[cs.r3])),
    el('rect',prop('x','16')+prop('y','267')+prop('width','112')+prop('height','56')+prop('fill',COLORS_HEX[cs.r4])),
    el('rect',prop('x','228')+prop('y','267')+prop('width','56')+prop('height','56')+prop('fill',COLORS_HEX[cs.r5]))
  ].join('');
}
function polygons1_sol(cs) { return el('polygon',prop('points','16,55 72,55 16,111')+prop('fill',COLORS_HEX[cs.p])) + el('polygon',prop('points','72,55 128,55 72,111')+prop('fill',COLORS_HEX[cs.p])); }
function circles1_sol(cs) { return el('circle',prop('cx','150')+prop('cy','189')+prop('r','78')+prop('fill',COLORS_HEX[cs.c1])) + el('circle',prop('cx','228')+prop('cy','295')+prop('r','28')+prop('fill',COLORS_HEX[cs.c2])) + el('path',prop('d','M228 267C220.574 267 213.452 269.95 208.201 275.201C202.95 280.452 200 287.574 200 295C200 302.426 202.95 309.548 208.201 314.799C213.452 320.05 220.574 323 228 323L228 267Z')+prop('fill',COLORS_HEX[cs.c3])); }
function img1_sol(v) { const c=colors1_sol(v); return rects1_sol(c)+polygons1_sol(c)+circles1_sol(c); }

// --- IMG2 (Ported from bauhaus.sol::_img2) ---
function colors2_sol(v) {
  const s = [
    { r1:C.BROWN, r2:C.GOLDEN,r3:C.BLUE,  r4:C.GREEN,r5:C.CORAL,c1:C.GOLDEN,c2:C.CYAN,  c3:C.GREEN },
    { r1:C.GREEN, r2:C.BROWN, r3:C.GOLDEN,r4:C.BLUE, r5:C.CYAN, c1:C.GREEN, c2:C.CORAL, c3:C.BLUE },
    { r1:C.BLUE,  r2:C.GOLDEN,r3:C.GREEN, r4:C.BLUE, r5:C.CORAL,c1:C.CYAN,  c2:C.BROWN, c3:C.BROWN },
    { r1:C.GOLDEN,r2:C.GREEN, r3:C.BLUE,  r4:C.GOLDEN,r5:C.BROWN,c1:C.BROWN, c2:C.CYAN,  c3:C.CORAL }
  ]; return s[v]; // poly is unused
}
function rects2_sol(cs) {
  return [
    el('rect',prop('x','16')+prop('y','55')+prop('width','268')+prop('height','268')+prop('fill',COLORS_HEX.DARK_BLUE)),
    el('rect',prop('x','128')+prop('y','55')+prop('width','156')+prop('height','156')+prop('fill',COLORS_HEX[cs.r1])),
    el('rect',prop('x','16')+prop('y','111')+prop('width','134')+prop('height','100')+prop('fill',COLORS_HEX[cs.r2])),
    el('rect',prop('x','16')+prop('y','211')+prop('width','212')+prop('height','56')+prop('fill',COLORS_HEX[cs.r3])),
    el('rect',prop('x','72')+prop('y','267')+prop('width','78')+prop('height','56')+prop('fill',COLORS_HEX[cs.r4])),
    el('rect',prop('x','150')+prop('y','267')+prop('width','134')+prop('height','56')+prop('fill',COLORS_HEX[cs.r5]))
  ].join('');
}
function circles2_sol(cs) { return el('circle',prop('cx','44')+prop('cy','295')+prop('r','28')+prop('fill',COLORS_HEX[cs.c1])) + el('path',prop('d','M16 55C16 62.4 17.4 69.6 20.3 76.4C23.1 83.2 27.2 89.4 32.4 94.6C37.6 99.8 43.8 103.9 50.6 106.7C57.4 109.6 64.6 111 72 111C79.4 111 86.6 109.6 93.4 106.7C100.2 103.9 106.4 99.8 111.6 94.6C116.8 89.4 120.9 83.2 123.7 76.4C126.6 69.6 128 62.4 128 55L16 55Z')+prop('fill',COLORS_HEX[cs.c2])) + el('path',prop('d','M284 211C284 190.3 275.8 170.5 261.2 155.8C246.5 141.2 226.7 133 206 133C185.3 133 165.5 141.2 150.9 155.86C136.2 170.5 128 190.3 128 211L284 211Z')+prop('fill',COLORS_HEX[cs.c3])); }
function img2_sol(v) { const c=colors2_sol(v); return rects2_sol(c)+circles2_sol(c); /* No polygons */}

// --- IMG3 (Ported from bauhaus.sol::_img3) ---
function colors3_sol(v) {
  const s = [
    { r1:C.BLUE, r2:C.CORAL,r3:C.BLUE,  r4:C.GREEN, c1:C.GOLDEN,c2:C.CYAN,  c3:C.GOLDEN },
    { r1:C.CORAL,r2:C.GREEN,r3:C.BROWN, r4:C.GOLDEN,c1:C.BLUE,  c2:C.BLUE,  c3:C.CYAN },
    { r1:C.CORAL,r2:C.CYAN, r3:C.CORAL, r4:C.GOLDEN,c1:C.GREEN, c2:C.BLUE,  c3:C.GREEN },
    { r1:C.GOLDEN,r2:C.CORAL,r3:C.GREEN, r4:C.BLUE,  c1:C.BROWN, c2:C.BLUE,  c3:C.GREEN }
  ]; return s[v]; // rect5 and poly are unused
}
function rects3_sol(cs) {
  return [
    el('rect',prop('x','16')+prop('y','55')+prop('width','268')+prop('height','268')+prop('fill',COLORS_HEX.DARK_BLUE)),
    el('rect',prop('x','16')+prop('y','205')+prop('width','75')+prop('height','118')+prop('fill',COLORS_HEX[cs.r1])),
    el('rect',prop('x','91')+prop('y','205')+prop('width','136')+prop('height','59')+prop('fill',COLORS_HEX[cs.r2])),
    el('rect',prop('x','166')+prop('y','180')+prop('width','118')+prop('height','25')+prop('fill',COLORS_HEX[cs.r3])),
    el('rect',prop('x','166')+prop('y','55')+prop('width','118')+prop('height','126')+prop('fill',COLORS_HEX[cs.r4]))
  ].join(''); // rect5 is unused
}
function circles3_sol(cs) { return el('circle',prop('cx','91')+prop('cy','130')+prop('r','75')+prop('fill',COLORS_HEX[cs.c1])) + el('path',prop('d','M284 264 166 264 166 263C166 232 193 206 225 205C258 206 284 232 284 264C284 264 284 264 284 264Z')+prop('fill',COLORS_HEX[cs.c2])) + el('path',prop('d','M284 323 166 323 166 323C166 290 193 265 225 264C258 265 284 290 284 323C284 323 284 323 284 323Z')+prop('fill',COLORS_HEX[cs.c3])); }
function img3_sol(v) { const c=colors3_sol(v); return rects3_sol(c)+circles3_sol(c); /* No polygons, 4 rects */ }

function selectBauhausPattern(collName, troveId) {
  const variant = troveId % 4;
  
  // Directly mirror the logic in bauhaus.sol::_bauhaus function
  // This uses string-based comparisons instead of keccak256 hashing, but the logic is the same
  
  // BTC-related collateral types
  if (collName === 'wBTC' || collName === 'tBTC' || collName === 'cbBTC') {
    return img1_sol(variant);
  }
  
  // USD-related collateral types
  if (collName === 'sfrxUSD' || collName === 'scrvUSD' || 
      collName === 'sUSDS' || collName === 'sDAI' || collName === 'sUSDe') {
    return img2_sol(variant);
  }
  
  // Default fallback
  return img3_sol(variant);
}

// --- Number Formatting (Port of numUtils.toLocaleString from Utils.sol) ---
function formatNumber_sol(valueStr, inputDecimals, displayDecimals) {
  try {
    const value = BigInt(valueStr);
    
    // Calculate whole and fractional parts
    let whole, fraction;
    
    if (inputDecimals > 0) {
      const divisor = 10n ** BigInt(inputDecimals);
      whole = value / divisor;
      
      // Logic aligned with numUtils.toLocaleString
      if (inputDecimals <= displayDecimals) {
        fraction = value % divisor;
        // Adjust fraction to match precision
        fraction = fraction * (10n ** BigInt(displayDecimals - inputDecimals));
        // Special case for values near zero
        fraction = (whole === 0n && value !== 1n) ? fraction * 10n : fraction;
      } else {
        fraction = (value % divisor) / (10n ** BigInt(inputDecimals - displayDecimals - 1));
      }
    } else {
      whole = value;
      fraction = 0n;
    }
    
    // Format whole number with commas
    let wholeStr = toLocaleWholeNumber(whole.toString());
    
    // Handle the case where fraction is zero
    if (fraction === 0n) {
      if (whole > 0n && displayDecimals > 0) {
        wholeStr = wholeStr + '.';
        // Add trailing zeros
        for (let i = 0; i < displayDecimals; i++) {
          wholeStr = wholeStr + '0';
        }
      }
      return wholeStr;
    }
    
    // Format fractional part with proper padding
    let fractionStr = fraction.toString();
    
    // Ensure the fraction has the correct number of digits
    if (displayDecimals > fractionStr.length) {
      const padding = '0'.repeat(displayDecimals - fractionStr.length);
      fractionStr = padding + fractionStr;
    } else if (fractionStr.length > displayDecimals) {
      fractionStr = fractionStr.substring(0, displayDecimals);
    }
    
    return displayDecimals > 0 ? `${wholeStr}.${fractionStr}` : wholeStr;
  } catch (e) {
    console.error(`Error formatting number '${valueStr}':`, e);
    return valueStr; // fallback
  }
}

// Helper function to add commas to whole number portion
function toLocaleWholeNumber(numStr) {
  // Skip if less than 4 digits
  if (numStr.length < 4) return numStr;
  
  // Calculate number of commas needed
  const numCommas = Math.floor((numStr.length - 1) / 3);
  const result = new Array(numStr.length + numCommas);
  
  let j = result.length - 1;
  let k = numStr.length;
  
  for (let i = 0; i < numStr.length; i++) {
    result[j] = numStr[k - 1];
    j = j > 0 ? j - 1 : 0;
    k--;
    
    if (k > 0 && (numStr.length - k) % 3 === 0) {
      result[j] = ',';
      j = j > 0 ? j - 1 : 0;
    }
  }
  
  return result.join('');
}

// --- Status Mapping (matches Solidity's baseSVG._status) ---
function statusToString_sol(statusNum) {
  // Match the contract's ITroveManager.Status enum values and strings
  if (statusNum === 1) return "Active";         // Status.active
  if (statusNum === 2) return "Closed";         // Status.closedByOwner  
  if (statusNum === 3) return "Liquidated";     // Status.closedByLiquidation
  if (statusNum === 4) return "Below Min Debt"; // Status.zombie
  if (statusNum === 0) return "Pending";        // Not in contract, but used in preview for testing
  return "Unknown";
}

// --- Asset Loading (Keep as is, but ensure data matches FixedAssetReader) ---
// Mapping for odd symbol aliases that don't match file names exactly
const ICON_FILE_MAP = {
  USDS: 'sUSDS',   // legacy alias used by UI, file on disk is sUSDS.txt
  sUSDe: 'sUSDE',  // different casing
};
function fileNameForCollateral(collName) {
  return ICON_FILE_MAP[collName] || collName;
}
function getIconBase64(collName) {
  const fileBase = fileNameForCollateral(collName);
  if (!fileBase) return null;
  try {
    return fs.readFileSync(path.join(ASSET_DIR, `${fileBase}.txt`), 'utf8').trim();
  } catch (e) {
    console.error(`Error loading icon for ${collName} (tried ${fileBase}.txt):`, e.message);
    return null;
  }
}
function getUSDafIconBase64() {
  try {
    return fs.readFileSync(path.join(ASSET_DIR, 'USDaf.txt'), 'utf8').trim();
  } catch (e) {
    console.error(`Error loading USDaf icon:`, e.message);
    return null;
  }
}

// --- Leverage Logo (from baseSVG.sol) ---
function leverageLogo_sol() {
  let asfLogoBase64;
  try {
    asfLogoBase64 = fs.readFileSync(path.join(ASSET_DIR, 'ASF-logo.txt'), 'utf8').trim();
  } catch (e) {
    console.error('Error loading ASF-logo.txt:', e.message);
    return '';
  }
  // Position and size should match Solidity logic
  return el('image',
    prop('x', '16') +
    prop('y', '19') +
    prop('width', '19') +
    prop('height', '19') +
    prop('href', `data:image/svg+xml;base64,${asfLogoBase64}`)
  );
}

// --- Main SVG Builder ---
function buildSVG_sol({ collName, troveId, rawDebt, rawColl, rawRate, owner, numericStatus, tokenIdStr }) {
  const collIconBase64 = getIconBase64(collName);
  const usdafIconBase64 = getUSDafIconBase64();

  // Format numbers (assuming raw values are full integer strings like uint256 would be)
  const formattedColl = formatNumber_sol(rawColl, 18, 4); // Example: 18 input, 4 display decimals
  const formattedDebt = formatNumber_sol(rawDebt, 18, 2); // Example: 18 input, 2 display decimals
  const formattedRate = formatNumber_sol(rawRate, 16, 2); // Example: 16 input, 2 display decimals

  // Token ID formatting (matches Solidity's LibString.slice for 0x... type string)
  const formattedTokenId = tokenIdStr.length > 10 ? `${tokenIdStr.slice(0, 6)}...${tokenIdStr.slice(-4)}` : tokenIdStr;
  const formattedOwner = owner.length > 10 ? `${owner.slice(0, 6)}...${owner.slice(-4)}` : owner;
  const statusText = statusToString_sol(numericStatus);

  const dmSans = 'font-family: DM Sans, Geist;'; // Fallback to DM Sans if Geist is not loaded

  return `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="484" viewBox="0 0 300 484">
    <style>
      @font-face { font-family: "Geist"; src: url("data:font/woff2;base64,${FONT_GEIST_BASE64}"); }
      text { ${dmSans} }
    </style>
    <rect ${prop('fill',COLORS_HEX.DARK_BLUE)} ${prop('rx','8')} ${prop('width','300')} ${prop('height','484')}/>
    ${leverageLogo_sol()}
    ${selectBauhausPattern(collName, troveId)}
    ${collIconBase64 ? `<image ${prop('x','264')} ${prop('y','342.5')} ${prop('width','20')} ${prop('height','20')} href="data:image/svg+xml;base64,${collIconBase64}"/>` : ''}
    ${usdafIconBase64 ? `<image ${prop('x','264')} ${prop('y','373.5')} ${prop('width','20')} ${prop('height','20')} href="data:image/svg+xml;base64,${usdafIconBase64}"/>` : ''}
    
    {/* Static Text - Matches baseSVG.sol order and content */}
    <text ${prop('x','16')} ${prop('y','358')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>Collateral</text>
    <text ${prop('x','16')} ${prop('y','389')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>Debt</text>
    <text ${prop('x','16')} ${prop('y','420')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>Interest Rate</text>
    <text ${prop('x','265')} ${prop('y','422')} ${prop('font-size','20')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>%</text>
    <text ${prop('x','16')} ${prop('y','462')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>Owner</text>

    {/* Dynamic Text - Matches baseSVG.sol positioning and formatting concept */}
    <text ${prop('text-anchor','end')} ${prop('x','284')} ${prop('y','33')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${formattedTokenId}</text> {/* Token ID (top-right) */}
    <text ${prop('x','40')} ${prop('y','33')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${statusText}</text> {/* Status (top-left) */}
    
    <text ${prop('text-anchor','end')} ${prop('x','256')} ${prop('y','360')} ${prop('font-size','20')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${formattedColl}</text>
    <text ${prop('text-anchor','end')} ${prop('x','256')} ${prop('y','391')} ${prop('font-size','20')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${formattedDebt}</text>
    <text ${prop('text-anchor','end')} ${prop('x','256')} ${prop('y','422')} ${prop('font-size','20')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${formattedRate}</text>
    <text ${prop('text-anchor','end')} ${prop('x','284')} ${prop('y','462')} ${prop('font-size','14')} ${prop('fill',COLORS_HEX.TEXT_WHITE)}>${formattedOwner}</text>
  </svg>`;
}

// --- Example Usage ---
const collateralTypes = [
  'wBTC', 'tBTC', 'cbBTC',        // BTC Group
  'sDAI', 'sUSDe', 'sUSDS',       // USD Group (keep both sUSDe and sUSDS)
  'sfrxUSD', 'scrvUSD',           // USD Group (cont.)
];
// Status values from ITroveManager.Status enum: 1=active, 2=closedByOwner, 3=closedByLiquidation, 4=zombie
const statusValues = [
  { value: 1, name: "Active" },
  { value: 2, name: "Closed" },
  { value: 3, name: "Liquidated" },
  { value: 4, name: "Below_Min_Debt" }
];

collateralTypes.forEach(collName => {
  // Generate one variant for each status to demonstrate all possible statuses
  statusValues.forEach(status => {
    const exampleTroveId = status.value % 4; // Cycle through variants based on status
    const exampleData = {
      collName,
      troveId: exampleTroveId,
      rawDebt: '1234560000000000000000', // e.g., 1234.56 with 18 decimals
      rawColl: '789012000000000000000000', // e.g., 78901.2 with 18 decimals
      rawRate: '23400000000000000',       // e.g., 2.34% with 16 decimals for rate display
      owner: '0x1234567890abcdef1234567890abcdef12345678',
      numericStatus: status.value, // Set status based on loop
      tokenIdStr: `0xTokenId_${collName}_status${status.value}`
    };
    
    const svgOutput = buildSVG_sol(exampleData);
    const outputPath = `${__dirname}/preview-2_${collName}_status${status.name}.svg`;
    fs.writeFileSync(outputPath, svgOutput);
    console.log(`Generated ${outputPath} (Status: ${status.name})`);
  });
  
  // Also generate one example with variant exploration for the default Active status
  if (collName === collateralTypes[0]) { // Just do this for the first collateral type
    console.log("\nGenerating variant examples for", collName, "with Active status:");
    for (let i = 0; i < 4; i++) {
      const exampleData = {
        collName,
        troveId: i,
        rawDebt: '1234560000000000000000',
        rawColl: '789012000000000000000000',
        rawRate: '23400000000000000',
        owner: '0x1234567890abcdef1234567890abcdef12345678',
        numericStatus: 1, // Active
        tokenIdStr: `0xTokenId_${collName}_var${i}`
      };
      
      const svgOutput = buildSVG_sol(exampleData);
      const outputPath = `${__dirname}/preview-2_${collName}_Active_variant${i}.svg`;
      fs.writeFileSync(outputPath, svgOutput);
      console.log(`Generated ${outputPath}`);
    }
  }
});

// console.log("\nIMPORTANT: Make sure to replace FONT_GEIST_BASE64 placeholder with actual font data.");
// Commented out as font is now loaded from DM_Sans.txt
console.log("\nIMPORTANT: The formatNumber_sol function is a placeholder and may need a more robust BigInt library or exact port of Solidity's numUtils.toLocaleString for perfect accuracy.");
console.log("IMPORTANT: Ensure local icon files in assets/ match the data in FixedAssetReader for corresponding keccak256 keys.");
