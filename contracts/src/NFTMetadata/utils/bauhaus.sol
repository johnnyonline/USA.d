//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SVG.sol";
import {LibString} from "./Utils.sol";

library bauhaus {
    // Color constants - clean, professional palette
    string constant GOLDEN = "#D1B931";
    string constant CORAL = "#D6694C";
    string constant GREEN = "#439255";
    string constant CYAN = "#7FADD0";
    string constant BLUE = "#2B3D9C";
    string constant DARK_BLUE = "#0F1739";
    string constant WHITE = "#FFFFFF";
    string constant LIGHT_GRAY = "#CACACA";

    enum colorCode {
        GOLDEN,
        CORAL,
        GREEN,
        CYAN,
        BLUE,
        DARK_BLUE,
        WHITE,
        LIGHT_GRAY
    }

    function _colorCode2Hex(colorCode _color) private pure returns (string memory) {
        if (_color == colorCode.GOLDEN) {
            return GOLDEN;
        } else if (_color == colorCode.CORAL) {
            return CORAL;
        } else if (_color == colorCode.GREEN) {
            return GREEN;
        } else if (_color == colorCode.CYAN) {
            return CYAN;
        } else if (_color == colorCode.BLUE) {
            return BLUE;
        } else if (_color == colorCode.DARK_BLUE) {
            return DARK_BLUE;
        } else if (_color == colorCode.WHITE) {
            return WHITE;
        } else if (_color == colorCode.LIGHT_GRAY) {
            return LIGHT_GRAY;
        } else {
            return DARK_BLUE;
        }
    }
    
    function _colorCode2Hex(colorCode _color, uint8 _alpha) private pure returns (string memory) {
        string memory baseColor = _colorCode2Hex(_color);
        
        if (_alpha == 255) {
            return baseColor;
        }
        
        string memory hexAlpha = LibString.toHexString(uint256(_alpha));
        if (bytes(hexAlpha).length == 1) {
            hexAlpha = string.concat("0", hexAlpha);
        }
        
        return string.concat(baseColor, hexAlpha);
    }

    // Quadtree structure used for generating line-based patterns
    struct QuadtreeCell {
        uint256 x;
        uint256 y;
        uint256 width;
        uint256 height;
        bool divided;
    }

    // Line segment structure
    struct Line {
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
    }

    // Main entry point - selects pattern based on status
    function _bauhaus(string memory _collName, uint256 _status) internal pure returns (string memory) {
        if (_status == 0) {        // Active
            return _reflectionPattern(_colorCode2Hex(colorCode.GREEN));
        } else if (_status == 1) { // Closed
            return _ttenPattern(_colorCode2Hex(colorCode.BLUE));
        } else if (_status == 2) { // Liquidated
            return _gyratePattern(_colorCode2Hex(colorCode.CORAL));
        } else {                   // Below Min Debt
            return _geometricPattern(0.8, 14, 24680, _colorCode2Hex(colorCode.CORAL));
        }
    }
    
    // PRNG functions for deterministic generation
    function _random(uint256 seed) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed)));
    }
    
    function _randomRange(uint256 seed, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (_random(seed) % (max - min));
    }
    
    // Generate a quadtree-based geometric pattern with line segments
    function _geometricPattern(
        uint8 strokeWidth, 
        uint8 complexity, 
        uint256 seed, 
        string memory color
    ) private pure returns (string memory) {
        string memory result = "";
        
        // Define the pattern box
        uint256 boxX = 26;
        uint256 boxY = 65;
        uint256 boxWidth = 248;
        uint256 boxHeight = 248;
        
        // Add background
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", color),
                    svg.prop("fill-opacity", "0.15")
                )
            )
        );
        
        // Create the initial cell
        QuadtreeCell memory root = QuadtreeCell({
            x: boxX,
            y: boxY,
            width: boxWidth,
            height: boxHeight,
            divided: false
        });
        
        // Generate a predefined number of cells based on complexity
        QuadtreeCell[] memory cells = new QuadtreeCell[](30);
        cells[0] = root;
        uint256 cellCount = 1;
        
        // Generate a predetermined pattern based on seed
        for (uint256 i = 0; i < 8 && i < cellCount; i++) {
            uint256 currentSeed = seed + i;
            
            // Divide some cells based on deterministic rules
            if (!cells[i].divided && _random(currentSeed) % 100 < 80) {
                // Mark as divided
                cells[i].divided = true;
                
                // Check if we have space for 4 more cells
                if (cellCount + 4 <= cells.length) {
                    uint256 halfWidth = cells[i].width / 2;
                    uint256 halfHeight = cells[i].height / 2;
                
                    // NW
                    cells[cellCount++] = QuadtreeCell({
                        x: cells[i].x,
                        y: cells[i].y,
                        width: halfWidth,
                        height: halfHeight,
                        divided: false
                    });
                    
                    // NE
                    cells[cellCount++] = QuadtreeCell({
                        x: cells[i].x + halfWidth,
                        y: cells[i].y,
                        width: halfWidth,
                        height: halfHeight,
                        divided: false
                    });
                    
                    // SW
                    cells[cellCount++] = QuadtreeCell({
                        x: cells[i].x,
                        y: cells[i].y + halfHeight,
                        width: halfWidth,
                        height: halfHeight,
                        divided: false
                    });
                    
                    // SE
                    cells[cellCount++] = QuadtreeCell({
                        x: cells[i].x + halfWidth,
                        y: cells[i].y + halfHeight,
                        width: halfWidth,
                        height: halfHeight,
                        divided: false
                    });
                }
            }
        }
        
        // Generate and draw division lines
        for (uint256 i = 0; i < cellCount; i++) {
            if (cells[i].divided) {
                uint256 midX = cells[i].x + (cells[i].width / 2);
                uint256 midY = cells[i].y + (cells[i].height / 2);
                
                // Vertical division line
                result = string.concat(
                    result,
                    svg.line(
                        string.concat(
                            svg.prop("x1", LibString.toString(midX)),
                            svg.prop("y1", LibString.toString(cells[i].y)),
                            svg.prop("x2", LibString.toString(midX)),
                            svg.prop("y2", LibString.toString(cells[i].y + cells[i].height)),
                            svg.prop("stroke", WHITE),
                            svg.prop("stroke-width", LibString.toString(strokeWidth)),
                            svg.prop("stroke-opacity", "0.8")
                        )
                    )
                );
                
                // Horizontal division line
                result = string.concat(
                    result,
                    svg.line(
                        string.concat(
                            svg.prop("x1", LibString.toString(cells[i].x)),
                            svg.prop("y1", LibString.toString(midY)),
                            svg.prop("x2", LibString.toString(cells[i].x + cells[i].width)),
                            svg.prop("y2", LibString.toString(midY)),
                            svg.prop("stroke", WHITE),
                            svg.prop("stroke-width", LibString.toString(strokeWidth)),
                            svg.prop("stroke-opacity", "0.8")
                        )
                    )
                );
            }
        }
        
        // Generate triangulation lines (diagonals)
        for (uint256 i = 0; i < cellCount; i++) {
            if (cells[i].divided) {
                // Add diagonal lines based on cell-specific seed
                uint256 cellSeed = seed ^ (cells[i].x * 37 + cells[i].y * 13);
                
                if (_random(cellSeed) % 100 < 70) {
                    // Diagonal: top-left to bottom-right
                    result = string.concat(
                        result,
                        svg.line(
                            string.concat(
                                svg.prop("x1", LibString.toString(cells[i].x)),
                                svg.prop("y1", LibString.toString(cells[i].y)),
                                svg.prop("x2", LibString.toString(cells[i].x + cells[i].width)),
                                svg.prop("y2", LibString.toString(cells[i].y + cells[i].height)),
                                svg.prop("stroke", WHITE),
                                svg.prop("stroke-width", LibString.toString(strokeWidth)),
                                svg.prop("stroke-opacity", "0.6")
                            )
                        )
                    );
                }
                
                if (_random(cellSeed + 1) % 100 < 70) {
                    // Diagonal: top-right to bottom-left
                    result = string.concat(
                        result,
                        svg.line(
                            string.concat(
                                svg.prop("x1", LibString.toString(cells[i].x + cells[i].width)),
                                svg.prop("y1", LibString.toString(cells[i].y)),
                                svg.prop("x2", LibString.toString(cells[i].x)),
                                svg.prop("y2", LibString.toString(cells[i].y + cells[i].height)),
                                svg.prop("stroke", WHITE),
                                svg.prop("stroke-width", LibString.toString(strokeWidth)),
                                svg.prop("stroke-opacity", "0.6")
                            )
                        )
                    );
                }
            }
        }
        
        // Add a border
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", "none"),
                    svg.prop("stroke", WHITE),
                    svg.prop("stroke-width", LibString.toString(uint256(strokeWidth) * 15 / 10)), // ×1.5
                    svg.prop("stroke-opacity", "0.9")
                )
            )
        );
        
        return result;
    }
    
    // Generate a 10 PRINT pattern (ttten style) with maze-like diagonal lines
    function _ttenPattern(string memory color) private pure returns (string memory) {
        string memory result = "";
        
        // Define the pattern box
        uint256 boxX = 26;
        uint256 boxY = 65;
        uint256 boxWidth = 248;
        uint256 boxHeight = 248;
        
        // Create background
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", color),
                    svg.prop("fill-opacity", "0.15")
                )
            )
        );
        
        // Add clipping path to contain pattern within bounds
        string memory clipPathId = "ttenClip";
        result = string.concat(
            result,
            svg.clipPath(
                string.concat(
                    svg.prop("id", clipPathId)
                ),
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                        svg.prop("rx", "5")
                    )
                )
            )
        );
        
        // Start a group with clip path
        result = string.concat(
            result,
            "<g ",
            svg.prop("clip-path", string.concat("url(#", clipPathId, ")")),
            ">"
        );
        
        // 10 PRINT pattern parameters
        uint256 gridSize = 20; // Size of each cell
        uint8 strokeWidth = 12; // 1.2px * 10 (for fixed-point math)
        
        // Generate the maze-like pattern
        uint256 seed = 54321;
        
        for (uint256 y = 0; y < boxHeight; y += gridSize) {
            for (uint256 x = 0; x < boxWidth; x += gridSize) {
                // Deterministically choose diagonal based on position and seed
                uint256 cellSeed = seed ^ (x * 31 + y * 17);
                bool isTopLeftToBottomRight = _random(cellSeed) % 100 < 50;
                
                if (isTopLeftToBottomRight) {
                    // Diagonal from top-left to bottom-right (↘)
            result = string.concat(
                result,
                        svg.line(
                    string.concat(
                                svg.prop("x1", LibString.toString(boxX + x)),
                                svg.prop("y1", LibString.toString(boxY + y)),
                                svg.prop("x2", LibString.toString(boxX + x + gridSize)),
                                svg.prop("y2", LibString.toString(boxY + y + gridSize)),
                                svg.prop("stroke", WHITE),
                                svg.prop("stroke-width", LibString.toString(strokeWidth / 10)), // Convert to decimal
                                svg.prop("stroke-opacity", "0.9")
                            )
                        )
                    );
                } else {
                    // Diagonal from top-right to bottom-left (↙)
            result = string.concat(
                result,
                svg.line(
                    string.concat(
                                svg.prop("x1", LibString.toString(boxX + x + gridSize)),
                                svg.prop("y1", LibString.toString(boxY + y)),
                                svg.prop("x2", LibString.toString(boxX + x)),
                                svg.prop("y2", LibString.toString(boxY + y + gridSize)),
                                svg.prop("stroke", WHITE),
                                svg.prop("stroke-width", LibString.toString(strokeWidth / 10)), // Convert to decimal
                                svg.prop("stroke-opacity", "0.9")
                    )
                )
            );
        }
            }
        }
        
        // Close the clipped group
        result = string.concat(result, "</g>");
        
        // Add border
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", "none"),
                    svg.prop("stroke", WHITE),
                    svg.prop("stroke-width", LibString.toString(strokeWidth * 15 / 100)), // ×1.5
                    svg.prop("stroke-opacity", "0.9")
                )
            )
        );
        
        return result;
    }
    
    // Generate a gggyrate-inspired concentric hexagon pattern for Liquidated status
    function _gyratePattern(string memory color) private pure returns (string memory) {
        string memory result = "";
        
        // Define the pattern box
        uint256 boxX = 26;
        uint256 boxY = 65;
        uint256 boxWidth = 248;
        uint256 boxHeight = 248;
        
        // Calculate center and max size
        uint256 centerX = boxX + boxWidth / 2;
        uint256 centerY = boxY + boxHeight / 2;
        
        // Calculate max radius to ensure hexagons reach corners
        // Using Pythagorean theorem to get diagonal length, then scale to ensure coverage
        uint256 diagonal = _sqrt((boxWidth * boxWidth / 4) + (boxHeight * boxHeight / 4));
        uint256 maxRadius = (diagonal * 115) / 100; // Multiply by 1.15 to ensure full coverage
        
        // Create background
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", color),
                    svg.prop("fill-opacity", "0.15")
                )
            )
        );
        
        // Add clipping path to contain pattern within bounds
        string memory clipPathId = "gyrateClip";
        result = string.concat(
            result,
            svg.clipPath(
                string.concat(
                    svg.prop("id", clipPathId)
                ),
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                        svg.prop("rx", "5")
                    )
                )
            )
        );
        
        // Start a group with clip path
            result = string.concat(
                result,
            "<g ",
            svg.prop("clip-path", string.concat("url(#", clipPathId, ")")),
            ">"
        );
        
        // Parameters for concentric hexagons
        uint256 numShapes = 25;
        uint256 fadeOpacityStart = 90; // 0.9 * 100 for fixed-point
        uint256 fadeOpacityEnd = 30;   // 0.3 * 100
        
        // Generate concentric hexagons
        for (uint256 i = numShapes; i > 0; i--) {
            uint256 size = (i * maxRadius) / numShapes;
            uint256 opacity = fadeOpacityStart - ((fadeOpacityStart - fadeOpacityEnd) * (numShapes - i)) / numShapes;
            
            // Generate hexagon points
            string memory points = _generateHexagonPoints(centerX, centerY, size);
            
            // Add the hexagon
            result = string.concat(
                result,
                svg.polygon(
                    string.concat(
                        svg.prop("points", points),
                        svg.prop("fill", "none"),
                        svg.prop("stroke", WHITE),
                        svg.prop("stroke-width", "1"),
                        svg.prop("stroke-opacity", LibString.toString(opacity / 100)) // Convert back to decimal
                    )
                )
            );
        }
        
        // Close the clipped group
        result = string.concat(result, "</g>");
        
        // Add border
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", "none"),
                    svg.prop("stroke", WHITE),
                    svg.prop("stroke-width", "1.5"),
                    svg.prop("stroke-opacity", "0.9")
                )
            )
        );
        
        return result;
    }
    
    // Helper function to calculate square root
    function _sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 result = 1;
        uint256 a = x;
        
        // Newton's method
        while (result + 1 < a / result) {
            result = (result + a / result) / 2;
        }
        return result;
    }
    
    // Helper function to generate hexagon points
    function _generateHexagonPoints(uint256 centerX, uint256 centerY, uint256 size) private pure returns (string memory) {
        string memory points = "";
        
        for (uint256 i = 0; i < 6; i++) {
            // Calculate angle in fixed-point math (100x for precision)
            // (PI/3) * i - PI/6
            uint256 angle = ((i * 10472) - 5236); // 10472 = PI/3 * 10000, 5236 = PI/6 * 10000
            
            // Calculate x and y using sine and cosine approximations
            int256 x = int256(centerX) + _fixedCos(angle) * int256(size) / 10000;
            int256 y = int256(centerY) + _fixedSin(angle) * int256(size) / 10000;
            
            // Append the point to the points string
            if (i > 0) {
                points = string.concat(points, " ");
            }
            
            points = string.concat(
                points, 
                LibString.toString(uint256(x)), 
                ",", 
                LibString.toString(uint256(y))
            );
        }
        
        return points;
    }
    
    // Fixed-point cosine approximation (input: angle in 10000ths of radians, output: cos(angle) * 10000)
    function _fixedCos(uint256 angle) private pure returns (int256) {
        // Normalize angle to [0, 2π)
        angle = angle % 62832; // 2π * 10000
        
        // Convert to degrees for simpler lookup
        uint256 deg = (angle * 180) / 31416; // * (180/π)
        
        // Simple lookup table for common angles
        if (deg == 0 || deg == 360) return 10000;      // cos(0°) = 1
        if (deg == 30) return 8660;                    // cos(30°) ≈ 0.866
        if (deg == 60) return 5000;                    // cos(60°) = 0.5
        if (deg == 90) return 0;                       // cos(90°) = 0
        if (deg == 120) return -5000;                  // cos(120°) = -0.5
        if (deg == 150) return -8660;                  // cos(150°) ≈ -0.866
        if (deg == 180) return -10000;                 // cos(180°) = -1
        if (deg == 210) return -8660;                  // cos(210°) ≈ -0.866
        if (deg == 240) return -5000;                  // cos(240°) = -0.5
        if (deg == 270) return 0;                      // cos(270°) = 0
        if (deg == 300) return 5000;                   // cos(300°) = 0.5
        if (deg == 330) return 8660;                   // cos(330°) ≈ 0.866
        
        // Fall back to simpler approximations for other angles
        if (deg < 90) return int256(10000 - ((deg * deg) / 81));    // Quadratic approximation
        if (deg < 180) return -int256(10000 - (((180 - deg) * (180 - deg)) / 81));
        if (deg < 270) return -int256(10000 - (((deg - 180) * (deg - 180)) / 81));
        return int256(10000 - (((360 - deg) * (360 - deg)) / 81));
    }
    
    // Fixed-point sine approximation (input: angle in 10000ths of radians, output: sin(angle) * 10000)
    function _fixedSin(uint256 angle) private pure returns (int256) {
        // sin(x) = cos(x - π/2)
        return _fixedCos(angle + 15708); // + π/2 * 10000
    }

    // Generate a simplified reflection pattern with concentric circles for Active status
    function _reflectionPattern(string memory color) private pure returns (string memory) {
        string memory result = "";
        
        // Define the pattern box
        uint256 boxX = 26;
        uint256 boxY = 65;
        uint256 boxWidth = 248;
        uint256 boxHeight = 248;
        
        // Calculate center point
        uint256 centerX = boxX + boxWidth / 2;
        uint256 centerY = boxY + boxHeight / 2;
        
        // Create background
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", color),
                    svg.prop("fill-opacity", "0.15")
                )
            )
        );
        
        // Add clipping path to contain pattern within bounds
        string memory clipPathId = "reflectionClip";
        result = string.concat(
            result,
            svg.clipPath(
                string.concat(
                    svg.prop("id", clipPathId)
                ),
                svg.rect(
                    string.concat(
                        svg.prop("x", LibString.toString(boxX)),
                        svg.prop("y", LibString.toString(boxY)),
                        svg.prop("width", LibString.toString(boxWidth)),
                        svg.prop("height", LibString.toString(boxHeight)),
                        svg.prop("rx", "5")
                    )
                )
            )
        );
        
        // Start a group with clip path
        result = string.concat(
            result,
            "<g ",
            svg.prop("clip-path", string.concat("url(#", clipPathId, ")")),
            ">"
        );
        
        // Simplified concentric circles pattern
        uint256 circleCount = 24;
        uint256 maxRadius = boxWidth * 70 / 100;
        
        // Draw concentric circles from center
        for (uint256 i = 0; i < circleCount; i++) {
            uint256 radius = (i + 1) * (maxRadius / circleCount);
            
            // Add the circle
            result = string.concat(
                result,
                svg.circle(
                    string.concat(
                        svg.prop("cx", LibString.toString(centerX)),
                        svg.prop("cy", LibString.toString(centerY)),
                        svg.prop("r", LibString.toString(radius)),
                        svg.prop("fill", "none"),
                        svg.prop("stroke", WHITE),
                        svg.prop("stroke-width", "0.5"),
                        svg.prop("stroke-opacity", "0.7")
                    )
                )
            );
        }
        
        // Close the clipped group
        result = string.concat(result, "</g>");
        
        // Add border
        result = string.concat(
            result,
            svg.rect(
                string.concat(
                    svg.prop("x", LibString.toString(boxX)),
                    svg.prop("y", LibString.toString(boxY)),
                    svg.prop("width", LibString.toString(boxWidth)),
                    svg.prop("height", LibString.toString(boxHeight)),
                    svg.prop("rx", "5"),
                    svg.prop("fill", "none"),
                    svg.prop("stroke", WHITE),
                    svg.prop("stroke-width", "1.5")
                )
            )
        );
        
        return result;
    }
}
