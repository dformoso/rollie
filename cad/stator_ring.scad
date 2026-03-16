// ==========================================
// GLOBAL PARAMETERS
// ==========================================
hub_outer_diameter    = 26;  // Outer diameter of the central hub
hub_rotation          = 30;  // Rotation of the inner hub and its features (degrees)
hub_depth             = 33;   

// Shroud (Outer Cylinder) Variables
shroud_width          = 33;  // Width of the outer cylinder (Z-axis)
shroud_outer_diameter = 120;
shroud_thickness      = 12;  // Thickness of the outer wall
shroud_inner_diameter = shroud_outer_diameter - (shroud_thickness * 2); 
webbing_depth         = shroud_width; 

strut_thickness       = 3;   // Width of the 3 radial connecting struts

// ==========================================
// SEGMENT SPECIFIC VARIABLES
// ==========================================

// --- TOP LEFT: CAMERA & PICO ---
// Camera Window (SUBTRACTIVE)
camera_window_length    = 25; 
camera_window_thickness = 12; 
camera_window_offset    = 65; 
camera_window_width     = 27; 

// Camera Cable Hole
camera_cable_length     = 12;   
camera_cable_thickness  = 10;   
camera_cable_offset     = 62;   
camera_cable_width      = 25; 
camera_cable_x_offset   = 0;    
camera_cable_y_offset   = -15;  
camera_cable_z_offset   = 0;    

// Pi Pico Components Bay (FLIPPED TO A HORIZONTAL SHELF)
pico_shelf_width     = 90;    // Width of the shelf (tangential span)
pico_shelf_thickness = 4;     // Z-axis thickness
pico_shelf_offset    = 18;    // Radial distance from center to inner edge
pico_shelf_depth     = 20;    // Radial depth
pico_shelf_z_offset  = -14.5; // Vertical placement along the Z-axis

// --- TOP RIGHT: SCREEN & PI ZERO ---
// Screen Components Bay Brace
screen_brace_length    = 80;
screen_brace_thickness = 5;
screen_brace_offset    = 43.5;

// Screen Bay Window (SUBTRACTIVE)
screen_window_length    = 70;
screen_window_thickness = 27;
screen_window_offset    = 70;
screen_window_width     = 34;   

// Pi Zero Access Hole (SUBTRACTIVE)
pi_access_length    = 52;
pi_access_width     = 28; 
pi_access_thickness = 10; 
pi_access_offset    = screen_brace_offset + 2;

// --- TOP & BOTTOM: CABLE ROUTING ---
// Pi Zero Top Cable Routing Hole (SUBTRACTIVE)
top_routing_length    = 53;   
top_routing_thickness = 37;    
top_routing_offset    = -16;   // Negative pushes it through center to the Top
top_routing_width     = 16.8; 
top_routing_x_offset  = 00;    
top_routing_y_offset  = 0;    
top_routing_z_offset  = 0;    

// Pi Zero Bottom Cable Routing Hole (SUBTRACTIVE)
bottom_routing_length    = 20;   
bottom_routing_thickness = 25;    // Shortened to avoid the lead pellet compartment
bottom_routing_offset    = 45;    // Ends safely at R=42 (Pellet box starts at 48)
bottom_routing_width     = 16.8; 
bottom_routing_x_offset  = 42;    
bottom_routing_y_offset  = 20;    
bottom_routing_z_offset  = 0;  

// Power Switch Hole (SUBTRACTIVE)
power_switch_length    = 10;   
power_switch_thickness = 9.1;    
power_switch_offset    = 50;    // +5mm offset applied here (45 + 5)
power_switch_width     = 8.4; 
power_switch_x_offset  = 55;    
power_switch_y_offset  = 30;    
power_switch_z_offset  = 0; 

// --- BOTTOM: COMPONENTS & BATTERY ---
// Bottom Components Bay Brace
bottom_brace_length    = 75;
bottom_brace_thickness = 2;
bottom_brace_offset    = 22;

// Battery Bottom Brace Cutout
battery_cutout_length    = 65;  
battery_cutout_height    = 24;  
battery_cutout_thickness = 10;  // Increased thickness to ensure a clean boolean punch 
battery_cutout_x_offset  = 3.5;   
battery_cutout_y_offset  = 0;   
battery_cutout_z_offset  = 0;   

// Battery Cable Routing Cavities
battery_cavity_radius = 0;      
battery_cavity_depth  = 10;     
battery_cavity_angles = [210, 330]; 

// Battery Strut Cable Hole (Bottom Left)
strut_hole_length   = 43;  
strut_hole_width    = 16;  
strut_hole_height   = 25;  
strut_hole_dist     = 26;  
strut_hole_angle    = 210; 
strut_hole_x_offset = 8;   
strut_hole_y_offset = 0;   
strut_hole_z_offset = 0;   

// --- BOTTOM LEFT: BNO055 SENSOR ---
bno055_rotation        = 186;   // Single variable to move all BNO055 objects

// BNO055 Components Bay Brace
bno055_brace_length    = 34;    
bno055_brace_thickness = 5;
bno055_brace_offset    = 57.5;  // Positioned directly in the middle of the strut (r=13 to r=48)

// BNO055 Bay Window (SUBTRACTIVE)
bno055_window_length    = 30;   // Cutout to leave the back exposed
bno055_window_thickness = 7;   
bno055_window_offset    = 60.5;
bno055_window_width     = 25;   // Z-height of the exposed window

// BNO055 Access Hole (Cross Shape +)
// Horizontal slot (wider than mount Y spacing of 20.32mm, shorter than Z spacing of 15.24mm)
bno055_cross_h_length    = 28;   
bno055_cross_h_width     = 0;    
// Vertical slot (narrower than mount Y spacing of 20.32mm, taller than Z spacing of 15.24mm)
bno055_cross_v_length    = 15.5;    
bno055_cross_v_width     = 18;   
bno055_cross_thickness   = 15;   // Deep enough to punch completely through the wall
bno055_cross_offset      = 57.5; // Same base offset as the brace

// BNO055 Mounts
bno055_mount_spacing_y = 20.32; // Tangential metric spacing for Adafruit board (longer side)
bno055_mount_spacing_z = 15.24; // Z-axis metric spacing (shorter side)
bno055_mount_hole_dia  = 3.2;   // Matches the camera mount hole size
bno055_mount_depth     = 12;
bno055_mount_dist      = 55;  // Middle of the strut
bno055_mount_z_offset  = 0;


// --- BOTTOM: LEAD BALL COMPARTMENT ---
ball_wall_height_front = 12.5;  
ball_wall_height_back  = 12.5;  
ball_wall_thickness    = 20;     
ball_wall_width        = 65;    
ball_wall_z_spacing    = 33;    

// Lead Ball Compartment Pocket (SHROUD CARVE)
ball_pocket_depth    = 15;  
ball_pocket_width    = 60;  
ball_pocket_height   = 22;  
ball_pocket_x_offset = -15; 
ball_pocket_y_offset = 0;   
ball_pocket_z_offset = 0;   

// ==========================================
// MOTOR & LAZY SUSAN PARAMETERS
// ==========================================
motor_width          = 11.8;
motor_height         = 10;  
motor_depth          = 30;   
motor_z_offset       = 16;   
dovetail_cap_expand  = 0.4; 

// Motor Enclosure Clearance Parameters
cap_cutout_depth  = 1.2;  
cap_cutout_length = 8.0;  
cap_cutout_width  = 18.0; 
cap_cutout_offset = 0;    

hub_cutout_depth  = 1.2;  
hub_cutout_length = 18.0; 
hub_cutout_width  = 16.0; 
hub_cutout_offset = 0;    

// Motor Cable Routing Hole
motor_cable_hole_width    = 20; // thickness
motor_cable_hole_length   = 9;  
motor_cable_hole_height   = 18; 
motor_cable_hole_rotation = 0;  
motor_cable_hole_x_offset = 5;  
motor_cable_hole_y_offset = -9.4; 
motor_cable_hole_z_offset = 0;  

// Lazy Susan Mounts
lazy_susan_hole_spacing  = 75.8; 
lazy_susan_hole_diameter = 4;  
lazy_susan_hole_depth    = 10;   
lazy_susan_rotation      = -14;  

// ==========================================
// MOUNTING HOLES PARAMETERS
// ==========================================
// Camera Mounts (Top Left)
camera_mount_spacing_x = 12.5;
camera_mount_spacing_y = 21;
camera_mount_hole_dia  = 3.2;  
camera_mount_depth     = 11;
camera_mount_rot       = 150;  
camera_mount_dist      = 52;   
camera_mount_x_offset  = 0;    
camera_mount_y_offset  = -3;   
camera_mount_z_offset  = 0;    

// Screen Mounts (Top Right)
screen_mount_spacing_x = 58;
screen_mount_spacing_y = 23;
screen_mount_hole_dia  = 4.2;  
screen_mount_depth     = 15;
screen_mount_rot       = 30;   
screen_mount_dist      = screen_brace_offset;
screen_mount_z_offset  = 0;

// Pi Pico Mounts (Top Left Shelf)
pico_mount_spacing_x = 11.4; 
pico_mount_spacing_y = 47;   
pico_mount_hole_dia  = 3;    
pico_mount_depth     = 10;   
pico_cutout_width    = 16;   
pico_cutout_length   = 40;   
pico_mount_rot       = 150;  
pico_mount_dist      = pico_shelf_offset + (pico_shelf_depth / 2); 
pico_mount_z_offset  = pico_shelf_z_offset; 

// Regulator Mounts (Radial Strut)
regulator_mount_spacing  = 20.5; 
regulator_mount_hole_dia = 3;    
regulator_mount_depth    = 5;    
regulator_mount_angle    = 330;  
regulator_mount_dist     = 26;   
regulator_mount_z_offset = 0;    

$fn = 120;

// ==========================================
// MODULE DEFINITIONS
// ==========================================
module BraceSegment(rot, length, thickness, distance_from_center) {
    rotate([0, 0, rot])
    translate([distance_from_center - thickness, -length/2])
    square([thickness, length]);
}

module ShelfSegment(rot, width, depth, thickness, distance_from_center, z_offset) {
    rotate([0, 0, rot])
    translate([distance_from_center + (depth / 2), 0, z_offset])
    cube([depth, width, thickness], center = true);
}

module MotorDovetailTrench() {
    linear_extrude(height = motor_depth, center = true) {
        polygon(points=[
            [-motor_width/2, -motor_height/2],
            [motor_width/2, -motor_height/2],
            [motor_width/2, -8.2], 
            [hub_outer_diameter/2 + 1, -motor_width/2], 
            [hub_outer_diameter/2 + 1, motor_width/2],
            [motor_width/2, 8.2],
            [motor_width/2, motor_height/2],
            [-motor_width/2, motor_height/2]
        ]);
    }
}

module DovetailCap() {
    cap_tol = 0.15; 
    exp = dovetail_cap_expand / 2; 
    cap_length = (hub_depth / 2) - (motor_z_offset - (motor_depth / 2));
    
    difference() {
        intersection() {
            linear_extrude(height = cap_length) {
                polygon([
                    [0, -8.2 + cap_tol - exp],
                    [7.8, -6.2 + cap_tol - exp],
                    [7.8, 6.2 - cap_tol + exp],
                    [0, 8.2 - cap_tol + exp]
                ]);
            }
            translate([-motor_width/2, 0, -1]) 
                cylinder(d = hub_outer_diameter, h = cap_length + 2);
        }
        
        translate([(cap_cutout_depth/2) - 0.1 + cap_cutout_offset, 0, (cap_cutout_length/2) - 0.1])
            cube([cap_cutout_depth + 0.2, cap_cutout_width, cap_cutout_length + 0.2], center = true);
    }
}

module MountingHolesRect(spacing_length, spacing_height, hole_dia, hole_depth) {
    for (y = [-spacing_length/2, spacing_length/2]) {
        for (z = [-spacing_height/2, spacing_height/2]) {
            translate([0, y, z])
            rotate([0, 90, 0]) 
            cylinder(d = hole_dia, h = hole_depth, center = true);
        }
    }
}

module MountingHolesZ(spacing_x, spacing_y, hole_dia, hole_depth) {
    for (x = [-spacing_x/2, spacing_x/2]) {
        for (y = [-spacing_y/2, spacing_y/2]) {
            translate([x, y, 0])
            cylinder(d = hole_dia, h = hole_depth, center = true);
        }
    }
}

module MountingHolesDiagonalY(diagonal_dist, hole_dia, hole_depth) {
    offset_val = (diagonal_dist / 2) * cos(45);
    
    translate([offset_val, 0, offset_val])
    rotate([90, 0, 0])
    cylinder(d = hole_dia, h = hole_depth, center = true);

    translate([-offset_val, 0, -offset_val])
    rotate([90, 0, 0])
    cylinder(d = hole_dia, h = hole_depth, center = true);
}

// ==========================================
// MAIN GEOMETRY (STATOR)
// ==========================================
difference() {
    union() {
        // 1. Central Hub
        color("silver")
        rotate([0, 0, hub_rotation])
        linear_extrude(height = hub_depth, center = true) {
            circle(d = hub_outer_diameter);
        }

        // 2a. Outer Shroud (Cylinder)
        color("darkgray")
        linear_extrude(height = shroud_width, center = true) {
            difference() {
                circle(d = shroud_outer_diameter);
                circle(d = shroud_inner_diameter);
            }
        }

        // 2b. Structural Webbing (Internal Struts and Vertical Braces)
        color("gray")
        linear_extrude(height = webbing_depth, center = true) {
            union() {
                // Radial Struts
                eps = 0.1; 
                for (i = [0 : 2]) {
                    rotate([0, 0, 90 + (i * 120)])
                    translate([(hub_outer_diameter/2) - eps, -(strut_thickness / 2)]) 
                    square([(shroud_inner_diameter/2) - (hub_outer_diameter/2) + (2 * eps), strut_thickness]);
                }
                
                // Components Bay: Top Right
                BraceSegment(30, screen_brace_length, screen_brace_thickness, screen_brace_offset);
                
                // Components Bay: Bottom
                BraceSegment(270, bottom_brace_length, bottom_brace_thickness, bottom_brace_offset);
                
                // Components Bay: Bottom Left (BNO055 Brace)
                BraceSegment(bno055_rotation, bno055_brace_length, bno055_brace_thickness, bno055_brace_offset);
            }
        }
        
        // 2c. Flipped Components Bay: Top Left (Horizontal Shelf)
        color("gray")
        ShelfSegment(150, pico_shelf_width, pico_shelf_depth, pico_shelf_thickness, pico_shelf_offset, pico_shelf_z_offset);
        
        // 2d. Lead Ball Compartment Walls (Bottom)
        color("darkslategray") {
            z_pos_front = ((ball_wall_z_spacing / 2) - (ball_wall_thickness / 2));
            rotate([0, 0, 270]) 
            translate([(shroud_inner_diameter/2) - (ball_wall_height_front/2), 0, z_pos_front])
                cube([ball_wall_height_front, ball_wall_width, ball_wall_thickness], center = true);

            z_pos_back = -((ball_wall_z_spacing / 2) - (ball_wall_thickness / 2));
            rotate([0, 0, 270]) 
            translate([(shroud_inner_diameter/2) - (ball_wall_height_back/2), 0, z_pos_back])
                cube([ball_wall_height_back, ball_wall_width, ball_wall_thickness], center = true);
        }
    }

    // --- HUB SUBTRACTIONS ---
    rotate([0, 0, hub_rotation]) {
        translate([0, 0,  motor_z_offset]) MotorDovetailTrench();
        translate([0, 0, -motor_z_offset]) MotorDovetailTrench();

        translate([motor_cable_hole_x_offset, motor_cable_hole_y_offset, motor_cable_hole_z_offset])
            rotate([0, 0, motor_cable_hole_rotation])
            cube([motor_cable_hole_width, motor_cable_hole_length, motor_cable_hole_height], center = true);
            
        translate([-motor_width/2 - (hub_cutout_depth/2) + hub_cutout_offset, 0, 0])
            cube([hub_cutout_depth + 0.1, hub_cutout_width, hub_cutout_length], center = true);
    }

    // --- LAZY SUSAN HOLES ---
    eps = 0.1; 
    lazy_susan_radius = lazy_susan_hole_spacing / sqrt(2);
    rotate([0, 0, lazy_susan_rotation]) {
        for (pos = [ [0, lazy_susan_radius], [0, -lazy_susan_radius], [lazy_susan_radius, 0], [-lazy_susan_radius, 0] ]) {
            translate([pos[0], pos[1], (shroud_width / 2) - lazy_susan_hole_depth + eps])
            cylinder(h = lazy_susan_hole_depth + eps, d = lazy_susan_hole_diameter);

            translate([pos[0], pos[1], -(shroud_width / 2) - eps])
            cylinder(h = lazy_susan_hole_depth + eps, d = lazy_susan_hole_diameter);
        }
    }

    // --- TOP RIGHT SUBTRACTIONS ---
    // Screen Bay
    linear_extrude(height = screen_window_width, center = true) {
        BraceSegment(30, screen_window_length, screen_window_thickness, screen_window_offset);
    }
    // Pi Zero Access Hole
    linear_extrude(height = pi_access_width, center = true) {
        BraceSegment(30, pi_access_length, pi_access_thickness, pi_access_offset);
    }
    // Screen Mounting Holes
    rotate([0, 0, screen_mount_rot]) {
        translate([screen_mount_dist, 0, screen_mount_z_offset])
        MountingHolesRect(screen_mount_spacing_x, screen_mount_spacing_y, screen_mount_hole_dia, screen_mount_depth);
    }
    
    // --- TOP LEFT SUBTRACTIONS ---
    // Camera Cable Subtraction
    translate([camera_cable_x_offset, camera_cable_y_offset, camera_cable_z_offset]) {
        linear_extrude(height = camera_cable_width, center = true) {
            BraceSegment(150, camera_cable_length, camera_cable_thickness, camera_cable_offset);
        }
    }
    // Camera Window Subtraction
    linear_extrude(height = camera_window_width, center = true) {
        BraceSegment(150, camera_window_length, camera_window_thickness, camera_window_offset);
    }
    // Camera Mounting Holes
    rotate([0, 0, camera_mount_rot]) {
        translate([camera_mount_dist + camera_mount_x_offset, camera_mount_y_offset, camera_mount_z_offset])
        MountingHolesRect(camera_mount_spacing_x, camera_mount_spacing_y, camera_mount_hole_dia, camera_mount_depth);
    }
    // Pi Pico Mounting Holes & Cutout
    rotate([0, 0, pico_mount_rot]) {
        translate([pico_mount_dist, 0, pico_mount_z_offset]) {
            MountingHolesZ(pico_mount_spacing_x, pico_mount_spacing_y, pico_mount_hole_dia, pico_mount_depth);
            cube([pico_cutout_width, pico_cutout_length, pico_mount_depth + 2], center = true);
        }
    }

    // --- ROUTING HOLES (TOP & BOTTOM) ---
    // Top Cable Routing Hole Subtraction
    translate([top_routing_x_offset, top_routing_y_offset, top_routing_z_offset]) {
        linear_extrude(height = top_routing_width, center = true) {
            BraceSegment(270, top_routing_length, top_routing_thickness, top_routing_offset);
        }
    }
    // Bottom Cable Routing Hole Subtraction
    translate([bottom_routing_x_offset, bottom_routing_y_offset, bottom_routing_z_offset]) {
        linear_extrude(height = bottom_routing_width, center = true) {
            BraceSegment(270, bottom_routing_length, bottom_routing_thickness, bottom_routing_offset);
        }
    }
    // Power Switch Hole Subtraction
    translate([power_switch_x_offset, power_switch_y_offset, power_switch_z_offset]) {
        linear_extrude(height = power_switch_width, center = true) {
            BraceSegment(270, power_switch_length, power_switch_thickness, power_switch_offset);
        }
    }

    // --- BOTTOM SUBTRACTIONS ---
    // Battery Bottom Brace Cutout
    rotate([0, 0, 270]) {
        translate([bottom_brace_offset - (bottom_brace_thickness / 2) + battery_cutout_x_offset, battery_cutout_y_offset, battery_cutout_z_offset])
        cube([battery_cutout_thickness, battery_cutout_length, battery_cutout_height], center = true);
    }
    // Lead Ball Compartment Pocket
    rotate([0, 0, 270]) {
        translate([(shroud_inner_diameter/2) + (ball_pocket_depth/2) - 0.1 + ball_pocket_x_offset, ball_pocket_y_offset, ball_pocket_z_offset])
        cube([ball_pocket_depth + 0.2, ball_pocket_width, ball_pocket_height], center = true);
    }
    // Battery Cable Routing Cavities
    for (angle = battery_cavity_angles) {
        rotate([0, 0, angle]) {
            translate([shroud_inner_diameter/2, 0, shroud_width/2])
                cylinder(r = battery_cavity_radius, h = battery_cavity_depth * 2, center = true);
            translate([shroud_inner_diameter/2, 0, -shroud_width/2])
                cylinder(r = battery_cavity_radius, h = battery_cavity_depth * 2, center = true);
        }
    }
    // Battery Strut Cable Hole (Bottom Left)
    rotate([0, 0, strut_hole_angle]) {
        translate([strut_hole_dist + strut_hole_x_offset, strut_hole_y_offset, strut_hole_z_offset])
        cube([strut_hole_length, strut_hole_width, strut_hole_height], center = true);
    }
    // Regulator Mounting Holes (Radial Strut)
    rotate([0, 0, regulator_mount_angle]) {
        translate([regulator_mount_dist, 0, regulator_mount_z_offset])
        MountingHolesDiagonalY(regulator_mount_spacing, regulator_mount_hole_dia, regulator_mount_depth);
    }
    
    // --- BOTTOM LEFT SUBTRACTIONS (BNO055) ---
    // BNO055 Bay Window
    linear_extrude(height = bno055_window_width, center = true) {
        BraceSegment(bno055_rotation, bno055_window_length, bno055_window_thickness, bno055_window_offset);
    }
    
    // BNO055 Access Hole (Cross Shape +)
    // Horizontal cut
    linear_extrude(height = bno055_cross_h_width, center = true) {
        BraceSegment(bno055_rotation, bno055_cross_h_length, bno055_cross_thickness, bno055_cross_offset);
    }
    // Vertical cut
    linear_extrude(height = bno055_cross_v_width, center = true) {
        BraceSegment(bno055_rotation, bno055_cross_v_length, bno055_cross_thickness, bno055_cross_offset);
    }

    // BNO055 Mounting Holes
    rotate([0, 0, bno055_rotation]) {
        translate([bno055_mount_dist, 0, bno055_mount_z_offset])
        MountingHolesRect(bno055_mount_spacing_y, bno055_mount_spacing_z, bno055_mount_hole_dia, bno055_mount_depth);
    }
}

// Generate Dovetail Caps
translate([-40, 70, -shroud_width/2]) DovetailCap();
translate([-50, 70, -shroud_width/2]) DovetailCap();