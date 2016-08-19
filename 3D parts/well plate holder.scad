$fn = 24;
// parameters (mm)

baseLength = 127.76;            // plate length
baseWidth = 85.48;              // plate width
room = .17;

length = baseLength + room*2;   // indentation length
width = baseWidth + room*2;     // indentation width
height = 10;                    // indentation height


// for specific max dimensions: 
// marginX = ([desiredLength] - length) / 2;
// marginY = ([desiredWidth] - width) / 2;
// marginZ = ([desiredHeight] - height);
marginX = 10;            // wall thickness (length)
marginY = 10;            // wall thickness (width)
marginZ = 6;             // base thickness (height)

// to remove a strut set it to 0
lipWidth = 10;          // lip width
strutA = 15;            // - strut width
strutB = 12;            // | strut width
strutX = 10;            // X struts width
strutZ = 5;             // strut thickness

screwMargin = 8;
screwRad = 2;
screwHeadRad = 4;
screwHeadDepth = 2;
screwDistX = 122;
screwDistY = 122;
plateThickness = 5;

// calculations
fullLength = length + marginX * 2;  // full length
fullWidth = width + marginY * 2;    // full width
fullHeight = height + marginZ;    // full height
cutoutLength = length - lipWidth * 2;  // cutout length
cutoutWidth = width - lipWidth * 2;    // cutout width
// diagonal strut length
strutLength = sqrt(cutoutLength*cutoutLength + cutoutWidth*cutoutWidth);
// screw plate dimensions
plateX = screwMargin * 2;
plateY = (screwMargin + (screwDistY - fullWidth) / 2);
offsetX = (screwMargin + (screwDistX - fullLength) / 2);


// Frame
translate([offsetX, plateY, 0]){
    // well plate (remove for printing)
    /*
    translate([marginX + room, marginY + room, marginZ]){
        cube([127.76, 85.48, 5.5]);
        translate([1.5, 1.5, 0]){
            cube([124.76, 82.48, 14.1]); 
        }
    }
    */
    render() difference(){
        // outside block
        cube([fullLength, fullWidth, fullHeight]);
        // indentation
        translate([marginX, marginY, marginZ]){
            cube([length, width, height]);
        }
        // corner cuts
        translate([0, 0, marginZ]){
            rotate([0, 0, 45]){
                translate([-10, -20, 0]){
                    cube([60, 30, height + 2]);
                }
            }
            cube([33.3, 19.2, height + 2]);
            translate([0, fullWidth, 0]){
                rotate([0, 0, -45]){
                    translate([-10, -10, 0]){
                        cube([60, 30, height + 2]);
                    }
                }
                translate([0, -19.2, 0])
                cube([33.3, 19.2, height + 2]);
            }
            translate([fullLength, fullWidth, 0]){
                rotate([0, 0, 225]){
                    translate([-10, -20, 0]){
                        cube([60, 30, height + 2]);
                    }
                }
                translate([-33.3, -19.2, 0])
                cube([33.3, 19.2, height + 2]);
            }
            translate([fullLength, 0, 0]){
                rotate([0, 0, -225]){
                    translate([-10, -10, 0]){
                        cube([60, 30, height + 2]);
                    }
                }
                translate([-33.3, 0, 0])
                cube([33.3, 19.2, height + 2]);
            }
        }
        // cutout bottom
        translate([marginX + lipWidth, marginY + lipWidth, 0]){
            cube([cutoutLength, cutoutWidth, marginZ]);
        }
        // side holes
        translate([fullLength / 2, 0, fullHeight + 2]){
            rotate([-90, 0, 0]){
            cylinder(h = marginY, r = height + 2);
            }
        }
        translate([fullLength / 2, fullWidth, fullHeight + 2]){
            rotate([90, 0, 0]){
            cylinder(h = marginY, r = height + 2);
            }
        }
        // Bevel
        translate([fullLength / 2, fullWidth / 2, fullHeight+ height/2]){
            intersection(){
                rotate([45, 0, 0]){
                    // along x
                    cube([fullLength, fullWidth/sqrt(2), fullWidth/sqrt(2)], true);
                }
                rotate([0, 45, 0]){
                    // along y
                    cube([fullLength/sqrt(2), fullWidth, fullLength/sqrt(2)], true);
                }
                cube([fullLength, fullWidth, height*2], true);
            }
        }
    }
    
    // Struts
    
    // strutA
    // [   ]
    // [---]
    // [   ].
    translate([(fullLength - strutA) / 2, marginY + lipWidth, 0]){
        cube([strutA, cutoutWidth, strutZ]);
    }

    // strutB
    // [ | ]
    // [ | ]
    // [ | ].
    translate([marginX + lipWidth, (fullWidth - strutB) / 2, 0]){
        cube([cutoutLength, strutB, strutZ]);
    }

    // strutX
    // [\  ]
    // [ \ ]
    // [  \].
    translate([(marginX + lipWidth), (marginY + lipWidth), 0]){
        rotate([0, 0, atan2(cutoutWidth, cutoutLength)]){
            translate([0, -strutX / 2, 0]){
                cube([strutLength, strutX, strutZ]);
            }
        }
    }

    // strutX
    // [  /]
    // [ / ]
    // [/  ].
    translate([(marginX + lipWidth), marginY + width - lipWidth, 0]){
        rotate([0, 0, atan2(-cutoutWidth, cutoutLength)]){
            translate([0, -strutX / 2, 0]){
                cube([strutLength, strutX, strutZ]);
            }
        }
    }
    translate([marginX + lipWidth + cutoutLength, marginY + lipWidth, 0]){
        rotate([0, 0, 45]){
            translate([-10, -10, 0]){
                cube([20,20,marginZ]);
            }
        }
    }
    translate([marginX + lipWidth + cutoutLength, marginY + lipWidth + cutoutWidth, 0]){
        rotate([0, 0, 45]){
            translate([-10, -10, 0]){
                cube([20,20,marginZ]);
            }
        }
    }
}

// Screw plates
render() difference(){
    cube([plateX, plateY, plateThickness]);
    translate([screwMargin, screwMargin, 0]){
        cylinder(h = plateThickness, r = screwRad);
        translate([0, 0, plateThickness - screwHeadDepth]){
            cylinder(h = screwHeadDepth, r1 = screwRad, r2 = screwHeadRad);
        }
    }
}
render() difference(){
    translate([screwDistX, 0, 0]){
        cube([plateX, plateY, plateThickness]);
    }
    translate([screwMargin + screwDistX, screwMargin, 0]){
       cylinder(h = plateThickness, r = screwRad);
       translate([0, 0, plateThickness - screwHeadDepth]){
            cylinder(h = screwHeadDepth, r1 = screwRad, r2 = screwHeadRad);
        }
    } 
}
render() difference(){
    translate([0, plateY + fullWidth, 0]){
        cube([plateX, plateY, plateThickness]);
    }
    translate([screwMargin, screwMargin + screwDistY, 0]){
       cylinder(h = plateThickness, r = screwRad);
       translate([0, 0, plateThickness - screwHeadDepth]){
            cylinder(h = screwHeadDepth, r1 = screwRad, r2 = screwHeadRad);
       }
    }
}
render() difference(){
    translate([screwDistX, plateY + fullWidth, 0]){
        cube([plateX, plateY, plateThickness]);
    }
    translate([screwMargin + screwDistX, screwMargin + screwDistY, 0]){
       cylinder(h = plateThickness, r = screwRad);
       translate([0, 0, plateThickness - screwHeadDepth]){
            cylinder(h = screwHeadDepth, r1 = screwRad, r2 = screwHeadRad);
       }
    }
}