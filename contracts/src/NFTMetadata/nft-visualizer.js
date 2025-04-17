// NFT Visualizer for USA.d Trove NFTs
// This script creates sample SVGs based on the updated NFT design

const fs = require('fs');
const path = require('path');

// Output directory
const outputDir = './nft-output';

// Check if output directory exists - if not, create it
if (!fs.existsSync(outputDir)) {
  try {
    fs.mkdirSync(outputDir, { recursive: true });
  } catch (err) {
    console.error(`Failed to create output directory: ${err.message}`);
    console.log('Will attempt to write to current directory instead');
  }
}

// SVG Utility Functions
const svg = {
  prop: (key, val) => `${key}="${val}" `,
  el: (tag, props, children = '') => {
    return children ? `<${tag} ${props}>${children}</${tag}>` : `<${tag} ${props}/>`;
  },
  rect: (props) => svg.el('rect', props),
  circle: (props) => svg.el('circle', props),
  text: (props, content) => svg.el('text', props, content),
  path: (d, props = '') => svg.el('path', `d="${d}" ${props}`),
  polygon: (props) => svg.el('polygon', props),
  line: (props) => svg.el('line', props),
  _svg: (props, children) => svg.el('svg', `xmlns="http://www.w3.org/2000/svg" ${props}`, children)
};

// Color Constants
const COLORS = {
  DARK_BLUE: "#0F1739",
  STOIC_WHITE: "#DEE4FB",
  GOLDEN: "#D1B931",
  CORAL: "#D6694C",
  GREEN: "#54B76A",
  CYAN: "#7FADD0",
  BLUE: "#364CC3",
  BROWN: "#B87F55",
  PURPLE: "#803CD9",
  TEAL: "#40B2A0",
  WHITE: "#FFFFFF",
  LIGHT_GRAY: "#CACACA",
  SOFT_WHITE: "#D3D3D9",
  STATUS_GREEN: "#285833",    // Active status (40% darker than #439255)
  STATUS_BLUE: "#1A255E",     // Closed status (40% darker than #2B3D9C)
  STATUS_RED: "#681F1F",      // Liquidated status (40% darker than #AE3434)
  STATUS_ORANGE: "#683B1A"    // Below Min Debt status (40% darker than #AE622B)
};

// Base SVG Elements
const baseSVG = {
  GEIST: 'style="font-family: DM Sans, sans-serif" ', // Using DM Sans for consistency, note: on-chain embeds base64 font data which can't be replicated in browser
  
  svgProps: () => {
    return `${svg.prop('width', '300')}${svg.prop('height', '484')}${svg.prop('viewBox', '0 0 300 484')}${svg.prop('style', 'background:none')}`;
  },
  
  baseElements: () => {
    return `${baseSVG.leverageLogo()}${baseSVG.boldLogo()}${baseSVG.staticTextEls()}`;
  },
  
  backgroundRect: (color) => {
    return svg.rect(`${svg.prop('fill', color)}${svg.prop('rx', '8')}${svg.prop('width', '300')}${svg.prop('height', '484')}`);
  },
  
  leverageLogo: () => {
    // Use actual leverage logo icon from base64 data
    return svg.el('image', `${svg.prop('x', '16')}${svg.prop('y', '18')}${svg.prop('width', '18')}${svg.prop('height', '18')}${svg.prop('opacity', '0.8')}${svg.prop('shape-rendering', 'crispEdges')}${svg.prop('href', `data:image/svg+xml;base64,${getAssetSVG('LeverageLogo')}`)}`)
  },
  
  boldLogo: () => {
    // Use actual USA.d logo icon
    return svg.el('image', `${svg.prop('x', '262')}${svg.prop('y', '371.5')}${svg.prop('width', '24')}${svg.prop('height', '24')}${svg.prop('shape-rendering', 'crispEdges')}${svg.prop('href', `data:image/svg+xml;base64,${getAssetSVG('USA.d')}`)}`)
  },
  
  staticTextEls: () => {
    return `${svg.text(`${baseSVG.GEIST}${svg.prop('x', '16')}${svg.prop('y', '358')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, "Collateral")}
      ${svg.text(`${baseSVG.GEIST}${svg.prop('x', '16')}${svg.prop('y', '389')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, "Debt")}
      ${svg.text(`${baseSVG.GEIST}${svg.prop('x', '16')}${svg.prop('y', '420')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, "Interest Rate")}
      ${svg.text(`${baseSVG.GEIST}${svg.prop('x', '245')}${svg.prop('y', '422')}${svg.prop('font-size', '20')}${svg.prop('fill', 'white')}`, "%")}
      ${svg.text(`${baseSVG.GEIST}${svg.prop('x', '16')}${svg.prop('y', '462')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, "Owner")}`;
  },
  
  statusEl: (status) => {
    // Always use white text for status for better contrast with colored backgrounds
    return svg.text(`${baseSVG.GEIST}${svg.prop('x', '40')}${svg.prop('y', '33')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, status);
  },
  
  formattedIdEl: (id) => {
    return svg.text(`${baseSVG.GEIST}${svg.prop('text-anchor', 'end')}${svg.prop('x', '284')}${svg.prop('y', '33')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, id);
  },
  
  formattedAddressEl: (address) => {
    return svg.text(`${baseSVG.GEIST}${svg.prop('text-anchor', 'end')}${svg.prop('x', '284')}${svg.prop('y', '462')}${svg.prop('font-size', '14')}${svg.prop('fill', 'white')}`, address);
  },
  
  formattedDynamicEl: (value, x, y) => {
    return svg.text(`${baseSVG.GEIST}${svg.prop('text-anchor', 'end')}${svg.prop('x', x)}${svg.prop('y', y)}${svg.prop('font-size', '20')}${svg.prop('fill', 'white')}`, value);
  },
  
  dynamicTextEls: (debt, coll, interestRate) => {
    return `${baseSVG.formattedDynamicEl(coll, 256, 358)}${baseSVG.formattedDynamicEl(debt, 256, 389)}${baseSVG.formattedDynamicEl(interestRate, 240, 422)}`;
  },
  
  collLogo: (collName) => {
    // Use actual collateral logo icon from simulated FixedAssetReader
    return svg.el('image', `${svg.prop('x', '262')}${svg.prop('y', '340.5')}${svg.prop('width', '24')}${svg.prop('height', '24')}${svg.prop('shape-rendering', 'crispEdges')}${svg.prop('href', `data:image/svg+xml;base64,${getAssetSVG(collName)}`)}`)
  }
};

// Function to simulate the FixedAssetReader contract by providing base64 encoded SVG icons
function getAssetSVG(assetName) {
  // Use actual base64 encoded SVGs from files
  const fs = require('fs');
  const path = require('path');
  
  // Path to base64 encoded SVG files
  const basePath = path.join(__dirname, 'utils', 'SVGsBase64');
  
  // Map asset name to filename
  const fileMap = {
    'USA.d': 'USA.d.txt',
    'tBTC': 'tBTC.txt',
    'wBTC': 'wBTC.txt',
    'cbBTC': 'cbBTC.txt',
    'sUSDS': 'sUSDS.txt',
    'sfrxUSD': 'sfrxUSD.txt',
    'scrvUSD': 'scrvUSD.txt',
    'sDAI': 'sDAI.txt',
    'sfrxETH': 'sfrxETH.txt',  // Updated to use sfrxETH.txt
    'LeverageLogo': 'ASF-logo.txt',  // Updated to use ASF-logo
  };
  
  // Get the appropriate file path
  const fileName = fileMap[assetName] || 'USA.d.txt';
  const filePath = path.join(basePath, fileName);
  
  try {
    // Read the base64 encoded SVG from file
    if (fs.existsSync(filePath)) {
      console.log(`Loading SVG for ${assetName} from ${filePath}`);
      return fs.readFileSync(filePath, 'utf8').trim();
    } else {
      console.log(`File not found: ${filePath}`);
    }
  } catch (error) {
    console.error(`Error reading SVG file for ${assetName} (${filePath}): ${error}`);
  }
  
  // Fallback to generated SVGs if file not found
  console.log(`Using fallback SVG for ${assetName}`);
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
    <circle cx="50" cy="50" r="45" fill="#CCCCCC"/>
    <text x="50" y="65" font-size="35" font-weight="bold" text-anchor="middle" fill="#555555">${assetName}</text>
  </svg>`).toString('base64');
}

// Quadtree Point class for line patterns
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
}

// Quadtree class for generating line-based patterns
class Quadtree {
  constructor(boundary, capacity, depth = 0, maxDepth = 5) {
    this.boundary = boundary; // {x, y, width, height}
    this.capacity = capacity; // Max points before subdivision
    this.points = [];
    this.divided = false;
    this.children = [];
    this.depth = depth;
    this.maxDepth = maxDepth;
  }

  // Add a point to the quadtree
  insert(point) {
    // If point is not in current boundary, don't add it
    if (!this.containsPoint(point)) {
      return false;
    }

    // If there's still room or we've reached max depth, add the point
    if (this.points.length < this.capacity || this.depth >= this.maxDepth) {
      this.points.push(point);
      return true;
    }

    // Otherwise, subdivide and add to appropriate child
    if (!this.divided) {
      this.subdivide();
    }

    // Try to insert point into a child
    for (let child of this.children) {
      if (child.insert(point)) {
        return true;
      }
    }

    return false;
  }

  // Check if a point is within the boundary
  containsPoint(point) {
    return (
      point.x >= this.boundary.x &&
      point.x < this.boundary.x + this.boundary.width &&
      point.y >= this.boundary.y &&
      point.y < this.boundary.y + this.boundary.height
    );
  }

  // Subdivide the current quadtree into four children
  subdivide() {
    const { x, y, width, height } = this.boundary;
    const halfWidth = width / 2;
    const halfHeight = height / 2;

    // Create four children
    const nw = { x, y, width: halfWidth, height: halfHeight };
    const ne = { x: x + halfWidth, y, width: halfWidth, height: halfHeight };
    const sw = { x, y: y + halfHeight, width: halfWidth, height: halfHeight };
    const se = { x: x + halfWidth, y: y + halfHeight, width: halfWidth, height: halfHeight };

    this.children = [
      new Quadtree(nw, this.capacity, this.depth + 1, this.maxDepth),
      new Quadtree(ne, this.capacity, this.depth + 1, this.maxDepth),
      new Quadtree(sw, this.capacity, this.depth + 1, this.maxDepth),
      new Quadtree(se, this.capacity, this.depth + 1, this.maxDepth)
    ];

    this.divided = true;
  }

  // Get all subdivision lines for drawing
  getLines() {
    let lines = [];
    
    if (this.divided) {
      // Add the two division lines of this node
      const { x, y, width, height } = this.boundary;
      const midX = x + width / 2;
      const midY = y + height / 2;
      
      // Vertical division line
      lines.push({ x1: midX, y1: y, x2: midX, y2: y + height });
      
      // Horizontal division line
      lines.push({ x1: x, y1: midY, x2: x + width, y2: midY });
      
      // Add lines from children
      for (let child of this.children) {
        lines = lines.concat(child.getLines());
      }
    }
    
    return lines;
  }
  
  // Get all points in the quadtree
  getAllPoints() {
    let allPoints = [...this.points];
    
    if (this.divided) {
      for (let child of this.children) {
        allPoints = allPoints.concat(child.getAllPoints());
      }
    }
    
    return allPoints;
  }
  
  // Generate triangulation lines based on quadtree points
  generateTriangulation() {
    let triangles = [];
    const allPoints = this.getAllPoints();
    
    // For simplicity, connect all corner points and some interior points
    // This is a naive approach; a proper Delaunay triangulation would be better
    
    // Add diagonal lines based on quadtree divisions
    if (this.divided) {
      const divisionLines = this.getLines();
      const { x, y, width, height } = this.boundary;
      
      // Add triangulating lines (diagonals)
      triangles.push({ 
        x1: x, y1: y, 
        x2: x + width, y2: y + height 
      });
      
      // Add triangulating lines (other diagonal)
      triangles.push({ 
        x1: x + width, y1: y, 
        x2: x, y2: y + height 
      });
      
      // Add children's triangulations
      for (let child of this.children) {
        triangles = triangles.concat(child.generateTriangulation());
      }
    }
    
    return triangles;
  }
}

// Function to generate a Quadtree with randomly distributed points
function generateQuadtree(x, y, width, height, numPoints, seed = 123456) {
  const boundary = { x, y, width, height };
  const quadtree = new Quadtree(boundary, 3, 0, 3); // capacity 3, max depth 3
  
  // Generate deterministic random points using seed
  let rand = seed;
  const nextRandom = () => {
    rand = (rand * 9301 + 49297) % 233280;
    return rand / 233280;
  };

  for (let i = 0; i < numPoints; i++) {
    const pointX = boundary.x + nextRandom() * boundary.width;
    const pointY = boundary.y + nextRandom() * boundary.height;
    quadtree.insert(new Point(pointX, pointY));
  }
  
  // Add corner points to ensure we have the boundary defined
  quadtree.insert(new Point(boundary.x, boundary.y));
  quadtree.insert(new Point(boundary.x + boundary.width, boundary.y));
  quadtree.insert(new Point(boundary.x, boundary.y + boundary.height));
  quadtree.insert(new Point(boundary.x + boundary.width, boundary.y + boundary.height));
  
  // Ensure we have center points on each edge
  quadtree.insert(new Point(boundary.x + boundary.width/2, boundary.y));
  quadtree.insert(new Point(boundary.x, boundary.y + boundary.height/2));
  quadtree.insert(new Point(boundary.x + boundary.width, boundary.y + boundary.height/2));
  quadtree.insert(new Point(boundary.x + boundary.width/2, boundary.y + boundary.height));
  
  // Subdivide if not already
  if (!quadtree.divided) {
    quadtree.subdivide();
  }
  
  return quadtree;
}

// Function to generate geometric pattern for Active status - line-based quadtree pattern
function createQuadtreePattern(color, strokeWidth = 1, density = 10, randomSeed = 12345) {
    const boxX = 26;
    const boxY = 65;
    const boxWidth = 248;
    const boxHeight = 248;
  
  let elements = [];

  // Create background
    elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="${color}" fill-opacity="0.15" rx="5" />`
  );
  
  // Generate quadtree with points
  const quadtree = generateQuadtree(boxX, boxY, boxWidth, boxHeight, density, randomSeed);
  
  // Get division lines
  const divisionLines = quadtree.getLines();
  
  // Draw quadtree division lines with animation
  let lineIndex = 0;
  for (const line of divisionLines) {
    const dur = 2 + (lineIndex % 8) * 0.25; // Vary duration for a dynamic effect
    elements.push(
      `<line x1="${line.x1}" y1="${line.y1}" x2="${line.x2}" y2="${line.y2}" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth}" stroke-opacity="0.8" >
         <animate attributeName="stroke-opacity" from="0.8" to="0.4" dur="${dur}s" repeatCount="indefinite" />
       </line>`
    );
    lineIndex++;
  }
  
  // Get triangulation lines
  const triangleLines = quadtree.generateTriangulation();
  
  // Draw triangulation lines with animation
  lineIndex = 0;
  for (const line of triangleLines) {
    const dur = 2 + (lineIndex % 6) * 0.3; // Slightly different timing for variety
    elements.push(
      `<line x1="${line.x1}" y1="${line.y1}" x2="${line.x2}" y2="${line.y2}" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth}" stroke-opacity="0.6" >
         <animate attributeName="stroke-opacity" from="0.6" to="0.3" dur="${dur}s" repeatCount="indefinite" />
       </line>`
    );
    lineIndex++;
  }
  
  // Draw border
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="none" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth * 1.5}" stroke-opacity="0.9" rx="5" />`
    );

    return elements.join('');
}

// Function to generate a simplified reflection pattern with concentric circles
function reflectionPattern() {
  const boxX = 26;
  const boxY = 65;
  const boxWidth = 248;
  const boxHeight = 248;
  
  let elements = [];
  
  // Create background
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="${COLORS.STATUS_GREEN}" fill-opacity="0.15" rx="5" />`
  );
  
  // Add clip path to ensure pattern stays within the box
  const clipPathId = "reflectionClip";
  elements.push(
    `<clipPath id="${clipPathId}">
      <rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" rx="5" />
    </clipPath>`
  );
  
  // Open a group with the clip path applied
  elements.push(`<g clip-path="url(#${clipPathId})">`);
  
  // Parameters for the pattern
  const centerX = boxX + boxWidth / 2;
  const centerY = boxY + boxHeight / 2;
  const circleCount = 25; // Updated to match on-chain logic
  const maxRadius = boxWidth * 0.7;
  const fadeOpacityStart = 0.9;
  const fadeOpacityEnd = 0.3;
  
  // Draw concentric circles from center with animation
  for (let i = circleCount; i > 0; i--) {
    const radius = (i / circleCount) * maxRadius;
    const opacity = fadeOpacityStart - ((fadeOpacityStart - fadeOpacityEnd) * (circleCount - i) / circleCount);
    const dur = 2 + (i * 0.1); // Animation duration increases slightly for outer circles
    elements.push(
      `<circle cx="${centerX}" cy="${centerY}" r="${radius}" fill="none" stroke="${COLORS.WHITE}" stroke-width="1.0" stroke-opacity="${opacity}" >
         <animate attributeName="stroke-opacity" from="${opacity}" to="${opacity * 0.5}" dur="${dur}s" repeatCount="indefinite" />
       </circle>`
    );
  }
  
  // Close the clipped group
  elements.push(`</g>`);
  
  // Add border
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="none" stroke="${COLORS.WHITE}" stroke-width="1.5" stroke-opacity="0.9" rx="5" />`
  );
  
  return elements.join('');
}

// Function to generate a 10 PRINT pattern (ttten style) for Closed status
function mondrianPattern() {
  const boxX = 26;
  const boxY = 65;
  const boxWidth = 248;
  const boxHeight = 248;
  
  let elements = [];
  
  // Create background
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="${COLORS.STATUS_BLUE}" fill-opacity="0.15" rx="5" />`
  );
  
  // First add a clip path to ensure the pattern stays within bounds
  const clipPathId = "ttenClip";
  elements.push(
    `<clipPath id="${clipPathId}">
      <rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" rx="5" />
    </clipPath>`
  );
  
  // Open a group with the clip path applied
  elements.push(`<g clip-path="url(#${clipPathId})">`);
  
  // 10 PRINT pattern parameters
  const gridSize = 16; // Updated to match on-chain logic
  const strokeWidth = 1.5; // Updated to match on-chain logic
  
  // Create the 10 PRINT pattern (ttten style)
  // Initialize random seed
  let rand = 54321;
  const nextRandom = () => {
    rand = (rand * 9301 + 49297) % 233280;
    return rand / 233280;
  };
  
  // Generate the maze-like pattern by drawing diagonal lines with animation
  let lineIndex = 0;
  for (let y = boxY; y < boxY + boxHeight; y += gridSize) {
    for (let x = boxX; x < boxX + boxWidth; x += gridSize) {
      const dur = 2 + (lineIndex % 10) * 0.2; // Vary duration for dynamic effect
      // Randomly choose between diagonal lines (↘ or ↙)
      if (nextRandom() > 0.5) {
        // Diagonal from top-left to bottom-right (↘)
        elements.push(
          `<line x1="${x}" y1="${y}" x2="${x + gridSize}" y2="${y + gridSize}" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth}" stroke-opacity="0.9" >
             <animate attributeName="stroke-opacity" from="0.9" to="0.5" dur="${dur}s" repeatCount="indefinite" />
           </line>`
        );
      } else {
        // Diagonal from top-right to bottom-left (↙)
        elements.push(
          `<line x1="${x + gridSize}" y1="${y}" x2="${x}" y2="${y + gridSize}" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth}" stroke-opacity="0.9" >
             <animate attributeName="stroke-opacity" from="0.9" to="0.5" dur="${dur}s" repeatCount="indefinite" />
           </line>`
        );
      }
      lineIndex++;
    }
  }
  
  // Close the clipped group
  elements.push(`</g>`);
  
  // Draw border
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="none" stroke="${COLORS.WHITE}" stroke-width="${strokeWidth * 1.5}" stroke-opacity="0.9" rx="5" />`
  );
  
  return elements.join('');
}

// Function to generate hexagon path for gggyrate pattern
function createHexagonPath(centerX, centerY, size) {
  const points = [];
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 3) * i - Math.PI / 6;
    const x = centerX + size * Math.cos(angle);
    const y = centerY + size * Math.sin(angle);
    points.push(`${x},${y}`);
  }
  return points.join(' ');
}

// Function to generate a gggyrate pattern for Liquidated status
function gyratePattern() {
  const boxX = 26;
  const boxY = 65;
  const boxWidth = 248;
  const boxHeight = 248;
  
  const centerX = boxX + boxWidth / 2;
  const centerY = boxY + boxHeight / 2;
  
  // Calculate the maxSize to ensure the outermost hexagon reaches the corners of the rectangle
  // For a regular hexagon, we need the distance from center to corner which is the half-diagonal
  // multiplied by 1.15 to ensure corners are covered
  const maxRadius = Math.sqrt(Math.pow(boxWidth/2, 2) + Math.pow(boxHeight/2, 2)) * 1.15;
  
  let elements = [];
  
  // Create background
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="${COLORS.STATUS_RED}" fill-opacity="0.15" rx="5" />`
  );
  
  // Add clip path to ensure pattern stays within the box
  const clipPathId = "gyrateClip";
  elements.push(
    `<clipPath id="${clipPathId}">
      <rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" rx="5" />
    </clipPath>`
  );
  
  // Open a group with the clip path applied
  elements.push(`<g clip-path="url(#${clipPathId})">`);
  
  // Generate concentric hexagons with animation
  const numShapes = 25;
  const fadeOpacityStart = 0.9;
  const fadeOpacityEnd = 0.3;
  
  for (let i = numShapes; i > 0; i--) {
    const size = (i / numShapes) * maxRadius;
    const opacity = fadeOpacityStart - ((fadeOpacityStart - fadeOpacityEnd) * (numShapes - i) / numShapes);
    const dur = 2 + (i * 0.1); // Animation duration varies for dynamic effect
    
    const hexPoints = createHexagonPath(centerX, centerY, size);
    
    elements.push(
      `<polygon points="${hexPoints}" fill="none" stroke="${COLORS.WHITE}" stroke-width="1" stroke-opacity="${opacity}" >
         <animate attributeName="stroke-opacity" from="${opacity}" to="${opacity * 0.5}" dur="${dur}s" repeatCount="indefinite" />
       </polygon>`
    );
  }
  
  // Close the clipped group
  elements.push(`</g>`);
  
  // Add border
  elements.push(
    `<rect x="${boxX}" y="${boxY}" width="${boxWidth}" height="${boxHeight}" fill="none" stroke="${COLORS.WHITE}" stroke-width="1.5" stroke-opacity="0.9" rx="5" />`
  );
  
  return elements.join('');
}

function diamondPattern() {
  return createQuadtreePattern(COLORS.STATUS_ORANGE, 0.8, 14, 24680);
}

// Function to generate NFT SVG
function generateNFT(collateralType, status) {
  // Determine status color
  let statusColor;
  let pattern;
  switch(status) {
    case 'Active':
      statusColor = COLORS.STATUS_GREEN;
      pattern = reflectionPattern();
      break;
    case 'Closed':
      statusColor = COLORS.STATUS_BLUE;
      pattern = mondrianPattern();
      break;
    case 'Liquidated':
      statusColor = COLORS.STATUS_RED;
      pattern = gyratePattern();
      break;
    case 'Below Min Debt':
      statusColor = COLORS.STATUS_ORANGE;
      pattern = diamondPattern();
      break;
    default:
      statusColor = COLORS.STOIC_WHITE;
      pattern = reflectionPattern();
  }
  
  // Generate sample values
  const id = '0x1234...5678';
  const collateral = '123.456';
  const debt = '50,000';
  const interestRate = '1.5';
  const owner = '0xabcd...efgh';
  
  // Create SVG
  const svgContent = svg._svg(
    baseSVG.svgProps(),
    `${baseSVG.backgroundRect(statusColor)}
    ${pattern}
    ${baseSVG.baseElements()}
    ${baseSVG.statusEl(status)}
    ${baseSVG.formattedIdEl(id)}
    ${baseSVG.formattedAddressEl(owner)}
    ${baseSVG.collLogo(collateralType)}
    ${baseSVG.dynamicTextEls(debt, collateral, interestRate)}`
  );
  
  return svgContent;
}

// Generate and save all NFTs
async function generateNFTs() {
  // Check if SVGsBase64 directory exists with our files
  const svgBasePath = path.join(__dirname, 'utils', 'SVGsBase64');
  if (!fs.existsSync(svgBasePath)) {
    console.error(`ERROR: SVGsBase64 directory not found at ${svgBasePath}`);
    console.log('Please make sure the base64 encoded SVG files are in place');
    return;
  }
  
  console.log(`Found SVGsBase64 directory at ${svgBasePath}`);

  // Correct list of 8 collateral types
  const collateralTypes = [
    'tBTC', 
    'wBTC', 
    'cbBTC', 
    'sUSDS', 
    'sfrxUSD', 
    'scrvUSD', 
    'sDAI', 
    'sfrxETH'
  ];
  const statuses = ['Active', 'Closed', 'Liquidated', 'Below Min Debt'];
  
  // Generate NFTs for each collateral type and status
  try {
    let outputPath;
    // Try to use the specified output directory first
    if (fs.existsSync(outputDir) || fs.mkdirSync(outputDir, { recursive: true })) {
      outputPath = outputDir;
    } else {
      // Fall back to current directory
      outputPath = '.';
      console.log(`Using current directory for output: ${outputPath}`);
    }
    
    for (const collType of collateralTypes) {
      for (const status of statuses) {
        const svg = generateNFT(collType, status);
        const filename = `${collType}-${status.replace(' ', '-')}.svg`;
        const filepath = path.join(outputPath, filename);
        
        try {
          fs.writeFileSync(filepath, svg);
          console.log(`Generated ${filepath}`);
        } catch (err) {
          console.error(`Error writing to ${filepath}: ${err.message}`);
        }
      }
    }
    
    // Create HTML preview
    createHTMLPreview(collateralTypes, statuses, outputPath);
    console.log('Generated HTML preview');
  } catch (err) {
    console.error(`Error generating NFTs: ${err.message}`);
  }
}

// Create HTML preview file that shows all generated NFTs
function createHTMLPreview(collateralTypes, statuses, outputPath = '.') {
  try {
    let html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>USA.d Trove NFT Previews</title>
      <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 20px; }
        h1 { color: #121B44; }
        h2 { margin-top: 30px; }
        .nft-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
        .nft-card { background: white; border-radius: 10px; padding: 15px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        h3 { margin-top: 0; color: #121B44; }
        img { max-width: 100%; height: auto; border-radius: 8px; }
        .status-section { margin-bottom: 40px; }
      </style>
    </head>
    <body>
      <h1>USA.d Trove NFT Previews</h1>
      <p>Updated designs showing minimalist geometric line patterns with proper collateral icons.</p>
    `;
    
    // Group by status first
    for (const status of statuses) {
      html += `
      <div class="status-section">
        <h2>Status: ${status}</h2>
        <div class="nft-grid">
      `;
      
      // Show all collateral types for this status
      for (const collateralType of collateralTypes) {
        const filename = `${collateralType}-${status.replace(' ', '-')}.svg`;
        
        html += `
        <div class="nft-card">
          <h3>${collateralType}</h3>
          <img src="${filename}" alt="${collateralType} ${status}" />
        </div>
        `;
      }
      
      html += `
        </div>
      </div>
      `;
    }
    
    html += `
    </body>
    </html>
    `;
    
    const previewPath = path.join(outputPath, 'preview.html');
    fs.writeFileSync(previewPath, html);
    console.log(`Generated HTML preview: ${previewPath}`);
  } catch (err) {
    console.error(`Error creating HTML preview: ${err.message}`);
  }
}

// Call the main function
generateNFTs().then(() => {
  console.log('NFT generation complete!');
}).catch(err => {
  console.error('Error generating NFTs:', err);
}); 