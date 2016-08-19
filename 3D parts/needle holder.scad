thickness = 8;
angle = 15;
space = .4;
$fn = 17;

render() difference(){
    union(){
        cylinder(r = 2.85, h = thickness + 3);
        difference(){
            union(){
                translate([-6, -5.75, 0])
                    cube([12, 12.25, thickness]);
                translate([-6, 6.5, 0])
                    cube([12, 3, thickness + 3]);
            }
            translate([0, -5.75, thickness])
                rotate([0, angle, 0])
                    cube([12, 12.25, thickness]);
            translate([0, -5.75, thickness])
                rotate([0, -angle, 0])
                    translate([-12, 0, 0])
                        cube([12, 12.25, thickness]);
            translate([0, 6.5, thickness + 3])
                rotate([0, angle, 0])
                    cube([12, 3, thickness]);
            translate([0, 6.5, thickness + 3])
                rotate([0, -angle, 0])
                    translate([-12, 0, 0])
                        cube([12, 3, thickness]);
            
        }
        
    }
    
    cylinder(r = .3 + space, h = thickness + 3);
    difference(){
        intersection(){
            minkowski(){
            cube([3.8, 3, 9], true);
            cylinder(h = 1, r=1.5 + space);
            }
        }
    }
    translate([0, 0, 5]){
    cylinder(r1 = 2.3 + space, r2 = 1.5 + space, h = 2);
        translate([0, 0, 2]){
            cylinder(h = 1.1, r1 = 1.5 + space, r2 = 1.5 + space);
            translate([0, 0, 1.1]) 
                cylinder(h = 1.7, r1 = 1.5 + space, r2 = 1.1 + space);
            cylinder(h = 3, r1 = 1.1 + space, r2 = 1 + space);
        }
    }
}

//translate([0, 0, -8.])
//    rotate([0, 90, 0])
//        needle();

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