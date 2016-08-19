//////////////////////////////////////////////////////////////////////////////////////////////
// Public Domain Parametric Involute Spur Gear (and involute helical gear and involute rack)
// version 1.1
// by Leemon Baird, 2011, Leemon@Leemon.com
//http://www.thingiverse.com/thing:5505
//
// This file is public domain.  Use it for any purpose, including commercial
// applications.  Attribution would be nice, but is not required.  There is
// no warranty of any kind, including its correctness, usefulness, or safety.
// 
// This is parameterized involute spur (or helical) gear.  It is much simpler and less powerful than
// others on Thingiverse.  But it is public domain.  I implemented it from scratch from the 
// descriptions and equations on Wikipedia and the web, using Mathematica for calculations and testing,
// and I now release it into the public domain.
//
//		http://en.wikipedia.org/wiki/Involute_gear
//		http://en.wikipedia.org/wiki/Gear
//		http://en.wikipedia.org/wiki/List_of_gear_nomenclature
//		http://gtrebaol.free.fr/doc/catia/spur_gear.html
//		http://www.cs.cmu.edu/~rapidproto/mechanisms/chpt7.html
//
// The module gear() gives an involute spur gear, with reasonable defaults for all the parameters.
// Normally, you should just choose the first 4 parameters, and let the rest be default values.
// The module gear() gives a gear in the XY plane, centered on the origin, with one tooth centered on
// the positive Y axis.  The various functions below it take the same parameters, and return various
// measurements for the gear.  The most important is pitch_radius, which tells how far apart to space
// gears that are meshing, and adendum_radius, which gives the size of the region filled by the gear.
// A gear has a "pitch circle", which is an invisible circle that cuts through the middle of each
// tooth (though not the exact center). In order for two gears to mesh, their pitch circles should 
// just touch.  So the distance between their centers should be pitch_radius() for one, plus pitch_radius() 
// for the other, which gives the radii of their pitch circles.
//
// In order for two gears to mesh, they must have the same mm_per_tooth and pressure_angle parameters.  
// mm_per_tooth gives the number of millimeters of arc around the pitch circle covered by one tooth and one
// space between teeth.  The pitch angle controls how flat or bulged the sides of the teeth are.  Common
// values include 14.5 degrees and 20 degrees, and occasionally 25.  Though I've seen 28 recommended for
// plastic gears. Larger numbers bulge out more, giving stronger teeth, so 28 degrees is the default here.
//
// The ratio of number_of_teeth for two meshing gears gives how many times one will make a full 
// revolution when the the other makes one full revolution.  If the two numbers are coprime (i.e. 
// are not both divisible by the same number greater than 1), then every tooth on one gear
// will meet every tooth on the other, for more even wear.  So coprime numbers of teeth are good.
//
// The module rack() gives a rack, which is a bar with teeth.  A rack can mesh with any
// gear that has the same mm_per_tooth and pressure_angle.
//
// Some terminology: 
// The outline of a gear is a smooth circle (the "pitch circle") which has mountains and valleys
// added so it is toothed.  So there is an inner circle (the "root circle") that touches the 
// base of all the teeth, an outer circle that touches the tips of all the teeth,
// and the invisible pitch circle in between them.  There is also a "base circle", which can be smaller than
// all three of the others, which controls the shape of the teeth.  The side of each tooth lies on the path 
// that the end of a string would follow if it were wrapped tightly around the base circle, then slowly unwound.  
// That shape is an "involute", which gives this type of gear its name.
//
//////////////////////////////////////////////////////////////////////////////////////////////

//An involute spur gear, with reasonable defaults for all the parameters.
//Normally, you should just choose the first 4 parameters, and let the rest be default values.
//Meshing gears must match in mm_per_tooth, pressure_angle, and twist,
//and be separated by the sum of their pitch radii, which can be found with pitch_radius().
module gear (
	mm_per_tooth    = 3,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,   //total number of teeth around the entire perimeter
	thickness       = 6,    //thickness of gear in mm
	hole_diameter   = 3,    //diameter of the hole in the center, in mm
	angle           = 0,    //teeth rotate this many degrees from bottom of gear to top.  360 makes the gear a screw with each thread going around once
	teeth_to_hide   = 0,    //number of teeth to delete to make this only a fraction of a circle
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	clearance       = 0.0,  //gap between top of a tooth on one gear and bottom of valley on a meshing gear (in millimeters)
	backlash        = 0.0   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
) {
	pi = 3.1415926;
	p  = mm_per_tooth * number_of_teeth / pi / 2;  //radius of pitch circle
	c  = p + mm_per_tooth / pi - clearance;        //radius of outer circle
	b  = p*cos(pressure_angle);                    //radius of base circle
	r  = p-(c-p)-clearance;                        //radius of root circle
	t  = mm_per_tooth/2-backlash/2;                //tooth thickness at pitch circle
	k  = -iang(b, p) - t/2/p/pi*180;              //angle to where involute meets base circle on each side of tooth
    difference() {
        linear_extrude(height = thickness, center = false, convexity = 10, twist = -360 * thickness * tan(angle) / (number_of_teeth * mm_per_tooth)) for (i = [0:number_of_teeth-teeth_to_hide-1] )
            rotate([0,0,i*360/number_of_teeth])
                
                    polygon(
                        points=[
                            [0, -hole_diameter/10],
                            polar(r, -181/number_of_teeth),
                            polar(r, r<b ? k : -180/number_of_teeth),
                            q7(0/5,r,b,c,k, 1),q7(1/5,r,b,c,k, 1),q7(2/5,r,b,c,k, 1),q7(3/5,r,b,c,k, 1),q7(4/5,r,b,c,k, 1),q7(5/5,r,b,c,k, 1),
                            q7(5/5,r,b,c,k,-1),q7(4/5,r,b,c,k,-1),q7(3/5,r,b,c,k,-1),q7(2/5,r,b,c,k,-1),q7(1/5,r,b,c,k,-1),q7(0/5,r,b,c,k,-1),
                            polar(r, r<b ? -k : 180/number_of_teeth),
                            polar(r, 181/number_of_teeth)
                        ],
                        paths=[[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]]
                    );
        cylinder(h=2*thickness+1, r=hole_diameter/2, center=true, $fn=20);
    }
    
};	
//these 4 functions are used by gear
function polar(r,theta)   = r*[sin(theta), cos(theta)];                            //convert polar to cartesian coordinates
function iang(r1,r2)      = sqrt((r2/r1)*(r2/r1) - 1)/3.1415926*180 - acos(r1/r2); //unwind a string this many degrees to go from radius r1 to radius r2
function q7(f,r,b,r2,t,s) = q6(b,s,t,(1-f)*max(b,r)+f*r2);                         //radius a fraction f up the curved side of the tooth 
function q6(b,s,t,d)      = polar(d,s*(iang(b,d)+t));                              //point at radius d on the involute curve

//a rack, which is a straight line with teeth (the same as a segment from a giant gear with a huge number of teeth).
//The "pitch circle" is a line along the X axis.
module rack (
	mm_per_tooth    = 3,    //this is the "circular pitch", the circumference of the pitch circle divided by the number of teeth
	number_of_teeth = 11,   //total number of teeth along the rack
	thickness       = 6,    //thickness of rack in mm (affects each tooth)
	height          = 120,   //height of rack in mm, from tooth top to far side of rack.
    angle           = 0,    
	pressure_angle  = 28,   //Controls how straight or bulged the tooth sides are. In degrees.
	backlash        = 0.0   //gap between two meshing teeth, in the direction along the circumference of the pitch circle
) {
	pi = 3.1415926;
	a = mm_per_tooth / pi; //addendum
	t = a*cos(pressure_angle)-1;        //tooth side is tilted so top/bottom corners move this amount
    multmatrix([[1, 0, tan(angle), 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [0, 0, 0, 1]])  {
            linear_extrude(height = thickness, center = false, convexity = 10) for (i = [0:number_of_teeth-1] )
                translate([i*mm_per_tooth,0,0])
                    
                        polygon(
                            points=[
                                [-mm_per_tooth * 3/4,                 a-height],
                                [-mm_per_tooth * 3/4 - backlash,     -a],
                                [-mm_per_tooth * 1/4 + backlash - t, -a],
                                [-mm_per_tooth * 1/4 + backlash + t,  a],
                                [ mm_per_tooth * 1/4 - backlash - t,  a],
                                [ mm_per_tooth * 1/4 - backlash + t, -a],
                                [ mm_per_tooth * 3/4 + backlash,     -a],
                                [ mm_per_tooth * 3/4,                 a-height],
                            ],
                            paths=[[0,1,2,3,4,5,6,7]]
                        );
    }
};	

//These 5 functions let the user find the derived dimensions of the gear.
//A gear fits within a circle of radius outer_radius, and two gears should have
//their centers separated by the sum of their pitch_radius.
function circular_pitch  (mm_per_tooth=3) = mm_per_tooth;                     //tooth density expressed as "circular pitch" in millimeters
function diametral_pitch (mm_per_tooth=3) = 3.1415926 / mm_per_tooth;         //tooth density expressed as "diametral pitch" in teeth per millimeter
function module_value    (mm_per_tooth=3) = mm_per_tooth / pi;                //tooth density expressed as "module" or "modulus" in millimeters
function pitch_radius    (mm_per_tooth=3,number_of_teeth=11) = mm_per_tooth * number_of_teeth / 3.1415926 / 2;
function outer_radius    (mm_per_tooth=3,number_of_teeth=11,clearance=0.1)    //The gear fits entirely within a cylinder of this radius.
	= mm_per_tooth*(1+number_of_teeth/2)/3.1415926  - clearance;              

//////////////////////////////////////////////////////////////////////////////////////////////
//example gear train.  
//Try it with OpenSCAD View/Animate command with 20 steps and 24 FPS.
//The gears will continue to be rotated to mesh correctly if you change the number of teeth.

n1 = 12; //red gear number of teeth
n5 = 15;  //gray rack
mm_per_tooth = 5; //all meshing gears need the same mm_per_tooth (and the same pressure_angle)
pressure_angle=20;
thickness    = 6;   // 1/2 width of gear and rack
hole         = 8.2;   // center hole of gear
height       = 7.5;
angle        = 15;
animLength   = 11;
extensionBot = 30;
extensionTop = 30;
echo("outer radius: ", outer_radius(mm_per_tooth, n1));

d1  = pitch_radius(mm_per_tooth,n1);
rackOffset = mm_per_tooth / 3.1415926; 

// stand upright
rotate([0, -90, 0]){

// red gear
   
rotate([0,0, $t*360/n1 * animLength]){
    color([1.00,0.75,0.75]){
        gear(mm_per_tooth,n1,thickness,hole, angle, 0, pressure_angle);
        mirror([0, 0, 1])
            gear(mm_per_tooth,n1,thickness,hole, angle, 0, pressure_angle);
        render()
        translate([0, 0, -thickness - 9])
        difference(){
            cylinder(r = outer_radius(mm_per_tooth, n1), h = 9);
            cylinder(r = hole / 2, h = 9, $fn = 20);
            translate([0, 0, 4.5])
            rotate([90, 0, 0])
            cylinder(r = 1.5, h = outer_radius(mm_per_tooth, n1), $fn = 10);
        }
    }
}


// rack
translate([(-floor(n5/2)-floor(n1/2)+$t*animLength+n1/2-n5/2 + 2)*mm_per_tooth,-d1-0,0]){
    color([0.75,0.75,0.75]){
        rack(mm_per_tooth,n5,thickness,height, angle, pressure_angle);
        mirror([0, 0, 1])
            rack(mm_per_tooth,n5,thickness,height, angle, pressure_angle);
    }
    
    // bottom extension 
    translate([-extensionBot - mm_per_tooth/4, rackOffset - height, 0]){
        render() difference(){
            translate([0, 0, -thickness]){
                cube([extensionBot, height - rackOffset * 2, thickness * 2]); // shaft
                translate([0, -height * 1.5 - 5, 0])
                    cube([5, height * 1.5 + 5, thickness * 2]); // foot
            }
            translate([0, -height * .7 - 5, 0])
                rotate([0, 90, 0])
                    cylinder(h = 5, r = 3, $fn = 16);// hole
            
            translate([-1, -height * 1.5 - 5, -thickness - 1]){ // foot bevels
                // bottom
                rotate([0, -angle, 0])
                    cube([2.5, height * 2.5 + 5, thickness*1.2]);
                translate([0, 0, thickness * 2 + 2])
                    rotate([0, angle + 90, 0])
                        cube([thickness*1.2, height * 2.5 + 5, 2.5]);
                // top
                translate([6, 0, 0]){
                    rotate([0, -angle, 0])
                        cube([2.5, 8 * 1.5, (thickness+1)/cos(15)]);
                    translate([0, 0, thickness * 2 + 2])
                        rotate([0, angle + 90, 0])
                            cube([(thickness+1)/cos(15), 8*1.5, 2.5]);
                }
            }
        }
        // needle for reference
        //translate([25,-height * .7 - 5, 0])
            //needle();
    }
    
    // top extension
    translate([mm_per_tooth * n5 - mm_per_tooth / 4, rackOffset - height, 0]){
        translate([0, 0, -thickness])
            cube([extensionTop, height - rackOffset * 2, thickness * 2]); // shaft
        translate([extensionTop - 4, 0, 0]){
            render() difference(){
                translate([0, -height * 1.5 - 5, -thickness])
                    cube([4, height * 1.5 + 5, thickness * 2]); // foot
                translate([0, -height * .7 - 5, 0])
                    rotate([0, 90, 0])
                        cylinder(h = 5, r = 4);         // hole
            }
        }
    }
    
}

render(){
    translate([0, 0, 11.5 + .1])
        rotate([0, 180, -90]){
            translate([0, 0, -.1])
                newPlate();
            centerBlock();
            translate([-.1, 0, 0])
                rackGuide();
        }
}

}


// for printing
/*
render() newPlate();
translate([-28, -39, 0])
    cylinder(r = 7, h = 1);
translate([-28, 37, 0])
    cylinder(r = 7, h = 1);
translate([78, -39, 0])
    cylinder(r = 7, h = 1);
translate([78, 37, 0])
    cylinder(r = 7, h = 1);
*/
/*
render() rotate([0, 90, 0])
    translate([16, 0, 0])
        rackGuide();
translate([-2.3, -5, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([-2.3, 4.2, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([-2.3, -27.8, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([-2.3, 27.2, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([3, 35, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([3, -37, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([34.8, 35, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
translate([34.8, -37, 0])
    cylinder(r = 3.5, h = 1, $fn = 20);
*/
/*
render() translate([0, 0, 33])
    rotate([0, 180, 0])
        centerBlock();
translate([19, 35, 0])
    cylinder(r = 5, h = 1);
translate([19, -37, 0])
    cylinder(r = 5, h = 1);
translate([0, 35, 0])
    cylinder(r = 5, h = 1);
translate([-.5, -37, 0])
    cylinder(r = 5, h = 1);
translate([-30, 35, 0])
    cylinder(r = 5, h = 1);
translate([-35, -39, 0])
    cylinder(r = 5, h = 1);
translate([-77, 35, 0])
    cylinder(r = 5, h = 1);
translate([-77, -37, 0])
    cylinder(r = 5, h = 1);
*/

// needle module
module needle(){
$fn = 20;
    rotate([0, -90, 0]){
        render() difference(){
            union(){
                translate([0, 0, .4])
                minkowski(){
                    cube([3.8, 3, .8], true);
                    cylinder(h = .1, r=1.5);
                }
                cylinder(h = 5, r=2.8);    
                translate([0, 0, 9]){
                    difference(){
                        intersection(){
                            minkowski(){
                            cube([3.8, 3, 10], true);
                                
                            cylinder(h = 1, r=1.5);
                            }
                            translate([0, 0, 2])
                            sphere(r = 7, $fn = 40);
                        }
                        translate([0, 0, 9]){
                            rotate_extrude(angle = 360){
                                translate([5.4, 0, 0])
                                    scale([.8, 1.1, 1])
                                        circle(r = 6, $fn = 40);
                            }
                        }
                    }
                }
                translate([0, 0, 15]){
                        cylinder(h = 1.1, r1 = 1.5, r2 = 1.5);
                        translate([0, 0, 1.1]) 
                            cylinder(h = 1.7, r1 = 1.5, r2 = 1.1);
                        cylinder(h = 3, r1 = 1.1, r2 = 1);
                    }
                //needle
                cylinder(h = 70, r = .3);
            }
            translate([-7, 0, 0]){
                cylinder(h = 15, r = 3.9, $fn = 40);
            }
            translate([7, 0, 0]){
                cylinder(h = 15, r = 3.9, $fn = 40);
            }
            cylinder(h = 7, r = 2.1);
            translate([0, 0, 7]){
                cylinder(h = 2, r1 = 2.1, r2 = .5);
                translate([0, 0, 2])
                    cylinder(h = 5, r1 = .5, r2 = .25);
            }
            cylinder(h = 70, r = .2);
        }
    }
}

// plate module
module plate(){
    difference(){
        linear_extrude(height = 4){
            difference(){
                polygon(points = [[0, 0], 
                                  [0, 9.8], 
                                  [3.7, 11.2], 
                                  [14, 41.8], 
                                  [11, 49], 
                                  [14, 54.4], 
                                  [30, 60], 
                                  [60, 63],
                                  [79.3, 63],
                                  [79.3, 44.2],
                                  [58, 0]]);
                translate([7.9, 5.8, 0])
                    circle(r = 2.05);
                translate([19, 47.6, 0])
                    circle(r = 2.05);
                translate([27.2, 49.3, 0])
                    circle(r = 2.05);
                translate([44, 17, 0])
                    circle(r = 2.05);
                translate([54.1, 5.8, 0])
                    circle(r = 2.05);
                translate([68.2, 38.2, 0])
                    circle(r = 2.05);
                translate([26.3, 33.7, 0])
                    circle(r = 6.4);
            }
        }
        translate([26.3, 33.7, -1.6])
            cylinder(r = 11.1, h = 4);
    }
}

module newPlate(){
    difference(){
        union(){
            translate([-24, -34.5, 0])
                cube([98, 67, 5]);
            // fitting nubs
            translate([-2.95, -26.9, 0])
                cube([6.9, 11.8, 8]);
            translate([-2.95, 15.1, 0])
                cube([6.9, 11.8, 8]);
            
            translate([39.5, 0, 4])
                rotate([0, 0, 15])
                    translate([2.5, 0, 0])
                        intersection(){
                        cube([46, 41, 8], true);
                        rotate([0, 0, 45])
                            cube([58, 58, 8], true);
                        }
        }
        translate([39, 0, 0]){
            rotate([0, 0, 15]){
                    hull(){
                        cylinder(r=12, h = 8);
                        translate([5, 0, 0])
                            cylinder(r=12, h = 8);
                    }
                translate([-31/2, -31/2, 0])
                    hull(){
                        cylinder(r=1.9, h = 8, $fn = 11);
                        translate([5, 0, 0])
                            cylinder(r=1.9, h = 8, $fn = 11);
                    }
                translate([-31/2, 31/2, 0])
                    hull(){
                        cylinder(r=1.9, h = 8, $fn = 11);
                        translate([5, 0, 0])
                            cylinder(r=1.9, h = 8, $fn = 11);
                    }
                translate([31/2, 31/2, 0])
                    hull(){
                        cylinder(r=1.9, h = 8, $fn = 11);
                        translate([5, 0, 0])
                            cylinder(r=1.9, h = 8, $fn = 11);
                    }
                translate([31/2, -31/2, 0])
                    hull(){
                        cylinder(r=1.9, h = 8, $fn = 11);
                        translate([5, 0, 0])
                            cylinder(r=1.9, h = 8, $fn = 11);
                    }
            }
        }
        cylinder(r = 6.5, h = 5);
        cylinder(r = 11.4, h = 3);
        
        // through holes
        translate([10, -16, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
        translate([10, 16, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
        translate([38, -27, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
        translate([38, 27, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
        translate([68, -27, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
        translate([68, 27, 0])
            cylinder(r = 2.4, h = 5, $fn = 11);
       
        // rack guide grooves
        translate([-19.3, -32.8, 0]){
            translate([0, 6.8, 0])
                cube([3.6, 19.2, 5]);
            translate([0, 38.8, 0])
                cube([3.6, 19.2, 5]);
        }
    }
}

module centerBlock(){
    translate([0, 0, 5]){
        difference(){
            // middle block
            translate([-16, -34.5, 0])
                cube([90, 67, 28]);
            // room for gear
            cylinder(r = 12, h = 22);
            // room for rack
            translate([-16, -34.5, 0])
                cube([9, 67, 13]);
            //room for motor
            translate([39.5, -5, 0])
                    cube([48, 34, 60], true);
            translate([39.5, 0, 0])
                rotate([0, 0, 15])
                    translate([2.5, 0, 0])
                        intersection(){
                            cube([48, 43, 60], true);
                            rotate([0, 0, 45])
                                cube([59, 59, 60], true);
                        }
            // attachment holes
            translate([19, -24, 5]){
                rotate([-90, 0, 0]){
                    rotate([0, 0, 90])
                        cylinder(r = 3.4, h = 10, $fn = 6);
                    cylinder(r = 1.9, h = 25, center = true, $fn = 10);
                    translate([0, -11, 0]){
                        rotate([0, 0, 90])
                            cylinder(r = 3.4, h = 10, $fn = 6);
                        cylinder(r = 1.9, h = 25, center = true, $fn = 10);
                    } 
                    translate([37.5, 0, 0]){
                        rotate([0, 0, 90])
                            cylinder(r = 3.4, h = 10, $fn = 6);
                        cylinder(r = 1.9, h = 25, center = true, $fn = 10);
                    }
                    translate([37.5, -11, 0]){
                        rotate([0, 0, 90])
                            cylinder(r = 3.4, h = 10, $fn = 6);
                        cylinder(r = 1.9, h = 25, center = true, $fn = 10);
                    }
                }
            }
            // through holes
            translate([10, -16, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            translate([10, 16, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            translate([38, -27, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            translate([38, 27, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            translate([68, -27, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            translate([68, 27, 0])
                cylinder(r = 2.4, h = 28, $fn = 10);
            
            // bearing socket
            translate([0, 0, 22]){
                cylinder(r = 6.5, h = 5);
                translate([0, 0, 3])
                    cylinder(r = 11.4, h = 3);
            }
            // rack guide screw holes
            translate([-16.1, 0, 21]){
                rotate([0, 90, 0]){
                    translate([0, -21, 0]){
                        cylinder(r = 1.9, h = 15, $fn = 10);
                        translate([0, 0, 6])
                            cylinder(r = 3.4, h = 5, $fn = 6);
                    }
                    translate([0, 21, 0]){
                        cylinder(r = 1.9, h = 15, $fn = 10);
                        translate([0, 0, 6])
                            cylinder(r = 3.4, h = 5, $fn = 6);
                    }
                }
            }
            // hollows and cuts
            translate([-3.3, -27.2, 0])
                cube([7.6, 12.2, 30]);
            translate([-3.3, -34.5, 0])
                cube([7.6, 19.5, 30]);
            translate([-7.3, -27.2, 17])
                cube([7.6, 12.2, 20]);
            translate([-3.3, 14.9, 0])
                cube([7.6, 12.2, 30]);
            translate([-3.3, 14.9, 0])
                cube([7.6, 18.2, 30]);
            translate([-7.3, 14.9, 17])
                cube([7.6, 12.2, 20]);
            translate([-16, -3, 0])
                cube([10, 6, 22]);
            
            translate([4, 20, 0])
            intersection(){
                rotate([0, 0, 15])
                    cube([35, 13, 30]);
                    cube([29, 13, 30]);
            }
        }
    }
}

module rackGuide(){
    difference(){
        union(){
            translate([-20, -34.5, 5])
                cube([4, 67, 28]);
            // fitting nubs
            translate([-19, -32.5, 0]){
                translate([0, 6.8, 0])
                    cube([3, 18.6, 5]);
                translate([0, 38.8, 0])
                    cube([3, 18.6, 5]);
            }
        }
        translate([-20.1, 0, 26]){
            rotate([0, 90, 0]){
                translate([0, -21, 0]){
                    hull(){
                        cylinder(r = 1.9, h = 5, $fn = 11);
                        translate([10, 0, 0])
                            cylinder(r = 1.9, h = 5, $fn = 11);
                    }
                    translate([10, 0, 0])
                        cylinder(r = 4.5, h = 5, $fn = 20);
                }
                translate([0, 21, 0]){
                    hull(){
                        cylinder(r = 1.9, h = 5, $fn = 11);
                        translate([10, 0, 0])
                            cylinder(r = 1.9, h = 5, $fn = 11);
                    }
                    translate([10, 0, 0])
                        cylinder(r = 4.5, h = 5, $fn = 20);
                }
            }
        }
    }
}